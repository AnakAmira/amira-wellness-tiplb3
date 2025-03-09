# src/backend/app/background/jobs/streak_calculation.py
import uuid
from datetime import date, timedelta
from typing import Dict, List, Optional

from sqlalchemy.orm import Session

from ...core.logging import get_logger  # Assuming correct relative import
from ...db.session import SessionLocal  # Assuming correct relative import
from ...crud import streak, user, achievement  # Assuming correct relative import
from ...models.streak import Streak  # Assuming correct relative import
from ...models.notification import NotificationType  # Assuming correct relative import
from ...schemas.progress import StreakUpdate  # Assuming correct relative import
from ...constants.achievements import AchievementType  # Assuming correct relative import
from ...services.notification import NotificationService  # Assuming correct relative import

# Initialize logger
logger = get_logger(__name__)

# Initialize notification service
notification_service = NotificationService()

# Define streak milestones
STREAK_MILESTONES = [3, 7, 14, 30, 60, 90]


def calculate_daily_streaks() -> Dict:
    """
    Calculates and updates streaks for all active users based on their activity.

    Returns:
        dict: Dictionary with streak calculation results
    """
    with SessionLocal() as db:
        # Get the current date for streak calculations
        today = date.today()

        # Initialize counters for tracking results
        total_users = 0
        streaks_increased = 0
        streaks_unchanged = 0
        milestones_reached = 0

        # Query all active users from the database
        active_users = user.get_multi(db)
        total_users = len(active_users)

        for user_obj in active_users:
            if not user.is_active(user_obj):
                continue

            # Get or create their streak record
            streak_obj = streak.get_by_user_id_or_create(db, user_obj.id)

            # Create a StreakUpdate object with the current date
            streak_update = StreakUpdate(activity_date=today)

            # Update the user's streak
            streak_obj, streak_increased = streak.update_streak(db, user_obj.id, streak_update)

            if streak_increased:
                streaks_increased += 1
                # Check for milestone achievements
                if check_streak_milestones(db, user_obj.id, streak_obj.current_streak):
                    milestones_reached += 1
            else:
                streaks_unchanged += 1

        # Log the streak calculation results
        logger.info(
            f"Streak calculation completed. Total users: {total_users}, "
            f"Streaks increased: {streaks_increased}, Streaks unchanged: {streaks_unchanged}, "
            f"Milestones reached: {milestones_reached}"
        )

        # Return a dictionary with the calculation results
        return {
            "total_users": total_users,
            "streaks_increased": streaks_increased,
            "streaks_unchanged": streaks_unchanged,
            "milestones_reached": milestones_reached,
        }


def check_streak_milestones(db: Session, user_id: uuid.UUID, current_streak: int) -> bool:
    """
    Checks if a user has reached a streak milestone and creates achievements if needed.

    Args:
        db: Database session
        user_id: ID of the user
        current_streak: The user's current streak value

    Returns:
        bool: True if a milestone was reached, False otherwise
    """
    # Check if the current streak matches any of the defined milestones
    if current_streak not in STREAK_MILESTONES:
        return False

    # Determine the achievement type based on the milestone
    achievement_type = get_achievement_type_for_streak(current_streak)
    if achievement_type is None:
        return False

    # Get or create the achievement record
    achievement_obj, _ = achievement.get_or_create_by_type(db, achievement_type)

    # Create an achievement notification for the user
    notification_service.create_achievement_notification(
        db=db,
        user_id=user_id,
        achievement_name=achievement_obj.name_es,
        achievement_description=achievement_obj.description_es,
        achievement_id=str(achievement_obj.id)
    )

    # Log the milestone achievement
    logger.info(f"User {user_id} reached milestone {current_streak} (achievement: {achievement_type.value})")

    return True


def get_achievement_type_for_streak(streak_value: int) -> Optional[AchievementType]:
    """
    Maps a streak milestone to the corresponding achievement type.

    Args:
        streak_value: The streak milestone value

    Returns:
        AchievementType: The achievement type for the streak milestone
    """
    # Match the streak value to the corresponding achievement type
    if streak_value == 3:
        return AchievementType.STREAK_3_DAYS
    elif streak_value == 7:
        return AchievementType.STREAK_7_DAYS
    elif streak_value == 14:
        return AchievementType.STREAK_14_DAYS
    elif streak_value == 30:
        return AchievementType.STREAK_30_DAYS
    elif streak_value == 60:
        return AchievementType.STREAK_60_DAYS
    elif streak_value == 90:
        return AchievementType.STREAK_90_DAYS
    else:
        return None


def send_streak_at_risk_reminders() -> Dict:
    """
    Sends reminder notifications to users whose streaks are at risk of being broken.

    Returns:
        dict: Dictionary with reminder sending results
    """
    with SessionLocal() as db:
        # Get the current date for reference
        today = date.today()

        # Get users with streaks at risk
        users_at_risk = streak.get_users_with_streak_at_risk(db, reference_date=today)

        # Initialize counter for tracking sent reminders
        reminders_sent = 0

        # For each user with streak at risk
        for streak_obj in users_at_risk:
            user_obj = user.get(db, streak_obj.user_id)
            if not user_obj:
                logger.warning(f"User not found for streak at risk: {streak_obj.user_id}")
                continue

            # Check if the user is active
            if not user.is_active(user_obj):
                logger.debug(f"Skipping streak reminder for inactive user: {user_obj.id}")
                continue

            # Create a streak reminder notification
            notification_service.create_streak_reminder(
                db=db,
                user_id=user_obj.id,
                current_streak=streak_obj.current_streak
            )
            reminders_sent += 1

        # Log the reminder sending results
        logger.info(f"Streak reminder process completed. Reminders sent: {reminders_sent}")

        # Return a dictionary with the number of reminders sent
        return {"reminders_sent": reminders_sent}