package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class OrbitaskTodayWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateAll(context, appWidgetManager, appWidgetIds)
    }

    companion object {
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
            val tasks = prefs.getString("todayTasks", "")
                .orEmpty()
                .split("\n")
                .filter { it.isNotBlank() }
                .take(4)
            val count = prefs.getInt("todayCount", 0)

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_today)
            views.setTextViewText(
                R.id.widget_today_title,
                if (count == 1) "Hoy · 1 tarea" else "Hoy · $count tareas",
            )

            val rowIds = intArrayOf(
                R.id.widget_today_task_1,
                R.id.widget_today_task_2,
                R.id.widget_today_task_3,
                R.id.widget_today_task_4,
            )
            rowIds.forEachIndexed { index, id ->
                if (index < tasks.size) {
                    views.setViewVisibility(id, View.VISIBLE)
                    views.setTextViewText(id, "○  ${tasks[index]}")
                } else {
                    views.setViewVisibility(id, View.GONE)
                }
            }

            views.setViewVisibility(
                R.id.widget_today_empty,
                if (tasks.isEmpty()) View.VISIBLE else View.GONE,
            )

            val openIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                101,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_today_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_today_add, pendingIntent)

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
