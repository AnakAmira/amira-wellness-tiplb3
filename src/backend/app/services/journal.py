"""
Service layer implementation for voice journal functionality in the Amira Wellness application.
Provides high-level business logic for creating, retrieving, processing, and managing voice journal recordings with emotional check-ins, implementing end-to-end encryption and secure storage integration.
"""

import typing
from typing import Dict, List, Optional, Tuple, Union, Any, BinaryIO
import uuid
from datetime import datetime

from sqlalchemy.orm import Session  # sqlalchemy==2.0+

from ..core.logging import get_logger  # Internal import
from ..core.config import settings  # Internal import
from ..models.journal import Journal  # Internal import
from ..models.emotion import EmotionalCheckin  # Internal import
from ..crud import journal  # Internal import
from ..schemas.journal import JournalCreate, JournalUpdate, JournalFilter, JournalExport  # Internal import
from ..schemas.emotion import EmotionalStateCreate  # Internal import
from ..services.storage import get_journal_storage_service  # Internal import
from ..services.encryption import JournalEncryptionService  # Internal import
from ..services.emotion import get_emotional_shift, get_recommended_tools_for_emotion  # Internal import
from ..utils.audio_processing import process_journal_audio, convert_audio_format, AudioProcessor, AudioProcessingError  # Internal import
from ..core.exceptions import ResourceNotFoundException, PermissionDeniedException  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Global variables
_journal_encryption_service: Optional[JournalEncryptionService] = None
SUPPORTED_EXPORT_FORMATS: List[str] = ['aac', 'mp3', 'wav', 'm4a', 'encrypted']


def get_journal_encryption_service(use_kms: bool = None) -> JournalEncryptionService:
    """Factory function to get a singleton JournalEncryptionService instance

    Args:
        use_kms: Whether to use AWS KMS

    Returns:
        Singleton JournalEncryptionService instance
    """
    global _journal_encryption_service
    if _journal_encryption_service is None:
        _journal_encryption_service = JournalEncryptionService(use_kms=use_kms)
    return _journal_encryption_service


def create_journal(db: Session, journal_data: JournalCreate, audio_data: bytes, encryption_key: bytes) -> Dict:
    """Creates a new journal entry with audio data and emotional check-ins

    Args:
        db: Database session
        journal_data: Journal creation schema
        audio_data: Audio data bytes
        encryption_key: Encryption key

    Returns:
        Created journal entry with metadata
    """
    logger.info(f"Creating journal entry for user: {journal_data.user_id}")

    # Process the audio data using process_journal_audio
    processed_audio = process_journal_audio(audio_data=audio_data, source_format=journal_data.audio_format)

    # Get the journal encryption service
    journal_encryption_service = get_journal_encryption_service()

    # Encrypt the processed audio data using the encryption service
    encrypted_data = journal_encryption_service.encrypt_journal(
        audio_data=processed_audio['audio'],
        key=encryption_key,
        user_id=str(journal_data.user_id)
    )

    # Save the encrypted audio to storage using the journal storage service
    journal_storage_service = get_journal_storage_service()
    storage_result = journal_storage_service.save_journal(
        audio_data=encrypted_data['encrypted_data'],
        user_id=str(journal_data.user_id),
        journal_id=str(journal_data.id),
        metadata=encrypted_data
    )

    # Create the journal entry in the database with emotional check-ins
    db_obj = journal.create_with_emotions(db, journal_data)

    logger.info(f"Journal entry created with ID: {db_obj.id}")
    return db_obj.to_dict()


def get_journal(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Retrieves a journal entry by ID with emotional check-ins

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Journal entry with emotional check-ins
    """
    logger.info(f"Fetching journal entry with emotions for journal_id: {journal_id}, user_id: {user_id}")
    try:
        journal_entry = journal.get_with_emotions(db, journal_id, user_id)
        return journal_entry
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e


def get_journal_audio(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, encryption_key: bytes) -> bytes:
    """Retrieves the audio data for a journal entry

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID
        encryption_key: Encryption key

    Returns:
        Decrypted audio data
    """
    logger.info(f"Fetching audio for journal_id: {journal_id}, user_id: {user_id}")
    try:
        journal_entry = journal.get(db, journal_id)

        if not journal_entry:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        if journal_entry.user_id != user_id:
            raise PermissionDeniedException(message="You do not have permission to access this journal entry")

        journal_storage_service = get_journal_storage_service()
        audio_data = journal_storage_service.load_journal(user_id=str(user_id), journal_id=str(journal_id))['data']

        journal_encryption_service = get_journal_encryption_service()
        decrypted_audio = journal_encryption_service.decrypt_journal(
            encrypted_data=audio_data,
            key=encryption_key,
            iv=journal_entry.encryption_iv,
            tag=journal_entry.encryption_tag,
            user_id=str(user_id)
        )

        return decrypted_audio
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e
    except Exception as e:
        logger.error(f"Error fetching audio: {e}")
        raise e


def get_user_journals(db: Session, user_id: uuid.UUID, page: int = 1, page_size: int = 10) -> Tuple[List[Dict], int]:
    """Retrieves journal entries for a specific user with pagination

    Args:
        db: Database session
        user_id: User ID
        page: Page number
        page_size: Number of items per page

    Returns:
        List of journal entries and total count
    """
    journals, total = journal.get_by_user(db, user_id, page, page_size)
    return [j.to_dict() for j in journals], total


def get_filtered_journals(db: Session, user_id: uuid.UUID, filter_params: JournalFilter, page: int = 1, page_size: int = 10) -> Tuple[List[Dict], int]:
    """Retrieves journal entries with filtering options

    Args:
        db: Database session
        user_id: User ID
        filter_params: Filtering parameters
        page: Page number
        page_size: Number of items per page

    Returns:
        List of filtered journal entries and total count
    """
    journals, total = journal.get_filtered(db, user_id, filter_params, page, page_size)
    return [j.to_dict() for j in journals], total


def update_journal(db: Session, journal_id: uuid.UUID, journal_data: JournalUpdate, user_id: uuid.UUID) -> Dict:
    """Updates a journal entry with new data

    Args:
        db: Database session
        journal_id: Journal ID
        journal_data: Journal update schema
        user_id: User ID

    Returns:
        Updated journal entry
    """
    db_obj = journal.get(db, journal_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)
    if db_obj.user_id != user_id:
        raise PermissionDeniedException(message="You do not have permission to update this journal entry")
    updated_journal = journal.update(db, db_obj, journal_data)
    return updated_journal.to_dict()


def mark_journal_as_favorite(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Marks a journal entry as favorite

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Updated journal entry
    """
    db_obj = journal.get(db, journal_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)
    if db_obj.user_id != user_id:
        raise PermissionDeniedException(message="You do not have permission to mark this journal entry as favorite")
    updated_journal = journal.mark_as_favorite(db, journal_id, user_id)
    return updated_journal.to_dict()


def unmark_journal_as_favorite(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Removes a journal entry from favorites

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Updated journal entry
    """
    db_obj = journal.get(db, journal_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)
    if db_obj.user_id != user_id:
        raise PermissionDeniedException(message="You do not have permission to unmark this journal entry as favorite")
    updated_journal = journal.unmark_as_favorite(db, journal_id, user_id)
    return updated_journal.to_dict()


def delete_journal(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Soft deletes a journal entry

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Deleted journal entry
    """
    db_obj = journal.get(db, journal_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)
    if db_obj.user_id != user_id:
        raise PermissionDeniedException(message="You do not have permission to delete this journal entry")
    deleted_journal = journal.soft_delete(db, journal_id, user_id)
    return deleted_journal.to_dict()


def restore_journal(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Restores a soft-deleted journal entry

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Restored journal entry
    """
    db_obj = journal.get(db, journal_id)
    if not db_obj:
        raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)
    if db_obj.user_id != user_id:
        raise PermissionDeniedException(message="You do not have permission to restore this journal entry")
    restored_journal = journal.restore(db, journal_id, user_id)
    return restored_journal.to_dict()


def get_journal_emotional_shift(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Gets the emotional shift data for a journal entry

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Emotional shift data with insights
    """
    try:
        return journal.get_emotional_shift(db, journal_id, user_id)
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e


def get_journal_stats(db: Session, user_id: uuid.UUID, start_date: datetime = None, end_date: datetime = None) -> Dict:
    """Gets journal usage statistics for a user

    Args:
        db: Database session
        user_id: User ID
        start_date: Start date for the range
        end_date: End date for the range

    Returns:
        Journal usage statistics
    """
    logger.info(f"Getting journal stats for user_id: {user_id}, start_date: {start_date}, end_date: {end_date}")
    if start_date is None:
        start_date = datetime.min
    if end_date is None:
        end_date = datetime.utcnow()
    return journal.get_journal_stats(db, user_id, start_date, end_date)


def export_journal(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, export_options: JournalExport, encryption_key: bytes) -> Dict:
    """Exports a journal entry to a downloadable format

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID
        export_options: Journal export schema
        encryption_key: Encryption key

    Returns:
        Export result with download URL
    """
    try:
        return journal.export_journal(db, journal_id, user_id, export_options, encryption_key)
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e
    except Exception as e:
        logger.error(f"Error exporting journal: {e}")
        raise e


def get_journal_download_url(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, expiration_seconds: int = None) -> str:
    """Generates a download URL for a journal audio file

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID
        expiration_seconds: Expiration time for the URL in seconds

    Returns:
        Presigned download URL
    """
    try:
        return journal.get_download_url(db, journal_id, user_id, expiration_seconds)
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e
    except Exception as e:
        logger.error(f"Error getting download URL: {e}")
        raise e


def get_recommended_tools_for_journal(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, limit: int = 5) -> List[Dict]:
    """Gets tool recommendations based on journal emotional data

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID
        limit: Maximum number of tools to recommend

    Returns:
        Recommended tools with relevance scores
    """
    try:
        return journal.get_recommended_tools_for_journal(db, journal_id, user_id, limit)
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e
    except Exception as e:
        logger.error(f"Error getting recommended tools: {e}")
        raise e


def sync_journal_to_cloud(db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
    """Synchronizes a journal recording to cloud storage

    Args:
        db: Database session
        journal_id: Journal ID
        user_id: User ID

    Returns:
        Synchronization result
    """
    try:
        return journal.mark_as_uploaded(db, journal_id, user_id)
    except ResourceNotFoundException as e:
        raise e
    except PermissionDeniedException as e:
        raise e
    except Exception as e:
        logger.error(f"Error syncing journal to cloud: {e}")
        raise e


class JournalService:
    """Service class for managing voice journal functionality"""

    def __init__(self):
        """Initializes the JournalService with required dependencies"""
        self._encryption_service = get_journal_encryption_service()
        self._storage_service = get_journal_storage_service()
        self._audio_processor = AudioProcessor()
        logger.info("JournalService initialized")

    def create_journal(self, db: Session, journal_data: JournalCreate, audio_data: bytes, encryption_key: bytes) -> Dict:
        """Creates a new journal entry with audio data and emotional check-ins"""
        # Process the audio data using _audio_processor
        processed_audio = self._audio_processor.process(audio_data=audio_data, source_format=journal_data.audio_format)

        # Encrypt the processed audio data using _encryption_service
        encrypted_data = self._encryption_service.encrypt_journal(
            audio_data=processed_audio['audio'],
            key=encryption_key,
            user_id=str(journal_data.user_id)
        )

        # Save the encrypted audio to storage using _storage_service
        storage_result = self._storage_service.save_journal(
            audio_data=encrypted_data['encrypted_data'],
            user_id=str(journal_data.user_id),
            journal_id=str(journal_data.id),
            metadata=encrypted_data
        )

        # Create the journal entry in the database with emotional check-ins
        db_obj = journal.create_with_emotions(db, journal_data)

        return db_obj.to_dict()

    def get_journal_audio(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, encryption_key: bytes) -> bytes:
        """Retrieves the audio data for a journal entry"""
        # Get the journal entry to verify access and get encryption details
        journal_entry = journal.get(db, journal_id)

        if not journal_entry:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        if journal_entry.user_id != user_id:
            raise PermissionDeniedException(message="You do not have permission to access this journal entry")

        # Load the encrypted audio data from storage using _storage_service
        audio_data = self._storage_service.load_journal(user_id=str(user_id), journal_id=str(journal_id))['data']

        # Decrypt the audio data using _encryption_service and user's key
        decrypted_audio = self._encryption_service.decrypt_journal(
            encrypted_data=audio_data,
            key=encryption_key,
            iv=journal_entry.encryption_iv,
            tag=journal_entry.encryption_tag,
            user_id=str(user_id)
        )

        return decrypted_audio

    def export_journal(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, export_options: JournalExport, encryption_key: bytes) -> Dict:
        """Exports a journal entry to a downloadable format"""
        # Validate export format is supported
        if export_options.format not in SUPPORTED_EXPORT_FORMATS:
            raise ValueError(f"Export format must be one of: {', '.join(SUPPORTED_EXPORT_FORMATS)}")

        # Get the journal audio data using get_journal_audio
        audio_data = self.get_journal_audio(db, journal_id, user_id, encryption_key)

        # Prepare the journal for export using _encryption_service
        prepared_journal = self._encryption_service.prepare_journal_for_export(
            audio_data=audio_data,
            key=encryption_key,
            user_id=str(user_id),
            export_format=export_options.format,
            metadata={
                "journal_id": str(journal_id),
                "user_id": str(user_id),
                "include_metadata": export_options.include_metadata,
                "include_emotional_data": export_options.include_emotional_data
            }
        )

        # Save the exported file to storage using _storage_service
        storage_result = self._storage_service.save_file(
            file_data=prepared_journal['audio_data'],
            user_id=str(user_id),
            file_id=str(journal_id),
            metadata=prepared_journal
        )

        # Generate a download URL with expiration
        download_url = self._storage_service.get_download_url(user_id=str(user_id), file_id=str(journal_id))

        # Return the export result with download URL
        return {
            "download_url": download_url,
            "format": export_options.format,
            "file_size_bytes": len(prepared_journal['audio_data']),
            "expiration_seconds": settings.DEFAULT_JOURNAL_EXPORT_EXPIRATION
        }

    def get_emotional_shift(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
        """Gets the emotional shift data for a journal entry"""
        # Get the journal entry with emotional check-ins
        journal_entry = journal.get_with_emotions(db, journal_id, user_id)

        # Extract pre and post emotional check-in IDs
        pre_checkin_id = journal_entry['pre_checkin'].id if journal_entry['pre_checkin'] else None
        post_checkin_id = journal_entry['post_checkin'].id if journal_entry['post_checkin'] else None

        # Get the emotional shift data using get_emotional_shift from emotion service
        emotional_shift = get_emotional_shift(pre_checkin_id, post_checkin_id)

        # Return the emotional shift data with insights
        return emotional_shift

    def get_recommended_tools(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, limit: int = 5) -> List[Dict]:
        """Gets tool recommendations based on journal emotional data"""
        # Get the journal entry with emotional check-ins
        journal_entry = journal.get_with_emotions(db, journal_id, user_id)

        # Extract post-journaling emotional state
        post_emotion = journal_entry['post_checkin']

        # Get tool recommendations using get_recommended_tools_for_emotion
        recommended_tools = get_recommended_tools_for_emotion(db, post_emotion.emotion_type, post_emotion.intensity, user_id, limit)

        # Return the recommended tools
        return recommended_tools

    def sync_to_cloud(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
        """Synchronizes a journal recording to cloud storage"""
        # Get the journal entry to verify access
        journal_entry = journal.get(db, journal_id)

        if not journal_entry:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        if journal_entry.user_id != user_id:
            raise PermissionDeniedException(message="You do not have permission to sync this journal entry")

        # Synchronize the journal to cloud storage using _storage_service
        sync_result = self._storage_service.sync_to_cloud(user_id=str(user_id), file_ids=[str(journal_id)])

        # Update the journal entry with cloud storage reference
        if sync_result['success']:
            journal.mark_as_uploaded(db, journal_id, sync_result['s3_key'], user_id)

        # Return the synchronization result
        return sync_result

    def configure_audio_processor(self, config: Dict) -> None:
        """Configures the audio processor settings"""
        # Apply settings for target format, sample rate, bit rate, channels
        if 'target_format' in config:
            self._audio_processor.set_target_format(config['target_format'])
        if 'target_sample_rate' in config:
            self._audio_processor.set_target_sample_rate(config['target_sample_rate'])
        if 'target_bit_rate' in config:
            self._audio_processor.set_target_bit_rate(config['target_bit_rate'])
        if 'target_channels' in config:
            self._audio_processor.set_target_channels(config['target_channels'])

        # Configure normalization and noise reduction options
        if 'apply_normalization' in config:
            if config['apply_normalization']:
                self._audio_processor.enable_normalization()
            else:
                self._audio_processor.disable_normalization()

        if 'apply_noise_reduction' in config:
            if config['apply_noise_reduction']:
                self._audio_processor.enable_noise_reduction()
            else:
                self._audio_processor.disable_noise_reduction()


class JournalServiceError(Exception):
    """Exception class for journal service errors"""

    def __init__(self, message: str, error_code: str):
        """Initialize the JournalServiceError with a message and error code"""
        super().__init__(message)
        self.message = message
        self.error_code = error_code


class AudioFormatError(JournalServiceError):
    """Exception for unsupported audio format errors"""

    def __init__(self, message: str):
        """Initialize the AudioFormatError with a message"""
        super().__init__(message, "UNSUPPORTED_AUDIO_FORMAT")


class JournalExportError(JournalServiceError):
    """Exception for journal export errors"""

    def __init__(self, message: str):
        """Initialize the JournalExportError with a message"""
        super().__init__(message, "JOURNAL_EXPORT_ERROR")