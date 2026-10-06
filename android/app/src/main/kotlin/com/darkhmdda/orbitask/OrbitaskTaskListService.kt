package com.darkhmdda.orbitask

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class OrbitaskTaskListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return Factory(applicationContext, intent.getStringExtra(EXTRA_MODE) ?: MODE_ALL)
    }

    private class Factory(
        private val context: Context,
        private val mode: String,
    ) : RemoteViewsFactory {
        private var tasks: List<JSONObject> = emptyList()

        override fun onCreate() = refresh()
        override fun onDataSetChanged() = refresh()
        override fun onDestroy() {}
        override fun getCount(): Int = tasks.size

        override fun getViewAt(position: Int): RemoteViews {
            val task = tasks[position]
            val views = RemoteViews(context.packageName, R.layout.orbitask_widget_task_row)
            val title = task.optString("title")
            val dueMillis = task.optLong("dueMillis", -1L)
            val priority = task.optInt("priority", 0)

            views.setTextViewText(R.id.widget_row_title, title)
            views.setTextViewText(R.id.widget_row_date, formatDate(dueMillis))

            val text = OrbitaskWidgetData.themeColor(context, "themeText", 0xFFF3F5F7.toInt())
            val muted = OrbitaskWidgetData.themeColor(context, "themeMuted", 0xFFAAB2BC.toInt())
            val accent = OrbitaskWidgetData.themeColor(context, "themeAccent", 0xFFA8BD86.toInt())
            views.setTextColor(R.id.widget_row_title, text)
            views.setTextColor(R.id.widget_row_date, muted)
            views.setTextColor(R.id.widget_row_check, accent)
            views.setTextColor(R.id.widget_row_priority, accent)
            views.setViewVisibility(
                R.id.widget_row_priority,
                if (priority == 3) View.VISIBLE else View.GONE,
            )

            val complete = Intent().apply {
                action = OrbitaskWidgetActionReceiver.ACTION_COMPLETE
                putExtra(OrbitaskWidgetActionReceiver.EXTRA_TASK_ID, task.optString("id"))
            }
            views.setOnClickFillInIntent(R.id.widget_row_check, complete)

            val open = Intent().apply {
                action = OrbitaskWidgetActionReceiver.ACTION_OPEN
            }
            views.setOnClickFillInIntent(R.id.widget_row_root, open)
            return views
        }

        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount(): Int = 1
        override fun getItemId(position: Int): Long =
            tasks[position].optString("id").hashCode().toLong()
        override fun hasStableIds(): Boolean = true

        private fun refresh() {
            val today = LocalDate.now()
            tasks = OrbitaskWidgetData.tasks(context)
                .filter { task ->
                    if (mode != MODE_UPCOMING) return@filter true
                    val due = task.optLong("dueMillis", -1L)
                    if (due < 0L) return@filter false
                    val date = Instant.ofEpochMilli(due)
                        .atZone(ZoneId.systemDefault())
                        .toLocalDate()
                    !date.isBefore(today)
                }
                .sortedWith(
                    compareBy<JSONObject> {
                        val due = it.optLong("dueMillis", Long.MAX_VALUE)
                        if (due < 0L) Long.MAX_VALUE else due
                    }.thenByDescending { it.optInt("priority", 0) },
                )
        }

        private fun formatDate(millis: Long): String {
            if (millis < 0L) return "Sin fecha"
            val date = Instant.ofEpochMilli(millis)
                .atZone(ZoneId.systemDefault())
                .toLocalDate()
            val today = LocalDate.now()
            return when (date) {
                today -> "Hoy"
                today.plusDays(1) -> "Mañana"
                else -> "${date.dayOfMonth}/${date.monthValue}"
            }
        }
    }

    companion object {
        const val EXTRA_MODE = "mode"
        const val MODE_ALL = "all"
        const val MODE_UPCOMING = "upcoming"
    }
}
