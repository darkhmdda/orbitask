package com.darkhmdda.orbitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.YearMonth

/** Calendario mensual con puntos en los días con tareas y la agenda del día elegido. */
class OrbitaskCalendarWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        OrbitaskWidgets.refreshAll(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = OrbitaskWidgetData.prefs(context).edit()
        appWidgetIds.forEach {
            editor.remove(offsetKey(it))
            editor.remove(selectedKey(it))
        }
        editor.apply()
    }

    companion object {
        private val CELLS = OrbitaskCalendarIds.cells.size
        private val AGENDA_ROWS = OrbitaskCalendarIds.agendaRows.size

        private val months = arrayOf(
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
        )

        fun offsetKey(appWidgetId: Int) = "calendarOffset_$appWidgetId"
        fun selectedKey(appWidgetId: Int) = "calendarSelected_$appWidgetId"

        fun updateAll(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val palette = WidgetPalette.load(context)
            val tasks = OrbitaskWidgetData.tasks(context)
            ids.forEach { manager.updateAppWidget(it, build(context, it, palette, tasks)) }
        }

        /** Día elegido en el widget; si no hay ninguno, hoy. */
        fun selectedDate(context: Context, appWidgetId: Int): LocalDate {
            val raw = OrbitaskWidgetData.prefs(context).getString(selectedKey(appWidgetId), null)
            return raw?.let {
                try {
                    LocalDate.parse(it)
                } catch (ignored: Exception) {
                    null
                }
            } ?: LocalDate.now()
        }

        private fun build(
            context: Context,
            appWidgetId: Int,
            palette: WidgetPalette,
            tasks: List<WidgetTask>,
        ): RemoteViews {
            val prefs = OrbitaskWidgetData.prefs(context)
            val today = LocalDate.now()
            val offset = prefs.getInt(offsetKey(appWidgetId), 0)
            val selected = selectedDate(context, appWidgetId)
            val yearMonth = YearMonth.from(today).plusMonths(offset.toLong())
            val firstDay = yearMonth.atDay(1)
            val leading = firstDay.dayOfWeek.value - 1
            val rows = (leading + yearMonth.lengthOfMonth() + 6) / 7
            val gridStart = firstDay.minusDays(leading.toLong())

            val byDate = tasks.filter { it.dueDate != null }.groupBy { it.dueDate!! }

            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_calendar)
            OrbitaskWidgets.applyChrome(views, R.id.widget_calendar_bg, palette)

            // Cabecera.
            views.setTextViewText(
                R.id.widget_calendar_title,
                "${months[yearMonth.monthValue - 1]} ${yearMonth.year}",
            )
            views.setTextColor(R.id.widget_calendar_title, palette.text)
            views.setInt(R.id.widget_calendar_prev, "setColorFilter", palette.muted)
            views.setInt(R.id.widget_calendar_next, "setColorFilter", palette.muted)
            intArrayOf(
                R.id.widget_calendar_weekday_1,
                R.id.widget_calendar_weekday_2,
                R.id.widget_calendar_weekday_3,
                R.id.widget_calendar_weekday_4,
                R.id.widget_calendar_weekday_5,
                R.id.widget_calendar_weekday_6,
                R.id.widget_calendar_weekday_7,
            ).forEach { views.setTextColor(it, palette.muted) }

            views.setOnClickPendingIntent(
                R.id.widget_calendar_title,
                calendarIntent(context, appWidgetId, OrbitaskWidgetActionReceiver.ACTION_CAL_TODAY, "today"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_calendar_prev,
                calendarIntent(context, appWidgetId, OrbitaskWidgetActionReceiver.ACTION_CAL_PREV, "prev"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_calendar_next,
                calendarIntent(context, appWidgetId, OrbitaskWidgetActionReceiver.ACTION_CAL_NEXT, "next"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_add,
                OrbitaskWidgets.actionIntent(
                    context,
                    OrbitaskWidgetActionReceiver.ACTION_NEW_TASK,
                    "orbitask://new/calendar/$appWidgetId/$selected",
                ) { it.putExtra(OrbitaskWidgetActionReceiver.EXTRA_DATE, selected.toString()) },
            )

            // Filas del mes: se ocultan las que sobran (meses de 4 o 5 semanas).
            for (row in 0 until 6) {
                views.setViewVisibility(OrbitaskCalendarIds.rows[row], if (row < rows) View.VISIBLE else View.GONE)
            }

            // Celdas.
            for (index in 0 until CELLS) {
                if (index / 7 >= rows) continue
                val date = gridStart.plusDays(index.toLong())
                val inMonth = date.month == yearMonth.month
                val isToday = date == today
                val isSelected = date == selected
                val pendingThatDay = byDate[date].orEmpty().filter { !it.completed }

                val cell = OrbitaskCalendarIds.cells[index]
                val bg = OrbitaskCalendarIds.cellBackgrounds[index]
                val ring = OrbitaskCalendarIds.cellRings[index]
                val text = OrbitaskCalendarIds.cellTexts[index]
                val dot = OrbitaskCalendarIds.cellDots[index]

                views.setTextViewText(text, date.dayOfMonth.toString())
                views.setTextColor(
                    text,
                    when {
                        isToday -> palette.onAccentReadable
                        inMonth -> palette.text
                        else -> palette.faint
                    },
                )

                views.setViewVisibility(bg, if (isToday) View.VISIBLE else View.GONE)
                if (isToday) views.setInt(bg, "setColorFilter", palette.accent)

                views.setViewVisibility(ring, if (isSelected && !isToday) View.VISIBLE else View.GONE)
                if (isSelected && !isToday) views.setInt(ring, "setColorFilter", palette.accentOnSurface)

                if (pendingThatDay.isEmpty()) {
                    views.setViewVisibility(dot, View.INVISIBLE)
                } else {
                    views.setViewVisibility(dot, View.VISIBLE)
                    val dotColor = when {
                        date.isBefore(today) -> palette.overdue
                        pendingThatDay.any { it.isHighPriority } -> palette.high
                        else -> palette.accentOnSurface
                    }
                    views.setInt(dot, "setColorFilter", dotColor)
                }

                val description = buildString {
                    append(WidgetDates.long(date, today))
                    if (pendingThatDay.isNotEmpty()) {
                        append(", ").append(OrbitaskWidgets.plural(pendingThatDay.size, "tarea", "tareas"))
                    }
                }
                views.setContentDescription(cell, description)
                views.setOnClickPendingIntent(
                    cell,
                    calendarIntent(
                        context,
                        appWidgetId,
                        OrbitaskWidgetActionReceiver.ACTION_CAL_SELECT,
                        "select/$index",
                    ) { it.putExtra(OrbitaskWidgetActionReceiver.EXTRA_DATE, date.toString()) },
                )
            }

            views.setInt(R.id.widget_calendar_divider, "setColorFilter", palette.line)
            bindAgenda(context, views, appWidgetId, palette, tasks, byDate, selected, today)
            return views
        }

        private fun bindAgenda(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            palette: WidgetPalette,
            tasks: List<WidgetTask>,
            byDate: Map<LocalDate, List<WidgetTask>>,
            selected: LocalDate,
            today: LocalDate,
        ) {
            val prefix = when (WidgetDates.daysFrom(today, selected)) {
                0L -> "Hoy · "
                1L -> "Mañana · "
                else -> ""
            }
            views.setTextViewText(R.id.widget_agenda_label, prefix + WidgetDates.long(selected, today))
            views.setTextColor(R.id.widget_agenda_label, palette.text)
            views.setTextColor(R.id.widget_agenda_empty, palette.muted)
            views.setTextColor(R.id.widget_agenda_more, palette.muted)

            val dayTasks = byDate[selected].orEmpty().sortedWith(
                compareBy<WidgetTask> { it.completed }
                    .thenByDescending { it.priority }
                    .thenBy { it.dueMillis ?: 0L },
            )

            for (k in 0 until AGENDA_ROWS) {
                views.setViewVisibility(OrbitaskCalendarIds.agendaRows[k], View.GONE)
            }
            views.setViewVisibility(R.id.widget_agenda_more, View.GONE)

            if (dayTasks.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_agenda_empty, View.GONE)
                dayTasks.take(AGENDA_ROWS).forEachIndexed { k, task ->
                    val sub = if (task.completed) "Completada" else describe(task)
                    bindAgendaRow(context, views, appWidgetId, palette, k, task, sub, selected.isBefore(today))
                }
                val extra = dayTasks.size - AGENDA_ROWS
                if (extra > 0) {
                    views.setViewVisibility(R.id.widget_agenda_more, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_agenda_more,
                        if (extra == 1) "y 1 tarea más" else "y $extra tareas más",
                    )
                }
                return
            }

            // Día sin tareas: se muestra lo próximo que hay después.
            views.setViewVisibility(R.id.widget_agenda_empty, View.VISIBLE)
            val next = tasks
                .filter { !it.completed && it.dueDate?.isAfter(selected) == true }
                .minWithOrNull(compareBy<WidgetTask> { it.dueMillis ?: Long.MAX_VALUE })
            if (next != null) {
                val sub = "Lo próximo · " + WidgetDates.long(next.dueDate!!, today).replaceFirstChar { it.lowercase() }
                bindAgendaRow(context, views, appWidgetId, palette, 0, next, sub, overdue = false, isNext = true)
            }
        }

        private fun describe(task: WidgetTask): String {
            val millis = task.dueMillis ?: return ""
            val time = java.time.Instant.ofEpochMilli(millis)
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalTime()
            val hour = "%02d:%02d".format(time.hour, time.minute)
            return when {
                task.isHighPriority -> "$hour · Prioridad alta"
                task.priority == WidgetTask.PRIORITY_MEDIUM -> "$hour · Prioridad media"
                else -> hour
            }
        }

        private fun bindAgendaRow(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            palette: WidgetPalette,
            k: Int,
            task: WidgetTask,
            sub: String,
            overdue: Boolean,
            isNext: Boolean = false,
        ) {
            val row = OrbitaskCalendarIds.agendaRows[k]
            val bar = OrbitaskCalendarIds.agendaBars[k]
            val title = OrbitaskCalendarIds.agendaTitles[k]
            val subtitle = OrbitaskCalendarIds.agendaSubtitles[k]

            views.setViewVisibility(row, View.VISIBLE)
            if (task.completed) {
                val struck = SpannableString(task.title)
                struck.setSpan(StrikethroughSpan(), 0, struck.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                views.setTextViewText(title, struck)
                views.setTextColor(title, palette.muted)
            } else {
                views.setTextViewText(title, task.title)
                views.setTextColor(title, palette.text)
            }
            views.setTextViewText(subtitle, sub)
            views.setTextColor(subtitle, if (overdue && !task.completed) palette.overdue else palette.muted)

            val barColor = when {
                isNext || task.completed -> palette.line
                overdue -> palette.overdue
                else -> palette.ringFor(task.priority)
            }
            views.setInt(bar, "setColorFilter", barColor)

            views.setOnClickPendingIntent(
                row,
                OrbitaskWidgets.actionIntent(
                    context,
                    OrbitaskWidgetActionReceiver.ACTION_OPEN_TASK,
                    "orbitask://calendar/$appWidgetId/agenda/$k/${task.id}",
                ) { it.putExtra(OrbitaskWidgetActionReceiver.EXTRA_TASK_ID, task.id) },
            )
        }

        private fun calendarIntent(
            context: Context,
            appWidgetId: Int,
            action: String,
            path: String,
            extras: (android.content.Intent) -> Unit = {},
        ) = OrbitaskWidgets.actionIntent(context, action, "orbitask://calendar/$appWidgetId/$path") {
            it.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            extras(it)
        }
    }
}
