package com.darkhmdda.orbitask

import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.time.LocalDate

/** Filas de las listas de "Todas las tareas" y "Próximas entregas". */
class OrbitaskTaskListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val mode = intent.getStringExtra(EXTRA_MODE) ?: OrbitaskWidgets.MODE_ALL
        return Factory(applicationContext, mode)
    }

    private sealed class Item {
        data class Section(val label: String, val overdue: Boolean) : Item()
        data class Row(val task: WidgetTask) : Item()
    }

    private class Factory(
        private val context: Context,
        private val mode: String,
    ) : RemoteViewsFactory {
        private var items: List<Item> = emptyList()
        private var palette: WidgetPalette = WidgetPalette.load(context)
        private var today: LocalDate = LocalDate.now()

        override fun onCreate() = refresh()
        override fun onDataSetChanged() = refresh()
        override fun onDestroy() {}
        override fun getCount(): Int = items.size
        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount(): Int = 3
        override fun hasStableIds(): Boolean = true

        override fun getItemId(position: Int): Long = when (val item = items.getOrNull(position)) {
            is Item.Section -> ("section:" + item.label).hashCode().toLong()
            is Item.Row -> item.task.id.hashCode().toLong()
            null -> position.toLong()
        }

        override fun getViewAt(position: Int): RemoteViews {
            return when (val item = items.getOrNull(position)) {
                is Item.Section -> sectionView(item)
                is Item.Row -> rowView(item.task)
                null -> RemoteViews(context.packageName, R.layout.orbitask_widget_section)
            }
        }

        private fun refresh() {
            palette = WidgetPalette.load(context)
            today = LocalDate.now()
            val tasks = OrbitaskWidgetData.tasks(context)
            items = if (mode == OrbitaskWidgets.MODE_UPCOMING) upcomingItems(tasks) else allItems(tasks)
        }

        /** Pendientes por fecha (vencidas primero) y, al final, las completadas. */
        private fun allItems(tasks: List<WidgetTask>): List<Item> {
            val pending = tasks.filter { !it.completed }.sortedWith(pendingOrder)
            val done = tasks.filter { it.completed }.sortedByDescending { it.updatedAt }
            val result = mutableListOf<Item>()
            pending.forEach { result.add(Item.Row(it)) }
            if (done.isNotEmpty()) {
                result.add(Item.Section("COMPLETADAS · ${done.size}", overdue = false))
                done.forEach { result.add(Item.Row(it)) }
            }
            return result
        }

        /**
         * Solo tareas con fecha: vencidas, esta semana, más adelante y las
         * completadas cuya fecha aún no ha pasado.
         */
        private fun upcomingItems(tasks: List<WidgetTask>): List<Item> {
            val dated = tasks.filter { it.dueDate != null }
            val pending = dated.filter { !it.completed }.sortedWith(pendingOrder)
            val weekEnd = today.plusDays(6)

            val overdue = pending.filter { it.dueDate!!.isBefore(today) }
            val week = pending.filter { val d = it.dueDate!!; !d.isBefore(today) && !d.isAfter(weekEnd) }
            val later = pending.filter { it.dueDate!!.isAfter(weekEnd) }
            val done = dated
                .filter { it.completed && !it.dueDate!!.isBefore(today) }
                .sortedByDescending { it.updatedAt }

            val result = mutableListOf<Item>()
            fun section(label: String, list: List<WidgetTask>, isOverdue: Boolean = false) {
                if (list.isEmpty()) return
                result.add(Item.Section(label, isOverdue))
                list.forEach { result.add(Item.Row(it)) }
            }
            section("VENCIDAS", overdue, isOverdue = true)
            section("ESTA SEMANA", week)
            section("MÁS ADELANTE", later)
            section("COMPLETADAS · ${done.size}", done)
            return result
        }

        private fun sectionView(section: Item.Section): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_section)
            views.setTextViewText(R.id.widget_section_label, section.label)
            views.setTextColor(
                R.id.widget_section_label,
                if (section.overdue) palette.overdue else palette.muted,
            )
            views.setInt(R.id.widget_section_line, "setColorFilter", palette.line)
            return views
        }

        private fun rowView(task: WidgetTask): RemoteViews {
            val upcoming = mode == OrbitaskWidgets.MODE_UPCOMING
            val layout = if (upcoming) R.layout.orbitask_widget_due_row else R.layout.orbitask_widget_task_row
            val views = RemoteViews(context.packageName, layout)
            val due = task.dueDate
            val isOverdue = !task.completed && due != null && due.isBefore(today)

            // Título: tachado y atenuado si está completada.
            if (task.completed) {
                val struck = SpannableString(task.title)
                struck.setSpan(StrikethroughSpan(), 0, struck.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                views.setTextViewText(R.id.widget_row_title, struck)
                views.setTextColor(R.id.widget_row_title, palette.muted)
            } else {
                views.setTextViewText(R.id.widget_row_title, task.title)
                views.setTextColor(R.id.widget_row_title, palette.text)
            }

            // Fecha o plazo.
            val dateText = if (upcoming && due != null) {
                WidgetDates.forDueRow(due, today, task.completed)
            } else {
                WidgetDates.forRow(due, today, task.completed)
            }
            views.setTextViewText(R.id.widget_row_date, dateText)
            views.setTextColor(R.id.widget_row_date, if (isOverdue) palette.overdue else palette.muted)

            // Recuadro de fecha (solo en "Próximas entregas").
            if (upcoming && due != null) {
                val withinWeek = WidgetDates.daysFrom(today, due) in 0..6
                views.setTextViewText(R.id.widget_row_day, due.dayOfMonth.toString())
                views.setTextViewText(
                    R.id.widget_row_weekday,
                    (if (withinWeek) WidgetDates.weekdayShort(due) else WidgetDates.monthShort(due))
                        .uppercase(),
                )
                val tileText = when {
                    task.completed -> palette.muted
                    isOverdue -> palette.overdue
                    else -> palette.text
                }
                views.setTextColor(R.id.widget_row_day, tileText)
                views.setTextColor(R.id.widget_row_weekday, tileText)
                views.setInt(R.id.widget_row_tile_bg, "setColorFilter", palette.line)
            }

            // Casilla: contorno del color de la prioridad, o rellena con marca.
            if (task.completed) {
                views.setViewVisibility(R.id.widget_row_box, View.GONE)
                views.setViewVisibility(R.id.widget_row_box_fill, View.VISIBLE)
                views.setViewVisibility(R.id.widget_row_tick, View.VISIBLE)
                views.setInt(R.id.widget_row_box_fill, "setColorFilter", palette.accent)
                views.setInt(R.id.widget_row_tick, "setColorFilter", palette.onAccentReadable)
                views.setContentDescription(R.id.widget_row_check, "Desmarcar ${task.title}")
            } else {
                views.setViewVisibility(R.id.widget_row_box, View.VISIBLE)
                views.setViewVisibility(R.id.widget_row_box_fill, View.GONE)
                views.setViewVisibility(R.id.widget_row_tick, View.GONE)
                views.setInt(R.id.widget_row_box, "setColorFilter", palette.ringFor(task.priority))
                views.setContentDescription(R.id.widget_row_check, "Completar ${task.title}")
            }

            views.setOnClickFillInIntent(
                R.id.widget_row_check,
                Intent().apply {
                    action = OrbitaskWidgetActionReceiver.ACTION_TOGGLE
                    putExtra(OrbitaskWidgetActionReceiver.EXTRA_TASK_ID, task.id)
                    putExtra(OrbitaskWidgetActionReceiver.EXTRA_COMPLETED, !task.completed)
                },
            )
            views.setOnClickFillInIntent(
                R.id.widget_row_root,
                Intent().apply {
                    action = OrbitaskWidgetActionReceiver.ACTION_OPEN_TASK
                    putExtra(OrbitaskWidgetActionReceiver.EXTRA_TASK_ID, task.id)
                },
            )
            return views
        }

        /** Vencidas y próximas primero, sin fecha al final; a igual fecha, más prioridad primero. */
        private val pendingOrder = compareBy<WidgetTask> { it.dueMillis ?: Long.MAX_VALUE }
            .thenByDescending { it.priority }
            .thenBy { it.title.lowercase() }
    }

    companion object {
        const val EXTRA_MODE = "mode"
    }
}
