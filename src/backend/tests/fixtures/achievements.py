"""
Test fixture module that provides achievement-related fixtures for unit and integration tests
in the Amira Wellness application. Creates various achievement test objects with different types,
categories, and criteria to support comprehensive testing of the gamification and progress tracking features.
"""

import pytest
import uuid
import datetime
import json

# Internal imports
from ...app.models.achievement import Achievement
from ...app.models.progress import UserAchievement
from ...app.constants.achievements import (
    AchievementType,
    AchievementCategory,
    CriteriaType,
    ActionType
)
from .database import test_db
from .users import regular_user


def create_test_achievement(
    achievement_type: AchievementType,
    category: AchievementCategory,
    name_es: str,
    name_en: str,
    description_es: str,
    description_en: str,
    icon_url: str,
    points: int,
    is_hidden: bool,
    criteria: dict,
    metadata: dict
) -> Achievement:
    """
    Helper function to create a test achievement with specified attributes.
    
    Args:
        achievement_type: Type of achievement
        category: Category of achievement
        name_es: Spanish name
        name_en: English name
        description_es: Spanish description
        description_en: English description
        icon_url: URL to achievement icon
        points: Points awarded for earning the achievement
        is_hidden: Whether the achievement is hidden until earned
        criteria: Dictionary containing achievement criteria
        metadata: Additional metadata for the achievement
        
    Returns:
        Achievement instance with specified attributes
    """
    achievement = Achievement(
        id=uuid.uuid4(),
        achievement_type=achievement_type,
        category=category,
        name_es=name_es,
        name_en=name_en,
        description_es=description_es,
        description_en=description_en,
        icon_url=icon_url,
        points=points,
        is_hidden=is_hidden,
        criteria=criteria,
        metadata=metadata,
        created_at=datetime.datetime.utcnow(),
        updated_at=datetime.datetime.utcnow(),
    )
    
    return achievement


def create_test_user_achievement(
    user_id: uuid.UUID,
    achievement_id: uuid.UUID,
    earned_date: datetime.datetime,
    is_viewed: bool,
    progress_data: dict
) -> UserAchievement:
    """
    Helper function to create a test user achievement with specified attributes.
    
    Args:
        user_id: ID of the user
        achievement_id: ID of the achievement
        earned_date: Date when the achievement was earned (None if in progress)
        is_viewed: Whether the user has viewed the achievement notification
        progress_data: Data tracking progress towards the achievement
        
    Returns:
        UserAchievement instance with specified attributes
    """
    user_achievement = UserAchievement(
        id=uuid.uuid4(),
        user_id=user_id,
        achievement_id=achievement_id,
        earned_date=earned_date,
        is_viewed=is_viewed,
        progress_data=progress_data,
        created_at=datetime.datetime.utcnow(),
        updated_at=datetime.datetime.utcnow(),
    )
    
    return user_achievement


@pytest.fixture
def first_step_achievement(test_db):
    """
    Creates a first step achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance for first step achievement
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.FIRST_STEP,
        category=AchievementCategory.MILESTONE,
        name_es="Primer paso",
        name_en="First step",
        description_es="Completar el primer check-in emocional",
        description_en="Complete your first emotional check-in",
        icon_url="/assets/images/achievements/first_step.svg",
        points=10,
        is_hidden=False,
        criteria={
            "type": CriteriaType.COUNT.value,
            "target": 1,
            "action": ActionType.EMOTIONAL_CHECK_IN.value
        },
        metadata={
            "display_order": 1,
            "tags": ["beginner", "onboarding"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def streak_3_days_achievement(test_db):
    """
    Creates a 3-day streak achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance for 3-day streak achievement
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.STREAK_3_DAYS,
        category=AchievementCategory.STREAK,
        name_es="Racha de 3 días",
        name_en="3-day streak",
        description_es="Usar la aplicación durante 3 días consecutivos",
        description_en="Use the app for 3 consecutive days",
        icon_url="/assets/images/achievements/streak_3.svg",
        points=15,
        is_hidden=False,
        criteria={
            "type": CriteriaType.STREAK.value,
            "target": 3,
            "action": ActionType.APP_USAGE.value
        },
        metadata={
            "display_order": 2,
            "next_achievement": AchievementType.STREAK_7_DAYS.value,
            "tags": ["streak", "consistency"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def streak_7_days_achievement(test_db):
    """
    Creates a 7-day streak achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance for 7-day streak achievement
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.STREAK_7_DAYS,
        category=AchievementCategory.STREAK,
        name_es="Racha de 7 días",
        name_en="7-day streak",
        description_es="Usar la aplicación durante 7 días consecutivos",
        description_en="Use the app for 7 consecutive days",
        icon_url="/assets/images/achievements/streak_7.svg",
        points=25,
        is_hidden=False,
        criteria={
            "type": CriteriaType.STREAK.value,
            "target": 7,
            "action": ActionType.APP_USAGE.value
        },
        metadata={
            "display_order": 3,
            "next_achievement": AchievementType.STREAK_14_DAYS.value,
            "tags": ["streak", "consistency"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def first_journal_achievement(test_db):
    """
    Creates a first journal achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance for first journal achievement
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.FIRST_JOURNAL,
        category=AchievementCategory.JOURNALING,
        name_es="Primera grabación",
        name_en="First recording",
        description_es="Completar tu primer diario de voz",
        description_en="Complete your first voice journal",
        icon_url="/assets/images/achievements/first_journal.svg",
        points=15,
        is_hidden=False,
        criteria={
            "type": CriteriaType.COUNT.value,
            "target": 1,
            "action": ActionType.VOICE_JOURNAL.value
        },
        metadata={
            "display_order": 8,
            "tags": ["journaling", "beginner"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def tool_explorer_achievement(test_db):
    """
    Creates a tool explorer achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance for tool explorer achievement
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.TOOL_EXPLORER,
        category=AchievementCategory.TOOL_USAGE,
        name_es="Explorador de herramientas",
        name_en="Tool explorer",
        description_es="Probar 5 herramientas diferentes",
        description_en="Try 5 different tools",
        icon_url="/assets/images/achievements/tool_explorer.svg",
        points=25,
        is_hidden=False,
        criteria={
            "type": CriteriaType.UNIQUE_COUNT.value,
            "target": 5,
            "action": ActionType.TOOL_USAGE.value
        },
        metadata={
            "display_order": 12,
            "tags": ["tools", "exploration"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def hidden_achievement(test_db):
    """
    Creates a hidden achievement for testing.
    
    Args:
        test_db: Database session fixture
        
    Returns:
        Achievement instance with is_hidden=True
    """
    achievement = create_test_achievement(
        achievement_type=AchievementType.WELLNESS_JOURNEY,
        category=AchievementCategory.MILESTONE,
        name_es="Viaje de bienestar",
        name_en="Wellness journey",
        description_es="Usar la aplicación durante 100 días en total",
        description_en="Use the app for a total of 100 days",
        icon_url="/assets/images/achievements/wellness_journey.svg",
        points=200,
        is_hidden=True,
        criteria={
            "type": CriteriaType.COUNT.value,
            "target": 100,
            "action": ActionType.ACTIVE_DAYS.value
        },
        metadata={
            "display_order": 18,
            "tags": ["milestone", "dedication", "journey"]
        }
    )
    
    test_db.add(achievement)
    test_db.commit()
    test_db.refresh(achievement)
    
    return achievement


@pytest.fixture
def earned_achievement(test_db, regular_user, first_step_achievement):
    """
    Creates an earned user achievement for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: User fixture
        first_step_achievement: Achievement fixture
        
    Returns:
        UserAchievement instance with earned status
    """
    earned_date = datetime.datetime.utcnow() - datetime.timedelta(days=3)
    
    user_achievement = create_test_user_achievement(
        user_id=regular_user.id,
        achievement_id=first_step_achievement.id,
        earned_date=earned_date,
        is_viewed=True,
        progress_data={
            "current": 1,
            "target": 1,
            "completed": True
        }
    )
    
    test_db.add(user_achievement)
    test_db.commit()
    test_db.refresh(user_achievement)
    
    return user_achievement


@pytest.fixture
def in_progress_achievement(test_db, regular_user, streak_7_days_achievement):
    """
    Creates an in-progress user achievement for testing.
    
    Args:
        test_db: Database session fixture
        regular_user: User fixture
        streak_7_days_achievement: Achievement fixture
        
    Returns:
        UserAchievement instance with in-progress status
    """
    user_achievement = create_test_user_achievement(
        user_id=regular_user.id,
        achievement_id=streak_7_days_achievement.id,
        earned_date=None,  # None because it's in progress
        is_viewed=False,
        progress_data={
            "current": 4,  # 4 days out of 7 completed
            "target": 7,
            "streak_dates": [
                (datetime.datetime.utcnow() - datetime.timedelta(days=4)).strftime("%Y-%m-%d"),
                (datetime.datetime.utcnow() - datetime.timedelta(days=3)).strftime("%Y-%m-%d"),
                (datetime.datetime.utcnow() - datetime.timedelta(days=2)).strftime("%Y-%m-%d"),
                (datetime.datetime.utcnow() - datetime.timedelta(days=1)).strftime("%Y-%m-%d")
            ],
            "completed": False
        }
    )
    
    test_db.add(user_achievement)
    test_db.commit()
    test_db.refresh(user_achievement)
    
    return user_achievement


@pytest.fixture
def all_achievements(test_db, first_step_achievement, streak_3_days_achievement, 
                    streak_7_days_achievement, first_journal_achievement, 
                    tool_explorer_achievement, hidden_achievement):
    """
    Creates a collection of all achievement types for testing.
    
    Args:
        test_db: Database session fixture
        first_step_achievement: First step achievement fixture
        streak_3_days_achievement: 3-day streak achievement fixture
        streak_7_days_achievement: 7-day streak achievement fixture
        first_journal_achievement: First journal achievement fixture
        tool_explorer_achievement: Tool explorer achievement fixture
        hidden_achievement: Hidden achievement fixture
        
    Returns:
        List of Achievement instances
    """
    return [
        first_step_achievement,
        streak_3_days_achievement,
        streak_7_days_achievement,
        first_journal_achievement,
        tool_explorer_achievement,
        hidden_achievement
    ]