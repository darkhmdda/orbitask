package com.darkhmdda.orbitask

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

object OrbitaskWidgetData {
    private const val PREFS = "orbitask_widget"
    private const val TASKS_JSON = "tasksJson"

    fun refreshFromDatabase(context: Context) {
        val dbFile = File(context.filesDir, "orbitask.sqlite")
        if (!dbFile.exists()) return

        val tasks = JSONArray()
        var completedCount = 0
        var pendingCount = 0
        var importantCount = 0
        var todayCount = 0
        var nextSevenDaysCount = 0
        var overdueCount = 0

        val today = LocalDate.now()
        val end = today.plusDays(6)

        val db = SQLiteDatabase.openDatabase(
            dbFile.path,
            null,
            SQLiteDatabase.OPEN_READONLY,
        )

        db.rawQuery(
            """
            SELECT id, title, priority, due_date, completed
            FROM tasks
            WHERE trashed_at IS NULL
            ORDER BY
              CASE WHEN due_date IS NULL THEN 1 ELSE 0 END,
              due_date ASC,
              created_at DESC
            """.trimIndent(),
            null,
        ).use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow("id")
            val titleIndex = cursor.getColumnIndexOrThrow("title")
            val priorityIndex = cursor.getColumnIndexOrThrow("priority")
            val dueIndex = cursor.getColumnIndexOrThrow("due_date")
            val completedIndex = cursor.getColumnIndexOrThrow("completed")

            while (cursor.moveToNext()) {
                val completed = cursor.getInt(completedIndex) != 0
                if (completed) {
                    completedCount++
                    continue
                }

                pendingCount++
                val id = cursor.getString(idIndex)
                val title = cursor.getString(titleIndex)
                val priority = cursor.getInt(priorityIndex)
                val dueMillis = if (cursor.isNull(dueIndex)) null else cursor.getLong(dueIndex)

                if (priority == 3) importantCount++

                val dueDate = dueMillis?.let {
                    Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault()).toLocalDate()
                }
                if (dueDate != null) {
                    if (dueDate == today) todayCount++
                    if (!dueDate.isBefore(today) && !dueDate.isAfter(end)) nextSevenDaysCount++
                    if (dueDate.isBefore(today)) overdueCount++
                }

                tasks.put(
                    JSONObject()
                        .put("id", id)
                        .put("title", title)
                        .put("priority", priority)
                        .put("dueMillis", dueMillis ?: JSONObject.NULL),
                )
            }
        }
        db.close()

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(TASKS_JSON, tasks.toString())
            .putInt("completedCount", completedCount)
            .putInt("pendingCount", pendingCount)
            .putInt("importantCount", importantCount)
            .putInt("todayCount", todayCount)
            .putInt("nextSevenDaysCount", nextSevenDaysCount)
            .putInt("overdueCount", overdueCount)
            .apply()
    }

    fun tasks(context: Context): List<JSONObject> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(TASKS_JSON, "[]") ?: "[]"
        val array = JSONArray(raw)
        return List(array.length()) { array.getJSONObject(it) }
    }

    fun completeTask(context: Context, taskId: String) {
        val dbFile = File(context.filesDir, "orbitask.sqlite")
        if (!dbFile.exists()) return

        val db = SQLiteDatabase.openDatabase(
            dbFile.path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        )
        db.execSQL(
            "UPDATE tasks SET completed = 1, updated_at = ? WHERE id = ?",
            arrayOf(System.currentTimeMillis(), taskId),
        )
        db.close()
        refreshFromDatabase(context)
    }

    fun themeColor(context: Context, key: String, fallback: Int): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getInt(key, fallback)
}
