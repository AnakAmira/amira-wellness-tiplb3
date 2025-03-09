from typing import List, Dict, Optional, Tuple, Union, Any
import uuid
from datetime import datetime

from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.journal import Journal
from ..models.emotion import EmotionalCheckin
from ..schemas.journal import JournalCreate, JournalUpdate, JournalFilter
from ..constants/emotions import EmotionContext
from ..services.storage import get_journal_storage_service
from .emotion import emotion as emotion_checkin
from ..core.exceptions import ResourceNotFoundException
from ..core.logging import logger


class CRUDJournal(CRUDBase[Journal, JournalCreate, JournalUpdate]):
    """CRUD operations for journal entries"""

    def __init__(self):
        """Initialize the CRUD operations for Journal model"""
        super().__init__(Journal)

    def get_by_user(
        self, db: Session, user_id: uuid.UUID, page: int = 1, page_size: int = 10
    ) -> Tuple[List[Journal], int]:
        """
        Get journal entries for a specific user

        Args:
            db: Database session
            user_id: User ID to filter by
            page: Page number (default: 1)
            page_size: Number of items per page (default: 10)

        Returns:
            Tuple[List[Journal], int]: List of journal entries and total count
        """
        logger.info(f"Fetching journal entries for user: {user_id}")
        # Create base query filtering by user_id and is_deleted=False
        query = select(Journal).where(Journal.user_id == user_id, Journal.is_deleted == False)

        # Get total count of records
        count_query = select(func.count()).select_from(Journal).where(Journal.user_id == user_id, Journal.is_deleted == False)
        total = db.execute(count_query).scalar_one()

        # Apply pagination parameters
        skip = (page - 1) * page_size
        query = query.offset(skip).limit(page_size)

        # Order by created_at descending
        query = query.order_by(Journal.created_at.desc())

        # Execute query and return results with count
        results = db.execute(query).scalars().all()
        logger.info(f"Returning {len(results)} journal entries for user: {user_id}")
        return list(results), total

    def get_filtered(
        self, db: Session, user_id: uuid.UUID, filter_params: JournalFilter, page: int = 1, page_size: int = 10
    ) -> Tuple[List[Journal], int]:
        """
        Get journal entries with filtering options

        Args:
            db: Database session
            user_id: User ID to filter by
            filter_params: Filtering parameters
            page: Page number (default: 1)
            page_size: Number of items per page (default: 10)

        Returns:
            Tuple[List[Journal], int]: List of filtered journal entries and total count
        """
        logger.info(f"Fetching filtered journal entries for user: {user_id} with filter: {filter_params}")
        # Create base query filtering by user_id and is_deleted=False
        conditions = [Journal.user_id == user_id, Journal.is_deleted == False]

        # Apply date range filter if provided
        if filter_params.start_date:
            conditions.append(Journal.created_at >= filter_params.start_date)
        if filter_params.end_date:
            conditions.append(Journal.created_at <= filter_params.end_date)

        # Apply favorite_only filter if provided
        if filter_params.favorite_only is not None:
            conditions.append(Journal.is_favorite == filter_params.favorite_only)

        # Apply emotion_types filter if provided (requires subquery)
        if filter_params.emotion_types:
            # Subquery to find journal IDs with matching emotion types
            subquery = (
                select(EmotionalCheckin.related_journal_id)
                .where(EmotionalCheckin.emotion_type.in_(filter_params.emotion_types))
                .distinct()
                .scalar_subquery()
            )
            conditions.append(Journal.id.in_(subquery))

        # Get total count of filtered records
        count_query = select(func.count()).select_from(Journal).where(and_(*conditions))
        total = db.execute(count_query).scalar_one()

        # Apply pagination parameters
        skip = (page - 1) * page_size
        query = select(Journal).where(and_(*conditions)).offset(skip).limit(page_size)

        # Order by created_at descending
        query = query.order_by(Journal.created_at.desc())

        # Execute query and return results with count
        results = db.execute(query).scalars().all()
        logger.info(f"Returning {len(results)} filtered journal entries for user: {user_id}")
        return list(results), total

    def create_with_emotions(self, db: Session, obj_in: JournalCreate) -> Journal:
        """
        Create a journal entry with pre and post emotional check-ins

        Args:
            db: Database session
            obj_in: Journal creation schema

        Returns:
            Journal: Created journal entry with emotional check-ins
        """
        logger.info(f"Creating journal entry for user: {obj_in.user_id}")
        # Extract pre_emotional_state and post_emotional_state from obj_in
        pre_emotional_state = obj_in.pre_emotional_state
        post_emotional_state = obj_in.post_emotional_state

        # Create journal entry using parent create method
        journal_data = obj_in.model_dump(exclude={"pre_emotional_state", "post_emotional_state"})
        db_obj = super().create(db, journal_data)

        # Create pre-journaling emotional check-in with context=PRE_JOURNALING
        pre_emotional_state_create = pre_emotional_state.model_dump()
        pre_emotional_state_create["user_id"] = obj_in.user_id
        pre_emotional_state_create["related_journal_id"] = db_obj.id
        emotion_checkin.create(db, pre_emotional_state_create)

        # Create post-journaling emotional check-in with context=POST_JOURNALING
        post_emotional_state_create = post_emotional_state.model_dump()
        post_emotional_state_create["user_id"] = obj_in.user_id
        post_emotional_state_create["related_journal_id"] = db_obj.id
        emotion_checkin.create(db, post_emotional_state_create)

        # Commit the session to persist all changes
        db.commit()
        logger.info(f"Journal entry created with ID: {db_obj.id}")
        # Return the created journal entry
        return db_obj

    def get_with_emotions(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
        """
        Get a journal entry with its emotional check-ins

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Dict: Journal entry with pre and post emotional check-ins
        """
        logger.info(f"Fetching journal entry with emotions for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Get emotional check-ins for the journal
        emotional_checkins = emotion_checkin.get_by_journal(db, journal_id)

        # Separate pre and post emotional check-ins
        pre_checkin = next((c for c in emotional_checkins if c.context == EmotionContext.PRE_JOURNALING), None)
        post_checkin = next((c for c in emotional_checkins if c.context == EmotionContext.POST_JOURNALING), None)

        # Return journal with emotional check-ins as dictionary
        result = {
            "journal": journal,
            "pre_checkin": pre_checkin,
            "post_checkin": post_checkin,
        }
        logger.info(f"Returning journal entry with emotions for journal_id: {journal_id}")
        return result

    def mark_as_favorite(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Journal:
        """
        Mark a journal entry as favorite

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Journal: Updated journal entry
        """
        logger.info(f"Marking journal as favorite for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.mark_as_favorite()
        journal.is_favorite = True

        # Commit the session to persist changes
        db.add(journal)
        db.commit()
        db.refresh(journal)
        logger.info(f"Journal marked as favorite for journal_id: {journal_id}")
        # Return the updated journal entry
        return journal

    def unmark_as_favorite(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Journal:
        """
        Remove a journal entry from favorites

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Journal: Updated journal entry
        """
        logger.info(f"Unmarking journal as favorite for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.unmark_as_favorite()
        journal.is_favorite = False

        # Commit the session to persist changes
        db.add(journal)
        db.commit()
        db.refresh(journal)
        logger.info(f"Journal unmarked as favorite for journal_id: {journal_id}")
        # Return the updated journal entry
        return journal

    def mark_as_uploaded(self, db: Session, journal_id: uuid.UUID, s3_key: str, user_id: uuid.UUID) -> Journal:
        """
        Mark a journal entry as uploaded to cloud storage

        Args:
            db: Database session
            journal_id: Journal ID
            s3_key: S3 key of the uploaded file
            user_id: User ID

        Returns:
            Journal: Updated journal entry
        """
        logger.info(f"Marking journal as uploaded for journal_id: {journal_id}, user_id: {user_id}, s3_key: {s3_key}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.mark_as_uploaded(s3_key)
        journal.is_uploaded = True
        journal.s3_key = s3_key

        # Commit the session to persist changes
        db.add(journal)
        db.commit()
        db.refresh(journal)
        logger.info(f"Journal marked as uploaded for journal_id: {journal_id}")
        # Return the updated journal entry
        return journal

    def soft_delete(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Journal:
        """
        Soft delete a journal entry

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Journal: Soft-deleted journal entry
        """
        logger.info(f"Soft deleting journal for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        query = select(Journal).where(Journal.id == journal_id)
        journal = db.execute(query).scalars().first()

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.soft_delete()
        journal.is_deleted = True

        # Commit the session to persist changes
        db.add(journal)
        db.commit()
        db.refresh(journal)
        logger.info(f"Journal soft deleted for journal_id: {journal_id}")
        # Return the soft-deleted journal entry
        return journal

    def restore(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Journal:
        """
        Restore a soft-deleted journal entry

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Journal: Restored journal entry
        """
        logger.info(f"Restoring journal for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID (including soft-deleted)
        query = select(Journal).where(Journal.id == journal_id)
        journal = db.execute(query).scalars().first()

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.restore()
        journal.is_deleted = False

        # Commit the session to persist changes
        db.add(journal)
        db.commit()
        db.refresh(journal)
        logger.info(f"Journal restored for journal_id: {journal_id}")
        # Return the restored journal entry
        return journal

    def get_emotional_shift(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
        """
        Get emotional shift data for a journal entry

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Dict: Emotional shift data between pre and post journaling
        """
        logger.info(f"Fetching emotional shift for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.get_emotional_shift()
        emotional_shift = journal.get_emotional_shift()
        logger.info(f"Returning emotional shift data for journal_id: {journal_id}")
        # Return emotional shift data
        return emotional_shift

    def get_journal_stats(self, db: Session, user_id: uuid.UUID, start_date: datetime, end_date: datetime) -> Dict:
        """
        Get journal usage statistics for a user

        Args:
            db: Database session
            user_id: User ID
            start_date: Start date for the range
            end_date: End date for the range

        Returns:
            Dict: Journal usage statistics
        """
        logger.info(f"Fetching journal stats for user_id: {user_id}, start_date: {start_date}, end_date: {end_date}")
        # Query total number of journals
        total_journals_query = select(func.count()).select_from(Journal).where(Journal.user_id == user_id, Journal.created_at >= start_date, Journal.created_at <= end_date)
        total_journals = db.execute(total_journals_query).scalar_one()

        # Query total duration of all journals
        total_duration_query = select(func.sum(Journal.duration_seconds)).where(Journal.user_id == user_id, Journal.created_at >= start_date, Journal.created_at <= end_date)
        total_duration = db.execute(total_duration_query).scalar() or 0

        # Query journals by emotion type
        emotion_query = select(EmotionalCheckin.emotion_type, func.count()).join(Journal, Journal.id == EmotionalCheckin.related_journal_id).where(Journal.user_id == user_id, Journal.created_at >= start_date, Journal.created_at <= end_date).group_by(EmotionalCheckin.emotion_type)
        emotion_results = db.execute(emotion_query).all()
        journals_by_emotion = {emotion_type: count for emotion_type, count in emotion_results}

        # Query journals by month
        month_query = select(func.date_trunc('month', Journal.created_at).label('month'), func.count()).where(Journal.user_id == user_id, Journal.created_at >= start_date, Journal.created_at <= end_date).group_by('month')
        month_results = db.execute(month_query).all()
        journals_by_month = {month.strftime('%Y-%m'): count for month, count in month_results}

        # Query significant emotional shifts
        # significant_shifts_query = select(Journal).where(Journal.user_id == user_id, Journal.created_at >= start_date, Journal.created_at <= end_date).order_by(desc(Journal.created_at)).limit(5)
        # significant_shifts = db.execute(significant_shifts_query).scalars().all()
        significant_shifts = []  # Placeholder for now

        # Compile statistics dictionary
        stats = {
            "total_journals": total_journals,
            "total_duration_seconds": total_duration,
            "journals_by_emotion": journals_by_emotion,
            "journals_by_month": journals_by_month,
            "significant_shifts": significant_shifts,
        }
        logger.info(f"Returning journal stats for user_id: {user_id}")
        return stats

    def get_audio_metadata(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID) -> Dict:
        """
        Get audio metadata for a journal entry

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID

        Returns:
            Dict: Audio metadata including encryption details
        """
        logger.info(f"Fetching audio metadata for journal_id: {journal_id}, user_id: {user_id}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Call journal.get_encryption_details()
        audio_metadata = {
            "encryption_iv": journal.encryption_iv,
            "encryption_tag": journal.encryption_tag,
            "audio_format": journal.audio_format,
            "file_size_bytes": journal.file_size_bytes,
            "duration_seconds": journal.duration_seconds
        }
        logger.info(f"Returning audio metadata for journal_id: {journal_id}")
        # Return audio metadata with encryption details
        return audio_metadata

    def export_journal(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, export_format: str, include_metadata: bool, include_emotional_data: bool, encryption_key: bytes) -> Dict:
        """
        Export a journal entry to a downloadable format

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID
            export_format: Format to export the journal to
            include_metadata: Whether to include metadata in the export
            include_emotional_data: Whether to include emotional data in the export
            encryption_key: Encryption key to use for the export

        Returns:
            Dict: Export result with download URL and metadata
        """
        logger.info(f"Exporting journal for journal_id: {journal_id}, user_id: {user_id}, format: {export_format}")
        # Get journal entry with emotions
        journal_with_emotions = self.get_with_emotions(db, journal_id, user_id)
        journal = journal_with_emotions["journal"]

        # Get journal storage service
        storage_service = get_journal_storage_service()

        # Load journal audio data
        journal_data = storage_service.load_journal(user_id, journal_id)
        audio_data = journal_data["data"]

        # Export to requested format
        export_result = storage_service.export_journal(
            audio_data=audio_data,
            user_id=user_id,
            format=export_format,
            metadata={
                "original_format": journal.audio_format,
                "journal_id": str(journal.id),
                "user_id": str(user_id),
                "include_metadata": include_metadata,
                "include_emotional_data": include_emotional_data
            }
        )

        # Generate download URL
        download_url = export_result["download_url"]
        logger.info(f"Journal exported to {export_format} format, download URL: {download_url}")
        # Return export result with URL and metadata
        return {
            "download_url": download_url,
            "format": export_format,
            "file_size_bytes": journal.file_size_bytes,
            "expiration_seconds": 3600  # Example expiration time
        }

    def get_download_url(self, db: Session, journal_id: uuid.UUID, user_id: uuid.UUID, expiration_seconds: int = 3600) -> str:
        """
        Get a temporary download URL for a journal audio file

        Args:
            db: Database session
            journal_id: Journal ID
            user_id: User ID
            expiration_seconds: Expiration time for the URL in seconds

        Returns:
            str: Presigned download URL
        """
        logger.info(f"Generating download URL for journal_id: {journal_id}, user_id: {user_id}, expiration: {expiration_seconds}")
        # Get journal entry by ID
        journal = self.get(db, journal_id)

        # Verify journal belongs to the specified user
        if not journal or journal.user_id != user_id:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Verify journal is uploaded to cloud storage
        if not journal.is_uploaded:
            raise ResourceNotFoundException(resource_type="Journal", resource_id=journal_id)

        # Get journal storage service
        storage_service = get_journal_storage_service()

        # Generate presigned download URL
        download_url = storage_service.get_journal_download_url(user_id, journal_id, expiration_seconds)
        logger.info(f"Returning download URL for journal_id: {journal_id}")
        # Return the download URL
        return download_url


# Create instances of the CRUD classes for export
journal = CRUDJournal()