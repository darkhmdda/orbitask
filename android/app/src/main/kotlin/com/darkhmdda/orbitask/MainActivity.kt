package com.darkhmdda.orbitask

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        widgetChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Flutter manda las tareas y los colores del tema activo, y pide repintar.
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

                    (args["tasksJson"] as? String)?.let { OrbitaskWidgetData.storeTasks(this, it) }

                    OrbitaskWidgets.refreshAll(this)
                    result.success(null)
                }

                // Lo que hay que hacer tras abrir la app desde un widget (abrir o crear una tarea).
                "takePendingAction" -> result.success(OrbitaskWidgetData.takePendingAction(this))

                // Tareas marcadas o desmarcadas en un widget, para que Flutter las guarde.
                "takeWidgetToggles" -> result.success(OrbitaskWidgetData.takeToggles(this))

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widgetChannel?.setMethodCallHandler(null)
        widgetChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        private const val CHANNEL = "com.darkhmdda.orbitask/widgets"

        /** Canal con Flutter mientras la app está en marcha (también en segundo plano). */
        private var widgetChannel: MethodChannel? = null

        /**
         * Avisa a Flutter de que hay cambios del widget por guardar. Si la app
         * no está en marcha no hace nada: Flutter los recoge al abrirse.
         * Debe llamarse desde el hilo principal.
         */
        fun notifyWidgetToggles() {
            widgetChannel?.invokeMethod("widgetTasksChanged", null)
        }
    }
}
