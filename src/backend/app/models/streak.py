from datetime import date, timedelta
from sqlalchemy import Column, Integer, ForeignKey, Boolean, Date
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from .base import BaseModel

# Constants for streak configuration
GRACE_PERIOD_DAYS = 1
GRACE_PERIOD_USES_PER_WEEK = 1

class Streak(BaseModel):
    """
    SQLAlchemy model representing a user's streak of consecutive days using the application.
    Tracks streak counts, history, and provides methods for streak management.
    
    A streak is defined as consecutive days where the user performs a meaningful 
    interaction with the application. The model includes a grace period mechanism 
    that allows for occasional missed days without breaking the streak.
    """
    
    # Foreign key to user
    user_id = Column(ForeignKey('users.id'), nullable=False, unique=True, index=True)
    
    # Streak counts
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    
    # Activity tracking
    last_activity_date = Column(Date, nullable=True)
    total_days_active = Column(Integer, nullable=False, default=0)
    
    # Streak history as JSON
    streak_history = Column(JSONB, nullable=False, default=list)
    
    # Grace period tracking
    grace_period_used_count = Column(Integer, nullable=False, default=0)
    grace_period_reset_date = Column(Date, nullable=True)
    grace_period_active = Column(Boolean, nullable=False, default=False)
    
    # Relationship to user
    user = relationship("User", back_populates="streaks")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if a streak record is accessible by a specific user.
        
        Args:
            user_id (UUID): ID of the user attempting to access the streak
            
        Returns:
            bool: True if the streak is accessible by the user, False otherwise
        """
        return str(self.user_id) == str(user_id)
    
    def record_activity(self, activity_date=None):
        """
        Records user activity for the current date and updates streak information.
        
        This method handles various scenarios:
        1. First-ever activity - initializes streak
        2. Same-day activity - no change in streak
        3. Consecutive day activity - increments streak
        4. Missed day within grace period - uses grace period if available
        5. Missed day beyond grace period - resets streak
        
        Args:
            activity_date (date, optional): The date of the activity. Defaults to current date.
            
        Returns:
            bool: True if streak was incremented or reset, False if unchanged
        """
        # Use current date if no date provided
        if activity_date is None:
            activity_date = date.today()
        
        # If this is the first activity ever
        if self.last_activity_date is None:
            self.current_streak = 1
            self.longest_streak = 1
            self.total_days_active = 1
            self.last_activity_date = activity_date
            
            # Initialize streak_history if it's None
            if self.streak_history is None:
                self.streak_history = []
            
            # Add first activity to history
            self.streak_history.append({
                "date": activity_date.isoformat(),
                "type": "activity",
                "streak": 1
            })
            
            return True
        
        # If already recorded activity for this date
        if self.last_activity_date == activity_date:
            return False
        
        # Calculate days since last activity
        days_diff = (activity_date - self.last_activity_date).days
        
        # Activity on the next day - increment streak
        if days_diff == 1:
            self.current_streak += 1
            self.total_days_active += 1
            self.last_activity_date = activity_date
            self.grace_period_active = False
            
            # Update streak_history
            self.streak_history.append({
                "date": activity_date.isoformat(),
                "type": "activity",
                "streak": self.current_streak
            })
            
            # Update longest streak if needed
            if self.current_streak > self.longest_streak:
                self.longest_streak = self.current_streak
                
            return True
        
        # Activity on the same day - no change in streak
        elif days_diff == 0:
            return False
        
        # Activity after gap but within grace period
        elif days_diff <= GRACE_PERIOD_DAYS + 1 and self.check_grace_period_availability():
            # Use grace period
            if self.use_grace_period():
                self.current_streak += 1
                self.total_days_active += 1
                self.last_activity_date = activity_date
                
                # Update streak_history
                self.streak_history.append({
                    "date": activity_date.isoformat(),
                    "type": "activity",
                    "streak": self.current_streak,
                    "grace_period_used": True
                })
                
                # Update longest streak if needed
                if self.current_streak > self.longest_streak:
                    self.longest_streak = self.current_streak
                    
                return True
            else:
                # Grace period not available, reset streak
                self.reset_streak()
                self.current_streak = 1
                self.total_days_active += 1
                self.last_activity_date = activity_date
                
                # Update streak_history
                self.streak_history.append({
                    "date": activity_date.isoformat(),
                    "type": "activity",
                    "streak": 1,
                    "reset": True
                })
                
                return True
        
        # Activity after a gap - reset streak
        else:
            self.reset_streak()
            self.current_streak = 1
            self.total_days_active += 1
            self.last_activity_date = activity_date
            
            # Update streak_history
            self.streak_history.append({
                "date": activity_date.isoformat(),
                "type": "activity",
                "streak": 1,
                "reset": True
            })
            
            return True
    
    def reset_streak(self):
        """
        Resets the current streak to zero.
        
        This method records the reset event in the streak history and
        resets the current streak counter and grace period status.
        """
        # Record reset in history
        if self.streak_history is None:
            self.streak_history = []
            
        self.streak_history.append({
            "date": date.today().isoformat(),
            "type": "reset",
            "previous_streak": self.current_streak
        })
        
        self.current_streak = 0
        self.grace_period_active = False
    
    def get_next_milestone(self):
        """
        Gets the next streak milestone for achievements.
        
        Milestone values are defined as 3, 7, 14, 30, 60, and 90 days.
        
        Returns:
            int: Next milestone value (3, 7, 14, 30, 60, or 90 days)
        """
        milestones = [3, 7, 14, 30, 60, 90]
        
        for milestone in milestones:
            if self.current_streak < milestone:
                return milestone
        
        return milestones[-1]  # Return the highest milestone if all are exceeded
    
    def get_milestone_progress(self):
        """
        Calculates progress towards the next streak milestone.
        
        Progress is calculated as the percentage of the way between the previous
        milestone and the next milestone.
        
        Returns:
            float: Percentage progress towards next milestone (0-1)
        """
        next_milestone = self.get_next_milestone()
        
        # Find the previous milestone
        milestones = [0, 3, 7, 14, 30, 60, 90]
        previous_milestone = 0
        
        for milestone in milestones:
            if milestone < next_milestone and milestone <= self.current_streak:
                previous_milestone = milestone
        
        # Calculate progress between previous and next milestone
        milestone_range = next_milestone - previous_milestone
        current_progress = self.current_streak - previous_milestone
        
        # Avoid division by zero
        if milestone_range == 0:
            return 1.0
            
        progress = current_progress / milestone_range
        
        # Cap at 1.0 (100%)
        return min(progress, 1.0)
    
    def check_grace_period_availability(self):
        """
        Checks if grace period is available for use.
        
        Grace periods are limited to a certain number of uses per week.
        The counter resets weekly to allow for continued use of the feature.
        
        Returns:
            bool: True if grace period can be used, False otherwise
        """
        today = date.today()
        
        # Initialize grace period reset date if not set
        if self.grace_period_reset_date is None:
            self.grace_period_reset_date = today
            self.grace_period_used_count = 0
            
        # Check if a week has passed since last reset
        days_since_reset = (today - self.grace_period_reset_date).days
        if days_since_reset >= 7:
            # Reset the grace period counter
            self.grace_period_used_count = 0
            self.grace_period_reset_date = today
            
        # Check if grace period is available
        return self.grace_period_used_count < GRACE_PERIOD_USES_PER_WEEK
    
    def use_grace_period(self):
        """
        Uses a grace period to maintain streak despite a missed day.
        
        The grace period feature allows users to maintain their streak even
        when they miss a day, supporting engagement and motivation.
        
        Returns:
            bool: True if grace period was successfully used, False otherwise
        """
        if self.check_grace_period_availability():
            self.grace_period_used_count += 1
            self.grace_period_active = True
            
            # Record grace period use in history
            if self.streak_history is None:
                self.streak_history = []
                
            self.streak_history.append({
                "date": date.today().isoformat(),
                "type": "grace_period",
                "streak": self.current_streak
            })
            
            return True
        
        return False
    
    def get_streak_history_by_month(self, year, month):
        """
        Gets streak history aggregated by month for visualization.
        
        This method filters and organizes streak history data for a specific
        month and year to support visualizations in the UI.
        
        Args:
            year (int): Year to retrieve history for
            month (int): Month to retrieve history for (1-12)
            
        Returns:
            dict: Dictionary with daily streak data for the specified month
        """
        if self.streak_history is None:
            return {}
            
        # Filter history for the specified month
        monthly_data = {}
        
        for entry in self.streak_history:
            entry_date = date.fromisoformat(entry["date"])
            
            if entry_date.year == year and entry_date.month == month:
                day = entry_date.day
                monthly_data[day] = {
                    "streak": entry.get("streak", 0),
                    "type": entry.get("type", "activity"),
                    "grace_period_used": entry.get("grace_period_used", False),
                    "reset": entry.get("reset", False)
                }
                
        return monthly_data
    
    def to_dict(self):
        """
        Converts the streak to a dictionary representation.
        
        This method extends the base to_dict method to include
        calculated fields like next milestone and milestone progress.
        
        Returns:
            dict: Dictionary representation of the streak
        """
        # Get basic dictionary from parent class
        base_dict = super().to_dict()
        
        # Add streak-specific fields
        next_milestone = self.get_next_milestone()
        milestone_progress = self.get_milestone_progress()
        
        # Format dates as ISO strings if they exist
        if self.last_activity_date:
            base_dict["last_activity_date"] = self.last_activity_date.isoformat()
        
        if self.grace_period_reset_date:
            base_dict["grace_period_reset_date"] = self.grace_period_reset_date.isoformat()
            
        # Add calculated fields
        base_dict.update({
            "next_milestone": next_milestone,
            "milestone_progress": milestone_progress
        })
        
        return base_dict