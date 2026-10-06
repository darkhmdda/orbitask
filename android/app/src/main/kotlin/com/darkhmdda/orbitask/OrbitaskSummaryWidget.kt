package com.darkhmdda.orbitask

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
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
            if (ids.isNotEmpty()) {
                manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_upcoming_list)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
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

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_summary)
            views.setInt(R.id.widget_summary_root, "setBackgroundColor", surface)
            views.setTextColor(R.id.widget_upcoming_title, text)
            views.setTextColor(R.id.widget_summary_add, accent)
            views.setTextColor(R.id.widget_upcoming_empty, muted)

            val serviceIntent = Intent(context, OrbitaskTaskListService::class.java).apply {
                putExtra(OrbitaskTaskListService.EXTRA_MODE, OrbitaskTaskListService.MODE_UPCOMING)
                data = Uri.parse("orbitask://upcoming/$appWidgetId")
            }
            views.setRemoteAdapter(R.id.widget_upcoming_list, serviceIntent)
            views.setEmptyView(R.id.widget_upcoming_list, R.id.widget_upcoming_empty)

            val templateIntent = Intent(context, OrbitaskWidgetActionReceiver::class.java)
            val template = PendingIntent.getBroadcast(
                context,
                2000 + appWidgetId,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_upcoming_list, template)

            val openIntent = Intent(context, MainActivity::class.java)
            val addPendingIntent = PendingIntent.getActivity(
                context,
                3000 + appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_summary_add, addPendingIntent)

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
