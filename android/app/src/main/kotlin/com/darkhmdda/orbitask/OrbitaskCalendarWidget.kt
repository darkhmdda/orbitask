package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.YearMonth

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
            val year = prefs.getInt("calendarYear", today.year).takeIf { it > 0 } ?: today.year
            val month = prefs.getInt("calendarMonth", today.monthValue)
                .takeIf { it in 1..12 } ?: today.monthValue

            val yearMonth = YearMonth.of(year, month)
            val firstDay = yearMonth.atDay(1)
            val leading = firstDay.dayOfWeek.value - 1
            val daysInMonth = yearMonth.lengthOfMonth()

            val cells = MutableList(42) { "" }
            for (day in 1..daysInMonth) {
                val count = prefs.getInt("calendarDay_$day", 0)
                val cell = if (count > 0) "$day•$count" else day.toString()
                cells[leading + day - 1] = cell
            }

            val rows = (0 until 6).joinToString("\n") { row ->
                (0 until 7).joinToString(" ") { col ->
                    val value = cells[row * 7 + col]
                    value.padStart(4, ' ')
                }
            }

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_calendar)
            views.setTextViewText(
                R.id.widget_calendar_title,
                "${monthNames[month - 1]} $year",
            )
            views.setTextViewText(R.id.widget_calendar_grid, rows)

            val openIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                103,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_calendar_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_calendar_add, pendingIntent)

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
