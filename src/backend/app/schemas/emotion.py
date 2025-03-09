"""
emotion.py

Pydantic schemas for emotional data in the Amira Wellness application.
This module provides data validation, serialization, and deserialization for
emotional check-ins, trends, insights, and related data structures used in API
requests and responses.
"""

from typing import List, Optional, Dict, Any, TypeVar, Generic
from datetime import datetime
import uuid

from pydantic import BaseModel, Field, model_validator, field_validator, ConfigDict

from .common import (
    BaseSchema, 
    IDSchema, 
    TimestampSchema, 
    PaginationParams, 
    PaginatedResponse,
    DateRangeParams
)
from ..constants.emotions import (
    EmotionType, 
    EmotionCategory,
    EmotionContext,
    TrendDirection,
    PeriodType,
    InsightType,
    EMOTION_INTENSITY_MIN,
    EMOTION_INTENSITY_MAX,
    EMOTION_INTENSITY_DEFAULT,
    get_emotion_display_name
)

# Type variable for generic types
T = TypeVar('T')


class EmotionalStateBase(BaseSchema):
    """
    Base schema for emotional state data with common fields.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion experienced"
    )
    intensity: int = Field(
        description="Intensity of the emotion (1-10)",
        ge=EMOTION_INTENSITY_MIN,
        le=EMOTION_INTENSITY_MAX,
        default=EMOTION_INTENSITY_DEFAULT
    )
    context: EmotionContext = Field(
        description="Context in which the emotion was recorded",
        default=EmotionContext.STANDALONE
    )
    notes: Optional[str] = Field(
        default=None,
        description="Optional notes about the emotional state"
    )

    @field_validator('intensity')
    @classmethod
    def validate_intensity(cls, v: int) -> int:
        """
        Validates that intensity is within allowed range.
        
        Args:
            v: The intensity value to validate
            
        Returns:
            Validated intensity value
            
        Raises:
            ValueError: If intensity is outside allowed range
        """
        if v < EMOTION_INTENSITY_MIN or v > EMOTION_INTENSITY_MAX:
            raise ValueError(
                f"Intensity must be between {EMOTION_INTENSITY_MIN} and {EMOTION_INTENSITY_MAX}"
            )
        return v


class EmotionalStateCreate(EmotionalStateBase):
    """
    Schema for creating a new emotional check-in.
    """
    user_id: Optional[uuid.UUID] = Field(
        default=None,
        description="User ID (can be automatically assigned from authentication context)"
    )
    related_journal_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Related voice journal entry ID, if applicable"
    )
    related_tool_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Related tool ID, if applicable"
    )


class EmotionalState(EmotionalStateBase, IDSchema, TimestampSchema):
    """
    Schema for emotional state data with ID and timestamps.
    """
    user_id: uuid.UUID = Field(
        description="ID of the user who recorded this emotional state"
    )
    related_journal_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Related voice journal entry ID, if applicable"
    )
    related_tool_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Related tool ID, if applicable"
    )
    emotion_metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata about the emotion (display name, color, etc.)"
    )

    @model_validator(mode='before')
    @classmethod
    def populate_emotion_metadata(cls, values: dict) -> dict:
        """
        Populates emotion metadata from emotion_type.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Values with populated emotion_metadata
        """
        emotion_type = values.get('emotion_type')
        if emotion_type and 'emotion_metadata' not in values:
            try:
                display_name = get_emotion_display_name(emotion_type)
                values['emotion_metadata'] = {
                    'display_name': display_name,
                    'color': '#000000',  # Default color, would be replaced with actual color from EMOTION_METADATA
                    'category': 'NEUTRAL'  # Default category, would be replaced with actual category
                }
            except ValueError:
                # If invalid emotion type, just leave metadata empty
                pass
        return values


class EmotionalStateSummary(BaseSchema):
    """
    Schema for summarized emotional state data.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion"
    )
    display_name: str = Field(
        description="Localized display name for the emotion"
    )
    intensity: int = Field(
        description="Intensity of the emotion (1-10)"
    )
    category: EmotionCategory = Field(
        description="Category of the emotion (POSITIVE, NEGATIVE, NEUTRAL)"
    )
    color: str = Field(
        description="Color code associated with the emotion"
    )
    timestamp: datetime = Field(
        description="When the emotional state was recorded"
    )


class EmotionalStateFilter(DateRangeParams):
    """
    Schema for filtering emotional check-ins.
    """
    emotion_types: Optional[List[EmotionType]] = Field(
        default=None,
        description="Filter by specific emotion types"
    )
    contexts: Optional[List[EmotionContext]] = Field(
        default=None,
        description="Filter by specific contexts"
    )
    min_intensity: Optional[int] = Field(
        default=None,
        description="Minimum intensity value for filtering",
        ge=EMOTION_INTENSITY_MIN,
        le=EMOTION_INTENSITY_MAX
    )
    max_intensity: Optional[int] = Field(
        default=None,
        description="Maximum intensity value for filtering",
        ge=EMOTION_INTENSITY_MIN,
        le=EMOTION_INTENSITY_MAX
    )
    related_journal_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Filter by related journal entry"
    )
    related_tool_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Filter by related tool"
    )
    notes_contains: Optional[str] = Field(
        default=None,
        description="Filter by text contained in notes"
    )

    @model_validator(mode='before')
    @classmethod
    def validate_intensity_range(cls, values: dict) -> dict:
        """
        Validates that min_intensity is not greater than max_intensity.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Validated values
            
        Raises:
            ValueError: If min_intensity is greater than max_intensity
        """
        min_intensity = values.get('min_intensity')
        max_intensity = values.get('max_intensity')
        
        if min_intensity is not None and max_intensity is not None:
            if min_intensity > max_intensity:
                raise ValueError("min_intensity cannot be greater than max_intensity")
        
        return values


class EmotionalStateList(PaginatedResponse[T], Generic[T]):
    """
    Schema for paginated list of emotional states.
    """
    pass


class EmotionalShift(BaseSchema):
    """
    Schema for emotional shift between pre and post check-ins.
    """
    pre_state: EmotionalState = Field(
        description="Emotional state before activity (e.g., journaling)"
    )
    post_state: EmotionalState = Field(
        description="Emotional state after activity"
    )
    intensity_change: int = Field(
        description="Change in intensity (positive or negative)"
    )
    emotion_type_changed: bool = Field(
        description="Whether the emotion type changed"
    )
    shift_direction: str = Field(
        description="Direction of the emotional shift (positive, negative, neutral)"
    )
    insights: List[str] = Field(
        default_factory=list,
        description="Insights derived from the emotional shift"
    )

    @model_validator(mode='before')
    @classmethod
    def calculate_shift_metrics(cls, values: dict) -> dict:
        """
        Calculates shift metrics from pre and post states.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Values with calculated shift metrics
        """
        pre_state = values.get('pre_state')
        post_state = values.get('post_state')
        
        if pre_state and post_state:
            # Calculate intensity change
            intensity_change = post_state.intensity - pre_state.intensity
            values['intensity_change'] = intensity_change
            
            # Determine if emotion type changed
            emotion_type_changed = pre_state.emotion_type != post_state.emotion_type
            values['emotion_type_changed'] = emotion_type_changed
            
            # Determine shift direction
            # Extract categories and determine shift direction
            pre_category = pre_state.emotion_metadata.get('category', EmotionCategory.NEUTRAL.value)
            post_category = post_state.emotion_metadata.get('category', EmotionCategory.NEUTRAL.value)
            
            # Determine shift direction based on categories and intensity
            if pre_category == EmotionCategory.NEGATIVE.value and post_category == EmotionCategory.POSITIVE.value:
                shift_direction = 'positive'
            elif pre_category == EmotionCategory.POSITIVE.value and post_category == EmotionCategory.NEGATIVE.value:
                shift_direction = 'negative'
            elif pre_category == post_category:
                if pre_category == EmotionCategory.POSITIVE.value and intensity_change > 0:
                    shift_direction = 'positive'
                elif pre_category == EmotionCategory.NEGATIVE.value and intensity_change < 0:
                    shift_direction = 'positive'
                elif pre_category == EmotionCategory.POSITIVE.value and intensity_change < 0:
                    shift_direction = 'negative'
                elif pre_category == EmotionCategory.NEGATIVE.value and intensity_change > 0:
                    shift_direction = 'negative'
                else:
                    shift_direction = 'neutral'
            else:
                shift_direction = 'neutral'
            
            values['shift_direction'] = shift_direction
            
            # Generate insights based on the shift
            insights = []
            if emotion_type_changed:
                pre_display = pre_state.emotion_metadata.get('display_name', str(pre_state.emotion_type.value))
                post_display = post_state.emotion_metadata.get('display_name', str(post_state.emotion_type.value))
                insights.append(f"Your emotion changed from {pre_display} to {post_display}")
            
            if abs(intensity_change) >= 3:
                if intensity_change > 0:
                    insights.append(f"The intensity of your emotion increased significantly by {intensity_change} points")
                else:
                    insights.append(f"The intensity of your emotion decreased significantly by {abs(intensity_change)} points")
            
            if shift_direction == 'positive':
                insights.append("Your emotional state has shifted in a positive direction")
            elif shift_direction == 'negative':
                insights.append("Your emotional state has shifted in a negative direction")
            
            values['insights'] = insights
        
        return values


class EmotionalTrendRequest(DateRangeParams):
    """
    Schema for requesting emotional trend analysis.
    """
    start_date: datetime = Field(
        description="Start date for trend analysis"
    )
    end_date: datetime = Field(
        description="End date for trend analysis"
    )
    period_type: PeriodType = Field(
        description="Time period aggregation type (DAY, WEEK, MONTH)"
    )
    emotion_types: Optional[List[EmotionType]] = Field(
        default=None,
        description="Specific emotion types to analyze (all if not specified)"
    )
    include_insights: Optional[bool] = Field(
        default=False,
        description="Whether to include generated insights in the response"
    )


class EmotionalTrendPoint(BaseSchema):
    """
    Schema for a single point in an emotional trend.
    """
    period_value: str = Field(
        description="String representation of the period (e.g., '2023-01-01' for daily)"
    )
    emotion_type: EmotionType = Field(
        description="Type of emotion"
    )
    average_intensity: float = Field(
        description="Average intensity during the period"
    )
    occurrence_count: int = Field(
        description="Number of occurrences during the period"
    )
    min_intensity: int = Field(
        description="Minimum intensity during the period"
    )
    max_intensity: int = Field(
        description="Maximum intensity during the period"
    )


class EmotionalTrend(BaseSchema):
    """
    Schema for emotional trend data for a specific emotion.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion"
    )
    display_name: str = Field(
        description="Localized display name for the emotion"
    )
    color: str = Field(
        description="Color code associated with the emotion"
    )
    data_points: List[EmotionalTrendPoint] = Field(
        description="Data points for the trend"
    )
    trend_direction: Optional[TrendDirection] = Field(
        default=None,
        description="Direction of the trend (INCREASING, DECREASING, STABLE, FLUCTUATING)"
    )
    average_intensity: float = Field(
        description="Average intensity across all data points"
    )


class EmotionalTrendResponse(BaseSchema):
    """
    Schema for emotional trend analysis response.
    """
    start_date: datetime = Field(
        description="Start date of the analysis period"
    )
    end_date: datetime = Field(
        description="End date of the analysis period"
    )
    period_type: PeriodType = Field(
        description="Time period aggregation type used"
    )
    trends: List[EmotionalTrend] = Field(
        description="Trend data for each emotion type"
    )
    insights: Optional[List['EmotionalInsight']] = Field(
        default=None,
        description="Generated insights from the trend analysis"
    )


class EmotionalInsight(BaseSchema):
    """
    Schema for insights generated from emotional data.
    """
    type: InsightType = Field(
        description="Type of insight"
    )
    title: str = Field(
        description="Concise title of the insight"
    )
    description: str = Field(
        description="Detailed description of the insight"
    )
    related_emotions: List[EmotionType] = Field(
        description="Emotion types related to this insight"
    )
    confidence: float = Field(
        description="Confidence level of the insight (0.0-1.0)",
        ge=0.0,
        le=1.0
    )
    recommended_actions: List[str] = Field(
        description="Recommended actions based on the insight"
    )


class EmotionalPatternDetection(DateRangeParams):
    """
    Schema for emotional pattern detection request.
    """
    start_date: datetime = Field(
        description="Start date for pattern detection"
    )
    end_date: datetime = Field(
        description="End date for pattern detection"
    )
    pattern_type: str = Field(
        description="Type of pattern to detect (daily, weekly, situational)"
    )
    min_occurrences: Optional[int] = Field(
        default=3,
        description="Minimum number of occurrences required to identify a pattern",
        ge=2
    )

    @field_validator('pattern_type')
    @classmethod
    def validate_pattern_type(cls, v: str) -> str:
        """
        Validates that pattern_type is one of the allowed values.
        
        Args:
            v: Pattern type to validate
            
        Returns:
            Validated pattern type
            
        Raises:
            ValueError: If pattern_type is not valid
        """
        allowed_types = ['daily', 'weekly', 'situational']
        if v not in allowed_types:
            raise ValueError(f"pattern_type must be one of: {', '.join(allowed_types)}")
        return v


class EmotionalPattern(BaseSchema):
    """
    Schema for detected emotional pattern.
    """
    pattern_type: str = Field(
        description="Type of pattern (daily, weekly, situational)"
    )
    pattern_key: str = Field(
        description="Unique identifier for the pattern"
    )
    description: str = Field(
        description="Human-readable description of the pattern"
    )
    emotions: List[EmotionType] = Field(
        description="Emotion types involved in the pattern"
    )
    occurrence_count: int = Field(
        description="Number of times this pattern was observed"
    )
    confidence: float = Field(
        description="Confidence level of the pattern detection (0.0-1.0)",
        ge=0.0,
        le=1.0
    )
    metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Additional metadata about the pattern"
    )


class EmotionDistribution(BaseSchema):
    """
    Schema for emotion distribution data.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion"
    )
    display_name: str = Field(
        description="Localized display name for the emotion"
    )
    color: str = Field(
        description="Color code associated with the emotion"
    )
    category: EmotionCategory = Field(
        description="Category of the emotion"
    )
    count: int = Field(
        description="Number of occurrences of the emotion"
    )
    percentage: float = Field(
        description="Percentage of total emotional check-ins (0.0-100.0)",
        ge=0.0,
        le=100.0
    )
    average_intensity: float = Field(
        description="Average intensity of the emotion"
    )


class EmotionalHealthAnalysis(BaseSchema):
    """
    Schema for comprehensive emotional health analysis.
    """
    start_date: datetime = Field(
        description="Start date of the analysis period"
    )
    end_date: datetime = Field(
        description="End date of the analysis period"
    )
    emotion_distribution: List[EmotionDistribution] = Field(
        description="Distribution of emotions during the period"
    )
    emotional_balance: Dict[str, Any] = Field(
        description="Balance between positive, negative, and neutral emotions"
    )
    trends: List[EmotionalTrend] = Field(
        description="Trend data for emotions over time"
    )
    patterns: List[EmotionalPattern] = Field(
        description="Detected emotional patterns"
    )
    insights: List[EmotionalInsight] = Field(
        description="Generated insights from the analysis"
    )
    recommendations: List[Dict[str, Any]] = Field(
        description="Recommended tools and actions based on the analysis"
    )


class ToolRecommendationRequest(BaseSchema):
    """
    Schema for tool recommendation request based on emotional state.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion for which to recommend tools"
    )
    intensity: int = Field(
        description="Intensity of the emotion (1-10)",
        ge=EMOTION_INTENSITY_MIN,
        le=EMOTION_INTENSITY_MAX
    )
    limit: Optional[int] = Field(
        default=5,
        description="Maximum number of recommendations to return",
        ge=1,
        le=20
    )

    @field_validator('intensity')
    @classmethod
    def validate_intensity(cls, v: int) -> int:
        """
        Validates that intensity is within allowed range.
        
        Args:
            v: The intensity value to validate
            
        Returns:
            Validated intensity value
            
        Raises:
            ValueError: If intensity is outside allowed range
        """
        if v < EMOTION_INTENSITY_MIN or v > EMOTION_INTENSITY_MAX:
            raise ValueError(
                f"Intensity must be between {EMOTION_INTENSITY_MIN} and {EMOTION_INTENSITY_MAX}"
            )
        return v


class ToolRecommendation(BaseSchema):
    """
    Schema for tool recommendation based on emotional state.
    """
    tool_id: uuid.UUID = Field(
        description="ID of the recommended tool"
    )
    name: str = Field(
        description="Name of the tool"
    )
    description: str = Field(
        description="Brief description of the tool"
    )
    category: str = Field(
        description="Category of the tool"
    )
    relevance_score: float = Field(
        description="Relevance score for the recommendation (0.0-1.0)",
        ge=0.0,
        le=1.0
    )
    reason_for_recommendation: str = Field(
        description="Explanation for why this tool was recommended"
    )