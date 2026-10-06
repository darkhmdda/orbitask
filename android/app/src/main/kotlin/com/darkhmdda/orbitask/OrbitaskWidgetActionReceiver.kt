package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class OrbitaskWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_COMPLETE -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                OrbitaskWidgetData.completeTask(context, taskId)
                refreshAll(context)
            }
            ACTION_OPEN -> {
                val launch = Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                context.startActivity(launch)
            }
            ACTION_CAL_PREV, ACTION_CAL_NEXT -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
                val prefs = context.getSharedPreferences("orbitask_widget", Context.MODE_PRIVATE)
                val key = "calendarOffset_$widgetId"
                val delta = if (intent.action == ACTION_CAL_PREV) -1 else 1
                prefs.edit().putInt(key, prefs.getInt(key, 0) + delta).apply()

                val manager = AppWidgetManager.getInstance(context)
                OrbitaskCalendarWidget.updateAll(context, manager, intArrayOf(widgetId))
            }
        }
    }

    private fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val allIds = manager.getAppWidgetIds(
            ComponentName(context, OrbitaskTodayWidget::class.java),
        )
        val upcomingIds = manager.getAppWidgetIds(
            ComponentName(context, OrbitaskSummaryWidget::class.java),
        )
        val calendarIds = manager.getAppWidgetIds(
            ComponentName(context, OrbitaskCalendarWidget::class.java),
        )
        OrbitaskTodayWidget.updateAll(context, manager, allIds)
        OrbitaskSummaryWidget.updateAll(context, manager, upcomingIds)
        OrbitaskCalendarWidget.updateAll(context, manager, calendarIds)
    }

    companion object {
        const val ACTION_COMPLETE = "com.darkhmdda.orbitask.widget.COMPLETE_TASK"
        const val ACTION_OPEN = "com.darkhmdda.orbitask.widget.OPEN"
        const val ACTION_CAL_PREV = "com.darkhmdda.orbitask.widget.CALENDAR_PREV"
        const val ACTION_CAL_NEXT = "com.darkhmdda.orbitask.widget.CALENDAR_NEXT"
        const val EXTRA_TASK_ID = "task_id"
    }
}
