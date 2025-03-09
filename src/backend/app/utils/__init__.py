"""
Initialization module for the utilities package in the Amira Wellness application.
Exposes commonly used utility functions and classes from the various utility modules
to provide a clean, simplified import interface for the rest of the application.
"""

# Import validation functions and the ValidationError class from the validators module
from .validators import (
    ValidationError,
    validate_email,
    validate_password,
    validate_passwords_match,
    validate_uuid,
    validate_emotion_type,
    validate_emotion_intensity,
    validate_emotion_context,
    validate_tool_category,
    validate_tool_content_type,
    validate_audio_format,
    validate_audio_metadata,
    validate_date_range,
    validate_pagination_params,
)

# Import date and time utility functions from the date_helpers module
from .date_helpers import (
    get_current_datetime,
    get_current_date,
    format_date,
    format_datetime,
    parse_date,
    parse_datetime,
    parse_iso_datetime,
    to_iso_format,
    add_days,
    subtract_days,
    is_streak_active,
    is_streak_at_risk,
)

# Import audio processing functions and classes from the audio_processing module
from .audio_processing import (
    process_journal_audio,
    convert_audio_format,
    get_audio_metadata,
    AudioProcessor,
    AudioQualityAnalyzer,
    AudioProcessingError,
)

# Import storage-related functions and classes from the storage module
from .storage import (
    save_file_locally,
    load_file_locally,
    delete_file_locally,
    upload_to_s3,
    download_from_s3,
    delete_from_s3,
    generate_presigned_url,
    StorageError,
)

# Import logging-related functions and classes from the logging module
from .logging import (
    configure_logger,
    log_info,
    log_error,
    log_warning,
    log_debug,
    log_function_call,
    LogContext,
)

# Import pagination-related functions and classes from the pagination module
from .pagination import (
    paginate_query,
    paginate_sqlalchemy2_query,
    create_paginated_response,
    Paginator,
)

__all__ = [
    "ValidationError",
    "validate_email",
    "validate_password",
    "validate_passwords_match",
    "validate_uuid",
    "validate_emotion_type",
    "validate_emotion_intensity",
    "validate_emotion_context",
    "validate_tool_category",
    "validate_tool_content_type",
    "validate_audio_format",
    "validate_audio_metadata",
    "validate_date_range",
    "validate_pagination_params",
    "get_current_datetime",
    "get_current_date",
    "format_date",
    "format_datetime",
    "parse_date",
    "parse_datetime",
    "parse_iso_datetime",
    "to_iso_format",
    "add_days",
    "subtract_days",
    "is_streak_active",
    "is_streak_at_risk",
    "process_journal_audio",
    "convert_audio_format",
    "get_audio_metadata",
    "AudioProcessor",
    "AudioQualityAnalyzer",
    "AudioProcessingError",
    "save_file_locally",
    "load_file_locally",
    "delete_file_locally",
    "upload_to_s3",
    "download_from_s3",
    "delete_from_s3",
    "generate_presigned_url",
    "StorageError",
    "configure_logger",
    "log_info",
    "log_error",
    "log_warning",
    "log_debug",
    "log_function_call",
    "LogContext",
    "paginate_query",
    "paginate_sqlalchemy2_query",
    "create_paginated_response",
    "Paginator",
]