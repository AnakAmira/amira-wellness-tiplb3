"""
Date and time utility functions for the Amira Wellness application.

This module provides reusable functions for date manipulation, formatting,
comparison, and calculation to support features such as streak tracking,
emotional trend analysis, and progress visualization.
"""

import datetime
import calendar
from typing import List, Dict, Union, Optional
import pytz  # version 2023.3

# Global constants for date and time operations
DEFAULT_TIMEZONE = pytz.timezone('UTC')
DATE_FORMAT = '%Y-%m-%d'
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
ISO_FORMAT = '%Y-%m-%dT%H:%M:%S.%fZ'
DAYS_OF_WEEK = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
MONTHS_OF_YEAR = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 
                  'August', 'September', 'October', 'November', 'December']


def get_current_datetime(timezone: Optional[pytz.timezone] = None) -> datetime.datetime:
    """
    Gets the current datetime in the specified timezone.
    
    Args:
        timezone: The timezone to get the current datetime in. Defaults to UTC.
        
    Returns:
        Current datetime in the specified timezone.
    """
    current_utc = datetime.datetime.now(datetime.timezone.utc)
    if timezone is None:
        timezone = DEFAULT_TIMEZONE
    
    return current_utc.astimezone(timezone)


def get_current_date(timezone: Optional[pytz.timezone] = None) -> datetime.date:
    """
    Gets the current date in the specified timezone.
    
    Args:
        timezone: The timezone to get the current date in. Defaults to UTC.
        
    Returns:
        Current date in the specified timezone.
    """
    return get_current_datetime(timezone).date()


def format_date(date: datetime.date, format_str: Optional[str] = None) -> str:
    """
    Formats a date object as a string using the specified format.
    
    Args:
        date: The date object to format.
        format_str: The format string to use. Defaults to DATE_FORMAT.
        
    Returns:
        Formatted date string.
    """
    if format_str is None:
        format_str = DATE_FORMAT
    
    return date.strftime(format_str)


def format_datetime(dt: datetime.datetime, format_str: Optional[str] = None) -> str:
    """
    Formats a datetime object as a string using the specified format.
    
    Args:
        dt: The datetime object to format.
        format_str: The format string to use. Defaults to DATETIME_FORMAT.
        
    Returns:
        Formatted datetime string.
    """
    if format_str is None:
        format_str = DATETIME_FORMAT
    
    return dt.strftime(format_str)


def parse_date(date_str: str, format_str: Optional[str] = None) -> datetime.date:
    """
    Parses a date string into a date object using the specified format.
    
    Args:
        date_str: The date string to parse.
        format_str: The format string to use. Defaults to DATE_FORMAT.
        
    Returns:
        Parsed date object.
    """
    if format_str is None:
        format_str = DATE_FORMAT
    
    return datetime.datetime.strptime(date_str, format_str).date()


def parse_datetime(datetime_str: str, format_str: Optional[str] = None, 
                  timezone: Optional[pytz.timezone] = None) -> datetime.datetime:
    """
    Parses a datetime string into a datetime object using the specified format.
    
    Args:
        datetime_str: The datetime string to parse.
        format_str: The format string to use. Defaults to DATETIME_FORMAT.
        timezone: The timezone to localize the parsed datetime to. Defaults to UTC.
        
    Returns:
        Parsed datetime object.
    """
    if format_str is None:
        format_str = DATETIME_FORMAT
        
    dt = datetime.datetime.strptime(datetime_str, format_str)
    
    if timezone is None:
        timezone = DEFAULT_TIMEZONE
    
    # Localize the datetime to the specified timezone
    return timezone.localize(dt) if dt.tzinfo is None else dt.astimezone(timezone)


def parse_iso_datetime(iso_str: str) -> datetime.datetime:
    """
    Parses an ISO format datetime string into a datetime object.
    
    Args:
        iso_str: The ISO datetime string to parse.
        
    Returns:
        Parsed datetime object in UTC.
    """
    # Use fromisoformat for Python 3.7+
    dt = datetime.datetime.fromisoformat(iso_str.replace('Z', '+00:00'))
    
    # If the datetime is naive (no timezone), assume UTC
    if dt.tzinfo is None:
        dt = DEFAULT_TIMEZONE.localize(dt)
    
    # Ensure the datetime is in UTC
    return dt.astimezone(pytz.UTC)


def to_iso_format(dt: datetime.datetime) -> str:
    """
    Converts a datetime object to ISO format string.
    
    Args:
        dt: The datetime object to convert.
        
    Returns:
        ISO formatted datetime string.
    """
    # If the datetime has no timezone, assume UTC
    if dt.tzinfo is None:
        dt = DEFAULT_TIMEZONE.localize(dt)
    
    # Convert to UTC if in a different timezone
    dt_utc = dt.astimezone(pytz.UTC)
    
    # Use isoformat() for cleaner ISO formatting
    return dt_utc.isoformat().replace('+00:00', 'Z')


def add_days(dt: Union[datetime.date, datetime.datetime], days: int) -> Union[datetime.date, datetime.datetime]:
    """
    Adds a specified number of days to a date or datetime.
    
    Args:
        dt: The date or datetime to add days to.
        days: The number of days to add.
        
    Returns:
        Date or datetime with days added.
    """
    return dt + datetime.timedelta(days=days)


def subtract_days(dt: Union[datetime.date, datetime.datetime], days: int) -> Union[datetime.date, datetime.datetime]:
    """
    Subtracts a specified number of days from a date or datetime.
    
    Args:
        dt: The date or datetime to subtract days from.
        days: The number of days to subtract.
        
    Returns:
        Date or datetime with days subtracted.
    """
    return dt - datetime.timedelta(days=days)


def date_range(start_date: datetime.date, end_date: datetime.date) -> List[datetime.date]:
    """
    Generates a range of dates between start and end dates.
    
    Args:
        start_date: The start date of the range (inclusive).
        end_date: The end date of the range (inclusive).
        
    Returns:
        List of dates in the range (inclusive).
    """
    dates = []
    current_date = start_date
    
    while current_date <= end_date:
        dates.append(current_date)
        current_date = add_days(current_date, 1)
    
    return dates


def days_between(start_date: datetime.date, end_date: datetime.date) -> int:
    """
    Calculates the number of days between two dates.
    
    Args:
        start_date: The start date.
        end_date: The end date.
        
    Returns:
        Number of days between the dates.
    """
    return abs((end_date - start_date).days)


def is_same_day(dt1: datetime.datetime, dt2: datetime.datetime) -> bool:
    """
    Checks if two datetime objects represent the same day.
    
    Args:
        dt1: First datetime object.
        dt2: Second datetime object.
        
    Returns:
        True if same day, False otherwise.
    """
    return dt1.date() == dt2.date()


def is_same_month(dt1: datetime.datetime, dt2: datetime.datetime) -> bool:
    """
    Checks if two datetime objects represent the same month.
    
    Args:
        dt1: First datetime object.
        dt2: Second datetime object.
        
    Returns:
        True if same month and year, False otherwise.
    """
    return (dt1.year, dt1.month) == (dt2.year, dt2.month)


def get_start_of_day(dt: datetime.datetime) -> datetime.datetime:
    """
    Gets the datetime representing the start of the day (00:00:00).
    
    Args:
        dt: The datetime object.
        
    Returns:
        Datetime at start of the day.
    """
    return datetime.datetime.combine(dt.date(), datetime.time.min, tzinfo=dt.tzinfo)


def get_end_of_day(dt: datetime.datetime) -> datetime.datetime:
    """
    Gets the datetime representing the end of the day (23:59:59).
    
    Args:
        dt: The datetime object.
        
    Returns:
        Datetime at end of the day.
    """
    return datetime.datetime.combine(dt.date(), datetime.time.max, tzinfo=dt.tzinfo)


def get_start_of_month(dt: Union[datetime.date, datetime.datetime]) -> datetime.date:
    """
    Gets the date representing the first day of the month.
    
    Args:
        dt: The date or datetime object.
        
    Returns:
        Date at start of the month.
    """
    return datetime.date(dt.year, dt.month, 1)


def get_end_of_month(dt: Union[datetime.date, datetime.datetime]) -> datetime.date:
    """
    Gets the date representing the last day of the month.
    
    Args:
        dt: The date or datetime object.
        
    Returns:
        Date at end of the month.
    """
    last_day = calendar.monthrange(dt.year, dt.month)[1]
    return datetime.date(dt.year, dt.month, last_day)


def get_day_of_week(dt: Union[datetime.date, datetime.datetime]) -> str:
    """
    Gets the day of week name for a date.
    
    Args:
        dt: The date or datetime object.
        
    Returns:
        Day of week name (Monday, Tuesday, etc.).
    """
    return DAYS_OF_WEEK[dt.weekday()]


def get_month_name(dt: Union[datetime.date, datetime.datetime]) -> str:
    """
    Gets the month name for a date.
    
    Args:
        dt: The date or datetime object.
        
    Returns:
        Month name (January, February, etc.).
    """
    return MONTHS_OF_YEAR[dt.month - 1]  # Month is 1-indexed but list is 0-indexed


def group_by_day(datetimes: List[datetime.datetime]) -> Dict[datetime.date, List[datetime.datetime]]:
    """
    Groups a list of datetime objects by day.
    
    Args:
        datetimes: List of datetime objects to group.
        
    Returns:
        Dictionary with dates as keys and lists of datetimes as values.
    """
    grouped = {}
    
    for dt in datetimes:
        date = dt.date()
        if date not in grouped:
            grouped[date] = []
        grouped[date].append(dt)
    
    return grouped


def group_by_month(datetimes: List[datetime.datetime]) -> Dict[str, List[datetime.datetime]]:
    """
    Groups a list of datetime objects by month.
    
    Args:
        datetimes: List of datetime objects to group.
        
    Returns:
        Dictionary with month strings (YYYY-MM) as keys and lists of datetimes as values.
    """
    grouped = {}
    
    for dt in datetimes:
        month_key = f"{dt.year}-{dt.month:02d}"
        if month_key not in grouped:
            grouped[month_key] = []
        grouped[month_key].append(dt)
    
    return grouped


def group_by_week(datetimes: List[datetime.datetime]) -> Dict[str, List[datetime.datetime]]:
    """
    Groups a list of datetime objects by week.
    
    Args:
        datetimes: List of datetime objects to group.
        
    Returns:
        Dictionary with week strings (YYYY-WW) as keys and lists of datetimes as values.
    """
    grouped = {}
    
    for dt in datetimes:
        # Get ISO year and week number
        iso_year, iso_week, _ = dt.isocalendar()
        week_key = f"{iso_year}-{iso_week:02d}"
        if week_key not in grouped:
            grouped[week_key] = []
        grouped[week_key].append(dt)
    
    return grouped


def get_date_n_days_ago(n: int, reference_date: Optional[datetime.date] = None) -> datetime.date:
    """
    Gets the date that was n days ago from a reference date.
    
    Args:
        n: Number of days to go back.
        reference_date: The reference date. Defaults to current date.
        
    Returns:
        Date that was n days ago.
    """
    if reference_date is None:
        reference_date = get_current_date()
    
    return subtract_days(reference_date, n)


def get_datetime_n_days_ago(n: int, reference_datetime: Optional[datetime.datetime] = None) -> datetime.datetime:
    """
    Gets the datetime that was n days ago from a reference datetime.
    
    Args:
        n: Number of days to go back.
        reference_datetime: The reference datetime. Defaults to current datetime.
        
    Returns:
        Datetime that was n days ago.
    """
    if reference_datetime is None:
        reference_datetime = get_current_datetime()
    
    return subtract_days(reference_datetime, n)


def is_future_date(date: datetime.date, reference_date: Optional[datetime.date] = None) -> bool:
    """
    Checks if a date is in the future compared to a reference date.
    
    Args:
        date: The date to check.
        reference_date: The reference date. Defaults to current date.
        
    Returns:
        True if date is in the future, False otherwise.
    """
    if reference_date is None:
        reference_date = get_current_date()
    
    return date > reference_date


def is_past_date(date: datetime.date, reference_date: Optional[datetime.date] = None) -> bool:
    """
    Checks if a date is in the past compared to a reference date.
    
    Args:
        date: The date to check.
        reference_date: The reference date. Defaults to current date.
        
    Returns:
        True if date is in the past, False otherwise.
    """
    if reference_date is None:
        reference_date = get_current_date()
    
    return date < reference_date


def get_streak_grace_period_end(last_activity_date: datetime.datetime, 
                               grace_period_days: int = 1) -> datetime.datetime:
    """
    Calculates the end of the grace period for streak maintenance.
    
    Args:
        last_activity_date: The date of the last activity.
        grace_period_days: Number of days in the grace period. Defaults to 1.
        
    Returns:
        End of grace period datetime.
    """
    grace_period_end_date = add_days(last_activity_date, grace_period_days)
    return get_end_of_day(grace_period_end_date)


def is_streak_active(last_activity_date: datetime.datetime, 
                    grace_period_days: int = 1,
                    reference_datetime: Optional[datetime.datetime] = None) -> bool:
    """
    Checks if a streak is still active based on last activity and grace period.
    
    Args:
        last_activity_date: The date of the last activity.
        grace_period_days: Number of days in the grace period. Defaults to 1.
        reference_datetime: The datetime to check against. Defaults to current datetime.
        
    Returns:
        True if streak is still active, False otherwise.
    """
    if reference_datetime is None:
        reference_datetime = get_current_datetime()
    
    grace_period_end = get_streak_grace_period_end(last_activity_date, grace_period_days)
    return reference_datetime <= grace_period_end


def get_streak_at_risk_threshold(last_activity_date: datetime.datetime,
                                grace_period_days: int = 1,
                                warning_hours: int = 6) -> datetime.datetime:
    """
    Calculates the datetime threshold for when a streak is at risk.
    
    Args:
        last_activity_date: The date of the last activity.
        grace_period_days: Number of days in the grace period. Defaults to 1.
        warning_hours: Hours before grace period ends to start warning. Defaults to 6.
        
    Returns:
        Threshold datetime when streak becomes at risk.
    """
    grace_period_end = get_streak_grace_period_end(last_activity_date, grace_period_days)
    warning_threshold = grace_period_end - datetime.timedelta(hours=warning_hours)
    return warning_threshold


def is_streak_at_risk(last_activity_date: datetime.datetime,
                     grace_period_days: int = 1,
                     warning_hours: int = 6,
                     reference_datetime: Optional[datetime.datetime] = None) -> bool:
    """
    Checks if a streak is at risk of being broken.
    
    Args:
        last_activity_date: The date of the last activity.
        grace_period_days: Number of days in the grace period. Defaults to 1.
        warning_hours: Hours before grace period ends to start warning. Defaults to 6.
        reference_datetime: The datetime to check against. Defaults to current datetime.
        
    Returns:
        True if streak is at risk, False otherwise.
    """
    if reference_datetime is None:
        reference_datetime = get_current_datetime()
    
    at_risk_threshold = get_streak_at_risk_threshold(
        last_activity_date, grace_period_days, warning_hours
    )
    grace_period_end = get_streak_grace_period_end(last_activity_date, grace_period_days)
    
    return reference_datetime >= at_risk_threshold and reference_datetime <= grace_period_end