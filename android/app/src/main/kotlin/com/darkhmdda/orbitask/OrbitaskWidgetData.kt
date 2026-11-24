package com.darkhmdda.orbitask

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Una tarea tal como la necesitan los widgets. */
data class WidgetTask(
    val id: String,
    val title: String,
    val priority: Int,
    val dueMillis: Long?,
    val completed: Boolean,
    val updatedAt: Long,
) {
    val dueDate: LocalDate?
        get() = dueMillis?.let {
            Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault()).toLocalDate()
        }

    val isHighPriority: Boolean get() = priority >= PRIORITY_HIGH

    companion object {
        /** `TaskPriority.high` en Dart (none=0, low=1, medium=2, high=3). */
        const val PRIORITY_HIGH = 3
        const val PRIORITY_MEDIUM = 2
    }
}

/**
 * Acceso a los datos de los widgets.
 *
 * Lee y escribe directamente `orbitask.sqlite` (la base de datos local de la
 * app en `filesDir`). Depende del nombre del archivo y de las columnas de las
 * tablas `tasks` y `reminders`: si cambia el esquema local, hay que
 * actualizar también este archivo.
 */
object OrbitaskWidgetData {
    private const val TAG = "OrbitaskWidgets"
    const val PREFS = "orbitask_widget"
    private const val DB_NAME = "orbitask.sqlite"
    private const val TASKS_JSON = "tasksJson"
    private const val PENDING_ACTION = "pendingAction"
    private const val CHANGED_TASKS = "changedTaskIds"

    /** Una acción pendiente (abrir tarea, nueva tarea) caduca a los 2 minutos. */
    private const val PENDING_ACTION_TTL_MS = 2 * 60 * 1000L

    /** Clase del plugin flutter_local_notifications que muestra los avisos programados. */
    private const val SCHEDULED_NOTIFICATION_RECEIVER =
        "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun databaseFile(context: Context) = File(context.filesDir, DB_NAME)

    /** Copia las tareas fuera de la Papelera a SharedPreferences para que los widgets las pinten. */
    fun refreshFromDatabase(context: Context) {
        val dbFile = databaseFile(context)
        if (!dbFile.exists()) return

        val tasks = JSONArray()
        try {
            SQLiteDatabase.openDatabase(
                dbFile.path,
                null,
                SQLiteDatabase.OPEN_READONLY,
            ).use { db ->
                db.rawQuery(
                    """
                    SELECT id, title, priority, due_date, completed, updated_at
                    FROM tasks
                    WHERE trashed_at IS NULL
                    """.trimIndent(),
                    null,
                ).use { cursor ->
                    val idIndex = cursor.getColumnIndexOrThrow("id")
                    val titleIndex = cursor.getColumnIndexOrThrow("title")
                    val priorityIndex = cursor.getColumnIndexOrThrow("priority")
                    val dueIndex = cursor.getColumnIndexOrThrow("due_date")
                    val completedIndex = cursor.getColumnIndexOrThrow("completed")
                    val updatedIndex = cursor.getColumnIndexOrThrow("updated_at")

                    while (cursor.moveToNext()) {
                        val json = JSONObject()
                            .put("id", cursor.getString(idIndex))
                            .put("title", cursor.getString(titleIndex) ?: "")
                            .put("priority", cursor.getInt(priorityIndex))
                            .put("completed", cursor.getInt(completedIndex) != 0)
                            .put("updatedAt", cursor.getLong(updatedIndex))
                        if (!cursor.isNull(dueIndex)) {
                            json.put("dueMillis", cursor.getLong(dueIndex))
                        }
                        tasks.put(json)
                    }
                }
            }
        } catch (error: Exception) {
            Log.w(TAG, "No se pudo leer la base de datos local", error)
            return
        }

        prefs(context).edit().putString(TASKS_JSON, tasks.toString()).apply()
    }

    fun tasks(context: Context): List<WidgetTask> {
        val raw = prefs(context).getString(TASKS_JSON, "[]") ?: "[]"
        val array = try {
            JSONArray(raw)
        } catch (ignored: Exception) {
            JSONArray()
        }
        return List(array.length()) { index ->
            val json = array.getJSONObject(index)
            WidgetTask(
                id = json.optString("id"),
                title = json.optString("title"),
                priority = json.optInt("priority", 0),
                dueMillis = if (json.has("dueMillis")) json.optLong("dueMillis") else null,
                completed = json.optBoolean("completed", false),
                updatedAt = json.optLong("updatedAt", 0L),
            )
        }
    }

    /**
     * Marca o desmarca una tarea desde el widget.
     *
     * Al completarla también cancela sus recordatorios programados. Al
     * desmarcarla, los recordatorios se vuelven a programar cuando se abre la
     * app (ver [takeChangedTasks]).
     */
    fun setCompleted(context: Context, taskId: String, completed: Boolean): Boolean {
        val dbFile = databaseFile(context)
        if (!dbFile.exists()) return false

        val reminderIds = mutableListOf<String>()
        try {
            SQLiteDatabase.openDatabase(
                dbFile.path,
                null,
                SQLiteDatabase.OPEN_READWRITE,
            ).use { db ->
                // La app puede tener la base abierta: espera en vez de fallar al instante.
                db.rawQuery("PRAGMA busy_timeout = 3000", null).use { it.moveToFirst() }

                val values = ContentValues().apply {
                    put("completed", if (completed) 1 else 0)
                    put("updated_at", System.currentTimeMillis())
                }
                db.update("tasks", values, "id = ?", arrayOf(taskId))

                if (completed) {
                    db.rawQuery(
                        "SELECT id FROM reminders WHERE task_id = ?",
                        arrayOf(taskId),
                    ).use { cursor ->
                        while (cursor.moveToNext()) reminderIds.add(cursor.getString(0))
                    }
                }
            }
        } catch (error: Exception) {
            Log.w(TAG, "No se pudo actualizar la tarea $taskId", error)
            return false
        }

        if (reminderIds.isNotEmpty()) cancelReminders(context, reminderIds)
        markChanged(context, taskId)
        refreshFromDatabase(context)
        return true
    }

    /** Mismo cálculo que `NotificationService.notificationId` en Dart (FNV-1a de 31 bits). */
    fun notificationId(reminderId: String): Int {
        var hash = 0x811c9dc5L
        for (codeUnit in reminderId) {
            hash = hash xor codeUnit.code.toLong()
            hash = (hash * 0x01000193L) and 0x7fffffffL
        }
        return if (hash == 0L) 1 else hash.toInt()
    }

    /**
     * Cancela la alarma que flutter_local_notifications programó para cada
     * recordatorio y quita el aviso si ya se mostró. Si el plugin cambiara su
     * forma de programar, esto no encontraría la alarma y no haría nada; en ese
     * caso la app la cancela igualmente al abrirse.
     */
    private fun cancelReminders(context: Context, reminderIds: List<String>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

        reminderIds.forEach { reminderId ->
            val id = notificationId(reminderId)
            try {
                val intent = Intent().setClassName(context, SCHEDULED_NOTIFICATION_RECEIVER)
                val pending = PendingIntent.getBroadcast(
                    context,
                    id,
                    intent,
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
                )
                if (pending != null) {
                    alarmManager?.cancel(pending)
                    pending.cancel()
                }
                notificationManager?.cancel(id)
            } catch (error: Exception) {
                Log.w(TAG, "No se pudo cancelar el recordatorio $reminderId", error)
            }
        }
    }

    private fun markChanged(context: Context, taskId: String) {
        val prefs = prefs(context)
        val ids = HashSet(prefs.getStringSet(CHANGED_TASKS, emptySet()) ?: emptySet())
        ids.add(taskId)
        prefs.edit().putStringSet(CHANGED_TASKS, ids).apply()
    }

    /** Ids de tareas que cambiaron desde el widget. Flutter los recoge al abrirse. */
    fun takeChangedTasks(context: Context): List<String> {
        val prefs = prefs(context)
        val ids = prefs.getStringSet(CHANGED_TASKS, emptySet())?.toList() ?: emptyList()
        prefs.edit().remove(CHANGED_TASKS).apply()
        return ids
    }

    /** Guarda lo que la app debe hacer al abrirse desde el widget. */
    fun storePendingAction(context: Context, action: JSONObject) {
        action.put("createdAt", System.currentTimeMillis())
        prefs(context).edit().putString(PENDING_ACTION, action.toString()).commit()
    }

    fun clearPendingAction(context: Context) {
        prefs(context).edit().remove(PENDING_ACTION).apply()
    }

    /** Devuelve y borra la acción pendiente, si existe y no ha caducado. */
    fun takePendingAction(context: Context): Map<String, Any?>? {
        val prefs = prefs(context)
        val raw = prefs.getString(PENDING_ACTION, null) ?: return null
        prefs.edit().remove(PENDING_ACTION).apply()

        val json = try {
            JSONObject(raw)
        } catch (ignored: Exception) {
            return null
        }
        val age = System.currentTimeMillis() - json.optLong("createdAt", 0L)
        if (age !in 0..PENDING_ACTION_TTL_MS) return null

        val result = mutableMapOf<String, Any?>()
        json.keys().forEach { key ->
            if (key != "createdAt") result[key] = json.opt(key)
        }
        return result
    }
}
