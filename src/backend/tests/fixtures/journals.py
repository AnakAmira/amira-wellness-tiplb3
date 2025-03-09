"""
Test fixture module that provides journal-related fixtures for unit and integration tests in the Amira Wellness application.
Creates various test journal objects with different states, durations, and associated emotional check-ins to support
comprehensive testing of voice journaling functionality.
"""

import pytest
import uuid
import datetime
import os
import base64

from ...app.models.journal import Journal
from ...app.models.emotion import EmotionalCheckin
from ...app.constants.emotions import EmotionType, EmotionContext
from .users import regular_user, premium_user
from .database import test_db

# Constants for test data
TEST_AUDIO_FORMATS = ["AAC", "MP3"]
TEST_STORAGE_PATH = "test_storage/journals/"
MOCK_ENCRYPTION_IV = base64.b64encode(os.urandom(16)).decode('utf-8')
MOCK_ENCRYPTION_TAG = base64.b64encode(os.urandom(16)).decode('utf-8')

def create_test_journal(
    user_id,
    title,
    duration_seconds,
    audio_format,
    file_size_bytes,
    is_favorite,
    is_uploaded,
    is_deleted
) -> Journal:
    """
    Helper function to create a test journal with specified attributes.
    
    Args:
        user_id: User ID associated with the journal
        title: Journal title
        duration_seconds: Duration in seconds
        audio_format: Audio format (AAC, MP3)
        file_size_bytes: Size of the audio file in bytes
        is_favorite: Whether the journal is marked as favorite
        is_uploaded: Whether the journal has been uploaded to cloud storage
        is_deleted: Whether the journal has been soft-deleted
        
    Returns:
        Journal instance with specified attributes
    """
    # Generate a unique ID for the journal
    journal_id = uuid.uuid4()
    
    # Create a storage path based on user ID and journal ID
    storage_path = f"{TEST_STORAGE_PATH}{user_id}/{journal_id}.{audio_format.lower()}"
    
    # Generate an S3 key if uploaded
    s3_key = f"journals/{user_id}/{journal_id}.{audio_format.lower()}" if is_uploaded else None
    
    # Create a new journal instance
    journal = Journal(
        id=journal_id,
        user_id=user_id,
        title=title,
        duration_seconds=duration_seconds,
        storage_path=storage_path,
        s3_key=s3_key,
        encryption_iv=MOCK_ENCRYPTION_IV,
        encryption_tag=MOCK_ENCRYPTION_TAG,
        audio_format=audio_format,
        file_size_bytes=file_size_bytes,
        is_favorite=is_favorite,
        is_uploaded=is_uploaded,
        is_deleted=is_deleted
    )
    
    # Set timestamps
    journal.created_at = datetime.datetime.utcnow()
    journal.updated_at = datetime.datetime.utcnow()
    
    return journal

def create_journal_with_checkins(
    user_id,
    title,
    duration_seconds,
    pre_emotion,
    pre_intensity,
    post_emotion,
    post_intensity
) -> tuple:
    """
    Creates a journal with associated pre and post emotional check-ins.
    
    Args:
        user_id: User ID associated with the journal
        title: Journal title
        duration_seconds: Duration in seconds
        pre_emotion: Emotion type before recording
        pre_intensity: Emotion intensity before recording
        post_emotion: Emotion type after recording
        post_intensity: Emotion intensity after recording
        
    Returns:
        Tuple containing (Journal, pre_checkin, post_checkin)
    """
    # Create a journal
    journal = create_test_journal(
        user_id=user_id,
        title=title,
        duration_seconds=duration_seconds,
        audio_format="AAC",
        file_size_bytes=duration_seconds * 10240,  # Rough estimate of file size
        is_favorite=False,
        is_uploaded=True,
        is_deleted=False
    )
    
    # Create pre-recording check-in
    pre_checkin = EmotionalCheckin(
        id=uuid.uuid4(),
        user_id=user_id,
        emotion_type=pre_emotion,
        intensity=pre_intensity,
        context=EmotionContext.PRE_JOURNALING,
        related_journal_id=journal.id
    )
    
    # Create post-recording check-in
    post_checkin = EmotionalCheckin(
        id=uuid.uuid4(),
        user_id=user_id,
        emotion_type=post_emotion,
        intensity=post_intensity,
        context=EmotionContext.POST_JOURNALING,
        related_journal_id=journal.id
    )
    
    # Set timestamps
    pre_checkin.created_at = datetime.datetime.utcnow() - datetime.timedelta(minutes=duration_seconds // 60 + 2)
    post_checkin.created_at = datetime.datetime.utcnow()
    
    return (journal, pre_checkin, post_checkin)

@pytest.fixture
def short_journal(test_db, regular_user):
    """
    Creates a short duration journal entry (under 2 minutes).
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance with short duration
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Quick thought",
        duration_seconds=90,  # 1.5 minutes
        audio_format="AAC",
        file_size_bytes=1024000,  # ~1 MB
        is_favorite=False,
        is_uploaded=False,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def medium_journal(test_db, regular_user):
    """
    Creates a medium duration journal entry (2-5 minutes).
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance with medium duration
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Daily reflection",
        duration_seconds=180,  # 3 minutes
        audio_format="AAC",
        file_size_bytes=2048000,  # ~2 MB
        is_favorite=False,
        is_uploaded=False,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def long_journal(test_db, regular_user):
    """
    Creates a long duration journal entry (over 5 minutes).
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance with long duration
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Deep emotional processing",
        duration_seconds=420,  # 7 minutes
        audio_format="AAC",
        file_size_bytes=4096000,  # ~4 MB
        is_favorite=False,
        is_uploaded=False,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def favorite_journal(test_db, regular_user):
    """
    Creates a journal entry marked as favorite.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance marked as favorite
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Important breakthrough",
        duration_seconds=240,  # 4 minutes
        audio_format="AAC",
        file_size_bytes=2560000,  # ~2.5 MB
        is_favorite=True,
        is_uploaded=False,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def uploaded_journal(test_db, regular_user):
    """
    Creates a journal entry that has been uploaded to cloud storage.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance marked as uploaded with S3 key
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Synced journal",
        duration_seconds=180,  # 3 minutes
        audio_format="AAC",
        file_size_bytes=2048000,  # ~2 MB
        is_favorite=False,
        is_uploaded=True,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def deleted_journal(test_db, regular_user):
    """
    Creates a soft-deleted journal entry.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Journal instance marked as deleted
    """
    journal = create_test_journal(
        user_id=regular_user.id,
        title="Deleted journal",
        duration_seconds=120,  # 2 minutes
        audio_format="AAC",
        file_size_bytes=1536000,  # ~1.5 MB
        is_favorite=False,
        is_uploaded=False,
        is_deleted=True
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def premium_journal(test_db, premium_user):
    """
    Creates a journal entry for a premium user.
    
    Args:
        test_db: Database session fixture
        premium_user: Premium user fixture
        
    Returns:
        Journal instance associated with premium user
    """
    journal = create_test_journal(
        user_id=premium_user.id,
        title="Premium reflection",
        duration_seconds=300,  # 5 minutes
        audio_format="MP3",
        file_size_bytes=3072000,  # ~3 MB
        is_favorite=False,
        is_uploaded=True,
        is_deleted=False
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    return journal

@pytest.fixture
def journal_with_checkins(test_db, regular_user):
    """
    Creates a journal with associated pre and post emotional check-ins.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Tuple of (Journal, pre_checkin, post_checkin)
    """
    journal, pre_checkin, post_checkin = create_journal_with_checkins(
        user_id=regular_user.id,
        title="Emotional processing",
        duration_seconds=240,  # 4 minutes
        pre_emotion=EmotionType.ANXIETY,
        pre_intensity=7,
        post_emotion=EmotionType.CALM,
        post_intensity=6
    )
    test_db.add(journal)
    test_db.add(pre_checkin)
    test_db.add(post_checkin)
    test_db.commit()
    test_db.refresh(journal)
    test_db.refresh(pre_checkin)
    test_db.refresh(post_checkin)
    return (journal, pre_checkin, post_checkin)

@pytest.fixture
def anxiety_to_calm_journal(test_db, regular_user):
    """
    Creates a journal showing emotional shift from anxiety to calm.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Tuple of (Journal, pre_checkin, post_checkin)
    """
    journal, pre_checkin, post_checkin = create_journal_with_checkins(
        user_id=regular_user.id,
        title="Anxiety relief",
        duration_seconds=300,  # 5 minutes
        pre_emotion=EmotionType.ANXIETY,
        pre_intensity=8,
        post_emotion=EmotionType.CALM,
        post_intensity=7
    )
    test_db.add(journal)
    test_db.add(pre_checkin)
    test_db.add(post_checkin)
    test_db.commit()
    test_db.refresh(journal)
    test_db.refresh(pre_checkin)
    test_db.refresh(post_checkin)
    return (journal, pre_checkin, post_checkin)

@pytest.fixture
def sadness_to_joy_journal(test_db, regular_user):
    """
    Creates a journal showing emotional shift from sadness to joy.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        Tuple of (Journal, pre_checkin, post_checkin)
    """
    journal, pre_checkin, post_checkin = create_journal_with_checkins(
        user_id=regular_user.id,
        title="Mood improvement",
        duration_seconds=360,  # 6 minutes
        pre_emotion=EmotionType.SADNESS,
        pre_intensity=7,
        post_emotion=EmotionType.JOY,
        post_intensity=6
    )
    test_db.add(journal)
    test_db.add(pre_checkin)
    test_db.add(post_checkin)
    test_db.commit()
    test_db.refresh(journal)
    test_db.refresh(pre_checkin)
    test_db.refresh(post_checkin)
    return (journal, pre_checkin, post_checkin)

@pytest.fixture
def multiple_journals(test_db, regular_user):
    """
    Creates multiple journal entries for a single user.
    
    Args:
        test_db: Database session fixture
        regular_user: Regular user fixture
        
    Returns:
        List of Journal instances
    """
    journals = []
    for i in range(5):
        journal = create_test_journal(
            user_id=regular_user.id,
            title=f"Journal entry {i}",
            duration_seconds=120 + i * 30,  # Increasing durations
            audio_format="AAC",
            file_size_bytes=1536000 + i * 512000,  # Increasing file sizes
            is_favorite=i % 3 == 0,  # Every third entry is a favorite
            is_uploaded=i % 2 == 0,  # Every second entry is uploaded
            is_deleted=False
        )
        test_db.add(journal)
        journals.append(journal)
    
    test_db.commit()
    for journal in journals:
        test_db.refresh(journal)
    
    return journals