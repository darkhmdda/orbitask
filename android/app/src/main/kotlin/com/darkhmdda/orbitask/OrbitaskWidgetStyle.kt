package com.darkhmdda.orbitask

import android.content.Context
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * Colores de los widgets. Salen del tema activo de Orbitask, que Flutter manda
 * por el canal `updateWidgets`. Los valores por defecto son los del tema Emilia
 * (el tema por defecto de la app).
 */
class WidgetPalette(
    val surface: Int,
    val surface2: Int,
    val text: Int,
    val muted: Int,
    val accent: Int,
    val onAccent: Int,
    val light: Boolean,
) {
    /** Prioridad alta. Ningún tema define este color, así que hay uno para claros y otro para oscuros. */
    val high: Int = if (light) 0xFFC2410C.toInt() else 0xFFF08A4B.toInt()

    /** Tareas vencidas. */
    val overdue: Int = if (light) 0xFFB42318.toInt() else 0xFFF97066.toInt()

    /** Líneas separadoras y recuadros de fecha. */
    val line: Int = surface2

    /** Días de otros meses en el calendario. */
    val faint: Int = withAlpha(muted, 0x8C)

    /** Acento legible sobre el fondo (algunos temas claros tienen acentos muy suaves). */
    val accentOnSurface: Int = readable(accent, surface, fallback = text)

    /** Color del "+" y de la marca de completado sobre el acento. */
    val onAccentReadable: Int = run {
        if (contrast(onAccent, accent) >= 3.0) {
            onAccent
        } else if (contrast(0xFFFFFFFF.toInt(), accent) >= contrast(0xFF000000.toInt(), accent)) {
            0xFFFFFFFF.toInt()
        } else {
            0xFF000000.toInt()
        }
    }

    /** Color del contorno de la casilla según la prioridad. */
    fun ringFor(priority: Int): Int = when {
        priority >= WidgetTask.PRIORITY_HIGH -> high
        priority == WidgetTask.PRIORITY_MEDIUM -> accentOnSurface
        else -> muted
    }

    companion object {
        fun load(context: Context): WidgetPalette {
            val prefs = OrbitaskWidgetData.prefs(context)
            fun color(key: String, fallback: Long) = prefs.getInt(key, fallback.toInt())
            return WidgetPalette(
                surface = color("themeSurface", 0xFFECECF3),
                surface2 = color("themeSurface2", 0xFFD2CCDF),
                text = color("themeText", 0xFF513A66),
                muted = color("themeMuted", 0xFF776584),
                accent = color("themeAccent", 0xFF76519F),
                onAccent = color("themeOnAccent", 0xFFFFFFFF),
                light = prefs.getBoolean("themeLight", true),
            )
        }

        fun withAlpha(color: Int, alpha: Int): Int = (color and 0x00FFFFFF) or (alpha shl 24)

        private fun channel(value: Int): Double {
            val c = value / 255.0
            return if (c <= 0.03928) c / 12.92 else ((c + 0.055) / 1.055).pow(2.4)
        }

        private fun luminance(color: Int): Double =
            0.2126 * channel((color shr 16) and 0xFF) +
                0.7152 * channel((color shr 8) and 0xFF) +
                0.0722 * channel(color and 0xFF)

        fun contrast(a: Int, b: Int): Double {
            val la = luminance(a)
            val lb = luminance(b)
            return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
        }

        fun readable(color: Int, background: Int, fallback: Int, minimum: Double = 3.0): Int =
            if (contrast(color, background) >= minimum) color else fallback
    }
}

/** Textos de fecha en español para los widgets. */
object WidgetDates {
    private val weekdaysShort = arrayOf("Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom")
    private val weekdaysLong =
        arrayOf("Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo")
    private val monthsShort =
        arrayOf("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
    val monthsLong = arrayOf(
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
    )

    fun daysFrom(today: LocalDate, date: LocalDate): Long = ChronoUnit.DAYS.between(today, date)

    fun weekdayShort(date: LocalDate) = weekdaysShort[date.dayOfWeek.value - 1]

    fun monthShort(date: LocalDate) = monthsShort[date.monthValue - 1]

    /** "Sáb 28 nov" (con el año si no es el actual). */
    fun short(date: LocalDate, today: LocalDate): String {
        val base = "${weekdayShort(date)} ${date.dayOfMonth} ${monthShort(date)}"
        return if (date.year == today.year) base else "$base ${date.year}"
    }

    /** "Martes 24 de noviembre" (con el año si no es el actual). */
    fun long(date: LocalDate, today: LocalDate): String {
        val base = "${weekdaysLong[date.dayOfWeek.value - 1]} ${date.dayOfMonth} de " +
            monthsLong[date.monthValue - 1]
        return if (date.year == today.year) base else "$base de ${date.year}"
    }

    /** "Vencida · ayer" / "Vencida · hace 3 días". */
    fun overdue(days: Long): String =
        if (days == 1L) "Vencida · ayer" else "Vencida · hace $days días"

    /** Fecha para la lista "Todas las tareas". */
    fun forRow(date: LocalDate?, today: LocalDate, completed: Boolean): String {
        if (date == null) return "Sin fecha"
        if (completed) return short(date, today)
        val days = daysFrom(today, date)
        return when {
            days < 0 -> overdue(-days)
            days == 0L -> "Hoy"
            days == 1L -> "Mañana"
            days < 7 -> "${short(date, today)} · en $days días"
            else -> short(date, today)
        }
    }

    /** Plazo para "Próximas entregas" (el día ya se ve en el recuadro). */
    fun forDueRow(date: LocalDate, today: LocalDate, completed: Boolean): String {
        if (completed) return "Completada"
        val days = daysFrom(today, date)
        return when {
            days < 0 -> overdue(-days)
            days == 0L -> "Hoy"
            days == 1L -> "Mañana"
            days < 7 -> "En $days días"
            else -> long(date, today)
        }
    }
}
