package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject
import java.time.LocalDate
import java.time.YearMonth

/** Recibe los toques en los widgets y la alarma de medianoche. */
class OrbitaskWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE, ACTION_COMPLETE_LEGACY -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                val completed = intent.getBooleanExtra(EXTRA_COMPLETED, true)
                // No se toca la base de datos: el cambio queda pendiente y
                // Flutter lo guarda (al momento si la app está abierta en
                // segundo plano, o la próxima vez que se abra).
                OrbitaskWidgetData.recordToggle(context, taskId, completed)
                OrbitaskWidgets.refreshAll(context)
                MainActivity.notifyWidgetToggles()
            }

            ACTION_OPEN_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                launchApp(context, JSONObject().put("action", "openTask").put("taskId", taskId))
            }

            ACTION_NEW_TASK -> {
                val action = JSONObject().put("action", "newTask")
                intent.getStringExtra(EXTRA_DATE)?.let { action.put("dueDate", it) }
                launchApp(context, action)
            }

            ACTION_OPEN_APP -> launchApp(context, null)

            ACTION_CAL_PREV, ACTION_CAL_NEXT, ACTION_CAL_TODAY, ACTION_CAL_SELECT -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
                updateCalendarState(context, widgetId, intent)
                OrbitaskCalendarWidget.updateAll(
                    context,
                    AppWidgetManager.getInstance(context),
                    intArrayOf(widgetId),
                )
            }

            ACTION_MIDNIGHT -> OrbitaskWidgets.refreshAll(context)
        }
    }

    private fun updateCalendarState(context: Context, widgetId: Int, intent: Intent) {
        val prefs = OrbitaskWidgetData.prefs(context)
        val offsetKey = OrbitaskCalendarWidget.offsetKey(widgetId)
        val selectedKey = OrbitaskCalendarWidget.selectedKey(widgetId)
        val editor = prefs.edit()

        when (intent.action) {
            ACTION_CAL_TODAY -> {
                editor.remove(offsetKey)
                editor.remove(selectedKey)
            }

            ACTION_CAL_SELECT -> {
                val date = intent.getStringExtra(EXTRA_DATE)
                if (date != null) editor.putString(selectedKey, date)
            }

            else -> {
                // Al cambiar de mes se selecciona su día 1, o hoy si se vuelve al mes actual.
                val delta = if (intent.action == ACTION_CAL_PREV) -1 else 1
                val offset = prefs.getInt(offsetKey, 0) + delta
                editor.putInt(offsetKey, offset)
                if (offset == 0) {
                    editor.remove(selectedKey)
                } else {
                    val first = YearMonth.from(LocalDate.now()).plusMonths(offset.toLong()).atDay(1)
                    editor.putString(selectedKey, first.toString())
                }
            }
        }
        editor.commit()
    }

    /**
     * Abre la app. Lo que tiene que hacer al abrirse (abrir una tarea, crear
     * una) se guarda aparte y Flutter lo recoge con `takePendingAction`.
     */
    private fun launchApp(context: Context, action: JSONObject?) {
        if (action != null) {
            OrbitaskWidgetData.storePendingAction(context, action)
        } else {
            OrbitaskWidgetData.clearPendingAction(context)
        }
        val launch = Intent(context, MainActivity::class.java).addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        try {
            context.startActivity(launch)
        } catch (error: Exception) {
            Log.w(TAG, "No se pudo abrir Orbitask desde el widget", error)
        }
    }

    companion object {
        private const val TAG = "OrbitaskWidgets"

        const val ACTION_TOGGLE = "com.darkhmdda.orbitask.widget.TOGGLE_TASK"
        /** Acción de la versión anterior de los widgets; se trata como completar. */
        const val ACTION_COMPLETE_LEGACY = "com.darkhmdda.orbitask.widget.COMPLETE_TASK"
        const val ACTION_OPEN_TASK = "com.darkhmdda.orbitask.widget.OPEN_TASK"
        const val ACTION_NEW_TASK = "com.darkhmdda.orbitask.widget.NEW_TASK"
        const val ACTION_OPEN_APP = "com.darkhmdda.orbitask.widget.OPEN"
        const val ACTION_CAL_PREV = "com.darkhmdda.orbitask.widget.CALENDAR_PREV"
        const val ACTION_CAL_NEXT = "com.darkhmdda.orbitask.widget.CALENDAR_NEXT"
        const val ACTION_CAL_TODAY = "com.darkhmdda.orbitask.widget.CALENDAR_TODAY"
        const val ACTION_CAL_SELECT = "com.darkhmdda.orbitask.widget.CALENDAR_SELECT"
        const val ACTION_MIDNIGHT = "com.darkhmdda.orbitask.widget.MIDNIGHT"

        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_COMPLETED = "completed"
        const val EXTRA_DATE = "date"
    }
}
