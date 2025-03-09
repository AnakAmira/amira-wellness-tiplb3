import os
import uuid
import io
import base64
from unittest.mock import patch, MagicMock

import pytest
import boto3
from botocore.exceptions import ClientError
from moto import mock_s3

from ...app.services.storage import (
    get_journal_storage_service,
    get_tool_storage_service,
    JournalStorageService,
    ToolStorageService,
    StorageServiceError
)
from ...app.utils.storage import (
    upload_to_s3,
    download_from_s3,
    delete_from_s3,
    generate_presigned_url,
    StorageError,
    CloudStorageError
)
from ...app.core.encryption import (
    encode_encryption_data, 
    decode_encryption_data
)
from ..fixtures.users import regular_user
from ..fixtures.database import test_db

# Test constants
TEST_STORAGE_DIR = os.path.join(os.path.dirname(__file__), 'test_storage')
TEST_AUDIO_DATA = b'This is test audio data'
TEST_METADATA = {'audio_format': 'AAC', 'duration_seconds': 120, 'sample_rate': 44100}


def setup_function():
    """Setup function that runs before each test to prepare the test environment."""
    # Ensure the test storage directory exists
    os.makedirs(TEST_STORAGE_DIR, exist_ok=True)
    
    # Set environment variables for testing
    os.environ["ENVIRONMENT"] = "test"
    os.environ["S3_BUCKET_NAME"] = "test-bucket"
    
    # Configure moto to mock AWS services
    mock_s3().start()
    
    # Create S3 bucket for testing
    s3_client = boto3.client('s3', region_name='us-east-1')
    s3_client.create_bucket(Bucket="test-bucket")


def teardown_function():
    """Teardown function that runs after each test to clean up the test environment."""
    # Clean up any test files created during the test
    if os.path.exists(TEST_STORAGE_DIR):
        import shutil
        shutil.rmtree(TEST_STORAGE_DIR)
    
    # Reset environment variables
    os.environ.pop("ENVIRONMENT", None)
    os.environ.pop("S3_BUCKET_NAME", None)
    
    # Stop moto mock services
    mock_s3().stop()


def create_test_audio_data(size_bytes=1024):
    """Helper function to create test audio data with specified size."""
    return os.urandom(size_bytes)


def test_journal_storage_service_initialization():
    """Tests that the JournalStorageService initializes correctly."""
    storage_service = JournalStorageService(local_storage_dir=TEST_STORAGE_DIR)
    assert storage_service is not None
    assert storage_service._storage_type == "journals"
    assert os.path.exists(TEST_STORAGE_DIR)


def test_tool_storage_service_initialization():
    """Tests that the ToolStorageService initializes correctly."""
    storage_service = ToolStorageService(local_storage_dir=TEST_STORAGE_DIR)
    assert storage_service is not None
    assert storage_service._storage_type == "tools"
    assert os.path.exists(TEST_STORAGE_DIR)


def test_save_journal_local(regular_user):
    """Tests saving a journal recording to local storage."""
    journal_service = JournalStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    journal_id = str(uuid.uuid4())
    result = journal_service.save_journal(
        audio_data=TEST_AUDIO_DATA,
        user_id=str(regular_user.id),
        journal_id=journal_id,
        metadata=TEST_METADATA
    )
    
    assert result is not None
    assert result['file_id'] == journal_id
    assert result['user_id'] == str(regular_user.id)
    assert os.path.exists(result['local_path'])
    assert result['size'] == len(TEST_AUDIO_DATA)
    assert result['metadata']['audio_format'] == 'AAC'
    assert result['is_cloud_synced'] is False


def test_load_journal_local(regular_user):
    """Tests loading a journal recording from local storage."""
    journal_service = JournalStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    # First save a journal
    journal_id = str(uuid.uuid4())
    save_result = journal_service.save_journal(
        audio_data=TEST_AUDIO_DATA,
        user_id=str(regular_user.id),
        journal_id=journal_id,
        metadata=TEST_METADATA
    )
    
    # Then load it
    load_result = journal_service.load_journal(
        user_id=str(regular_user.id),
        journal_id=journal_id
    )
    
    assert load_result is not None
    assert load_result['file_id'] == journal_id
    assert load_result['user_id'] == str(regular_user.id)
    assert load_result['data'] == TEST_AUDIO_DATA
    assert load_result['size'] == len(TEST_AUDIO_DATA)
    assert load_result['metadata']['audio_format'] == 'AAC'
    assert load_result['loaded_from_cloud'] is False


def test_delete_journal_local(regular_user):
    """Tests deleting a journal recording from local storage."""
    journal_service = JournalStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    # First save a journal
    journal_id = str(uuid.uuid4())
    save_result = journal_service.save_journal(
        audio_data=TEST_AUDIO_DATA,
        user_id=str(regular_user.id),
        journal_id=journal_id,
        metadata=TEST_METADATA
    )
    
    # Verify it exists
    file_path = save_result['local_path']
    assert os.path.exists(file_path)
    
    # Then delete it
    delete_result = journal_service.delete_journal(
        user_id=str(regular_user.id),
        journal_id=journal_id
    )
    
    assert delete_result is True
    assert not os.path.exists(file_path)


def test_save_journal_cloud(regular_user):
    """Tests saving a journal recording to cloud storage (S3)."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'upload_to_s3') as mock_upload:
        mock_upload.return_value = {
            'status': 'success',
            's3_key': 'test_key',
            'etag': 'test_etag'
        }
        
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        journal_id = str(uuid.uuid4())
        result = journal_service.save_journal(
            audio_data=TEST_AUDIO_DATA,
            user_id=str(regular_user.id),
            journal_id=journal_id,
            metadata=TEST_METADATA
        )
        
        assert result is not None
        assert result['file_id'] == journal_id
        assert result['user_id'] == str(regular_user.id)
        assert os.path.exists(result['local_path'])
        assert result['size'] == len(TEST_AUDIO_DATA)
        assert result['is_cloud_synced'] is True
        assert 's3_key' in result
        
        # Verify the upload_to_s3 function was called
        mock_upload.assert_called_once()


def test_load_journal_cloud(regular_user):
    """Tests loading a journal recording from cloud storage (S3)."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'download_from_s3') as mock_download:
        mock_download.return_value = {
            'data': TEST_AUDIO_DATA,
            'metadata': TEST_METADATA
        }
        
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        journal_id = str(uuid.uuid4())
        
        # Load directly from cloud
        load_result = journal_service.load_journal(
            user_id=str(regular_user.id),
            journal_id=journal_id
        )
        
        assert load_result is not None
        assert load_result['file_id'] == journal_id
        assert load_result['user_id'] == str(regular_user.id)
        assert load_result['data'] == TEST_AUDIO_DATA
        assert load_result['metadata'] == TEST_METADATA
        assert load_result['loaded_from_cloud'] is True
        
        # Verify the download_from_s3 function was called
        mock_download.assert_called_once()


def test_delete_journal_cloud(regular_user):
    """Tests deleting a journal recording from cloud storage (S3)."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'delete_from_s3') as mock_delete:
        mock_delete.return_value = True
        
        # First save a journal locally to have something to delete
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        journal_id = str(uuid.uuid4())
        save_result = journal_service.save_journal(
            audio_data=TEST_AUDIO_DATA,
            user_id=str(regular_user.id),
            journal_id=journal_id,
            metadata=TEST_METADATA
        )
        
        # Delete it (should try to delete from cloud)
        delete_result = journal_service.delete_journal(
            user_id=str(regular_user.id),
            journal_id=journal_id
        )
        
        assert delete_result is True
        
        # Verify the delete_from_s3 function was called
        mock_delete.assert_called_once()


def test_get_journal_download_url(regular_user):
    """Tests generating a download URL for a journal recording."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'generate_presigned_url') as mock_url:
        test_url = "https://test-bucket.s3.amazonaws.com/test-key?signature=xyz"
        mock_url.return_value = test_url
        
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        journal_id = str(uuid.uuid4())
        
        url = journal_service.get_journal_download_url(
            user_id=str(regular_user.id),
            journal_id=journal_id,
            expiration=3600
        )
        
        assert url is not None
        assert url == test_url
        
        # Verify the generate_presigned_url function was called with correct parameters
        mock_url.assert_called_once()
        args, kwargs = mock_url.call_args
        assert 'expiration' in kwargs
        assert kwargs['expiration'] == 3600


def test_export_journal(regular_user):
    """Tests exporting a journal recording to a different format."""
    journal_service = JournalStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    export_id = str(uuid.uuid4())
    result = journal_service.export_journal(
        audio_data=TEST_AUDIO_DATA,
        user_id=str(regular_user.id),
        export_id=export_id,
        format="mp3",
        metadata={
            'original_format': 'AAC',
            'quality': 'high'
        }
    )
    
    assert result is not None
    assert export_id in result['file_id']
    assert result['file_id'].endswith('.mp3')
    assert result['user_id'] == str(regular_user.id)
    assert os.path.exists(result['local_path'])
    assert result['metadata']['original_format'] == 'AAC'
    assert result['metadata']['export_format'] == 'mp3'
    assert 'quality' in result['metadata']


def test_sync_journals_to_cloud(regular_user):
    """Tests synchronizing local journal recordings to cloud storage."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'upload_to_s3') as mock_upload:
        mock_upload.return_value = {
            'status': 'success',
            's3_key': 'test_key',
            'etag': 'test_etag'
        }
        
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        # Save multiple journals locally
        journal_ids = []
        for i in range(3):
            journal_id = str(uuid.uuid4())
            journal_service.save_journal(
                audio_data=TEST_AUDIO_DATA,
                user_id=str(regular_user.id),
                journal_id=journal_id,
                metadata=TEST_METADATA
            )
            journal_ids.append(journal_id)
        
        # Sync them to cloud
        sync_result = journal_service.sync_journals_to_cloud(
            user_id=str(regular_user.id),
            journal_ids=journal_ids
        )
        
        assert sync_result is not None
        assert sync_result['success'] is True
        assert sync_result['synced_count'] == 3
        assert sync_result['failed_count'] == 0
        
        # Verify the upload_to_s3 function was called for each journal
        assert mock_upload.call_count == 3


def test_save_tool_resource():
    """Tests saving a tool resource to storage."""
    tool_service = ToolStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    tool_id = str(uuid.uuid4())
    resource_id = str(uuid.uuid4())
    result = tool_service.save_tool_resource(
        resource_data=TEST_AUDIO_DATA,
        tool_id=tool_id,
        resource_id=resource_id,
        metadata={
            'resource_type': 'audio',
            'content_type': 'audio/mp3'
        }
    )
    
    assert result is not None
    assert result['file_id'] == resource_id
    assert os.path.exists(result['local_path'])
    assert result['size'] == len(TEST_AUDIO_DATA)
    assert result['metadata']['tool_id'] == tool_id
    assert result['metadata']['resource_type'] == 'audio'


def test_load_tool_resource():
    """Tests loading a tool resource from storage."""
    tool_service = ToolStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    # First save a tool resource
    tool_id = str(uuid.uuid4())
    resource_id = str(uuid.uuid4())
    save_result = tool_service.save_tool_resource(
        resource_data=TEST_AUDIO_DATA,
        tool_id=tool_id,
        resource_id=resource_id,
        metadata={
            'resource_type': 'audio',
            'content_type': 'audio/mp3'
        }
    )
    
    # Then load it
    load_result = tool_service.load_tool_resource(
        tool_id=tool_id,
        resource_id=resource_id
    )
    
    assert load_result is not None
    assert load_result['file_id'] == resource_id
    assert load_result['data'] == TEST_AUDIO_DATA
    assert load_result['size'] == len(TEST_AUDIO_DATA)
    assert load_result['metadata']['tool_id'] == tool_id
    assert load_result['metadata']['resource_type'] == 'audio'


def test_delete_tool_resource():
    """Tests deleting a tool resource from storage."""
    tool_service = ToolStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    # First save a tool resource
    tool_id = str(uuid.uuid4())
    resource_id = str(uuid.uuid4())
    save_result = tool_service.save_tool_resource(
        resource_data=TEST_AUDIO_DATA,
        tool_id=tool_id,
        resource_id=resource_id,
        metadata={
            'resource_type': 'audio',
            'content_type': 'audio/mp3'
        }
    )
    
    # Verify it exists
    file_path = save_result['local_path']
    assert os.path.exists(file_path)
    
    # Then delete it
    delete_result = tool_service.delete_tool_resource(
        tool_id=tool_id,
        resource_id=resource_id
    )
    
    assert delete_result is True
    assert not os.path.exists(file_path)


def test_get_tool_resource_url():
    """Tests generating a download URL for a tool resource."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'generate_presigned_url') as mock_url:
        test_url = "https://test-bucket.s3.amazonaws.com/test-key?signature=xyz"
        mock_url.return_value = test_url
        
        tool_service = ToolStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        tool_id = str(uuid.uuid4())
        resource_id = str(uuid.uuid4())
        
        url = tool_service.get_tool_resource_url(
            tool_id=tool_id,
            resource_id=resource_id,
            expiration=86400
        )
        
        assert url is not None
        assert url == test_url
        
        # Verify the generate_presigned_url function was called with correct parameters
        mock_url.assert_called_once()
        args, kwargs = mock_url.call_args
        assert 'expiration' in kwargs
        assert kwargs['expiration'] == 86400


def test_storage_error_handling(regular_user):
    """Tests error handling in storage operations."""
    from ...app.utils import storage as storage_utils
    
    with patch.object(storage_utils, 'upload_to_s3', side_effect=CloudStorageError("S3 upload failed")):
        journal_service = JournalStorageService(
            local_storage_dir=TEST_STORAGE_DIR, 
            use_cloud_storage=True
        )
        
        journal_id = str(uuid.uuid4())
        
        # This should still succeed since local storage works even if cloud fails
        result = journal_service.save_journal(
            audio_data=TEST_AUDIO_DATA,
            user_id=str(regular_user.id),
            journal_id=journal_id,
            metadata=TEST_METADATA
        )
        
        assert result is not None
        assert result['is_cloud_synced'] is False
        
        # Now test a more serious error that should propagate
        with patch.object(storage_utils, 'save_file_locally', side_effect=StorageError("File system error")):
            with pytest.raises(StorageServiceError):
                journal_service.save_journal(
                    audio_data=TEST_AUDIO_DATA,
                    user_id=str(regular_user.id),
                    journal_id=str(uuid.uuid4()),
                    metadata=TEST_METADATA
                )


def test_encryption_integration(regular_user):
    """Tests that storage operations correctly handle encryption data."""
    # Generate some encryption data
    iv = os.urandom(12)  # 12 bytes for GCM
    tag = os.urandom(16)  # 16 bytes for auth tag
    
    # Encode encryption data to base64 strings
    encoded_iv = encode_encryption_data(iv)
    encoded_tag = encode_encryption_data(tag)
    
    # Include encryption data in metadata
    metadata = {
        **TEST_METADATA,
        'encryption': {
            'iv': encoded_iv,
            'tag': encoded_tag
        }
    }
    
    journal_service = JournalStorageService(
        local_storage_dir=TEST_STORAGE_DIR, 
        use_cloud_storage=False
    )
    
    journal_id = str(uuid.uuid4())
    
    # Save a journal with encryption metadata
    save_result = journal_service.save_journal(
        audio_data=TEST_AUDIO_DATA,
        user_id=str(regular_user.id),
        journal_id=journal_id,
        metadata=metadata
    )
    
    # Load the journal
    load_result = journal_service.load_journal(
        user_id=str(regular_user.id),
        journal_id=journal_id
    )
    
    # Verify encryption data was preserved
    assert 'encryption' in load_result['metadata']
    assert 'iv' in load_result['metadata']['encryption']
    assert 'tag' in load_result['metadata']['encryption']
    
    # Decode the encryption data
    loaded_iv = decode_encryption_data(load_result['metadata']['encryption']['iv'])
    loaded_tag = decode_encryption_data(load_result['metadata']['encryption']['tag'])
    
    # Verify the decoded data matches the original
    assert loaded_iv == iv
    assert loaded_tag == tag