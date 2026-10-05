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

            val todayTasks = (args["todayTasks"] as? List<*>)
                ?.mapNotNull { it?.toString() }
                ?.take(4)
                ?: emptyList()

            prefs.edit()
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
                .putString("todayTasks", todayTasks.joinToString("\n"))
                .apply()

            val manager = AppWidgetManager.getInstance(this)
            val todayIds = manager.getAppWidgetIds(
                ComponentName(this, OrbitaskTodayWidget::class.java),
            )
            val summaryIds = manager.getAppWidgetIds(
                ComponentName(this, OrbitaskSummaryWidget::class.java),
            )

            OrbitaskTodayWidget.updateAll(this, manager, todayIds)
            OrbitaskSummaryWidget.updateAll(this, manager, summaryIds)
            result.success(null)
        }
    }
}
