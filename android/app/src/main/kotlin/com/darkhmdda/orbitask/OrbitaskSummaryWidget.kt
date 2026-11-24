package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/**
 * Widget "Próximas entregas". El nombre de la clase se conserva por
 * compatibilidad: si cambiara, Android quitaría los widgets ya colocados.
 */
class OrbitaskSummaryWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        OrbitaskWidgets.refreshAll(context)
    }
}
