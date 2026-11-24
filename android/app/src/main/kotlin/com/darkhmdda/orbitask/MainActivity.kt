package com.darkhmdda.orbitask

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
            when (call.method) {
                // Flutter manda los colores del tema activo y pide repintar los widgets.
                "updateWidgets" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    val editor = OrbitaskWidgetData.prefs(this).edit()
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
                    (args["themeLight"] as? Boolean)?.let { editor.putBoolean("themeLight", it) }
                    editor.apply()

                    OrbitaskWidgets.refreshAll(this)
                    result.success(null)
                }

                // Lo que hay que hacer tras abrir la app desde un widget (abrir o crear una tarea).
                "takePendingAction" -> result.success(OrbitaskWidgetData.takePendingAction(this))

                // Tareas marcadas o desmarcadas desde un widget, para ajustar sus recordatorios.
                "takeChangedTasks" -> result.success(OrbitaskWidgetData.takeChangedTasks(this))

                else -> result.notImplemented()
            }
        }
    }
}
