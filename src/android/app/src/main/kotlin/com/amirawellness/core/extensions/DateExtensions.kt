package com.amirawellness.core.extensions

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

/**
 * Extension functions for the Date class to provide date formatting, manipulation, and comparison utilities.
 * These functions support various features in the Amira Wellness application such as journal entry 
 * timestamps, emotional trend visualization, and streak tracking.
 */

// Date format constants for consistent formatting across the application
private const val DATE_FORMAT_FULL = "EEEE, MMMM d, yyyy"
private const val DATE_FORMAT_MEDIUM = "MMM d, yyyy"
private const val DATE_FORMAT_SHORT = "MM/dd/yyyy"
private const val DATE_FORMAT_TIME = "h:mm a"
private const val DATE_FORMAT_DATE_TIME = "MMM d, yyyy h:mm a"
private const val DATE_FORMAT_ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
private const val DATE_FORMAT_JOURNAL = "EEEE, MMMM d"
private const val DATE_FORMAT_MONTH_YEAR = "MMMM yyyy"
private const val DATE_FORMAT_WEEK = "'Week of' MMM d"
private const val DATE_FORMAT_DAY = "EEEE"

/**
 * Formats a Date object to a string using the specified format pattern.
 *
 * @param pattern the date format pattern
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Formatted date string according to the specified pattern
 */
fun Date.toFormattedString(pattern: String, locale: Locale? = null): String {
    val dateFormat = SimpleDateFormat(pattern, locale ?: Locale.getDefault())
    return dateFormat.format(this)
}

/**
 * Formats a Date object to a full date string (e.g., 'Monday, January 1, 2023').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Full date string
 */
fun Date.toFullDateString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_FULL, locale)
}

/**
 * Formats a Date object to a medium date string (e.g., 'Jan 1, 2023').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Medium date string
 */
fun Date.toMediumDateString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_MEDIUM, locale)
}

/**
 * Formats a Date object to a short date string (e.g., '01/01/2023').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Short date string
 */
fun Date.toShortDateString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_SHORT, locale)
}

/**
 * Formats a Date object to a time string (e.g., '3:30 PM').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Time string
 */
fun Date.toTimeString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_TIME, locale)
}

/**
 * Formats a Date object to a date and time string (e.g., 'Jan 1, 2023 3:30 PM').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Date and time string
 */
fun Date.toDateTimeString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_DATE_TIME, locale)
}

/**
 * Formats a Date object to an ISO 8601 string (e.g., '2023-01-01T15:30:00.000+0000').
 *
 * @return ISO 8601 formatted date string
 */
fun Date.toIso8601String(): String {
    val dateFormat = SimpleDateFormat(DATE_FORMAT_ISO8601)
    dateFormat.timeZone = TimeZone.getTimeZone("UTC")
    return dateFormat.format(this)
}

/**
 * Formats a Date object for journal display (e.g., 'Monday, January 1').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Journal date string
 */
fun Date.toJournalDateString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_JOURNAL, locale)
}

/**
 * Formats a Date object to a month and year string (e.g., 'January 2023').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Month and year string
 */
fun Date.toMonthYearString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_MONTH_YEAR, locale)
}

/**
 * Formats a Date object to a week string (e.g., 'Week of Jan 1').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Week string
 */
fun Date.toWeekString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_WEEK, locale)
}

/**
 * Formats a Date object to a day of week string (e.g., 'Monday').
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Day of week string
 */
fun Date.toDayOfWeekString(locale: Locale? = null): String {
    return toFormattedString(DATE_FORMAT_DAY, locale)
}

/**
 * Checks if two dates are on the same day.
 *
 * @param other the date to compare with
 * @return True if the dates are on the same day, false otherwise
 */
fun Date.isSameDay(other: Date): Boolean {
    val cal1 = Calendar.getInstance().apply { time = this@isSameDay }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
           cal1.get(Calendar.MONTH) == cal2.get(Calendar.MONTH) &&
           cal1.get(Calendar.DAY_OF_MONTH) == cal2.get(Calendar.DAY_OF_MONTH)
}

/**
 * Checks if two dates are in the same week.
 *
 * @param other the date to compare with
 * @return True if the dates are in the same week, false otherwise
 */
fun Date.isSameWeek(other: Date): Boolean {
    val cal1 = Calendar.getInstance().apply { time = this@isSameWeek }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
           cal1.get(Calendar.WEEK_OF_YEAR) == cal2.get(Calendar.WEEK_OF_YEAR)
}

/**
 * Checks if two dates are in the same month.
 *
 * @param other the date to compare with
 * @return True if the dates are in the same month, false otherwise
 */
fun Date.isSameMonth(other: Date): Boolean {
    val cal1 = Calendar.getInstance().apply { time = this@isSameMonth }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
           cal1.get(Calendar.MONTH) == cal2.get(Calendar.MONTH)
}

/**
 * Checks if two dates are in the same year.
 *
 * @param other the date to compare with
 * @return True if the dates are in the same year, false otherwise
 */
fun Date.isSameYear(other: Date): Boolean {
    val cal1 = Calendar.getInstance().apply { time = this@isSameYear }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR)
}

/**
 * Checks if the date is today.
 *
 * @return True if the date is today, false otherwise
 */
fun Date.isToday(): Boolean {
    return isSameDay(Date())
}

/**
 * Checks if the date is yesterday.
 *
 * @return True if the date is yesterday, false otherwise
 */
fun Date.isYesterday(): Boolean {
    val yesterday = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, -1)
    }.time
    return isSameDay(yesterday)
}

/**
 * Checks if the date is tomorrow.
 *
 * @return True if the date is tomorrow, false otherwise
 */
fun Date.isTomorrow(): Boolean {
    val tomorrow = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, 1)
    }.time
    return isSameDay(tomorrow)
}

/**
 * Checks if the date is in the current week.
 *
 * @return True if the date is in the current week, false otherwise
 */
fun Date.isInThisWeek(): Boolean {
    return isSameWeek(Date())
}

/**
 * Checks if the date is in the current month.
 *
 * @return True if the date is in the current month, false otherwise
 */
fun Date.isInThisMonth(): Boolean {
    return isSameMonth(Date())
}

/**
 * Checks if the date is in the current year.
 *
 * @return True if the date is in the current year, false otherwise
 */
fun Date.isInThisYear(): Boolean {
    return isSameYear(Date())
}

/**
 * Calculates the number of days between two dates.
 *
 * @param other the date to calculate days from
 * @return Number of days between the dates
 */
fun Date.daysBetween(other: Date): Int {
    val diffInMillis = kotlin.math.abs(time - other.time)
    return TimeUnit.DAYS.convert(diffInMillis, TimeUnit.MILLISECONDS).toInt()
}

/**
 * Calculates the number of weeks between two dates.
 *
 * @param other the date to calculate weeks from
 * @return Number of weeks between the dates
 */
fun Date.weeksBetween(other: Date): Int {
    val diffInMillis = kotlin.math.abs(time - other.time)
    return TimeUnit.DAYS.convert(diffInMillis, TimeUnit.MILLISECONDS).toInt() / 7
}

/**
 * Calculates the number of months between two dates.
 *
 * @param other the date to calculate months from
 * @return Number of months between the dates
 */
fun Date.monthsBetween(other: Date): Int {
    val cal1 = Calendar.getInstance().apply { time = this@monthsBetween }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    val yearDiff = cal1.get(Calendar.YEAR) - cal2.get(Calendar.YEAR)
    val monthDiff = cal1.get(Calendar.MONTH) - cal2.get(Calendar.MONTH)
    
    return kotlin.math.abs(yearDiff * 12 + monthDiff)
}

/**
 * Calculates the number of years between two dates.
 *
 * @param other the date to calculate years from
 * @return Number of years between the dates
 */
fun Date.yearsBetween(other: Date): Int {
    val cal1 = Calendar.getInstance().apply { time = this@yearsBetween }
    val cal2 = Calendar.getInstance().apply { time = other }
    
    return kotlin.math.abs(cal1.get(Calendar.YEAR) - cal2.get(Calendar.YEAR))
}

/**
 * Adds a specified number of days to the date.
 *
 * @param days the number of days to add
 * @return New date with days added
 */
fun Date.addDays(days: Int): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@addDays
        add(Calendar.DAY_OF_YEAR, days)
    }
    return calendar.time
}

/**
 * Adds a specified number of weeks to the date.
 *
 * @param weeks the number of weeks to add
 * @return New date with weeks added
 */
fun Date.addWeeks(weeks: Int): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@addWeeks
        add(Calendar.WEEK_OF_YEAR, weeks)
    }
    return calendar.time
}

/**
 * Adds a specified number of months to the date.
 *
 * @param months the number of months to add
 * @return New date with months added
 */
fun Date.addMonths(months: Int): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@addMonths
        add(Calendar.MONTH, months)
    }
    return calendar.time
}

/**
 * Adds a specified number of years to the date.
 *
 * @param years the number of years to add
 * @return New date with years added
 */
fun Date.addYears(years: Int): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@addYears
        add(Calendar.YEAR, years)
    }
    return calendar.time
}

/**
 * Returns a new date set to the start of the day (00:00:00).
 *
 * @return Date at the start of the day
 */
fun Date.startOfDay(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@startOfDay
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return calendar.time
}

/**
 * Returns a new date set to the end of the day (23:59:59.999).
 *
 * @return Date at the end of the day
 */
fun Date.endOfDay(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@endOfDay
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
        set(Calendar.MILLISECOND, 999)
    }
    return calendar.time
}

/**
 * Returns a new date set to the start of the week (Sunday or Monday based on locale).
 *
 * @param locale the locale to determine first day of week, defaults to system locale
 * @return Date at the start of the week
 */
fun Date.startOfWeek(locale: Locale? = null): Date {
    val calendar = Calendar.getInstance(locale ?: Locale.getDefault()).apply {
        time = this@startOfWeek
        set(Calendar.DAY_OF_WEEK, firstDayOfWeek)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return calendar.time
}

/**
 * Returns a new date set to the end of the week (Saturday or Sunday based on locale).
 *
 * @param locale the locale to determine last day of week, defaults to system locale
 * @return Date at the end of the week
 */
fun Date.endOfWeek(locale: Locale? = null): Date {
    val calendar = Calendar.getInstance(locale ?: Locale.getDefault()).apply {
        time = this@endOfWeek
        set(Calendar.DAY_OF_WEEK, firstDayOfWeek + 6)
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
        set(Calendar.MILLISECOND, 999)
    }
    return calendar.time
}

/**
 * Returns a new date set to the start of the month.
 *
 * @return Date at the start of the month
 */
fun Date.startOfMonth(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@startOfMonth
        set(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return calendar.time
}

/**
 * Returns a new date set to the end of the month.
 *
 * @return Date at the end of the month
 */
fun Date.endOfMonth(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@endOfMonth
        set(Calendar.DAY_OF_MONTH, getActualMaximum(Calendar.DAY_OF_MONTH))
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
        set(Calendar.MILLISECOND, 999)
    }
    return calendar.time
}

/**
 * Returns a new date set to the start of the year (January 1, 00:00:00).
 *
 * @return Date at the start of the year
 */
fun Date.startOfYear(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@startOfYear
        set(Calendar.MONTH, Calendar.JANUARY)
        set(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return calendar.time
}

/**
 * Returns a new date set to the end of the year (December 31, 23:59:59.999).
 *
 * @return Date at the end of the year
 */
fun Date.endOfYear(): Date {
    val calendar = Calendar.getInstance().apply {
        time = this@endOfYear
        set(Calendar.MONTH, Calendar.DECEMBER)
        set(Calendar.DAY_OF_MONTH, 31)
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
        set(Calendar.MILLISECOND, 999)
    }
    return calendar.time
}

/**
 * Gets the day of week as an integer (1-7, where 1 is Sunday).
 *
 * @return Day of week (1-7)
 */
fun Date.getDayOfWeek(): Int {
    val calendar = Calendar.getInstance().apply { time = this@getDayOfWeek }
    return calendar.get(Calendar.DAY_OF_WEEK)
}

/**
 * Gets the day of month (1-31).
 *
 * @return Day of month (1-31)
 */
fun Date.getDayOfMonth(): Int {
    val calendar = Calendar.getInstance().apply { time = this@getDayOfMonth }
    return calendar.get(Calendar.DAY_OF_MONTH)
}

/**
 * Gets the month as an integer (0-11, where 0 is January).
 *
 * @return Month (0-11)
 */
fun Date.getMonth(): Int {
    val calendar = Calendar.getInstance().apply { time = this@getMonth }
    return calendar.get(Calendar.MONTH)
}

/**
 * Gets the year.
 *
 * @return Year
 */
fun Date.getYear(): Int {
    val calendar = Calendar.getInstance().apply { time = this@getYear }
    return calendar.get(Calendar.YEAR)
}

/**
 * Gets the week of year.
 *
 * @return Week of year
 */
fun Date.getWeekOfYear(): Int {
    val calendar = Calendar.getInstance().apply { time = this@getWeekOfYear }
    return calendar.get(Calendar.WEEK_OF_YEAR)
}

/**
 * Returns a human-readable string representing the relative time (e.g., 'Today', 'Yesterday', '2 days ago').
 * Useful for displaying journal entries and emotional check-ins in a user-friendly way.
 *
 * @param locale the locale to use for formatting, defaults to system locale
 * @return Relative time span string
 */
fun Date.getRelativeTimeSpanString(locale: Locale? = null): String {
    val now = Date()
    
    // Check for today, yesterday, tomorrow
    when {
        isToday() -> return "Hoy" // Today in Spanish
        isYesterday() -> return "Ayer" // Yesterday in Spanish
        isTomorrow() -> return "Mañana" // Tomorrow in Spanish
    }
    
    // Calculate difference in days
    val days = daysBetween(now)
    
    // Within a week
    if (days < 7) {
        return if (this.before(now)) {
            "Hace $days ${if (days == 1) "día" else "días"}" // X days ago
        } else {
            "En $days ${if (days == 1) "día" else "días"}" // In X days
        }
    }
    
    // Within a month
    val weeks = weeksBetween(now)
    if (weeks < 4) {
        return if (this.before(now)) {
            "Hace $weeks ${if (weeks == 1) "semana" else "semanas"}" // X weeks ago
        } else {
            "En $weeks ${if (weeks == 1) "semana" else "semanas"}" // In X weeks
        }
    }
    
    // Within a year
    val months = monthsBetween(now)
    if (months < 12) {
        return if (this.before(now)) {
            "Hace $months ${if (months == 1) "mes" else "meses"}" // X months ago
        } else {
            "En $months ${if (months == 1) "mes" else "meses"}" // In X months
        }
    }
    
    // Beyond a year
    val years = yearsBetween(now)
    return if (this.before(now)) {
        "Hace $years ${if (years == 1) "año" else "años"}" // X years ago
    } else {
        "En $years ${if (years == 1) "año" else "años"}" // In X years
    }
}

/**
 * Parses an ISO 8601 formatted string to a Date object.
 * Used for API communication and data persistence.
 *
 * @param iso8601String the ISO 8601 formatted string to parse
 * @return Parsed Date object or null if parsing fails
 */
fun parseIso8601(iso8601String: String): Date? {
    return try {
        val dateFormat = SimpleDateFormat(DATE_FORMAT_ISO8601)
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")
        dateFormat.parse(iso8601String)
    } catch (e: Exception) {
        null
    }
}