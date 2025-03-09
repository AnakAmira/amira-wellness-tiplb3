"""
validators.py

This module provides utility functions for data validation across the Amira Wellness application.
It includes validators for user data, emotional states, journal entries, tools, and other core entities
to ensure data integrity and consistency.
"""

import re
import uuid
import datetime
from typing import Dict, List, Tuple, Union, Any, Optional

from pydantic import ValidationError as PydanticValidationError  # pydantic v2.4+

from ..constants.emotions import (
    EmotionType,
    EmotionContext,
    EMOTION_INTENSITY_MIN,
    EMOTION_INTENSITY_MAX
)
from ..constants.tools import (
    ToolCategory,
    ToolContentType,
    ToolDifficulty,
    TOOL_DURATION_MIN,
    TOOL_DURATION_MAX
)
from ..constants.error_codes import ErrorCategory, ERROR_CODES


# Regular expression for email validation
EMAIL_REGEX = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

# Regular expression for password validation
# Requires at least 10 characters, with uppercase, lowercase, digit, and special character
PASSWORD_REGEX = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{10,}$'

# Supported audio formats
SUPPORTED_AUDIO_FORMATS = ['aac', 'mp3', 'm4a', 'wav']

# Audio file size and duration limits
MAX_AUDIO_FILE_SIZE = 50 * 1024 * 1024  # 50 MB
MIN_AUDIO_DURATION = 1  # 1 second
MAX_AUDIO_DURATION = 3600  # 60 minutes


class ValidationError(Exception):
    """
    Custom exception for validation errors in the Amira Wellness application.
    
    Attributes:
        field (str): The field that failed validation
        message (str): The error message
        error_code (str): The error code from ERROR_CODES
        category (ErrorCategory): The error category
    """
    
    def __init__(self, field: str, message: str, error_code: str):
        """
        Initialize a ValidationError exception.
        
        Args:
            field (str): The field that failed validation
            message (str): The error message
            error_code (str): The error code from ERROR_CODES
        """
        self.field = field
        self.message = message
        self.error_code = error_code
        self.category = ERROR_CODES[error_code]["category"] if error_code in ERROR_CODES else ErrorCategory.VALIDATION
        super().__init__(f"{field}: {message}")
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convert the validation error to a dictionary representation.
        
        Returns:
            Dict[str, Any]: Dictionary with field, message, error_code, and category
        """
        return {
            "field": self.field,
            "message": self.message,
            "error_code": self.error_code,
            "category": self.category.value if isinstance(self.category, ErrorCategory) else str(self.category)
        }


def validate_email(email: str) -> bool:
    """
    Validates that an email address is properly formatted.
    
    Args:
        email (str): The email address to validate
        
    Returns:
        bool: True if email is valid, False otherwise
    """
    if not email:
        return False
    
    return bool(re.match(EMAIL_REGEX, email))


def validate_password(password: str) -> bool:
    """
    Validates that a password meets security requirements.
    
    Password must:
    - Be at least 10 characters long
    - Contain at least one uppercase letter
    - Contain at least one lowercase letter
    - Contain at least one digit
    - Contain at least one special character (@$!%*?&)
    
    Args:
        password (str): The password to validate
        
    Returns:
        bool: True if password is valid, False otherwise
    """
    if not password:
        return False
    
    return bool(re.match(PASSWORD_REGEX, password))


def validate_passwords_match(password: str, password_confirm: str) -> bool:
    """
    Validates that two passwords match.
    
    Args:
        password (str): The first password
        password_confirm (str): The second password to compare
        
    Returns:
        bool: True if passwords match, False otherwise
    """
    return password == password_confirm


def validate_uuid(uuid_str: str) -> bool:
    """
    Validates that a string is a valid UUID.
    
    Args:
        uuid_str (str): The string to validate as a UUID
        
    Returns:
        bool: True if string is a valid UUID, False otherwise
    """
    try:
        uuid_obj = uuid.UUID(uuid_str)
        return str(uuid_obj) == uuid_str
    except (ValueError, AttributeError, TypeError):
        return False


def validate_emotion_type(emotion_type: str) -> bool:
    """
    Validates that an emotion type is valid.
    
    Args:
        emotion_type (str): The emotion type to validate
        
    Returns:
        bool: True if emotion type is valid, False otherwise
    """
    try:
        EmotionType(emotion_type)
        return True
    except (ValueError, TypeError):
        return False


def validate_emotion_intensity(intensity: int) -> bool:
    """
    Validates that an emotion intensity is within allowed range.
    
    Args:
        intensity (int): The intensity value to validate
        
    Returns:
        bool: True if intensity is valid, False otherwise
    """
    try:
        return EMOTION_INTENSITY_MIN <= int(intensity) <= EMOTION_INTENSITY_MAX
    except (ValueError, TypeError):
        return False


def validate_emotion_context(context: str) -> bool:
    """
    Validates that an emotion context is valid.
    
    Args:
        context (str): The context to validate
        
    Returns:
        bool: True if context is valid, False otherwise
    """
    try:
        EmotionContext(context)
        return True
    except (ValueError, TypeError):
        return False


def validate_tool_category(category: str) -> bool:
    """
    Validates that a tool category is valid.
    
    Args:
        category (str): The category to validate
        
    Returns:
        bool: True if category is valid, False otherwise
    """
    try:
        ToolCategory(category)
        return True
    except (ValueError, TypeError):
        return False


def validate_tool_content_type(content_type: str) -> bool:
    """
    Validates that a tool content type is valid.
    
    Args:
        content_type (str): The content type to validate
        
    Returns:
        bool: True if content type is valid, False otherwise
    """
    try:
        ToolContentType(content_type)
        return True
    except (ValueError, TypeError):
        return False


def validate_tool_difficulty(difficulty: str) -> bool:
    """
    Validates that a tool difficulty level is valid.
    
    Args:
        difficulty (str): The difficulty level to validate
        
    Returns:
        bool: True if difficulty is valid, False otherwise
    """
    try:
        ToolDifficulty(difficulty)
        return True
    except (ValueError, TypeError):
        return False


def validate_tool_duration(duration: int) -> bool:
    """
    Validates that a tool duration is within allowed range.
    
    Args:
        duration (int): The duration value to validate in minutes
        
    Returns:
        bool: True if duration is valid, False otherwise
    """
    try:
        return TOOL_DURATION_MIN <= int(duration) <= TOOL_DURATION_MAX
    except (ValueError, TypeError):
        return False


def validate_tool_content(content: Dict[str, Any], content_type: Union[str, ToolContentType]) -> bool:
    """
    Validates that tool content structure matches the content type.
    
    Args:
        content (Dict[str, Any]): The content to validate
        content_type (Union[str, ToolContentType]): The expected content type
        
    Returns:
        bool: True if content structure is valid, False otherwise
    """
    if not isinstance(content, dict):
        return False
    
    # Convert string content_type to enum if necessary
    if isinstance(content_type, str):
        try:
            content_type = ToolContentType(content_type)
        except (ValueError, TypeError):
            return False
    elif not isinstance(content_type, ToolContentType):
        return False
    
    # Common required fields for all content types
    if 'title' not in content or not content['title'] or 'instructions' not in content or not content['instructions']:
        return False
    
    # Specific validation based on content type
    if content_type == ToolContentType.TEXT:
        # TEXT only requires the common fields
        return True
        
    elif content_type == ToolContentType.AUDIO:
        # AUDIO requires audio_url
        return 'audio_url' in content and bool(content['audio_url'])
        
    elif content_type == ToolContentType.VIDEO:
        # VIDEO requires video_url
        return 'video_url' in content and bool(content['video_url'])
        
    elif content_type == ToolContentType.INTERACTIVE or content_type == ToolContentType.GUIDED_EXERCISE:
        # INTERACTIVE and GUIDED_EXERCISE require steps
        if 'steps' not in content or not isinstance(content['steps'], list) or not content['steps']:
            return False
            
        # Validate each step
        for step in content['steps']:
            if not isinstance(step, dict):
                return False
                
            # Each step must have order, title, and description
            if ('order' not in step or not isinstance(step['order'], int) or
                'title' not in step or not step['title'] or 
                'description' not in step or not step['description']):
                return False
                
        return True
    
    # If we get here, the content type is not recognized
    return False


def validate_audio_format(file_format: str) -> bool:
    """
    Validates that an audio file format is supported.
    
    Args:
        file_format (str): The file format to validate (e.g., 'mp3', 'aac')
        
    Returns:
        bool: True if format is supported, False otherwise
    """
    if not isinstance(file_format, str):
        return False
    
    return file_format.lower() in SUPPORTED_AUDIO_FORMATS


def validate_audio_file_size(file_size_bytes: int) -> bool:
    """
    Validates that an audio file size is within allowed limits.
    
    Args:
        file_size_bytes (int): The file size in bytes to validate
        
    Returns:
        bool: True if file size is valid, False otherwise
    """
    try:
        size = int(file_size_bytes)
        return 0 < size <= MAX_AUDIO_FILE_SIZE
    except (ValueError, TypeError):
        return False


def validate_audio_duration(duration_seconds: int) -> bool:
    """
    Validates that an audio duration is within allowed limits.
    
    Args:
        duration_seconds (int): The duration in seconds to validate
        
    Returns:
        bool: True if duration is valid, False otherwise
    """
    try:
        duration = int(duration_seconds)
        return MIN_AUDIO_DURATION <= duration <= MAX_AUDIO_DURATION
    except (ValueError, TypeError):
        return False


def validate_audio_metadata(metadata: Dict[str, Any]) -> Tuple[bool, str]:
    """
    Validates complete audio metadata for a journal entry.
    
    Args:
        metadata (Dict[str, Any]): The metadata to validate
        
    Returns:
        Tuple[bool, str]: (is_valid, error_message)
    """
    if not isinstance(metadata, dict):
        return False, "Metadata must be a dictionary"
    
    # Check required fields
    required_fields = ['file_format', 'file_size_bytes', 'sample_rate', 'bit_rate', 'channels']
    for field in required_fields:
        if field not in metadata:
            return False, f"Missing required field: {field}"
    
    # Validate file format
    if not validate_audio_format(metadata['file_format']):
        return False, f"Unsupported audio format: {metadata['file_format']}"
    
    # Validate file size
    if not validate_audio_file_size(metadata['file_size_bytes']):
        return False, f"Invalid file size: {metadata['file_size_bytes']} bytes"
    
    # Validate other fields
    try:
        sample_rate = int(metadata['sample_rate'])
        if sample_rate <= 0:
            return False, f"Invalid sample rate: {sample_rate}"
            
        bit_rate = int(metadata['bit_rate'])
        if bit_rate <= 0:
            return False, f"Invalid bit rate: {bit_rate}"
            
        channels = int(metadata['channels'])
        if channels not in [1, 2]:  # Only mono (1) or stereo (2) are supported
            return False, f"Invalid channels: {channels}"
    except (ValueError, TypeError):
        return False, "Invalid numeric value in metadata"
    
    # If we get here, the metadata is valid
    return True, ""


def validate_date_range(start_date: datetime.datetime, end_date: datetime.datetime) -> bool:
    """
    Validates that a date range is valid (start_date <= end_date).
    
    Args:
        start_date (datetime.datetime): The start date
        end_date (datetime.datetime): The end date
        
    Returns:
        bool: True if date range is valid, False otherwise
    """
    if not isinstance(start_date, datetime.datetime) or not isinstance(end_date, datetime.datetime):
        return False
    
    return start_date <= end_date


def validate_pagination_params(page: int, page_size: int) -> Tuple[int, int]:
    """
    Validates pagination parameters and returns sanitized values.
    
    Args:
        page (int): The page number (1-indexed)
        page_size (int): The page size
        
    Returns:
        Tuple[int, int]: (validated_page, validated_page_size)
    """
    try:
        validated_page = max(1, int(page))  # Ensure page is at least 1
    except (ValueError, TypeError):
        validated_page = 1
    
    try:
        validated_page_size = int(page_size)
        # Ensure page_size is between 1 and 100
        validated_page_size = max(1, min(100, validated_page_size))
    except (ValueError, TypeError):
        validated_page_size = 20  # Default page size
    
    return validated_page, validated_page_size


def create_validation_error(field: str, message: str, error_code: str) -> Dict[str, Any]:
    """
    Creates a standardized validation error response.
    
    Args:
        field (str): The field that failed validation
        message (str): The error message
        error_code (str): The error code from ERROR_CODES
        
    Returns:
        Dict[str, Any]: Validation error dictionary
    """
    error = {
        "field": field,
        "message": message,
        "error_code": error_code
    }
    
    # Add error category if the error code exists
    if error_code in ERROR_CODES:
        error["category"] = ERROR_CODES[error_code]["category"].value
    
    return error