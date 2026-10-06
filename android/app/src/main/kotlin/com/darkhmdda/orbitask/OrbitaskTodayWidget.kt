package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
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
            if (ids.isNotEmpty()) {
                manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_all_tasks_list)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("orbitask_widget", Context.MODE_PRIVATE)
            val count = prefs.getInt("pendingCount", 0)

            val surface = OrbitaskWidgetData.themeColor(
                context,
                "themeSurface",
                0xFF151A20.toInt(),
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

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_today)
            views.setTextViewText(
                R.id.widget_today_title,
                if (count == 1) "Todas las tareas · 1 pendiente"
                else "Todas las tareas · $count pendientes",
            )
            views.setInt(R.id.widget_today_root, "setBackgroundColor", surface)
            views.setTextColor(R.id.widget_today_title, text)
            views.setTextColor(R.id.widget_today_add, accent)
            views.setTextColor(R.id.widget_today_empty, muted)

            val serviceIntent = Intent(context, OrbitaskTaskListService::class.java).apply {
                putExtra(OrbitaskTaskListService.EXTRA_MODE, OrbitaskTaskListService.MODE_ALL)
                data = Uri.parse("orbitask://all-tasks/$appWidgetId")
            }
            views.setRemoteAdapter(R.id.widget_all_tasks_list, serviceIntent)
            views.setEmptyView(R.id.widget_all_tasks_list, R.id.widget_today_empty)

            val templateIntent = Intent(context, OrbitaskWidgetActionReceiver::class.java)
            val template = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_all_tasks_list, template)

            val openIntent = Intent(context, MainActivity::class.java)
            val addPendingIntent = PendingIntent.getActivity(
                context,
                1000 + appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_today_add, addPendingIntent)

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
