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
            val prefs = getSharedPreferences("orbitask_widget", MODE_PRIVATE)

            val allTasks = (args["allTasks"] as? List<*>)
                ?.mapNotNull { it?.toString() }
                ?.take(6)
                ?: emptyList()

            val calendarCounts = args["calendarCounts"] as? Map<*, *> ?: emptyMap<Any, Any>()
            val editor = prefs.edit()
                .putInt("todayCount", (args["todayCount"] as? Number)?.toInt() ?: 0)
                .putInt(
                    "nextSevenDaysCount",
                    (args["nextSevenDaysCount"] as? Number)?.toInt() ?: 0,
                )
                .putInt("overdueCount", (args["overdueCount"] as? Number)?.toInt() ?: 0)
                .putInt(
                    "importantCount",
                    (args["importantCount"] as? Number)?.toInt() ?: 0,
                )
                .putInt(
                    "completedCount",
                    (args["completedCount"] as? Number)?.toInt() ?: 0,
                )
                .putInt("pendingCount", (args["pendingCount"] as? Number)?.toInt() ?: 0)
                .putString("allTasks", allTasks.joinToString("\n"))
                .putInt("calendarYear", (args["calendarYear"] as? Number)?.toInt() ?: 0)
                .putInt("calendarMonth", (args["calendarMonth"] as? Number)?.toInt() ?: 0)

            for (day in 1..31) {
                val value = (calendarCounts[day.toString()] as? Number)?.toInt() ?: 0
                editor.putInt("calendarDay_$day", value)
            }
            editor.apply()

            val manager = AppWidgetManager.getInstance(this)
            val taskIds = manager.getAppWidgetIds(
                ComponentName(this, OrbitaskTodayWidget::class.java),
            )
            val summaryIds = manager.getAppWidgetIds(
                ComponentName(this, OrbitaskSummaryWidget::class.java),
            )
            val calendarIds = manager.getAppWidgetIds(
                ComponentName(this, OrbitaskCalendarWidget::class.java),
            )

            OrbitaskTodayWidget.updateAll(this, manager, taskIds)
            OrbitaskSummaryWidget.updateAll(this, manager, summaryIds)
            OrbitaskCalendarWidget.updateAll(this, manager, calendarIds)
            result.success(null)
        }
    }
}
