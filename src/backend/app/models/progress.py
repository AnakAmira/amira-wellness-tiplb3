"""
SQLAlchemy ORM models for progress tracking in the Amira Wellness application.
These models define the database schemas for user activity tracking, usage statistics,
and progress metrics to support the progress tracking and visualization features.
"""

from datetime import date, timedelta  # standard library
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Boolean, Enum  # sqlalchemy 2.0+
from sqlalchemy.dialects.postgresql import JSONB  # sqlalchemy 2.0+
from sqlalchemy.orm import relationship  # sqlalchemy 2.0+

from .base import BaseModel
from ..constants.emotions import EmotionType, PeriodType, TrendDirection
from ..constants.tools import ToolCategory
from ..constants.achievements import ActionType

# Define time ranges for time of day categorization
TIME_OF_DAY_RANGES = {
    'MORNING': (6, 12),
    'AFTERNOON': (12, 18),
    'EVENING': (18, 22),
    'NIGHT': (22, 6)
}

# Define days of week for activity categorization
DAYS_OF_WEEK = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
]


class UserActivity(BaseModel):
    """
    SQLAlchemy model representing a user activity record for tracking app usage.
    Each record represents a single user action within the application, such as
    completing a journal entry, performing an emotional check-in, or using a tool.
    """
    # Foreign key reference to the user
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    
    # Type of activity performed
    activity_type = Column(Enum(ActionType), nullable=False, index=True)
    
    # When the activity occurred
    activity_date = Column(DateTime, nullable=False, index=True)
    
    # Time of day category (MORNING, AFTERNOON, EVENING, NIGHT)
    time_of_day = Column(String(50), nullable=False, index=True)
    
    # Day of week (MONDAY, TUESDAY, etc.)
    day_of_week = Column(String(50), nullable=False, index=True)
    
    # Additional activity data in JSON format (activity-specific details)
    metadata = Column(JSONB, nullable=True)
    
    # Relationship to user model (will be defined in the user model)
    # user = relationship("User", back_populates="activities")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if an activity record is accessible by a specific user.
        
        Args:
            user_id (UUID): ID of the user attempting to access the activity
            
        Returns:
            bool: True if the activity is accessible by the user, False otherwise
        """
        return str(self.user_id) == str(user_id)
    
    @staticmethod
    def get_time_of_day(timestamp):
        """
        Determines the time of day category based on the activity timestamp.
        
        Args:
            timestamp (DateTime): The timestamp to categorize
            
        Returns:
            str: Time of day category (MORNING, AFTERNOON, EVENING, NIGHT)
        """
        hour = timestamp.hour
        
        for time_of_day, (start, end) in TIME_OF_DAY_RANGES.items():
            # Handle special case for NIGHT which spans across midnight
            if time_of_day == 'NIGHT':
                if hour >= start or hour < end:
                    return time_of_day
            # Normal case for other times of day
            elif start <= hour < end:
                return time_of_day
        
        # Default fallback in case of unexpected hour value
        return 'AFTERNOON'
    
    @staticmethod
    def get_day_of_week(timestamp):
        """
        Determines the day of week based on the activity timestamp.
        
        Args:
            timestamp (DateTime): The timestamp to categorize
            
        Returns:
            str: Day of week (MONDAY, TUESDAY, etc.)
        """
        # Python's weekday() returns 0 for Monday, 1 for Tuesday, etc.
        weekday_index = timestamp.weekday()
        return DAYS_OF_WEEK[weekday_index]


class UsageStatistics(BaseModel):
    """
    SQLAlchemy model representing aggregated usage statistics for a user.
    This model stores aggregated metrics about a user's app usage patterns,
    which can be used for progress visualization and insights.
    """
    # Foreign key reference to the user
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    
    # Type of period this statistic covers (DAY, WEEK, MONTH)
    period_type = Column(Enum(PeriodType), nullable=False, index=True)
    
    # Specific value for the period (e.g., "2023-01-15" for a DAY, "2023-W02" for a WEEK)
    period_value = Column(String(50), nullable=False, index=True)
    
    # Usage statistics counts
    total_journal_entries = Column(Integer, nullable=False, default=0)
    total_journaling_minutes = Column(Integer, nullable=False, default=0)
    total_checkins = Column(Integer, nullable=False, default=0)
    total_tool_usage = Column(Integer, nullable=False, default=0)
    
    # Tool usage breakdown by category (stored as JSON)
    tool_usage_by_category = Column(JSONB, nullable=True)
    
    # Most active time of day for the user
    active_time_of_day = Column(String(50), nullable=True)
    
    # Most productive day of the week for the user
    most_productive_day = Column(String(50), nullable=True)
    
    # Relationship to user model (will be defined in the user model)
    # user = relationship("User", back_populates="usage_statistics")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if usage statistics are accessible by a specific user.
        
        Args:
            user_id (UUID): ID of the user attempting to access the statistics
            
        Returns:
            bool: True if the statistics are accessible by the user, False otherwise
        """
        return str(self.user_id) == str(user_id)
    
    def get_tool_usage_for_category(self, category):
        """
        Retrieves tool usage statistics for a specific category.
        
        Args:
            category (ToolCategory): The tool category to get statistics for
            
        Returns:
            dict: Dictionary with usage count and total duration for the category
        """
        if not self.tool_usage_by_category:
            return {"usage_count": 0, "total_duration": 0}
        
        category_key = category.value if isinstance(category, ToolCategory) else str(category)
        
        if category_key in self.tool_usage_by_category:
            return self.tool_usage_by_category[category_key]
        else:
            return {"usage_count": 0, "total_duration": 0}
    
    def update_from_activities(self, activities):
        """
        Updates usage statistics based on user activity records.
        
        Args:
            activities (list): List of UserActivity objects to aggregate
            
        Returns:
            None: Updates the statistics in place
        """
        if not activities:
            return
        
        # Initialize counters
        journal_count = 0
        journal_minutes = 0
        checkin_count = 0
        tool_usage_count = 0
        tool_usage_by_category = {}
        time_of_day_counts = {"MORNING": 0, "AFTERNOON": 0, "EVENING": 0, "NIGHT": 0}
        day_of_week_counts = {day: 0 for day in DAYS_OF_WEEK}
        
        # Process each activity
        for activity in activities:
            # Count activities by type
            if activity.activity_type == ActionType.VOICE_JOURNAL:
                journal_count += 1
                # Extract duration from metadata if available
                if activity.metadata and "duration_seconds" in activity.metadata:
                    journal_minutes += round(activity.metadata["duration_seconds"] / 60)
            
            elif activity.activity_type == ActionType.EMOTIONAL_CHECK_IN:
                checkin_count += 1
            
            elif activity.activity_type == ActionType.TOOL_USAGE:
                tool_usage_count += 1
                # Update tool usage by category
                if activity.metadata and "category" in activity.metadata:
                    category = activity.metadata["category"]
                    duration = activity.metadata.get("duration_minutes", 0)
                    
                    if category not in tool_usage_by_category:
                        tool_usage_by_category[category] = {"usage_count": 0, "total_duration": 0}
                    
                    tool_usage_by_category[category]["usage_count"] += 1
                    tool_usage_by_category[category]["total_duration"] += duration
            
            # Update time of day and day of week counters
            if activity.time_of_day in time_of_day_counts:
                time_of_day_counts[activity.time_of_day] += 1
            
            if activity.day_of_week in day_of_week_counts:
                day_of_week_counts[activity.day_of_week] += 1
        
        # Determine most active time of day
        active_time = max(time_of_day_counts.items(), key=lambda x: x[1])[0] if time_of_day_counts else None
        
        # Determine most productive day of week
        productive_day = max(day_of_week_counts.items(), key=lambda x: x[1])[0] if day_of_week_counts else None
        
        # Update the statistics
        self.total_journal_entries = journal_count
        self.total_journaling_minutes = journal_minutes
        self.total_checkins = checkin_count
        self.total_tool_usage = tool_usage_count
        self.tool_usage_by_category = tool_usage_by_category
        self.active_time_of_day = active_time
        self.most_productive_day = productive_day


class ProgressInsight(BaseModel):
    """
    SQLAlchemy model representing an insight derived from progress data analysis.
    These insights provide users with meaningful observations about their emotional
    patterns and usage habits, helping them gain awareness and make progress.
    """
    # Foreign key reference to the user
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    
    # Type of insight (PATTERN, TRIGGER, etc.)
    type = Column(String(50), nullable=False, index=True)
    
    # Short title describing the insight
    title = Column(String(255), nullable=False)
    
    # Detailed description of the insight
    description = Column(String(255), nullable=False)
    
    # Supporting data or evidence for the insight
    supporting_data = Column(String(255), nullable=True)
    
    # Actionable steps the user can take based on the insight
    actionable_steps = Column(JSONB, nullable=True)
    
    # Related tools that might help address the insight
    related_tools = Column(JSONB, nullable=True)
    
    # Confidence level of the insight (0-1)
    confidence = Column(Float, nullable=False, default=0.5)
    
    # Relationship to user model (will be defined in the user model)
    # user = relationship("User", back_populates="progress_insights")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if a progress insight is accessible by a specific user.
        
        Args:
            user_id (UUID): ID of the user attempting to access the insight
            
        Returns:
            bool: True if the insight is accessible by the user, False otherwise
        """
        return str(self.user_id) == str(user_id)
    
    def get_localized_title(self, language_code):
        """
        Returns the insight title in the specified language.
        
        Args:
            language_code (str): Language code (e.g., 'en', 'es')
            
        Returns:
            str: Localized insight title
        """
        # For now, we only support Spanish (default) and English
        if language_code == 'en':
            # Check if English title is available in metadata
            if self.metadata and 'title_en' in self.metadata:
                return self.metadata['title_en']
            # Fallback to Spanish title
            return self.title
        
        # Default to Spanish title
        return self.title
    
    def get_localized_description(self, language_code):
        """
        Returns the insight description in the specified language.
        
        Args:
            language_code (str): Language code (e.g., 'en', 'es')
            
        Returns:
            str: Localized insight description
        """
        # For now, we only support Spanish (default) and English
        if language_code == 'en':
            # Check if English description is available in metadata
            if self.metadata and 'description_en' in self.metadata:
                return self.metadata['description_en']
            # Fallback to Spanish description
            return self.description
        
        # Default to Spanish description
        return self.description


class UserAchievement(BaseModel):
    """
    SQLAlchemy model representing an achievement earned by a user.
    This model tracks which achievements users have earned, when they earned them,
    and for in-progress achievements, how close they are to completion.
    """
    # Foreign key reference to the user
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    
    # Foreign key reference to the achievement definition
    achievement_id = Column(ForeignKey('achievements.id'), nullable=False, index=True)
    
    # When the achievement was earned (null if in progress)
    earned_date = Column(DateTime, nullable=True)
    
    # Whether the user has viewed/acknowledged the achievement
    is_viewed = Column(Boolean, nullable=False, default=False)
    
    # Progress data for achievements that track progress (e.g., streaks, counts)
    progress_data = Column(JSONB, nullable=True)
    
    # Relationships (will be defined in the respective models)
    # user = relationship("User", back_populates="achievements")
    # achievement = relationship("Achievement", back_populates="user_achievements")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if a user achievement is accessible by a specific user.
        
        Args:
            user_id (UUID): ID of the user attempting to access the achievement
            
        Returns:
            bool: True if the achievement is accessible by the user, False otherwise
        """
        return str(self.user_id) == str(user_id)
    
    def mark_as_viewed(self):
        """
        Marks the achievement as viewed by the user.
        
        Returns:
            None: Updates the achievement in place
        """
        self.is_viewed = True
    
    def update_progress(self, progress_data):
        """
        Updates the progress data for an in-progress achievement.
        
        Args:
            progress_data (dict): New progress data to update with
            
        Returns:
            None: Updates the achievement in place
        """
        if not self.progress_data:
            self.progress_data = {}
        
        # Update the existing progress data with new values
        self.progress_data.update(progress_data)
    
    def get_progress_percentage(self):
        """
        Calculates the percentage of progress towards completing the achievement.
        
        Returns:
            float: Percentage of completion (0-100)
        """
        if not self.progress_data or 'current' not in self.progress_data or 'target' not in self.progress_data:
            # If achievement is already earned but doesn't have progress data
            if self.earned_date:
                return 100.0
            # If no progress data and not earned
            return 0.0
        
        current = self.progress_data['current']
        target = self.progress_data['target']
        
        if target <= 0:
            return 0.0
        
        percentage = (current / target) * 100
        
        # Cap at 100%
        return min(percentage, 100.0)