package com.darkhmdda.orbitask

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.ZoneId

/** Piezas comunes de los tres widgets: refresco, acciones y el widget de lista. */
object OrbitaskWidgets {
    const val MODE_ALL = "all"
    const val MODE_UPCOMING = "upcoming"

    /** Repinta todos los widgets colocados con las últimas tareas que mandó Flutter. */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val allIds = idsOf(context, manager, OrbitaskTodayWidget::class.java)
        val upcomingIds = idsOf(context, manager, OrbitaskSummaryWidget::class.java)
        val calendarIds = idsOf(context, manager, OrbitaskCalendarWidget::class.java)

        updateListWidgets(context, manager, allIds, MODE_ALL)
        updateListWidgets(context, manager, upcomingIds, MODE_UPCOMING)
        OrbitaskCalendarWidget.updateAll(context, manager, calendarIds)

        val anyWidget = allIds.isNotEmpty() || upcomingIds.isNotEmpty() || calendarIds.isNotEmpty()
        scheduleMidnightRefresh(context, anyWidget)
    }

    private fun idsOf(context: Context, manager: AppWidgetManager, provider: Class<*>): IntArray =
        manager.getAppWidgetIds(ComponentName(context, provider))

    /**
     * PendingIntent hacia [OrbitaskWidgetActionReceiver]. Cada uno lleva una
     * URI distinta para que Android no los confunda entre sí.
     */
    fun actionIntent(
        context: Context,
        action: String,
        uri: String,
        extras: (Intent) -> Unit = {},
    ): PendingIntent {
        val intent = Intent(context, OrbitaskWidgetActionReceiver::class.java).apply {
            this.action = action
            data = Uri.parse(uri)
            extras(this)
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Fondo redondeado y botón "+" con los colores del tema. */
    fun applyChrome(views: RemoteViews, backgroundId: Int, palette: WidgetPalette) {
        views.setInt(backgroundId, "setColorFilter", palette.surface)
        views.setInt(R.id.widget_add_bg, "setColorFilter", palette.accent)
        views.setInt(R.id.widget_add_icon, "setColorFilter", palette.onAccentReadable)
    }

    private fun updateListWidgets(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
        mode: String,
    ) {
        if (ids.isEmpty()) return
        val palette = WidgetPalette.load(context)
        val tasks = OrbitaskWidgetData.tasks(context)
        ids.forEach { manager.updateAppWidget(it, buildListWidget(context, it, mode, palette, tasks)) }
        @Suppress("DEPRECATION")
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
    }

    private fun buildListWidget(
        context: Context,
        appWidgetId: Int,
        mode: String,
        palette: WidgetPalette,
        tasks: List<WidgetTask>,
    ): RemoteViews {
        val today = LocalDate.now()
        val views = RemoteViews(context.packageName, R.layout.orbitask_widget_list)
        applyChrome(views, R.id.widget_bg, palette)

        val pending = tasks.filter { !it.completed }
        val overdue = pending.count { task -> task.dueDate?.isBefore(today) == true }

        if (mode == MODE_ALL) {
            val done = tasks.size - pending.size
            views.setTextViewText(R.id.widget_title, "Todas las tareas")
            views.setTextViewText(
                R.id.widget_subtitle,
                buildString {
                    append(plural(pending.size, "pendiente", "pendientes"))
                    if (done > 0) append(" · ").append(plural(done, "hecha", "hechas"))
                    if (overdue > 0) append(" · ").append(plural(overdue, "vencida", "vencidas"))
                },
            )
            views.setTextViewText(R.id.widget_empty, "No hay tareas. Toca + para crear una.")
        } else {
            val upcoming = pending.count { it.dueDate != null }
            views.setTextViewText(R.id.widget_title, "Próximas entregas")
            views.setTextViewText(
                R.id.widget_subtitle,
                buildString {
                    append(plural(upcoming, "entrega pendiente", "entregas pendientes"))
                    if (overdue > 0) append(" · ").append(plural(overdue, "vencida", "vencidas"))
                },
            )
            views.setTextViewText(R.id.widget_empty, "Sin entregas próximas.")
        }

        views.setTextColor(R.id.widget_title, palette.text)
        views.setTextColor(R.id.widget_subtitle, if (overdue > 0) palette.overdue else palette.muted)
        views.setTextColor(R.id.widget_empty, palette.muted)

        val serviceIntent = Intent(context, OrbitaskTaskListService::class.java).apply {
            putExtra(OrbitaskTaskListService.EXTRA_MODE, mode)
            data = Uri.parse("orbitask://list/$mode/$appWidgetId")
        }
        @Suppress("DEPRECATION")
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)

        // Plantilla para los toques en las filas: cada fila completa el action y los extras.
        val template = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            Intent(context, OrbitaskWidgetActionReceiver::class.java).apply {
                data = Uri.parse("orbitask://template/$mode/$appWidgetId")
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
        views.setPendingIntentTemplate(R.id.widget_list, template)

        views.setOnClickPendingIntent(
            R.id.widget_add,
            actionIntent(
                context,
                OrbitaskWidgetActionReceiver.ACTION_NEW_TASK,
                "orbitask://new/$mode/$appWidgetId",
            ),
        )
        views.setOnClickPendingIntent(
            R.id.widget_header,
            actionIntent(
                context,
                OrbitaskWidgetActionReceiver.ACTION_OPEN_APP,
                "orbitask://open/$mode/$appWidgetId",
            ),
        )
        return views
    }

    fun plural(count: Int, one: String, many: String) = if (count == 1) "1 $one" else "$count $many"

    /**
     * Programa un repintado poco después de medianoche para que "Hoy",
     * "Mañana" y el día marcado en el calendario cambien solos. Usa una alarma
     * inexacta que no despierta al teléfono: se ejecuta al encender la pantalla.
     */
    private fun scheduleMidnightRefresh(context: Context, enabled: Boolean) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pending = actionIntent(
            context,
            OrbitaskWidgetActionReceiver.ACTION_MIDNIGHT,
            "orbitask://midnight",
        )
        if (!enabled) {
            alarmManager.cancel(pending)
            return
        }
        val nextMidnight = LocalDate.now()
            .plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .plusMinutes(1)
            .toInstant()
            .toEpochMilli()
        alarmManager.set(AlarmManager.RTC, nextMidnight, pending)
    }
}
