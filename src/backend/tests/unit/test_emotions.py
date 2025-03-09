import pytest
import datetime
import uuid

# Import emotion-related enums
from ...app.constants.emotions import ( # package_version: N/A
    EmotionType, EmotionCategory, EmotionContext, TrendDirection, PeriodType, InsightType,
    EMOTION_INTENSITY_MIN, EMOTION_INTENSITY_MAX,
    get_emotion_display_name, get_emotion_category, get_emotion_color, validate_emotion_intensity
)

# Import emotion-related models
from ...app.models.emotion import EmotionalCheckin, EmotionalTrend, EmotionalInsight # package_version: N/A

# Import CRUD operations
from ...app.crud.emotion import emotion, emotional_trend, emotional_insight # package_version: N/A

# Import schemas
from ...app.schemas.emotion import EmotionalStateCreate, EmotionalStateFilter, EmotionalTrendRequest # package_version: N/A

# Import service functions
from ...app.services.emotion import ( # package_version: N/A
    create_emotional_checkin, get_emotional_checkin, get_emotion_distribution,
    analyze_emotional_trends, get_emotional_shift, get_recommended_tools_for_emotion,
    EmotionAnalysisService
)

# Import exceptions
from ...app.core.exceptions import ValidationException, ResourceNotFoundException, PermissionDeniedException # package_version: N/A

# Import database and user fixtures
from ..fixtures.database import test_db # package_version: N/A
from ..fixtures.users import regular_user # package_version: N/A
from ..fixtures.emotions import ( # package_version: N/A
    joy_emotion, sadness_emotion, anxiety_emotion, pre_journal_emotion, post_journal_emotion,
    emotion_pair, daily_emotion_trend, increasing_emotion_trend, emotion_insight,
    multiple_emotion_checkins
)

@pytest.mark.unit
def test_emotional_checkin_model(joy_emotion):
    """Test the EmotionalCheckin model properties and methods"""
    assert joy_emotion.emotion_type == EmotionType.JOY
    assert EMOTION_INTENSITY_MIN <= joy_emotion.intensity <= EMOTION_INTENSITY_MAX
    assert joy_emotion.context == EmotionContext.STANDALONE
    assert joy_emotion.user_id is not None
    assert joy_emotion.id is not None

@pytest.mark.unit
def test_emotional_checkin_validate_intensity_valid(joy_emotion):
    """Test that validate_intensity accepts valid intensity values"""
    assert joy_emotion.validate_intensity('intensity', 5) == 5

@pytest.mark.unit
def test_emotional_checkin_validate_intensity_invalid(joy_emotion):
    """Test that validate_intensity rejects invalid intensity values"""
    with pytest.raises(ValueError):
        joy_emotion.validate_intensity('intensity', EMOTION_INTENSITY_MIN - 1)
    with pytest.raises(ValueError):
        joy_emotion.validate_intensity('intensity', EMOTION_INTENSITY_MAX + 1)

@pytest.mark.unit
def test_emotional_checkin_get_emotion_metadata(joy_emotion):
    """Test that get_emotion_metadata returns correct metadata"""
    metadata = joy_emotion.get_emotion_metadata()
    assert isinstance(metadata, dict)
    assert 'display_name' in metadata
    assert 'description' in metadata
    assert 'color' in metadata
    assert metadata['display_name'] == 'Alegría'
    assert metadata['color'] == '#FFD700'

@pytest.mark.unit
def test_emotional_checkin_is_accessible_by_user(joy_emotion, regular_user):
    """Test that is_accessible_by_user correctly determines access"""
    assert joy_emotion.is_accessible_by_user(regular_user.id) is True
    assert joy_emotion.is_accessible_by_user(uuid.uuid4()) is False

@pytest.mark.unit
def test_emotional_trend_model(daily_emotion_trend):
    """Test the EmotionalTrend model properties and methods"""
    assert daily_emotion_trend.period_type == PeriodType.DAY
    assert daily_emotion_trend.emotion_type is not None
    assert daily_emotion_trend.user_id is not None
    assert daily_emotion_trend.id is not None

@pytest.mark.unit
def test_emotional_trend_calculate_trend_direction():
    """Test that calculate_trend_direction correctly determines trend direction"""
    trend = EmotionalTrend(user_id=uuid.uuid4(), period_type=PeriodType.DAY, period_value='2024-01-01', emotion_type=EmotionType.JOY, occurrence_count=1, average_intensity=5, min_intensity=1, max_intensity=10)
    increasing_values = [1, 2, 3, 4, 5]
    assert trend.calculate_trend_direction(increasing_values) == TrendDirection.INCREASING
    decreasing_values = [5, 4, 3, 2, 1]
    assert trend.calculate_trend_direction(decreasing_values) == TrendDirection.DECREASING
    stable_values = [5, 5, 5, 5, 5]
    assert trend.calculate_trend_direction(stable_values) == TrendDirection.STABLE
    fluctuating_values = [1, 5, 2, 4, 3]
    assert trend.calculate_trend_direction(fluctuating_values) == TrendDirection.FLUCTUATING

@pytest.mark.unit
def test_emotional_trend_is_accessible_by_user(daily_emotion_trend, regular_user):
    """Test that is_accessible_by_user correctly determines access for trends"""
    assert daily_emotion_trend.is_accessible_by_user(regular_user.id) is True
    assert daily_emotion_trend.is_accessible_by_user(uuid.uuid4()) is False

@pytest.mark.unit
def test_emotional_insight_model(emotion_insight):
    """Test the EmotionalInsight model properties and methods"""
    assert emotion_insight.type is not None
    assert emotion_insight.user_id is not None
    assert emotion_insight.id is not None

@pytest.mark.unit
def test_emotional_insight_is_accessible_by_user(emotion_insight, regular_user):
    """Test that is_accessible_by_user correctly determines access for insights"""
    assert emotion_insight.is_accessible_by_user(regular_user.id) is True
    assert emotion_insight.is_accessible_by_user(uuid.uuid4()) is False

@pytest.mark.unit
def test_create_emotional_checkin(test_db, regular_user):
    """Test creating a new emotional check-in with valid data"""
    data = {\
        'user_id': regular_user.id,\
        'emotion_type': EmotionType.JOY,\
        'intensity': 5,\
        'context': EmotionContext.STANDALONE,\
        'notes': 'Test check-in'\
    }
    checkin = create_emotional_checkin(test_db, data)
    assert checkin.emotion_type == EmotionType.JOY
    assert checkin.intensity == 5
    assert checkin.context == EmotionContext.STANDALONE
    assert checkin.user_id == regular_user.id

@pytest.mark.unit
def test_create_emotional_checkin_invalid_intensity(test_db, regular_user):
    """Test that creating a check-in with invalid intensity raises ValidationException"""
    with pytest.raises(ValidationException):
        data = {\
            'user_id': regular_user.id,\
            'emotion_type': EmotionType.JOY,\
            'intensity': EMOTION_INTENSITY_MIN - 1,\
            'context': EmotionContext.STANDALONE,\
            'notes': 'Test check-in'\
        }
        create_emotional_checkin(test_db, data)
    with pytest.raises(ValidationException):
        data = {\
            'user_id': regular_user.id,\
            'emotion_type': EmotionType.JOY,\
            'intensity': EMOTION_INTENSITY_MAX + 1,\
            'context': EmotionContext.STANDALONE,\
            'notes': 'Test check-in'\
        }
        create_emotional_checkin(test_db, data)

@pytest.mark.unit
def test_get_emotional_checkin(test_db, joy_emotion, regular_user):
    """Test retrieving an emotional check-in by ID"""
    checkin = get_emotional_checkin(test_db, joy_emotion.id, regular_user.id)
    assert checkin is not None
    assert checkin.id == joy_emotion.id
    assert checkin.emotion_type == joy_emotion.emotion_type

@pytest.mark.unit
def test_get_emotional_checkin_not_found(test_db, regular_user):
    """Test that retrieving a non-existent check-in raises ResourceNotFoundException"""
    with pytest.raises(ResourceNotFoundException):
        get_emotional_checkin(test_db, uuid.uuid4(), regular_user.id)

@pytest.mark.unit
def test_get_emotional_checkin_permission_denied(test_db, joy_emotion):
    """Test that retrieving another user's check-in raises PermissionDeniedException"""
    with pytest.raises(PermissionDeniedException):
        get_emotional_checkin(test_db, joy_emotion.id, uuid.uuid4())

@pytest.mark.unit
def test_get_emotion_distribution(test_db, multiple_emotion_checkins, regular_user):
    """Test getting emotion distribution for a user"""
    start_date = datetime.datetime.now() - datetime.timedelta(days=7)
    end_date = datetime.datetime.now()
    distribution = get_emotion_distribution(test_db, regular_user.id, start_date, end_date)
    assert isinstance(distribution, dict)
    assert EmotionType.JOY in distribution
    assert EmotionType.ANXIETY in distribution
    assert 'count' in distribution[EmotionType.JOY]
    assert 'percentage' in distribution[EmotionType.JOY]
    assert 'average_intensity' in distribution[EmotionType.JOY]
    total_percentage = sum(d['percentage'] for d in distribution.values())
    assert abs(total_percentage - 100) < 1  # Allow for rounding errors

@pytest.mark.unit
def test_analyze_emotional_trends(test_db, multiple_emotion_checkins, regular_user):
    """Test analyzing emotional trends for a user"""
    start_date = datetime.datetime.now() - datetime.timedelta(days=7)
    end_date = datetime.datetime.now()
    request = {\
        'start_date': start_date,\
        'end_date': end_date,\
        'period_type': PeriodType.DAY\
    }
    analysis = analyze_emotional_trends(test_db, regular_user.id, request)
    assert isinstance(analysis, dict)
    assert 'start_date' in analysis
    assert 'end_date' in analysis
    assert 'period_type' in analysis
    assert 'trends' in analysis
    assert isinstance(analysis['trends'], list)
    if analysis['trends']:
        trend = analysis['trends'][0]
        assert 'emotion_type' in trend
        assert 'display_name' in trend
        assert 'color' in trend
        assert 'data_points' in trend

@pytest.mark.unit
def test_get_emotional_shift(test_db, emotion_pair):
    """Test calculating emotional shift between pre and post journal check-ins"""
    pre_emotion, post_emotion = emotion_pair
    shift = get_emotional_shift(test_db, pre_emotion.related_journal_id)
    assert isinstance(shift, dict)
    assert 'pre_state' in shift
    assert 'post_state' in shift
    assert 'intensity_change' in shift
    assert 'insights' in shift
    assert shift['intensity_change'] == (post_emotion.intensity - pre_emotion.intensity)
    assert isinstance(shift['insights'], list)

@pytest.mark.unit
def test_get_emotional_shift_missing_checkin(test_db, pre_journal_emotion):
    """Test that calculating shift with missing check-in raises ValidationException"""
    with pytest.raises(ValidationException):
        get_emotional_shift(test_db, pre_journal_emotion.id)

@pytest.mark.unit
def test_get_recommended_tools_for_emotion(test_db, regular_user):
    """Test getting tool recommendations based on emotional state"""
    recommendations = get_recommended_tools_for_emotion(test_db, regular_user.id, EmotionType.ANXIETY, 7, limit=3)
    assert isinstance(recommendations, list)
    assert len(recommendations) <= 3
    if recommendations:
        recommendation = recommendations[0]
        assert 'tool_id' in recommendation
        assert 'name' in recommendation
        assert 'relevance_score' in recommendation
        assert 'reason_for_recommendation' in recommendation

@pytest.mark.unit
def test_get_recommended_tools_for_emotion_invalid_intensity(test_db, regular_user):
    """Test that getting recommendations with invalid intensity raises ValidationException"""
    with pytest.raises(ValidationException):
        get_recommended_tools_for_emotion(test_db, regular_user.id, EmotionType.ANXIETY, EMOTION_INTENSITY_MAX + 1, limit=3)

@pytest.mark.unit
def test_emotion_crud_get_by_user(test_db, multiple_emotion_checkins, regular_user):
    """Test retrieving emotional check-ins for a specific user"""
    checkins = emotion.get_by_user(test_db, regular_user.id, skip=0, limit=10)
    assert len(checkins) > 0
    for checkin in checkins:
        assert checkin.user_id == regular_user.id

@pytest.mark.unit
def test_emotion_crud_get_filtered(test_db, multiple_emotion_checkins, regular_user):
    """Test retrieving filtered emotional check-ins"""
    # Filter by emotion_types
    filters = EmotionalStateFilter(emotion_types=[EmotionType.JOY])
    checkins, count = emotion.get_filtered(test_db, filters, regular_user.id, skip=0, limit=10)
    assert len(checkins) > 0
    for checkin in checkins:
        assert checkin.emotion_type == EmotionType.JOY

    # Filter by min_intensity
    filters = EmotionalStateFilter(min_intensity=7)
    checkins, count = emotion.get_filtered(test_db, filters, regular_user.id, skip=0, limit=10)
    assert len(checkins) > 0
    for checkin in checkins:
        assert checkin.intensity >= 7

@pytest.mark.unit
def test_emotion_crud_get_pre_post_journal(test_db, emotion_pair):
    """Test retrieving pre and post journal check-ins"""
    pre_emotion, post_emotion = emotion_pair
    pre, post = emotion.get_pre_post_journal(test_db, pre_emotion.related_journal_id)
    assert pre.context == EmotionContext.PRE_JOURNALING
    assert post.context == EmotionContext.POST_JOURNALING
    assert pre.related_journal_id == post.related_journal_id

@pytest.mark.unit
def test_emotional_trend_crud_calculate_trends(test_db, multiple_emotion_checkins, regular_user):
    """Test calculating emotional trends from check-in data"""
    start_date = datetime.datetime.now() - datetime.timedelta(days=7)
    end_date = datetime.datetime.now()
    trends = emotional_trend.calculate_trends(test_db, regular_user.id, start_date, end_date, PeriodType.DAY, emotion_types=None)
    assert len(trends) > 0
    for trend in trends:
        assert trend.period_type == PeriodType.DAY
        assert trend.user_id == regular_user.id
        assert trend.trend_direction in [TrendDirection.INCREASING, TrendDirection.DECREASING, TrendDirection.STABLE, TrendDirection.FLUCTUATING, None]

@pytest.mark.unit
def test_emotional_insight_crud_generate_insights(test_db, multiple_emotion_checkins, regular_user):
    """Test generating emotional insights from check-in data"""
    start_date = datetime.datetime.now() - datetime.timedelta(days=7)
    end_date = datetime.datetime.now()
    insights = emotional_insight.generate_insights(test_db, regular_user.id, start_date, end_date)
    assert isinstance(insights, list)
    if insights:
        insight = insights[0]
        assert insight.user_id == regular_user.id
        assert insight.type in [InsightType.PATTERN, InsightType.TRIGGER, InsightType.IMPROVEMENT]

@pytest.mark.unit
def test_emotion_analysis_service(test_db, multiple_emotion_checkins, regular_user):
    """Test the EmotionAnalysisService class methods"""
    service = EmotionAnalysisService()
    start_date = datetime.datetime.now() - datetime.timedelta(days=7)
    end_date = datetime.datetime.now()
    analysis = service.analyze_emotional_health(test_db, regular_user.id, start_date, end_date)
    assert isinstance(analysis, dict)
    assert 'emotion_distribution' in analysis
    assert 'emotional_balance' in analysis
    assert 'trends' in analysis
    assert 'patterns' in analysis
    assert 'insights' in analysis
    assert 'recommendations' in analysis

    balance = service.calculate_emotional_balance(multiple_emotion_checkins)
    assert isinstance(balance, dict)
    assert 'positive_percentage' in balance
    assert 'negative_percentage' in balance
    assert 'neutral_percentage' in balance
    assert abs(balance['positive_percentage'] + balance['negative_percentage'] + balance['neutral_percentage'] - 100) < 1

    triggers = service.identify_emotional_triggers(multiple_emotion_checkins)
    assert isinstance(triggers, dict)

@pytest.mark.unit
def test_constants_emotion_functions():
    """Test the emotion-related utility functions from constants"""
    assert get_emotion_display_name(EmotionType.JOY, use_english=False) == 'Alegría'
    assert get_emotion_display_name(EmotionType.JOY, use_english=True) == 'Joy'
    assert get_emotion_category(EmotionType.JOY) == EmotionCategory.POSITIVE
    assert get_emotion_category(EmotionType.SADNESS) == EmotionCategory.NEGATIVE
    assert get_emotion_color(EmotionType.JOY) == '#FFD700'
    assert validate_emotion_intensity(5) is True
    assert validate_emotion_intensity(EMOTION_INTENSITY_MAX + 1) is False