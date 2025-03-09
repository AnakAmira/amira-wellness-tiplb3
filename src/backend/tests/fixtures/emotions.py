"""
Test fixture module that provides emotion-related fixtures for unit and integration tests
in the Amira Wellness application. Includes fixtures for various emotional states, check-ins,
and trends to support testing of the emotional tracking functionality.
"""

import pytest
import datetime
import uuid

# Import emotion-related enums
from ...app.constants.emotions import (
    EmotionType, EmotionContext, TrendDirection, PeriodType
)

# Import emotion-related models
from ...app.models.emotion import (
    EmotionalCheckin, EmotionalTrend, EmotionalInsight
)

# Import database and user fixtures
from .database import test_db
from .users import regular_user

# Sample emotion check-in data for creating fixtures
EMOTION_CHECKIN_DATA = [
    {
        'emotion_type': EmotionType.JOY, 
        'intensity': 8, 
        'context': EmotionContext.STANDALONE, 
        'notes': 'Feeling great today'
    },
    {
        'emotion_type': EmotionType.SADNESS, 
        'intensity': 6, 
        'context': EmotionContext.STANDALONE, 
        'notes': 'Feeling down today'
    },
    {
        'emotion_type': EmotionType.ANXIETY, 
        'intensity': 7, 
        'context': EmotionContext.STANDALONE, 
        'notes': 'Feeling nervous about presentation'
    },
    {
        'emotion_type': EmotionType.CALM, 
        'intensity': 9, 
        'context': EmotionContext.TOOL_USAGE, 
        'notes': 'After meditation session'
    },
    {
        'emotion_type': EmotionType.FRUSTRATION, 
        'intensity': 8, 
        'context': EmotionContext.STANDALONE, 
        'notes': 'Stuck on a problem'
    }
]

@pytest.fixture
def joy_emotion(test_db, regular_user):
    """
    Creates a joy emotional check-in instance for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Joy emotional check-in instance
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.JOY,
        intensity=8,
        context=EmotionContext.STANDALONE,
        notes='Feeling great today'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def sadness_emotion(test_db, regular_user):
    """
    Creates a sadness emotional check-in instance for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Sadness emotional check-in instance
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.SADNESS,
        intensity=6,
        context=EmotionContext.STANDALONE,
        notes='Feeling down today'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def anxiety_emotion(test_db, regular_user):
    """
    Creates an anxiety emotional check-in instance for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Anxiety emotional check-in instance
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.ANXIETY,
        intensity=7,
        context=EmotionContext.STANDALONE,
        notes='Feeling nervous about presentation'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def calm_emotion(test_db, regular_user):
    """
    Creates a calm emotional check-in instance for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Calm emotional check-in instance
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.CALM,
        intensity=9,
        context=EmotionContext.TOOL_USAGE,
        notes='After meditation session'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def frustration_emotion(test_db, regular_user):
    """
    Creates a frustration emotional check-in instance for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Frustration emotional check-in instance
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.FRUSTRATION,
        intensity=8,
        context=EmotionContext.STANDALONE,
        notes='Stuck on a problem'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def pre_journal_emotion(test_db, regular_user):
    """
    Creates a pre-journaling emotional check-in for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Pre-journaling emotional check-in
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.ANXIETY,
        intensity=8,
        context=EmotionContext.PRE_JOURNALING,
        notes='Feeling anxious before journaling'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def post_journal_emotion(test_db, regular_user):
    """
    Creates a post-journaling emotional check-in for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalCheckin: Post-journaling emotional check-in
    """
    emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.CALM,
        intensity=6,
        context=EmotionContext.POST_JOURNALING,
        notes='Feeling more calm after journaling'
    )
    test_db.add(emotion)
    test_db.commit()
    test_db.refresh(emotion)
    return emotion

@pytest.fixture
def emotion_pair(test_db, regular_user):
    """
    Creates a pair of pre/post journaling emotions for testing emotional shifts.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        tuple: Pair of pre and post journaling emotional check-ins
    """
    # Create a common journal_id for both emotions
    journal_id = str(uuid.uuid4())
    
    # Pre-journaling emotion
    pre_emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.ANXIETY,
        intensity=8,
        context=EmotionContext.PRE_JOURNALING,
        notes='Feeling anxious before journaling',
        related_journal_id=journal_id
    )
    
    # Post-journaling emotion
    post_emotion = EmotionalCheckin(
        user_id=regular_user.id,
        emotion_type=EmotionType.CALM,
        intensity=6,
        context=EmotionContext.POST_JOURNALING,
        notes='Feeling more calm after journaling',
        related_journal_id=journal_id
    )
    
    test_db.add(pre_emotion)
    test_db.add(post_emotion)
    test_db.commit()
    test_db.refresh(pre_emotion)
    test_db.refresh(post_emotion)
    
    return pre_emotion, post_emotion

@pytest.fixture
def daily_emotion_trend(test_db, regular_user):
    """
    Creates a daily emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Daily emotional trend
    """
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.DAY,
        period_value=datetime.date.today().isoformat(),
        emotion_type=EmotionType.JOY,
        occurrence_count=5,
        average_intensity=7.5,
        min_intensity=6,
        max_intensity=9,
        trend_direction=TrendDirection.STABLE
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def weekly_emotion_trend(test_db, regular_user):
    """
    Creates a weekly emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Weekly emotional trend
    """
    # Get ISO week format for the current date
    today = datetime.date.today()
    week_number = today.isocalendar()[1]
    year = today.year
    period_value = f"{year}-W{week_number:02d}"
    
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.WEEK,
        period_value=period_value,
        emotion_type=EmotionType.ANXIETY,
        occurrence_count=12,
        average_intensity=6.8,
        min_intensity=4,
        max_intensity=9,
        trend_direction=TrendDirection.DECREASING
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def monthly_emotion_trend(test_db, regular_user):
    """
    Creates a monthly emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Monthly emotional trend
    """
    # Get year-month format for the current date
    today = datetime.date.today()
    period_value = f"{today.year}-{today.month:02d}"
    
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.MONTH,
        period_value=period_value,
        emotion_type=EmotionType.CALM,
        occurrence_count=28,
        average_intensity=7.2,
        min_intensity=5,
        max_intensity=10,
        trend_direction=TrendDirection.INCREASING
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def increasing_emotion_trend(test_db, regular_user):
    """
    Creates an increasing emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Increasing emotional trend
    """
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.WEEK,
        period_value=f"{datetime.date.today().year}-W{datetime.date.today().isocalendar()[1]:02d}",
        emotion_type=EmotionType.JOY,
        occurrence_count=7,
        average_intensity=7.8,
        min_intensity=5,
        max_intensity=10,
        trend_direction=TrendDirection.INCREASING
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def decreasing_emotion_trend(test_db, regular_user):
    """
    Creates a decreasing emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Decreasing emotional trend
    """
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.WEEK,
        period_value=f"{datetime.date.today().year}-W{datetime.date.today().isocalendar()[1]:02d}",
        emotion_type=EmotionType.ANXIETY,
        occurrence_count=7,
        average_intensity=5.2,
        min_intensity=3,
        max_intensity=8,
        trend_direction=TrendDirection.DECREASING
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def stable_emotion_trend(test_db, regular_user):
    """
    Creates a stable emotional trend for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalTrend: Stable emotional trend
    """
    trend = EmotionalTrend(
        user_id=regular_user.id,
        period_type=PeriodType.WEEK,
        period_value=f"{datetime.date.today().year}-W{datetime.date.today().isocalendar()[1]:02d}",
        emotion_type=EmotionType.CALM,
        occurrence_count=7,
        average_intensity=6.9,
        min_intensity=6,
        max_intensity=8,
        trend_direction=TrendDirection.STABLE
    )
    test_db.add(trend)
    test_db.commit()
    test_db.refresh(trend)
    return trend

@pytest.fixture
def emotion_insight(test_db, regular_user):
    """
    Creates an emotional insight for testing.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        EmotionalInsight: Emotional insight instance
    """
    insight = EmotionalInsight(
        user_id=regular_user.id,
        type="PATTERN",
        description="You seem to experience anxiety most often on Monday mornings",
        related_emotions="ANXIETY,STRESS",
        confidence=0.85,
        recommended_actions="Consider starting your Monday with a brief meditation or breathing exercise"
    )
    test_db.add(insight)
    test_db.commit()
    test_db.refresh(insight)
    return insight

@pytest.fixture
def multiple_emotion_checkins(test_db, regular_user):
    """
    Creates multiple emotional check-ins for a user to test analysis functions.
    
    Args:
        test_db: Test database session
        regular_user: Regular user fixture
        
    Returns:
        list: List of emotional check-in instances
    """
    # Create a list to hold the created check-ins
    checkins = []
    
    # Sample emotions for the week
    emotion_data = [
        {"emotion_type": EmotionType.JOY, "intensity": 8, "context": EmotionContext.STANDALONE},
        {"emotion_type": EmotionType.ANXIETY, "intensity": 7, "context": EmotionContext.STANDALONE},
        {"emotion_type": EmotionType.CALM, "intensity": 6, "context": EmotionContext.TOOL_USAGE},
        {"emotion_type": EmotionType.SADNESS, "intensity": 5, "context": EmotionContext.STANDALONE},
        {"emotion_type": EmotionType.FRUSTRATION, "intensity": 7, "context": EmotionContext.STANDALONE},
        {"emotion_type": EmotionType.CALM, "intensity": 8, "context": EmotionContext.TOOL_USAGE},
        {"emotion_type": EmotionType.JOY, "intensity": 9, "context": EmotionContext.STANDALONE},
    ]
    
    # Create check-ins
    for i, data in enumerate(emotion_data):
        checkin = EmotionalCheckin(
            user_id=regular_user.id,
            emotion_type=data["emotion_type"],
            intensity=data["intensity"],
            context=data["context"],
            notes=f"Check-in {i+1} for testing"
        )
        test_db.add(checkin)
        checkins.append(checkin)
    
    test_db.commit()
    
    # Refresh all check-ins to get their IDs
    for checkin in checkins:
        test_db.refresh(checkin)
    
    return checkins