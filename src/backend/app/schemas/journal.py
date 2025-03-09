"""
journal.py

Pydantic schema definitions for voice journal functionality in the Amira Wellness
application. Provides models for API request/response validation, data serialization,
and client-server communication related to voice journaling with emotional check-ins.
"""

from typing import List, Optional, Dict, Any, Union
from datetime import datetime
import uuid

from pydantic import BaseModel, Field, validator, model_validator, constr

from .common import (
    BaseSchema, 
    IDSchema, 
    TimestampSchema, 
    PaginatedResponse,
    DateRangeParams
)
from .emotion import (
    EmotionalStateBase,
    EmotionalState
)
from ..constants.emotions import (
    EmotionType,
    EmotionContext,
    TrendDirection
)


class JournalBase(BaseSchema):
    """Base schema for journal data with common fields."""
    title: str = Field(
        description="Title of the journal entry",
        min_length=1,
        max_length=100
    )
    duration_seconds: int = Field(
        description="Duration of the audio recording in seconds",
        gt=0
    )
    audio_format: str = Field(
        description="Format of the audio recording (e.g., AAC, MP3)",
        examples=["AAC", "MP3", "WAV"]
    )
    is_favorite: bool = Field(
        default=False,
        description="Whether the journal entry is marked as favorite"
    )
    
    @validator('duration_seconds')
    @classmethod
    def validate_duration(cls, v: int) -> int:
        """
        Validates that duration_seconds is positive.
        
        Args:
            v: The duration value to validate
            
        Returns:
            Validated duration value
            
        Raises:
            ValueError: If duration is not positive
        """
        if v <= 0:
            raise ValueError("Duration must be greater than 0 seconds")
        return v
    
    @validator('audio_format')
    @classmethod
    def validate_audio_format(cls, v: str) -> str:
        """
        Validates that audio_format is supported.
        
        Args:
            v: The audio format to validate
            
        Returns:
            Validated audio format
            
        Raises:
            ValueError: If format is not supported
        """
        supported_formats = ["AAC", "MP3", "WAV", "M4A", "OGG"]
        if v.upper() not in supported_formats:
            raise ValueError(f"Audio format must be one of: {', '.join(supported_formats)}")
        return v.upper()


class JournalCreate(JournalBase):
    """Schema for creating a new journal entry."""
    user_id: uuid.UUID = Field(
        description="ID of the user creating the journal entry"
    )
    file_size_bytes: int = Field(
        description="Size of the audio file in bytes",
        ge=0
    )
    pre_emotional_state: EmotionalStateBase = Field(
        description="Emotional state before recording"
    )
    post_emotional_state: EmotionalStateBase = Field(
        description="Emotional state after recording"
    )
    
    @validator('file_size_bytes')
    @classmethod
    def validate_file_size(cls, v: int) -> int:
        """
        Validates that file_size_bytes is non-negative.
        
        Args:
            v: The file size to validate
            
        Returns:
            Validated file size value
            
        Raises:
            ValueError: If file size is negative
        """
        if v < 0:
            raise ValueError("File size cannot be negative")
        return v
    
    @model_validator(mode='before')
    @classmethod
    def validate_emotional_states(cls, values: dict) -> dict:
        """
        Validates that both pre and post emotional states are provided.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Validated values
            
        Raises:
            ValueError: If either emotional state is missing
        """
        if not values.get('pre_emotional_state'):
            raise ValueError("Pre-recording emotional state is required")
        if not values.get('post_emotional_state'):
            raise ValueError("Post-recording emotional state is required")
        return values


class JournalUpdate(BaseSchema):
    """Schema for updating an existing journal entry."""
    title: Optional[str] = Field(
        default=None,
        description="Updated title for the journal entry",
        min_length=1,
        max_length=100
    )
    is_favorite: Optional[bool] = Field(
        default=None,
        description="Updated favorite status"
    )
    
    @model_validator(mode='before')
    @classmethod
    def validate_at_least_one_field(cls, values: dict) -> dict:
        """
        Validates that at least one field is provided for update.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Validated values
            
        Raises:
            ValueError: If no fields are provided for update
        """
        # Check if any field has a non-None value
        update_fields = [field for field, value in values.items() 
                         if value is not None and field != '__pydantic_fields_set__']
        if not update_fields:
            raise ValueError("At least one field must be provided for update")
        return values


class Journal(JournalBase, IDSchema, TimestampSchema):
    """Schema for journal entry data in responses."""
    user_id: uuid.UUID = Field(
        description="ID of the user who created the journal entry"
    )
    file_size_bytes: int = Field(
        description="Size of the audio file in bytes"
    )
    is_uploaded: bool = Field(
        description="Whether the audio file has been uploaded to storage"
    )
    pre_emotional_state: Optional[EmotionalState] = Field(
        default=None,
        description="Emotional state before recording"
    )
    post_emotional_state: Optional[EmotionalState] = Field(
        default=None,
        description="Emotional state after recording"
    )


class JournalSummary(BaseSchema):
    """Schema for journal summary in list responses."""
    id: uuid.UUID = Field(
        description="Unique identifier of the journal entry"
    )
    title: str = Field(
        description="Title of the journal entry"
    )
    duration_seconds: int = Field(
        description="Duration of the audio recording in seconds"
    )
    is_favorite: bool = Field(
        description="Whether the journal entry is marked as favorite"
    )
    pre_emotion_type: EmotionType = Field(
        description="Type of emotion before recording"
    )
    pre_emotion_intensity: int = Field(
        description="Intensity of emotion before recording"
    )
    post_emotion_type: EmotionType = Field(
        description="Type of emotion after recording"
    )
    post_emotion_intensity: int = Field(
        description="Intensity of emotion after recording"
    )
    created_at: datetime = Field(
        description="Creation timestamp of the journal entry"
    )


class JournalFilter(DateRangeParams):
    """Schema for filtering journal entries in list requests."""
    emotion_types: Optional[List[EmotionType]] = Field(
        default=None,
        description="Filter journals by emotional types"
    )
    favorite_only: Optional[bool] = Field(
        default=None,
        description="Filter to show only favorite journals"
    )


class JournalList(PaginatedResponse[JournalSummary]):
    """Schema for paginated list of journal entries."""
    pass


class EmotionalShift(BaseSchema):
    """Schema for emotional shift data between pre and post journaling."""
    pre_emotional_state: EmotionalState = Field(
        description="Emotional state before journaling"
    )
    post_emotional_state: EmotionalState = Field(
        description="Emotional state after journaling"
    )
    primary_shift: EmotionType = Field(
        description="Primary emotion that changed during journaling"
    )
    intensity_change: int = Field(
        description="Change in emotional intensity (can be positive or negative)"
    )
    trend_direction: TrendDirection = Field(
        description="Direction of the emotional trend"
    )
    insights: List[str] = Field(
        description="Generated insights about the emotional shift"
    )


class JournalExport(BaseSchema):
    """Schema for journal export options."""
    format: str = Field(
        description="Export format (e.g., ENCRYPTED, MP3, AAC)",
        examples=["ENCRYPTED", "MP3", "AAC"]
    )
    include_metadata: Optional[bool] = Field(
        default=True,
        description="Whether to include journal metadata in the export"
    )
    include_emotional_data: Optional[bool] = Field(
        default=True,
        description="Whether to include emotional data in the export"
    )
    
    @validator('format')
    @classmethod
    def validate_format(cls, v: str) -> str:
        """
        Validates that export format is supported.
        
        Args:
            v: The export format to validate
            
        Returns:
            Validated export format
            
        Raises:
            ValueError: If format is not supported
        """
        supported_formats = ["ENCRYPTED", "MP3", "AAC", "WAV", "M4A"]
        if v.upper() not in supported_formats:
            raise ValueError(f"Export format must be one of: {', '.join(supported_formats)}")
        return v.upper()


class JournalExportResult(BaseSchema):
    """Schema for journal export result."""
    download_url: str = Field(
        description="URL to download the exported journal"
    )
    format: str = Field(
        description="Format of the exported file"
    )
    file_size_bytes: int = Field(
        description="Size of the exported file in bytes"
    )
    expiration_seconds: int = Field(
        description="Time in seconds until the download URL expires"
    )


class JournalStats(BaseSchema):
    """Schema for journal usage statistics."""
    total_journals: int = Field(
        description="Total number of journal entries"
    )
    total_duration_seconds: int = Field(
        description="Total duration of all journal entries in seconds"
    )
    journals_by_emotion: Dict[str, int] = Field(
        description="Number of journal entries by emotion type"
    )
    journals_by_month: Dict[str, int] = Field(
        description="Number of journal entries by month"
    )
    significant_shifts: List[EmotionalShift] = Field(
        description="List of journal entries with significant emotional shifts"
    )


class JournalAudioMetadata(BaseSchema):
    """Schema for journal audio metadata."""
    encryption_iv: str = Field(
        description="Initialization vector for encryption"
    )
    encryption_tag: str = Field(
        description="Authentication tag for encryption"
    )
    audio_format: str = Field(
        description="Format of the audio recording"
    )
    file_size_bytes: int = Field(
        description="Size of the audio file in bytes"
    )
    duration_seconds: int = Field(
        description="Duration of the audio recording in seconds"
    )