package com.darkhmdda.orbitask

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
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
    val reminderIds: List<String> = emptyList(),
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
 * Datos de los widgets.
 *
 * **Kotlin no abre nunca `orbitask.sqlite`.** La app usa su propia copia de
 * SQLite (paquete `sqlite3`) y el sistema Android trae otra: si las dos abren
 * el mismo archivo en el mismo proceso, al cerrar una se pierden los bloqueos
 * de la otra y la base de datos puede corromperse
 * (https://www.sqlite.org/howtocorrupt.html, apartado 2.2).
 *
 * Por eso Flutter manda las tareas ya leídas (`updateWidgets`), y lo que se
 * marca o desmarca en el widget se guarda aquí como cambio pendiente hasta que
 * Flutter lo aplica en la base de datos (`takeWidgetToggles`).
 */
object OrbitaskWidgetData {
    private const val TAG = "OrbitaskWidgets"
    const val PREFS = "orbitask_widget"
    private const val TASKS_JSON = "tasksJson"
    private const val PENDING_TOGGLES = "pendingToggles"
    private const val PENDING_ACTION = "pendingAction"

    /** Una acción pendiente (abrir tarea, nueva tarea) caduca a los 2 minutos. */
    private const val PENDING_ACTION_TTL_MS = 2 * 60 * 1000L

    /** Clase del plugin flutter_local_notifications que muestra los avisos programados. */
    private const val SCHEDULED_NOTIFICATION_RECEIVER =
        "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Guarda las tareas que manda Flutter (JSON ya preparado en Dart). */
    fun storeTasks(context: Context, tasksJson: String) {
        prefs(context).edit().putString(TASKS_JSON, tasksJson).apply()
    }

    /** Tareas para pintar, con los cambios pendientes del widget ya aplicados. */
    fun tasks(context: Context): List<WidgetTask> {
        val prefs = prefs(context)
        val toggles = readToggles(prefs)
        val array = readArray(prefs.getString(TASKS_JSON, "[]"))

        return List(array.length()) { index ->
            val json = array.getJSONObject(index)
            val id = json.optString("id")
            val toggle = toggles.optJSONObject(id)
            val reminders = json.optJSONArray("reminderIds")
            WidgetTask(
                id = id,
                title = json.optString("title"),
                priority = json.optInt("priority", 0),
                dueMillis = if (json.has("dueMillis") && !json.isNull("dueMillis")) {
                    json.optLong("dueMillis")
                } else {
                    null
                },
                completed = toggle?.optBoolean("completed")
                    ?: json.optBoolean("completed", false),
                updatedAt = toggle?.optLong("at") ?: json.optLong("updatedAt", 0L),
                reminderIds = if (reminders == null) {
                    emptyList()
                } else {
                    List(reminders.length()) { reminders.optString(it) }
                },
            )
        }
    }

    /**
     * Apunta que una tarea se marcó o desmarcó en el widget. Al completarla
     * también cancela en el momento las alarmas de sus recordatorios.
     */
    fun recordToggle(context: Context, taskId: String, completed: Boolean) {
        val prefs = prefs(context)
        val toggles = readToggles(prefs)
        toggles.put(
            taskId,
            JSONObject()
                .put("completed", completed)
                .put("at", System.currentTimeMillis()),
        )
        prefs.edit().putString(PENDING_TOGGLES, toggles.toString()).commit()

        if (completed) {
            val task = tasks(context).firstOrNull { it.id == taskId }
            if (task != null) cancelReminders(context, task.reminderIds)
        }
    }

    /**
     * Devuelve y borra los cambios pendientes para que Flutter los guarde en la
     * base de datos. También los pasa a la copia local de tareas, para que el
     * widget no muestre el estado antiguo mientras Flutter los aplica.
     */
    fun takeToggles(context: Context): List<Map<String, Any>> {
        val prefs = prefs(context)
        val toggles = readToggles(prefs)
        if (toggles.length() == 0) return emptyList()

        val array = readArray(prefs.getString(TASKS_JSON, "[]"))
        for (index in 0 until array.length()) {
            val json = array.getJSONObject(index)
            val toggle = toggles.optJSONObject(json.optString("id")) ?: continue
            json.put("completed", toggle.optBoolean("completed"))
            json.put("updatedAt", toggle.optLong("at"))
        }

        val result = mutableListOf<Map<String, Any>>()
        toggles.keys().forEach { taskId ->
            val toggle = toggles.optJSONObject(taskId) ?: return@forEach
            result.add(mapOf("taskId" to taskId, "completed" to toggle.optBoolean("completed")))
        }

        prefs.edit()
            .putString(TASKS_JSON, array.toString())
            .remove(PENDING_TOGGLES)
            .commit()
        return result
    }

    private fun readToggles(prefs: SharedPreferences): JSONObject = try {
        JSONObject(prefs.getString(PENDING_TOGGLES, "{}") ?: "{}")
    } catch (ignored: Exception) {
        JSONObject()
    }

    private fun readArray(raw: String?): JSONArray = try {
        JSONArray(raw ?: "[]")
    } catch (ignored: Exception) {
        JSONArray()
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
     * caso la app la cancela igualmente al aplicar el cambio.
     */
    private fun cancelReminders(context: Context, reminderIds: List<String>) {
        if (reminderIds.isEmpty()) return
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
