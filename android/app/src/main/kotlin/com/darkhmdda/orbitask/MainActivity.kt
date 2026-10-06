package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.darkhmdda.orbitask/widgets",
        ).setMethodCallHandler { call, result ->
            if (call.method != "updateWidgets") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
            val editor = getSharedPreferences("orbitask_widget", MODE_PRIVATE).edit()

            listOf(
                "themeSurface",
                "themeSurface2",
                "themeText",
                "themeMuted",
                "themeAccent",
                "themeAccent2",
                "themeBorder",
                "themeOnAccent",
            ).forEach { key ->
                val value = (args[key] as? Number)?.toInt()
                if (value != null) editor.putInt(key, value)
            }
            editor.apply()

            OrbitaskWidgetData.refreshFromDatabase(this)
            refreshWidgets()
            result.success(null)
        }
    }

    private fun refreshWidgets() {
        val manager = AppWidgetManager.getInstance(this)

        val allTaskIds = manager.getAppWidgetIds(
            ComponentName(this, OrbitaskTodayWidget::class.java),
        )
        val upcomingIds = manager.getAppWidgetIds(
            ComponentName(this, OrbitaskSummaryWidget::class.java),
        )
        val calendarIds = manager.getAppWidgetIds(
            ComponentName(this, OrbitaskCalendarWidget::class.java),
        )

        OrbitaskTodayWidget.updateAll(this, manager, allTaskIds)
        OrbitaskSummaryWidget.updateAll(this, manager, upcomingIds)
        OrbitaskCalendarWidget.updateAll(this, manager, calendarIds)
    }
}
