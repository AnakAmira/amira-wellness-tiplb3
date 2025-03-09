"""
Unit tests for the encryption functionality in the Amira Wellness application.

This module tests the core encryption and decryption operations, key management,
and specialized encryption services for voice journals and emotional data.
"""

import os
import base64
import json
import uuid
import pytest
from unittest.mock import MagicMock, patch

# Import AWS exceptions for mocking
from botocore.exceptions import ClientError

# Import core encryption functions
from app.core.encryption import (
    generate_encryption_key, generate_salt, derive_key_from_password,
    encrypt, decrypt, encrypt_file, decrypt_file,
    encrypt_with_kms, decrypt_with_kms, encrypt_key_with_kms, decrypt_key_with_kms,
    encode_encryption_data, decode_encryption_data,
    EncryptionError, EncryptionKeyError, DecryptionError, KMSError,
    EncryptionManager
)

# Import encryption services
from app.services.encryption import (
    EncryptionService, JournalEncryptionService, EmotionalDataEncryptionService,
    get_encryption_service, generate_user_encryption_key, derive_user_key_from_password,
    encode_for_storage, decode_from_storage
)

# Import app settings for KMS test conditionals
from app.core.config import settings


# Basic core encryption function tests
def test_generate_encryption_key():
    """Tests that generate_encryption_key produces keys of the correct length"""
    # Generate a key
    key = generate_encryption_key()
    
    # Verify it's bytes and of correct length
    assert isinstance(key, bytes)
    assert len(key) == 32  # 256 bits = 32 bytes
    
    # Generate another key and verify it's different (randomness check)
    another_key = generate_encryption_key()
    assert key != another_key


def test_generate_salt():
    """Tests that generate_salt produces salts of the correct length"""
    # Generate a salt
    salt = generate_salt()
    
    # Verify it's bytes and of correct length
    assert isinstance(salt, bytes)
    assert len(salt) == 16  # 128 bits = 16 bytes
    
    # Generate another salt and verify it's different (randomness check)
    another_salt = generate_salt()
    assert salt != another_salt


def test_derive_key_from_password():
    """Tests that derive_key_from_password correctly derives keys from passwords"""
    # Create test password and salt
    password = "TestPassword123!"
    salt = generate_salt()
    
    # Derive a key
    key = derive_key_from_password(password, salt)
    
    # Verify it's bytes and of correct length
    assert isinstance(key, bytes)
    assert len(key) == 32  # 256 bits = 32 bytes
    
    # Derive another key with the same password and salt, should be identical
    another_key = derive_key_from_password(password, salt)
    assert key == another_key
    
    # Derive a key with different password but same salt, should be different
    different_password_key = derive_key_from_password("DifferentPassword123!", salt)
    assert key != different_password_key
    
    # Derive a key with the same password but different salt, should be different
    different_salt_key = derive_key_from_password(password, generate_salt())
    assert key != different_salt_key


def test_encrypt_decrypt_cycle():
    """Tests the full encryption and decryption cycle for data integrity"""
    # Create test data, key, and associated data
    data = b"Test data to encrypt"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data
    encryption_result = encrypt(data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    
    # Decrypt the data
    decrypted_data = decrypt(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted data matches original
    assert decrypted_data == data


def test_encrypt_decrypt_with_wrong_key():
    """Tests that decryption fails when using the wrong key"""
    # Create test data, key, and associated data
    data = b"Test data to encrypt"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data
    encryption_result = encrypt(data, key, associated_data)
    
    # Create a different key (wrong key)
    wrong_key = generate_encryption_key()
    
    # Attempt to decrypt with the wrong key, should raise DecryptionError
    with pytest.raises(DecryptionError):
        decrypt(
            encryption_result["encrypted_data"],
            wrong_key,
            encryption_result["iv"],
            encryption_result["tag"],
            associated_data
        )


def test_encrypt_decrypt_with_wrong_associated_data():
    """Tests that decryption fails when using wrong associated data"""
    # Create test data, key, and associated data
    data = b"Test data to encrypt"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data
    encryption_result = encrypt(data, key, associated_data)
    
    # Create different associated data
    wrong_associated_data = b"Wrong associated data"
    
    # Attempt to decrypt with wrong associated data, should raise DecryptionError
    with pytest.raises(DecryptionError):
        decrypt(
            encryption_result["encrypted_data"],
            key,
            encryption_result["iv"],
            encryption_result["tag"],
            wrong_associated_data
        )


def test_encrypt_decrypt_with_tampered_data():
    """Tests that decryption fails when the encrypted data has been tampered with"""
    # Create test data, key, and associated data
    data = b"Test data to encrypt"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data
    encryption_result = encrypt(data, key, associated_data)
    
    # Tamper with the encrypted data
    tampered_data = bytearray(encryption_result["encrypted_data"])
    tampered_data[0] = (tampered_data[0] + 1) % 256  # Modify the first byte
    
    # Attempt to decrypt with tampered data, should raise DecryptionError
    with pytest.raises(DecryptionError):
        decrypt(
            bytes(tampered_data),
            key,
            encryption_result["iv"],
            encryption_result["tag"],
            associated_data
        )


def test_encrypt_file_decrypt_file_cycle():
    """Tests the encryption and decryption cycle for file data"""
    # Create test file data, key, and associated data
    file_data = b"Test file data to encrypt"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the file data
    encryption_result = encrypt_file(file_data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    
    # Decrypt the file data
    decrypted_file_data = decrypt_file(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted file data matches original
    assert decrypted_file_data == file_data


def test_encode_decode_encryption_data():
    """Tests encoding and decoding of binary encryption data to/from base64"""
    # Create test binary data
    binary_data = b"Test binary data"
    
    # Encode to base64 string
    encoded_data = encode_encryption_data(binary_data)
    
    # Verify it's a string
    assert isinstance(encoded_data, str)
    
    # Decode back to binary
    decoded_data = decode_encryption_data(encoded_data)
    
    # Verify decoded data matches original
    assert decoded_data == binary_data


# EncryptionManager tests
def test_encryption_manager_init():
    """Tests initialization of the EncryptionManager with different configurations"""
    # Create EncryptionManager with default settings
    manager = EncryptionManager()
    
    # Verify it has the expected attributes
    assert hasattr(manager, '_use_kms')
    
    # Create EncryptionManager with KMS enabled
    manager_with_kms = EncryptionManager(use_kms=True)
    assert manager_with_kms._use_kms is True
    
    # Create EncryptionManager with specific KMS key ID
    kms_key_id = "test-key-id"
    manager_with_key_id = EncryptionManager(use_kms=True, kms_key_id=kms_key_id)
    assert manager_with_key_id._kms_key_id == kms_key_id


def test_encryption_manager_encrypt_decrypt_cycle():
    """Tests the encryption and decryption cycle using the EncryptionManager"""
    # Create EncryptionManager with KMS disabled
    manager = EncryptionManager(use_kms=False)
    
    # Create test data, key, and associated data
    data = b"Test data to encrypt with manager"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data using the manager
    encryption_result = manager.encrypt_data(data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    
    # Decrypt the data using the manager
    decrypted_data = manager.decrypt_data(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted data matches original
    assert decrypted_data == data


def test_encryption_manager_generate_user_key():
    """Tests the generation of user encryption keys by the EncryptionManager"""
    # Create EncryptionManager with KMS disabled
    manager = EncryptionManager(use_kms=False)
    
    # Generate a key with password and salt
    password = "TestPassword123!"
    salt = generate_salt()
    key_result = manager.generate_user_key(password, salt)
    
    # Verify result is a tuple containing key and salt
    assert isinstance(key_result, tuple)
    assert len(key_result) == 2
    key, returned_salt = key_result
    
    # Verify key is bytes and of correct length
    assert isinstance(key, bytes)
    assert len(key) == 32  # 256 bits = 32 bytes
    
    # Verify salt matches what was provided
    assert returned_salt == salt
    
    # Generate a key with just password (should generate a salt)
    key_result2 = manager.generate_user_key(password)
    assert isinstance(key_result2, tuple)
    assert len(key_result2) == 2
    key2, salt2 = key_result2
    
    # Verify salt was generated
    assert salt2 is not None
    assert isinstance(salt2, bytes)
    
    # Generate a key without any parameters (should generate a random key)
    key_result3 = manager.generate_user_key()
    assert isinstance(key_result3, tuple)
    assert len(key_result3) == 2
    key3, salt3 = key_result3


# EncryptionService tests
def test_encryption_service_init():
    """Tests initialization of the EncryptionService with different configurations"""
    # Create EncryptionService with default settings
    service = EncryptionService()
    
    # Verify it has the expected attributes
    assert hasattr(service, '_encryption_manager')
    assert hasattr(service, '_use_kms')
    
    # Create EncryptionService with KMS enabled
    service_with_kms = EncryptionService(use_kms=True)
    assert service_with_kms._use_kms is True
    
    # Create EncryptionService with specific KMS key ID
    kms_key_id = "test-key-id"
    service_with_key_id = EncryptionService(use_kms=True, kms_key_id=kms_key_id)
    assert service_with_key_id._kms_key_id == kms_key_id


def test_encryption_service_encrypt_decrypt_cycle():
    """Tests the encryption and decryption cycle using the EncryptionService"""
    # Create EncryptionService with KMS disabled
    service = EncryptionService(use_kms=False)
    
    # Create test data, key, and associated data
    data = b"Test data to encrypt with service"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the data using the service
    encryption_result = service.encrypt_data(data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    
    # Decrypt the data using the service
    decrypted_data = service.decrypt_data(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted data matches original
    assert decrypted_data == data


def test_encryption_service_encrypt_decrypt_file_cycle():
    """Tests the file encryption and decryption cycle using the EncryptionService"""
    # Create EncryptionService with KMS disabled
    service = EncryptionService(use_kms=False)
    
    # Create test file data, key, and associated data
    file_data = b"Test file data to encrypt with service"
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the file data using the service
    encryption_result = service.encrypt_file(file_data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    
    # Decrypt the file data using the service
    decrypted_file_data = service.decrypt_file(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted file data matches original
    assert decrypted_file_data == file_data


def test_encryption_service_encrypt_decrypt_json():
    """Tests the JSON encryption and decryption using the EncryptionService"""
    # Create EncryptionService with KMS disabled
    service = EncryptionService(use_kms=False)
    
    # Create test JSON data, key, and associated data
    json_data = {
        "key1": "value1",
        "key2": 123,
        "key3": ["list", "of", "values"],
        "key4": {"nested": "object"}
    }
    key = generate_encryption_key()
    associated_data = b"Test associated data"
    
    # Encrypt the JSON data using the service
    encryption_result = service.encrypt_json(json_data, key, associated_data)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    assert "format" in encryption_result
    assert encryption_result["format"] == "json"
    
    # Decrypt the JSON data using the service
    decrypted_json_data = service.decrypt_json(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        associated_data
    )
    
    # Verify decrypted JSON data matches original
    assert decrypted_json_data == json_data


def test_encryption_service_generate_user_key():
    """Tests the generation of user encryption keys by the EncryptionService"""
    # Create EncryptionService with KMS disabled
    service = EncryptionService(use_kms=False)
    
    # Generate a key with user ID and password
    user_id = "test-user-id"
    password = "TestPassword123!"
    key_result = service.generate_user_key(user_id, password)
    
    # Verify result is a tuple containing key and salt
    assert isinstance(key_result, tuple)
    assert len(key_result) == 2
    key, salt = key_result
    
    # Verify key is bytes and of correct length
    assert isinstance(key, bytes)
    assert len(key) == 32  # 256 bits = 32 bytes
    
    # Verify salt is bytes
    assert isinstance(salt, bytes)
    
    # Generate a key with just user ID (should generate a random key)
    key_result2 = service.generate_user_key(user_id)
    assert isinstance(key_result2, tuple)
    assert len(key_result2) == 2
    key2, salt2 = key_result2
    
    # Verify key was generated
    assert key2 is not None
    assert isinstance(key2, bytes)


# JournalEncryptionService tests
def test_journal_encryption_service_encrypt_decrypt_cycle():
    """Tests the encryption and decryption cycle for journals using the JournalEncryptionService"""
    # Create JournalEncryptionService with KMS disabled
    service = JournalEncryptionService(use_kms=False)
    
    # Create test audio data, key, user ID, and metadata
    audio_data = b"Test audio data for voice journal"
    key = generate_encryption_key()
    user_id = "test-user-id"
    metadata = {
        "duration_seconds": 60,
        "file_name": "test_recording.m4a"
    }
    
    # Encrypt the journal using the service
    encryption_result = service.encrypt_journal(audio_data, key, user_id, metadata)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    assert "user_id" in encryption_result
    assert "timestamp" in encryption_result
    assert "type" in encryption_result
    assert "checksum" in encryption_result
    assert "duration_seconds" in encryption_result
    assert "file_name" in encryption_result
    
    # Decrypt the journal using the service
    decrypted_audio_data = service.decrypt_journal(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        user_id,
        None,  # No encrypted_key in this test
        encryption_result["checksum"]
    )
    
    # Verify decrypted audio data matches original
    assert decrypted_audio_data == audio_data


def test_journal_encryption_service_prepare_for_export():
    """Tests the preparation of journal data for export"""
    # Create JournalEncryptionService with KMS disabled
    service = JournalEncryptionService(use_kms=False)
    
    # Create test audio data, key, user ID, and metadata
    audio_data = b"Test audio data for voice journal export"
    key = generate_encryption_key()
    user_id = "test-user-id"
    metadata = {
        "duration_seconds": 60,
        "file_name": "test_recording.m4a"
    }
    
    # Prepare the journal for export in encrypted format
    export_package = service.prepare_journal_for_export(
        audio_data, key, user_id, 'encrypted', metadata
    )
    
    # Verify export package contains expected fields
    assert "encrypted_data" in export_package
    assert "iv" in export_package
    assert "tag" in export_package
    assert "export_id" in export_package
    assert "timestamp" in export_package
    assert "user_id" in export_package
    assert "format" in export_package
    assert "type" in export_package
    assert "checksum" in export_package
    assert "duration_seconds" in export_package
    assert "file_name" in export_package
    
    # Verify format is set correctly
    assert export_package["format"] == "encrypted"
    
    # Prepare the journal for export in a different format
    export_package2 = service.prepare_journal_for_export(
        audio_data, key, user_id, 'mp3', metadata
    )
    
    # Verify format is set correctly
    assert export_package2["format"] == "mp3"


# EmotionalDataEncryptionService tests
def test_emotional_data_encryption_service_encrypt_decrypt_cycle():
    """Tests the encryption and decryption cycle for emotional data"""
    # Create EmotionalDataEncryptionService with KMS disabled
    service = EmotionalDataEncryptionService(use_kms=False)
    
    # Create test emotional data, key, and user ID
    emotional_data = {
        "primary_emotion": "ANXIETY",
        "intensity": 7,
        "timestamp": "2023-01-01T12:00:00Z",
        "context": "PRE_JOURNALING",
        "notes": "Feeling anxious about upcoming presentation"
    }
    key = generate_encryption_key()
    user_id = "test-user-id"
    
    # Encrypt the emotional data using the service
    encryption_result = service.encrypt_emotional_data(emotional_data, key, user_id)
    
    # Verify encryption result contains expected components
    assert "encrypted_data" in encryption_result
    assert "iv" in encryption_result
    assert "tag" in encryption_result
    assert "user_id" in encryption_result
    assert "type" in encryption_result
    assert "timestamp" in encryption_result
    
    # Decrypt the emotional data using the service
    decrypted_emotional_data = service.decrypt_emotional_data(
        encryption_result["encrypted_data"],
        key,
        encryption_result["iv"],
        encryption_result["tag"],
        user_id
    )
    
    # Verify decrypted emotional data matches original
    assert decrypted_emotional_data == emotional_data


# AWS KMS integration tests
@pytest.mark.skipif(not settings.USE_AWS_KMS, reason='KMS not enabled')
def test_kms_integration_encrypt_decrypt():
    """Tests AWS KMS integration for encryption and decryption"""
    # Mock the KMS client
    with patch('app.core.encryption.get_kms_client') as mock_get_kms_client:
        # Set up the mock KMS client
        mock_kms_client = MagicMock()
        mock_get_kms_client.return_value = mock_kms_client
        
        # Set up mock responses
        mock_kms_client.encrypt.return_value = {
            'CiphertextBlob': b'encrypted-data',
            'KeyId': 'test-key-id'
        }
        mock_kms_client.decrypt.return_value = {
            'Plaintext': b'decrypted-data',
            'KeyId': 'test-key-id'
        }
        
        # Test data and key ID
        data = b"Test data for KMS encryption"
        key_id = "test-key-id"
        
        # Encrypt with KMS
        kms_result = encrypt_with_kms(data, key_id)
        
        # Verify KMS result
        assert "ciphertext" in kms_result
        assert "encryption_context" in kms_result
        
        # Decrypt with KMS
        decrypted_data = decrypt_with_kms(
            kms_result["ciphertext"],
            kms_result["encryption_context"]
        )
        
        # Verify decrypted data (in this case, it's the mock return value)
        assert decrypted_data == b'decrypted-data'
        
        # Verify KMS client was called with expected parameters
        mock_kms_client.encrypt.assert_called_once()
        mock_kms_client.decrypt.assert_called_once()


@pytest.mark.skipif(not settings.USE_AWS_KMS, reason='KMS not enabled')
def test_kms_integration_key_encryption():
    """Tests AWS KMS integration for key encryption"""
    # Mock the KMS client
    with patch('app.core.encryption.get_kms_client') as mock_get_kms_client:
        # Set up the mock KMS client
        mock_kms_client = MagicMock()
        mock_get_kms_client.return_value = mock_kms_client
        
        # Set up mock responses
        mock_kms_client.encrypt.return_value = {
            'CiphertextBlob': b'encrypted-key',
            'KeyId': 'test-key-id'
        }
        mock_kms_client.decrypt.return_value = {
            'Plaintext': b'decrypted-key',
            'KeyId': 'test-key-id'
        }
        
        # Generate a key and key ID
        key = generate_encryption_key()
        key_id = "test-key-id"
        
        # Encrypt the key with KMS
        encrypted_key = encrypt_key_with_kms(key, key_id)
        
        # Verify encrypted key
        assert encrypted_key == b'encrypted-key'
        
        # Decrypt the key with KMS
        decrypted_key = decrypt_key_with_kms(encrypted_key)
        
        # Verify decrypted key (in this case, it's the mock return value)
        assert decrypted_key == b'decrypted-key'
        
        # Verify KMS client was called with expected parameters
        mock_kms_client.encrypt.assert_called_once()
        mock_kms_client.decrypt.assert_called_once()


@pytest.mark.skipif(not settings.USE_AWS_KMS, reason='KMS not enabled')
def test_kms_error_handling():
    """Tests error handling for AWS KMS operations"""
    # Mock the KMS client
    with patch('app.core.encryption.get_kms_client') as mock_get_kms_client:
        # Set up the mock KMS client
        mock_kms_client = MagicMock()
        mock_get_kms_client.return_value = mock_kms_client
        
        # Set up mock to raise exception
        client_error = ClientError(
            error_response={'Error': {'Code': 'ValidationException', 'Message': 'Test error'}},
            operation_name='Encrypt'
        )
        mock_kms_client.encrypt.side_effect = client_error
        
        # Test data and key ID
        data = b"Test data for KMS error handling"
        key_id = "test-key-id"
        
        # Attempt to encrypt with KMS, should raise KMSError
        with pytest.raises(KMSError):
            encrypt_with_kms(data, key_id)
        
        # Change the mock to raise exception for decrypt
        mock_kms_client.decrypt.side_effect = client_error
        
        # Attempt to decrypt with KMS, should raise KMSError
        with pytest.raises(KMSError):
            decrypt_with_kms(b"encrypted-data")


@pytest.mark.skipif(not settings.USE_AWS_KMS, reason='KMS not enabled')
def test_encryption_manager_with_kms():
    """Tests EncryptionManager with KMS integration"""
    # Mock the KMS client
    with patch('app.core.encryption.get_kms_client') as mock_get_kms_client:
        # Set up the mock KMS client
        mock_kms_client = MagicMock()
        mock_get_kms_client.return_value = mock_kms_client
        
        # Set up mock responses
        mock_kms_client.encrypt.return_value = {
            'CiphertextBlob': b'encrypted-key',
            'KeyId': 'test-key-id'
        }
        mock_kms_client.decrypt.return_value = {
            'Plaintext': generate_encryption_key(),  # Return a valid key for decryption
            'KeyId': 'test-key-id'
        }
        
        # Create EncryptionManager with KMS enabled
        manager = EncryptionManager(use_kms=True, kms_key_id="test-key-id")
        
        # Create test data, key, and associated data
        data = b"Test data to encrypt with KMS manager"
        key = generate_encryption_key()
        associated_data = b"Test associated data"
        
        # Encrypt the data using the manager
        encryption_result = manager.encrypt_data(data, key, associated_data)
        
        # Verify encryption result contains expected components
        assert "encrypted_data" in encryption_result
        assert "iv" in encryption_result
        assert "tag" in encryption_result
        assert "encrypted_key" in encryption_result
        
        # Mock the decrypt_key_with_kms function to return the original key
        with patch('app.core.encryption.decrypt_key_with_kms', return_value=key):
            # Decrypt the data using the manager
            decrypted_data = manager.decrypt_data(
                encryption_result["encrypted_data"],
                None,  # No key, using encrypted_key with KMS
                encryption_result["iv"],
                encryption_result["tag"],
                associated_data,
                encryption_result["encrypted_key"]
            )
            
            # Verify decrypted data matches original
            assert decrypted_data == data