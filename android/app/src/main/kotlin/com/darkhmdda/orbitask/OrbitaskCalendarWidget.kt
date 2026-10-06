package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class OrbitaskCalendarWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateAll(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        private val monthNames = listOf(
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
        )

        fun updateAll(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
        ) {
            ids.forEach { updateWidget(context, manager, it) }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("orbitask_widget", Context.MODE_PRIVATE)
            val today = LocalDate.now()
            val offset = prefs.getInt("calendarOffset_$appWidgetId", 0)
            val yearMonth = YearMonth.from(today).plusMonths(offset.toLong())
            val firstDay = yearMonth.atDay(1)
            val leading = firstDay.dayOfWeek.value - 1
            val daysInMonth = yearMonth.lengthOfMonth()

            val surface = OrbitaskWidgetData.themeColor(
                context,
                "themeSurface",
                0xFF151A20.toInt(),
            )
            val surface2 = OrbitaskWidgetData.themeColor(
                context,
                "themeSurface2",
                0xFF252C35.toInt(),
            )
            val text = OrbitaskWidgetData.themeColor(
                context,
                "themeText",
                0xFFF3F5F7.toInt(),
            )
            val muted = OrbitaskWidgetData.themeColor(
                context,
                "themeMuted",
                0xFFAAB2BC.toInt(),
            )
            val accent = OrbitaskWidgetData.themeColor(
                context,
                "themeAccent",
                0xFFA8BD86.toInt(),
            )
            val onAccent = OrbitaskWidgetData.themeColor(
                context,
                "themeOnAccent",
                Color.WHITE,
            )

            val tasksByDay = mutableMapOf<Int, MutableList<JSONObject>>()
            OrbitaskWidgetData.tasks(context).forEach { task ->
                val due = task.optLong("dueMillis", -1L)
                if (due < 0L) return@forEach
                val date = Instant.ofEpochMilli(due)
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate()
                if (date.year == yearMonth.year && date.monthValue == yearMonth.monthValue) {
                    tasksByDay.getOrPut(date.dayOfMonth) { mutableListOf() }.add(task)
                }
            }

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_calendar)
            views.setInt(R.id.widget_calendar_root, "setBackgroundColor", surface)
            views.setTextViewText(
                R.id.widget_calendar_title,
                "${monthNames[yearMonth.monthValue - 1]} ${yearMonth.year}",
            )
            views.setTextColor(R.id.widget_calendar_title, text)
            views.setTextColor(R.id.widget_calendar_prev, muted)
            views.setTextColor(R.id.widget_calendar_next, muted)
            views.setTextColor(R.id.widget_calendar_add, accent)

            intArrayOf(
                R.id.widget_calendar_weekday_1,
                R.id.widget_calendar_weekday_2,
                R.id.widget_calendar_weekday_3,
                R.id.widget_calendar_weekday_4,
                R.id.widget_calendar_weekday_5,
                R.id.widget_calendar_weekday_6,
                R.id.widget_calendar_weekday_7,
            ).forEach { views.setTextColor(it, muted) }

            for (index in 0 until 42) {
                val id = context.resources.getIdentifier(
                    "calendar_cell_$index",
                    "id",
                    context.packageName,
                )
                val day = index - leading + 1
                if (day !in 1..daysInMonth) {
                    views.setTextViewText(id, "")
                    views.setInt(id, "setBackgroundColor", Color.TRANSPARENT)
                    continue
                }

                val dayTasks = tasksByDay[day].orEmpty()
                val label = when {
                    dayTasks.isEmpty() -> day.toString()
                    dayTasks.size == 1 -> {
                        val raw = dayTasks.first().optString("title")
                        val short = if (raw.length > 9) raw.take(8) + "…" else raw
                        "$day\n• $short"
                    }
                    else -> "$day\n• ${dayTasks.size} tareas"
                }

                val isToday = offset == 0 && day == today.dayOfMonth
                views.setTextViewText(id, label)
                views.setTextColor(id, if (isToday) onAccent else text)
                views.setInt(
                    id,
                    "setBackgroundColor",
                    when {
                        isToday -> accent
                        dayTasks.isNotEmpty() -> surface2
                        else -> Color.TRANSPARENT
                    },
                )
            }

            views.setOnClickPendingIntent(
                R.id.widget_calendar_prev,
                calendarIntent(context, appWidgetId, false),
            )
            views.setOnClickPendingIntent(
                R.id.widget_calendar_next,
                calendarIntent(context, appWidgetId, true),
            )

            val openIntent = Intent(context, MainActivity::class.java)
            val addPendingIntent = PendingIntent.getActivity(
                context,
                4000 + appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_calendar_add, addPendingIntent)
            manager.updateAppWidget(appWidgetId, views)
        }

        private fun calendarIntent(
            context: Context,
            appWidgetId: Int,
            next: Boolean,
        ): PendingIntent {
            val intent = Intent(context, OrbitaskWidgetActionReceiver::class.java).apply {
                action = if (next) {
                    OrbitaskWidgetActionReceiver.ACTION_CAL_NEXT
                } else {
                    OrbitaskWidgetActionReceiver.ACTION_CAL_PREV
                }
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            return PendingIntent.getBroadcast(
                context,
                (if (next) 6000 else 5000) + appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
