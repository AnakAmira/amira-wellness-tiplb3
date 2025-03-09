"""
tool.py

Pydantic schema definitions for the tool library in the Amira Wellness application.
Provides data validation, serialization, and deserialization for tools, tool favorites,
tool usage, and related data structures used in API requests and responses.
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
from ..constants.tools import (
    ToolCategory,
    ToolContentType,
    ToolDifficulty,
    TOOL_DURATION_MIN,
    TOOL_DURATION_MAX,
    TOOL_DURATION_DEFAULT,
    get_tool_category_display_name
)
from ..constants.emotions import EmotionType
from .emotion import EmotionalState

# Type variable for generic types
T = TypeVar('T')


class ToolBase(BaseSchema):
    """
    Base schema for tool data with common fields.
    """
    name: str = Field(
        description="Name of the tool",
        min_length=1,
        max_length=100
    )
    description: str = Field(
        description="Description of the tool",
        min_length=1,
        max_length=1000
    )
    category: ToolCategory = Field(
        description="Category of the tool"
    )
    content_type: ToolContentType = Field(
        description="Type of content for the tool"
    )
    content: Dict[str, Any] = Field(
        description="Content of the tool, structure depends on content_type"
    )
    estimated_duration: int = Field(
        description=f"Estimated duration in minutes (between {TOOL_DURATION_MIN} and {TOOL_DURATION_MAX})",
        ge=TOOL_DURATION_MIN,
        le=TOOL_DURATION_MAX,
        default=TOOL_DURATION_DEFAULT
    )
    difficulty: ToolDifficulty = Field(
        description="Difficulty level of the tool",
        default=ToolDifficulty.BEGINNER
    )
    target_emotions: List[EmotionType] = Field(
        description="Emotions that this tool targets or helps with",
        default_factory=list
    )
    icon_url: Optional[str] = Field(
        default=None,
        description="URL to the tool's icon image"
    )
    is_active: bool = Field(
        default=True,
        description="Whether the tool is currently active and available"
    )
    is_premium: bool = Field(
        default=False,
        description="Whether the tool is a premium feature requiring subscription"
    )

    @field_validator('estimated_duration')
    @classmethod
    def validate_duration(cls, v: int) -> int:
        """
        Validates that duration is within allowed range.
        
        Args:
            v: The duration value to validate
            
        Returns:
            Validated duration value
        """
        if v < TOOL_DURATION_MIN:
            return TOOL_DURATION_MIN
        if v > TOOL_DURATION_MAX:
            return TOOL_DURATION_MAX
        return v

    @model_validator(mode='before')
    @classmethod
    def validate_content(cls, values: dict) -> dict:
        """
        Validates that content is appropriate for the content_type.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Validated values
            
        Raises:
            ValueError: If content is not valid for the content_type
        """
        content = values.get('content')
        content_type = values.get('content_type')
        
        if content is not None and content_type is not None:
            # Validate content structure based on content_type
            if content_type == ToolContentType.TEXT:
                if not content.get('text'):
                    raise ValueError("TEXT content must include 'text' field")
            
            elif content_type == ToolContentType.AUDIO:
                if not content.get('audio_url'):
                    raise ValueError("AUDIO content must include 'audio_url' field")
            
            elif content_type == ToolContentType.VIDEO:
                if not content.get('video_url'):
                    raise ValueError("VIDEO content must include 'video_url' field")
            
            elif content_type == ToolContentType.INTERACTIVE:
                if not content.get('steps') or not isinstance(content.get('steps'), list):
                    raise ValueError("INTERACTIVE content must include 'steps' field as a list")
            
            elif content_type == ToolContentType.GUIDED_EXERCISE:
                if not content.get('steps') or not isinstance(content.get('steps'), list):
                    raise ValueError("GUIDED_EXERCISE content must include 'steps' field as a list")
                if not content.get('duration'):
                    raise ValueError("GUIDED_EXERCISE content must include 'duration' field")
        
        return values


class ToolCreate(ToolBase):
    """
    Schema for creating a new tool.
    """
    pass


class ToolUpdate(BaseSchema):
    """
    Schema for updating an existing tool.
    """
    name: Optional[str] = Field(
        default=None,
        description="Name of the tool",
        min_length=1,
        max_length=100
    )
    description: Optional[str] = Field(
        default=None,
        description="Description of the tool",
        min_length=1,
        max_length=1000
    )
    category: Optional[ToolCategory] = Field(
        default=None,
        description="Category of the tool"
    )
    content_type: Optional[ToolContentType] = Field(
        default=None,
        description="Type of content for the tool"
    )
    content: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Content of the tool, structure depends on content_type"
    )
    estimated_duration: Optional[int] = Field(
        default=None,
        description=f"Estimated duration in minutes (between {TOOL_DURATION_MIN} and {TOOL_DURATION_MAX})",
        ge=TOOL_DURATION_MIN,
        le=TOOL_DURATION_MAX
    )
    difficulty: Optional[ToolDifficulty] = Field(
        default=None,
        description="Difficulty level of the tool"
    )
    target_emotions: Optional[List[EmotionType]] = Field(
        default=None,
        description="Emotions that this tool targets or helps with"
    )
    icon_url: Optional[str] = Field(
        default=None,
        description="URL to the tool's icon image"
    )
    is_active: Optional[bool] = Field(
        default=None,
        description="Whether the tool is currently active and available"
    )
    is_premium: Optional[bool] = Field(
        default=None,
        description="Whether the tool is a premium feature requiring subscription"
    )


class Tool(ToolBase, IDSchema, TimestampSchema):
    """
    Schema for tool data with ID and timestamps.
    """
    category_metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata about the category (display name, color, etc.)"
    )
    content_type_metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata about the content type (display name, icon, etc.)"
    )
    is_favorited: bool = Field(
        default=False,
        description="Whether the tool is favorited by the current user (contextual)"
    )
    usage_count: int = Field(
        default=0,
        description="Number of times the tool has been used by the current user (contextual)"
    )

    @model_validator(mode='before')
    @classmethod
    def populate_metadata(cls, values: dict) -> dict:
        """
        Populates category and content type metadata.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Values with populated metadata
        """
        category = values.get('category')
        if category and 'category_metadata' not in values:
            try:
                display_name = get_tool_category_display_name(category)
                values['category_metadata'] = {
                    'display_name': display_name,
                    'description': 'Category description',  # Would be replaced with actual description
                    'color': '#000000',  # Would be replaced with actual color
                }
            except ValueError:
                # If invalid category, just leave metadata empty
                pass
        
        content_type = values.get('content_type')
        if content_type and 'content_type_metadata' not in values:
            values['content_type_metadata'] = {
                'display_name': str(content_type.value),  # Would be replaced with localized display name
                'icon': 'default.png',  # Would be replaced with actual icon
            }
        
        # Set default values for contextual fields if not provided
        if 'is_favorited' not in values:
            values['is_favorited'] = False
        
        if 'usage_count' not in values:
            values['usage_count'] = 0
        
        return values


class ToolSummary(BaseSchema):
    """
    Schema for summarized tool data.
    """
    id: uuid.UUID = Field(
        description="Unique identifier of the tool"
    )
    name: str = Field(
        description="Name of the tool"
    )
    description: str = Field(
        description="Description of the tool"
    )
    category: ToolCategory = Field(
        description="Category of the tool"
    )
    category_display_name: str = Field(
        description="Localized display name for the category"
    )
    category_color: str = Field(
        description="Color code associated with the category"
    )
    content_type: ToolContentType = Field(
        description="Type of content for the tool"
    )
    estimated_duration: int = Field(
        description="Estimated duration in minutes"
    )
    difficulty: ToolDifficulty = Field(
        description="Difficulty level of the tool"
    )
    icon_url: Optional[str] = Field(
        default=None,
        description="URL to the tool's icon image"
    )
    is_premium: bool = Field(
        description="Whether the tool is a premium feature requiring subscription"
    )
    is_favorited: bool = Field(
        description="Whether the tool is favorited by the current user"
    )


class ToolFilter(PaginationParams):
    """
    Schema for filtering tools.
    """
    categories: Optional[List[ToolCategory]] = Field(
        default=None,
        description="Filter by specific categories"
    )
    content_types: Optional[List[ToolContentType]] = Field(
        default=None,
        description="Filter by specific content types"
    )
    difficulties: Optional[List[ToolDifficulty]] = Field(
        default=None,
        description="Filter by specific difficulty levels"
    )
    target_emotions: Optional[List[EmotionType]] = Field(
        default=None,
        description="Filter by emotions that tools target"
    )
    max_duration: Optional[int] = Field(
        default=None,
        description="Maximum duration in minutes",
        gt=0
    )
    is_active: Optional[bool] = Field(
        default=None,
        description="Filter by active status"
    )
    is_premium: Optional[bool] = Field(
        default=None,
        description="Filter by premium status"
    )
    favorites_only: Optional[bool] = Field(
        default=None,
        description="Only include favorited tools"
    )
    search_query: Optional[str] = Field(
        default=None,
        description="Search query for tool name and description"
    )


class ToolList(PaginatedResponse[T], Generic[T]):
    """
    Schema for paginated list of tools.
    """
    pass


class ToolFavoriteCreate(BaseSchema):
    """
    Schema for creating a tool favorite.
    """
    tool_id: uuid.UUID = Field(
        description="ID of the tool to favorite"
    )
    user_id: Optional[uuid.UUID] = Field(
        default=None,
        description="User ID (can be automatically assigned from authentication context)"
    )


class ToolFavorite(IDSchema, TimestampSchema):
    """
    Schema for tool favorite data with ID and timestamps.
    """
    user_id: uuid.UUID = Field(
        description="ID of the user who favorited the tool"
    )
    tool_id: uuid.UUID = Field(
        description="ID of the favorited tool"
    )
    tool: Optional[Tool] = Field(
        default=None,
        description="The favorited tool data (included when requested)"
    )


class ToolUsageCreate(BaseSchema):
    """
    Schema for creating a tool usage record.
    """
    tool_id: uuid.UUID = Field(
        description="ID of the tool used"
    )
    user_id: Optional[uuid.UUID] = Field(
        default=None,
        description="User ID (can be automatically assigned from authentication context)"
    )
    duration_seconds: int = Field(
        description="Duration of tool usage in seconds",
        ge=0
    )
    completion_status: str = Field(
        description="Status of completion (COMPLETED, PARTIAL, ABANDONED)"
    )
    pre_checkin_id: Optional[uuid.UUID] = Field(
        default=None,
        description="ID of the pre-usage emotional check-in, if applicable"
    )
    post_checkin_id: Optional[uuid.UUID] = Field(
        default=None,
        description="ID of the post-usage emotional check-in, if applicable"
    )

    @field_validator('completion_status')
    @classmethod
    def validate_completion_status(cls, v: str) -> str:
        """
        Validates that completion_status is one of the allowed values.
        
        Args:
            v: Completion status to validate
            
        Returns:
            Validated completion status
            
        Raises:
            ValueError: If completion_status is not valid
        """
        allowed_statuses = ['COMPLETED', 'PARTIAL', 'ABANDONED']
        if v not in allowed_statuses:
            raise ValueError(f"completion_status must be one of: {', '.join(allowed_statuses)}")
        return v


class ToolUsage(IDSchema, TimestampSchema):
    """
    Schema for tool usage data with ID and timestamps.
    """
    user_id: uuid.UUID = Field(
        description="ID of the user who used the tool"
    )
    tool_id: uuid.UUID = Field(
        description="ID of the used tool"
    )
    duration_seconds: int = Field(
        description="Duration of tool usage in seconds",
        ge=0
    )
    completed_at: datetime = Field(
        description="When the tool usage was completed"
    )
    completion_status: str = Field(
        description="Status of completion (COMPLETED, PARTIAL, ABANDONED)"
    )
    pre_checkin_id: Optional[uuid.UUID] = Field(
        default=None,
        description="ID of the pre-usage emotional check-in, if applicable"
    )
    post_checkin_id: Optional[uuid.UUID] = Field(
        default=None,
        description="ID of the post-usage emotional check-in, if applicable"
    )
    tool: Optional[Tool] = Field(
        default=None,
        description="The used tool data (included when requested)"
    )
    pre_checkin: Optional[EmotionalState] = Field(
        default=None,
        description="Pre-usage emotional state (included when requested)"
    )
    post_checkin: Optional[EmotionalState] = Field(
        default=None,
        description="Post-usage emotional state (included when requested)"
    )

    def get_emotional_shift(self) -> Optional[Dict[str, Any]]:
        """
        Calculates the emotional shift from pre to post check-in if available.
        
        Returns:
            Dictionary with emotional shift data or None if not available
        """
        if not self.pre_checkin or not self.post_checkin:
            return None
        
        # Calculate the difference in emotion intensity
        intensity_change = self.post_checkin.intensity - self.pre_checkin.intensity
        
        # Determine if the emotion type changed
        emotion_type_changed = self.pre_checkin.emotion_type != self.post_checkin.emotion_type
        
        # Determine if the shift is positive, negative, or neutral
        shift_direction = "neutral"
        
        # Simple logic: if emotion changed from negative to positive or intensity improved for positive emotion
        # or intensity decreased for negative emotion, consider it a positive shift
        # This logic would be more sophisticated in the real implementation
        if emotion_type_changed:
            shift_direction = "changed"
        elif intensity_change > 0:
            shift_direction = "increased"
        elif intensity_change < 0:
            shift_direction = "decreased"
        
        return {
            "pre_emotion": self.pre_checkin.emotion_type.value,
            "pre_intensity": self.pre_checkin.intensity,
            "post_emotion": self.post_checkin.emotion_type.value,
            "post_intensity": self.post_checkin.intensity,
            "intensity_change": intensity_change,
            "emotion_type_changed": emotion_type_changed,
            "shift_direction": shift_direction
        }


class ToolUsageFilter(DateRangeParams):
    """
    Schema for filtering tool usage records.
    """
    tool_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Filter by specific tool"
    )
    categories: Optional[List[ToolCategory]] = Field(
        default=None,
        description="Filter by tool categories"
    )
    completion_statuses: Optional[List[str]] = Field(
        default=None,
        description="Filter by completion statuses"
    )
    min_duration: Optional[int] = Field(
        default=None,
        description="Minimum duration in seconds",
        ge=0
    )
    max_duration: Optional[int] = Field(
        default=None,
        description="Maximum duration in seconds",
        ge=0
    )


class ToolUsageList(PaginatedResponse[ToolUsage]):
    """
    Schema for paginated list of tool usage records.
    """
    pass


class ToolUsageStatistics(BaseSchema):
    """
    Schema for tool usage statistics.
    """
    total_usages: int = Field(
        description="Total number of tool usages"
    )
    total_duration_seconds: int = Field(
        description="Total duration of tool usage in seconds"
    )
    usages_by_category: Dict[str, int] = Field(
        description="Number of usages by tool category"
    )
    usages_by_completion_status: Dict[str, int] = Field(
        description="Number of usages by completion status"
    )
    most_used_tools: List[Dict[str, Any]] = Field(
        description="List of most used tools with usage counts"
    )
    usage_by_time_of_day: Dict[str, Any] = Field(
        description="Tool usage distribution by time of day"
    )
    usage_by_day_of_week: Dict[str, Any] = Field(
        description="Tool usage distribution by day of week"
    )


class ToolRecommendationRequest(BaseSchema):
    """
    Schema for requesting tool recommendations.
    """
    emotion_type: EmotionType = Field(
        description="Type of emotion for which to recommend tools"
    )
    intensity: int = Field(
        description="Intensity of the emotion (1-10)",
        ge=1,
        le=10
    )
    limit: Optional[int] = Field(
        default=5,
        description="Maximum number of recommendations to return",
        ge=1,
        le=20
    )
    include_premium: Optional[bool] = Field(
        default=False,
        description="Whether to include premium tools in recommendations"
    )


class ToolRecommendation(BaseSchema):
    """
    Schema for tool recommendation.
    """
    tool_id: uuid.UUID = Field(
        description="ID of the recommended tool"
    )
    name: str = Field(
        description="Name of the tool"
    )
    description: str = Field(
        description="Description of the tool"
    )
    category: ToolCategory = Field(
        description="Category of the tool"
    )
    category_display_name: str = Field(
        description="Localized display name for the category"
    )
    content_type: ToolContentType = Field(
        description="Type of content for the tool"
    )
    estimated_duration: int = Field(
        description="Estimated duration in minutes"
    )
    relevance_score: float = Field(
        description="Relevance score for the recommendation (0.0-1.0)",
        ge=0.0,
        le=1.0
    )
    reason_for_recommendation: str = Field(
        description="Explanation for why this tool was recommended"
    )
    is_premium: bool = Field(
        description="Whether the tool is a premium feature requiring subscription"
    )
    is_favorited: bool = Field(
        description="Whether the tool is favorited by the current user"
    )


class ToolRecommendationResponse(BaseSchema):
    """
    Schema for tool recommendation response.
    """
    emotion_type: EmotionType = Field(
        description="Emotion type for which tools were recommended"
    )
    intensity: int = Field(
        description="Intensity level for which tools were recommended"
    )
    recommendations: List[ToolRecommendation] = Field(
        description="List of tool recommendations"
    )


class ToolCategoryStats(BaseSchema):
    """
    Schema for tool category statistics.
    """
    category: ToolCategory = Field(
        description="Tool category"
    )
    display_name: str = Field(
        description="Localized display name for the category"
    )
    color: str = Field(
        description="Color code associated with the category"
    )
    tool_count: int = Field(
        description="Number of tools in this category"
    )
    usage_count: int = Field(
        description="Number of tool usages for this category"
    )
    favorite_count: int = Field(
        description="Number of times tools in this category have been favorited"
    )


class ToolLibraryStats(BaseSchema):
    """
    Schema for overall tool library statistics.
    """
    total_tools: int = Field(
        description="Total number of tools in the library"
    )
    total_premium_tools: int = Field(
        description="Number of premium tools in the library"
    )
    total_favorites: int = Field(
        description="Total number of tool favorites across all users"
    )
    total_usages: int = Field(
        description="Total number of tool usages across all users"
    )
    categories: List[ToolCategoryStats] = Field(
        description="Statistics for each tool category"
    )
    most_popular_tools: List[Dict[str, Any]] = Field(
        description="List of most popular tools based on usage and favorites"
    )
    most_effective_tools: List[Dict[str, Any]] = Field(
        description="List of most effective tools based on emotional improvement"
    )