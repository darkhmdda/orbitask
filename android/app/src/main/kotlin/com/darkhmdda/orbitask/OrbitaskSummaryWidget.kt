package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class OrbitaskSummaryWidget : AppWidgetProvider() {
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
            val completed = prefs.getInt("completedCount", 0)
            val pending = prefs.getInt("pendingCount", 0)
            val important = prefs.getInt("importantCount", 0)
            val today = prefs.getInt("todayCount", 0)

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_summary)
            views.setTextViewText(R.id.widget_summary_today, today.toString())
            views.setTextViewText(R.id.widget_summary_completed, completed.toString())
            views.setTextViewText(R.id.widget_summary_pending, pending.toString())
            views.setTextViewText(R.id.widget_summary_important, important.toString())

            val openIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                102,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_summary_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_summary_add, pendingIntent)

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
