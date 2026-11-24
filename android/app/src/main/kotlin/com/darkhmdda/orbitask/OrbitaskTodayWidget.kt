package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/**
 * Widget "Todas las tareas". El nombre de la clase se conserva por
 * compatibilidad: si cambiara, Android quitaría los widgets ya colocados.
 */
class OrbitaskTodayWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        OrbitaskWidgets.refreshAll(context)
    }
}
