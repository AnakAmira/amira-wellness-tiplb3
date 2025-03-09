import pytest
import uuid
import datetime
import unittest.mock as mock
from unittest.mock import MagicMock, patch, Mock
import io
from io import BytesIO

from ...app.models.journal import Journal
from ...app.models.emotion import EmotionalCheckin
from ...app.crud.journal import journal
from ...app.schemas.journal import JournalCreate, JournalUpdate, JournalFilter
from ...app.schemas.emotion import EmotionalStateCreate
from ...app.constants.emotions import EmotionType, EmotionContext
from ...app.services.journal import create_journal, get_journal, get_journal_audio
from ...app.services.journal import export_journal, JournalService
from ...app.core.exceptions import ResourceNotFoundException, PermissionDeniedException

from . import test_db
from ..fixtures.users import regular_user, premium_user
from ..fixtures.journals import short_journal, medium_journal, long_journal
from ..fixtures.journals import favorite_journal, uploaded_journal, deleted_journal
from ..fixtures.journals import journal_with_checkins, anxiety_to_calm_journal, sadness_to_joy_journal
from ..fixtures.journals import multiple_journals

TEST_AUDIO_DATA = b'test audio data'
TEST_ENCRYPTION_KEY = b'test encryption key'

def create_test_journal_data(user_id: uuid.UUID) -> JournalCreate:
    """Helper function to create test journal data for creating journals"""
    # Create pre-emotional state with ANXIETY and intensity 7
    pre_emotional_state = EmotionalStateCreate(
        emotion_type=EmotionType.ANXIETY,
        intensity=7,
        context=EmotionContext.PRE_JOURNALING
    )
    # Create post-emotional state with CALM and intensity 6
    post_emotional_state = EmotionalStateCreate(
        emotion_type=EmotionType.CALM,
        intensity=6,
        context=EmotionContext.POST_JOURNALING
    )
    # Create journal data with title, duration, format, and emotional states
    journal_data = JournalCreate(
        user_id=user_id,
        title="Test Journal",
        duration_seconds=60,
        audio_format="AAC",
        file_size_bytes=1024,
        pre_emotional_state=pre_emotional_state,
        post_emotional_state=post_emotional_state
    )
    # Return the journal creation data
    return journal_data

def mock_storage_service():
    """Helper function to create a mock storage service"""
    # Create a MagicMock object for the storage service
    storage_service_mock = MagicMock()
    # Configure the mock to return appropriate values for method calls
    storage_service_mock.save_journal.return_value = {"s3_key": "test_s3_key"}
    storage_service_mock.load_journal.return_value = {"data": TEST_AUDIO_DATA}
    storage_service_mock.get_journal_download_url.return_value = "http://test_download_url"
    # Return the configured mock storage service
    return storage_service_mock

def mock_encryption_service():
    """Helper function to create a mock encryption service"""
    # Create a MagicMock object for the encryption service
    encryption_service_mock = MagicMock()
    # Configure the mock to return appropriate values for method calls
    encryption_service_mock.encrypt_journal.return_value = {
        "encrypted_data": b"encrypted audio data",
        "iv": b"iv",
        "tag": b"tag"
    }
    encryption_service_mock.decrypt_journal.return_value = b"decrypted audio data"
    # Return the configured mock encryption service
    return encryption_service_mock

class TestJournalModel:
    """Test cases for the Journal model methods"""

    def test_journal_is_accessible_by_user(self, short_journal, regular_user):
        """Test that a journal is accessible by its owner"""
        # Check that the journal is accessible by its owner
        assert short_journal.is_accessible_by_user(regular_user.id) is True
        # Check that the journal is not accessible by another user
        another_user_id = uuid.uuid4()
        assert short_journal.is_accessible_by_user(another_user_id) is False

    def test_mark_as_favorite(self, short_journal):
        """Test marking a journal as favorite"""
        # Verify journal is not initially marked as favorite
        assert short_journal.is_favorite is False
        # Mark the journal as favorite
        short_journal.mark_as_favorite()
        # Verify journal is now marked as favorite
        assert short_journal.is_favorite is True

    def test_unmark_as_favorite(self, favorite_journal):
        """Test unmarking a journal from favorites"""
        # Verify journal is initially marked as favorite
        assert favorite_journal.is_favorite is True
        # Unmark the journal as favorite
        favorite_journal.unmark_as_favorite()
        # Verify journal is no longer marked as favorite
        assert favorite_journal.is_favorite is False

    def test_mark_as_uploaded(self, short_journal):
        """Test marking a journal as uploaded to cloud storage"""
        # Verify journal is not initially marked as uploaded
        assert short_journal.is_uploaded is False
        # Mark the journal as uploaded with an S3 key
        s3_key = "test_s3_key"
        short_journal.mark_as_uploaded(s3_key)
        # Verify journal is now marked as uploaded
        assert short_journal.is_uploaded is True
        # Verify the S3 key is set correctly
        assert short_journal.s3_key == s3_key

    def test_soft_delete(self, short_journal):
        """Test soft deleting a journal"""
        # Verify journal is not initially marked as deleted
        assert short_journal.is_deleted is False
        # Soft delete the journal
        short_journal.soft_delete()
        # Verify journal is now marked as deleted
        assert short_journal.is_deleted is True

    def test_restore(self, deleted_journal):
        """Test restoring a soft-deleted journal"""
        # Verify journal is initially marked as deleted
        assert deleted_journal.is_deleted is True
        # Restore the journal
        deleted_journal.restore()
        # Verify journal is no longer marked as deleted
        assert deleted_journal.is_deleted is False

    def test_get_encryption_details(self, short_journal):
        """Test retrieving encryption details for a journal"""
        # Get encryption details from the journal
        encryption_details = short_journal.get_encryption_details()
        # Verify the encryption_iv is returned
        assert encryption_details['encryption_iv'] == short_journal.encryption_iv
        # Verify the encryption_tag is returned
        assert encryption_details['encryption_tag'] == short_journal.encryption_tag

class TestJournalCRUD:
    """Test cases for journal CRUD operations"""

    def test_get_by_user(self, test_db, regular_user, multiple_journals):
        """Test retrieving journals for a specific user"""
        # Get journals for the regular user
        journals, total = journal.get_by_user(test_db, regular_user.id)
        # Verify the correct number of journals is returned
        assert len(journals) == len(multiple_journals)
        # Verify the journals belong to the user
        for j in journals:
            assert j.user_id == regular_user.id
        # Verify pagination works correctly
        journals_page_1, total = journal.get_by_user(test_db, regular_user.id, page=1, page_size=2)
        assert len(journals_page_1) == 2
        assert total == len(multiple_journals)

    def test_get_filtered_by_date_range(self, test_db, regular_user, multiple_journals):
        """Test filtering journals by date range"""
        # Create a date range filter
        start_date = datetime.datetime.utcnow() - datetime.timedelta(days=7)
        end_date = datetime.datetime.utcnow()
        filter_params = JournalFilter(start_date=start_date, end_date=end_date)
        # Get filtered journals for the regular user
        filtered_journals, total = journal.get_filtered(test_db, regular_user.id, filter_params)
        # Verify the correct journals are returned based on date range
        for j in filtered_journals:
            assert start_date <= j.created_at <= end_date

    def test_get_filtered_by_favorite(self, test_db, regular_user, multiple_journals, favorite_journal):
        """Test filtering journals by favorite status"""
        # Create a favorite filter
        filter_params = JournalFilter(favorite_only=True)
        # Get filtered journals for the regular user
        filtered_journals, total = journal.get_filtered(test_db, regular_user.id, filter_params)
        # Verify only favorite journals are returned
        assert len(filtered_journals) == 1
        assert filtered_journals[0].is_favorite is True

    def test_get_filtered_by_emotion_type(self, test_db, regular_user, anxiety_to_calm_journal, sadness_to_joy_journal):
        """Test filtering journals by emotion type"""
        # Create an emotion type filter for ANXIETY
        filter_params = JournalFilter(emotion_types=[EmotionType.ANXIETY])
        # Get filtered journals for the regular user
        filtered_journals, total = journal.get_filtered(test_db, regular_user.id, filter_params)
        # Verify only journals with ANXIETY emotion are returned
        assert len(filtered_journals) == 1
        #assert filtered_journals[0].pre_emotion == EmotionType.ANXIETY

    def test_create_with_emotions(self, test_db, regular_user):
        """Test creating a journal with emotional check-ins"""
        # Create journal data with pre and post emotional states
        journal_data = create_test_journal_data(regular_user.id)
        # Create the journal with emotional check-ins
        db_obj = journal.create_with_emotions(test_db, journal_data)
        # Verify the journal is created with the correct data
        assert db_obj.title == journal_data.title
        assert db_obj.duration_seconds == journal_data.duration_seconds
        # Verify the emotional check-ins are created and linked to the journal
        assert len(db_obj.emotional_checkins) == 2
        assert db_obj.emotional_checkins[0].context == EmotionContext.PRE_JOURNALING
        assert db_obj.emotional_checkins[1].context == EmotionContext.POST_JOURNALING

    def test_get_with_emotions(self, test_db, regular_user, journal_with_checkins):
        """Test retrieving a journal with its emotional check-ins"""
        journal_obj, pre_checkin, post_checkin = journal_with_checkins
        # Get the journal with its emotional check-ins
        journal_data = journal.get_with_emotions(test_db, journal_obj.id, regular_user.id)
        # Verify the journal data is correct
        assert journal_data["journal"].title == journal_obj.title
        assert journal_data["journal"].duration_seconds == journal_obj.duration_seconds
        # Verify the pre-emotional check-in is included
        assert journal_data["pre_checkin"].emotion_type == pre_checkin.emotion_type
        assert journal_data["pre_checkin"].intensity == pre_checkin.intensity
        # Verify the post-emotional check-in is included
        assert journal_data["post_checkin"].emotion_type == post_checkin.emotion_type
        assert journal_data["post_checkin"].intensity == post_checkin.intensity

    def test_mark_as_favorite_crud(self, test_db, regular_user, short_journal):
        """Test marking a journal as favorite through CRUD operations"""
        # Mark the journal as favorite
        updated_journal = journal.mark_as_favorite(test_db, short_journal.id, regular_user.id)
        # Verify the journal is marked as favorite in the database
        assert updated_journal.is_favorite is True

    def test_unmark_as_favorite_crud(self, test_db, regular_user, favorite_journal):
        """Test unmarking a journal from favorites through CRUD operations"""
        # Unmark the journal as favorite
        updated_journal = journal.unmark_as_favorite(test_db, favorite_journal.id, regular_user.id)
        # Verify the journal is unmarked as favorite in the database
        assert updated_journal.is_favorite is False

    def test_mark_as_uploaded_crud(self, test_db, regular_user, short_journal):
        """Test marking a journal as uploaded through CRUD operations"""
        # Mark the journal as uploaded with an S3 key
        s3_key = "test_s3_key"
        updated_journal = journal.mark_as_uploaded(test_db, short_journal.id, s3_key, regular_user.id)
        # Verify the journal is marked as uploaded in the database
        assert updated_journal.is_uploaded is True
        # Verify the S3 key is set correctly in the database
        assert updated_journal.s3_key == s3_key

    def test_soft_delete_crud(self, test_db, regular_user, short_journal):
        """Test soft deleting a journal through CRUD operations"""
        # Soft delete the journal
        deleted_journal = journal.soft_delete(test_db, short_journal.id, regular_user.id)
        # Verify the journal is marked as deleted in the database
        assert deleted_journal.is_deleted is True
        # Verify the journal is not returned in normal queries
        journals, total = journal.get_by_user(test_db, regular_user.id)
        assert short_journal not in journals

    def test_restore_crud(self, test_db, regular_user, deleted_journal):
        """Test restoring a soft-deleted journal through CRUD operations"""
        # Restore the journal
        restored_journal = journal.restore(test_db, deleted_journal.id, regular_user.id)
        # Verify the journal is unmarked as deleted in the database
        assert restored_journal.is_deleted is False
        # Verify the journal is returned in normal queries
        journals, total = journal.get_by_user(test_db, regular_user.id)
        assert restored_journal in journals

    def test_get_emotional_shift_crud(self, test_db, regular_user, anxiety_to_calm_journal):
        """Test retrieving emotional shift data for a journal"""
        journal_obj, pre_checkin, post_checkin = anxiety_to_calm_journal
        # Get the emotional shift data for the journal
        emotional_shift = journal.get_emotional_shift(test_db, journal_obj.id, regular_user.id)
        # Verify the pre-emotional state is included
        assert emotional_shift["pre_emotion"] == pre_checkin.emotion_type
        assert emotional_shift["pre_intensity"] == pre_checkin.intensity
        # Verify the post-emotional state is included
        assert emotional_shift["post_emotion"] == post_checkin.emotion_type
        assert emotional_shift["post_intensity"] == post_checkin.intensity
        # Verify the intensity change is calculated correctly
        assert emotional_shift["intensity_change"] == (post_checkin.intensity - pre_checkin.intensity)

    def test_get_journal_stats(self, test_db, regular_user, multiple_journals, anxiety_to_calm_journal, sadness_to_joy_journal):
        """Test retrieving journal usage statistics"""
        # Get journal statistics for the regular user
        stats = journal.get_journal_stats(test_db, regular_user.id, datetime.datetime.min, datetime.datetime.max)
        # Verify the total number of journals is correct
        assert stats["total_journals"] == len(multiple_journals) + 2
        # Verify the total duration is calculated correctly
        total_duration = sum(j.duration_seconds for j in multiple_journals) + anxiety_to_calm_journal[0].duration_seconds + sadness_to_joy_journal[0].duration_seconds
        assert stats["total_duration_seconds"] == total_duration
        # Verify the journals by emotion are categorized correctly
        assert EmotionType.ANXIETY in stats["journals_by_emotion"]
        assert EmotionType.CALM in stats["journals_by_emotion"]
        assert EmotionType.SADNESS in stats["journals_by_emotion"]
        assert EmotionType.JOY in stats["journals_by_emotion"]
        # Verify the journals by month are categorized correctly
        assert len(stats["journals_by_month"]) > 0

    def test_get_audio_metadata(self, test_db, regular_user, short_journal):
        """Test retrieving audio metadata for a journal"""
        # Get the audio metadata for the journal
        metadata = journal.get_audio_metadata(test_db, short_journal.id, regular_user.id)
        # Verify the encryption details are included
        assert metadata["encryption_iv"] == short_journal.encryption_iv
        assert metadata["encryption_tag"] == short_journal.encryption_tag
        # Verify the audio format is included
        assert metadata["audio_format"] == short_journal.audio_format
        # Verify the file size is included
        assert metadata["file_size_bytes"] == short_journal.file_size_bytes
        # Verify the duration is included
        assert metadata["duration_seconds"] == short_journal.duration_seconds

class TestJournalService:
    """Test cases for journal service functions"""

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_create_journal_service(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user):
        """Test creating a journal through the service layer"""
        # Mock the storage service
        storage_service_mock = mock_storage_service()
        mock_get_storage_service.return_value = storage_service_mock
        # Mock the encryption service
        encryption_service_mock = mock_encryption_service()
        mock_get_encryption_service.return_value = encryption_service_mock
        # Create journal data with pre and post emotional states
        journal_data = create_test_journal_data(regular_user.id)
        # Patch the service dependencies
        with patch('src.backend.app.services.journal.get_journal_storage_service', return_value=storage_service_mock), \
             patch('src.backend.app.services.journal.get_journal_encryption_service', return_value=encryption_service_mock):
            # Call create_journal service function
            db_obj = create_journal(test_db, journal_data, TEST_AUDIO_DATA, TEST_ENCRYPTION_KEY)
            # Verify the journal is created with the correct data
            assert db_obj.title == journal_data.title
            assert db_obj.duration_seconds == journal_data.duration_seconds
            # Verify the audio is processed, encrypted, and stored
            encryption_service_mock.encrypt_journal.assert_called_once()
            storage_service_mock.save_journal.assert_called_once()

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_get_journal_service(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user, journal_with_checkins):
        """Test retrieving a journal through the service layer"""
        journal_obj, pre_checkin, post_checkin = journal_with_checkins
        # Call get_journal service function
        journal_data = get_journal(test_db, journal_obj.id, regular_user.id)
        # Verify the journal data is correct
        assert journal_data["journal"].title == journal_obj.title
        assert journal_data["journal"].duration_seconds == journal_obj.duration_seconds
        # Verify the emotional check-ins are included
        assert journal_data["pre_checkin"].emotion_type == pre_checkin.emotion_type
        assert journal_data["post_checkin"].emotion_type == post_checkin.emotion_type

    def test_get_journal_not_found(self, test_db, regular_user):
        """Test retrieving a non-existent journal"""
        # Call get_journal with a non-existent journal ID
        with pytest.raises(ResourceNotFoundException):
            get_journal(test_db, uuid.uuid4(), regular_user.id)

    def test_get_journal_permission_denied(self, test_db, regular_user, premium_user, journal_with_checkins):
        """Test retrieving a journal without permission"""
        journal_obj, pre_checkin, post_checkin = journal_with_checkins
        # Call get_journal with premium_user trying to access regular_user's journal
        with pytest.raises(PermissionDeniedException):
            get_journal(test_db, journal_obj.id, premium_user.id)

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_get_journal_audio_service(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user, uploaded_journal):
        """Test retrieving journal audio through the service layer"""
        # Mock the storage service to return encrypted audio data
        storage_service_mock = mock_storage_service()
        mock_get_storage_service.return_value = storage_service_mock
        # Mock the encryption service to decrypt the audio data
        encryption_service_mock = mock_encryption_service()
        mock_get_encryption_service.return_value = encryption_service_mock
        # Patch the service dependencies
        with patch('src.backend.app.services.journal.get_journal_storage_service', return_value=storage_service_mock), \
             patch('src.backend.app.services.journal.get_journal_encryption_service', return_value=encryption_service_mock):
            # Call get_journal_audio service function
            audio_data = get_journal_audio(test_db, uploaded_journal.id, regular_user.id, TEST_ENCRYPTION_KEY)
            # Verify the audio data is retrieved and decrypted
            assert audio_data == b"decrypted audio data"
            encryption_service_mock.decrypt_journal.assert_called_once()

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_get_journal_emotional_shift_service(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user, anxiety_to_calm_journal):
        """Test retrieving emotional shift data through the service layer"""
        journal_obj, pre_checkin, post_checkin = anxiety_to_calm_journal
        # Call get_journal_emotional_shift service function
        emotional_shift = get_journal_emotional_shift(test_db, journal_obj.id, regular_user.id)
        # Verify the emotional shift data is correct
        assert emotional_shift["pre_emotion"] == pre_checkin.emotion_type
        assert emotional_shift["post_emotion"] == post_checkin.emotion_type
        # Verify insights are generated for the emotional shift
        assert len(emotional_shift["insights"]) > 0

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_export_journal_service(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user, uploaded_journal):
        """Test exporting a journal through the service layer"""
        # Mock the storage service
        storage_service_mock = mock_storage_service()
        mock_get_storage_service.return_value = storage_service_mock
        # Mock the encryption service
        encryption_service_mock = mock_encryption_service()
        mock_get_encryption_service.return_value = encryption_service_mock
        # Patch the service dependencies
        with patch('src.backend.app.services.journal.get_journal_storage_service', return_value=storage_service_mock), \
             patch('src.backend.app.services.journal.get_journal_encryption_service', return_value=encryption_service_mock):
            # Create export options
            export_options = JournalExport(format="mp3")
            # Call export_journal service function
            export_result = export_journal(test_db, uploaded_journal.id, regular_user.id, export_options, TEST_ENCRYPTION_KEY)
            # Verify the journal is exported in the requested format
            assert export_result["format"] == "mp3"
            # Verify a download URL is generated
            assert export_result["download_url"] == "http://test_download_url"

    @patch('src.backend.app.services.journal.get_journal_storage_service')
    @patch('src.backend.app.services.journal.get_journal_encryption_service')
    def test_journal_service_class(self, mock_get_encryption_service, mock_get_storage_service, test_db, regular_user, uploaded_journal):
        """Test the JournalService class methods"""
        # Mock the storage service
        storage_service_mock = mock_storage_service()
        mock_get_storage_service.return_value = storage_service_mock
        # Mock the encryption service
        encryption_service_mock = mock_encryption_service()
        mock_get_encryption_service.return_value = encryption_service_mock
        # Create a JournalService instance with mocked dependencies
        journal_service = JournalService()
        # Test the create_journal method
        journal_data = create_test_journal_data(regular_user.id)
        db_obj = journal_service.create_journal(test_db, journal_data, TEST_AUDIO_DATA, TEST_ENCRYPTION_KEY)
        assert db_obj["title"] == journal_data.title
        # Test the get_journal_audio method
        audio_data = journal_service.get_journal_audio(test_db, uploaded_journal.id, regular_user.id, TEST_ENCRYPTION_KEY)
        assert audio_data == b"decrypted audio data"
        # Test the export_journal method
        export_options = JournalExport(format="mp3")
        export_result = journal_service.export_journal(test_db, uploaded_journal.id, regular_user.id, export_options, TEST_ENCRYPTION_KEY)
        assert export_result["format"] == "mp3"
        assert export_result["download_url"] == "http://test_download_url"
        # Test the get_emotional_shift method
        # Create a mock for get_emotional_shift
        with mock.patch('src.backend.app.services.journal.get_emotional_shift') as mock_get_emotional_shift:
            mock_get_emotional_shift.return_value = {"shift": "data"}
            emotional_shift = journal_service.get_emotional_shift(test_db, uploaded_journal.id, regular_user.id)
            assert emotional_shift == {"shift": "data"}
        # Test the get_recommended_tools method
        # Create a mock for get_recommended_tools_for_emotion
        with mock.patch('src.backend.app.services.journal.get_recommended_tools_for_emotion') as mock_get_recommended_tools:
            mock_get_recommended_tools.return_value = [{"tool": "tool1"}]
            recommended_tools = journal_service.get_recommended_tools(test_db, uploaded_journal.id, regular_user.id)
            assert recommended_tools == [{"tool": "tool1"}]
        # Test the sync_to_cloud method
        sync_result = journal_service.sync_to_cloud(test_db, uploaded_journal.id, regular_user.id)
        assert sync_result["s3_key"] == "test_s3_key"
        # Test the configure_audio_processor method
        journal_service.configure_audio_processor({"target_format": "wav"})