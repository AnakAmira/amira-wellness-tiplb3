"""
Service layer implementation for encryption operations in the Amira Wellness application.

This module provides high-level encryption functionality for voice recordings and emotional data,
with support for end-to-end encryption, key management, and secure storage. This service acts
as a bridge between the core encryption functionality and application-specific encryption needs.
"""

import os
import base64
import json
import uuid
import datetime
from typing import Dict, List, Optional, Tuple, Union, Any, BinaryIO

# Internal imports for logging, configuration, and core encryption
from ..core.logging import logger
from ..core.config import settings
from ..core.encryption import (
    generate_encryption_key, generate_salt, derive_key_from_password,
    encrypt, decrypt, encrypt_file, decrypt_file,
    encrypt_with_kms, decrypt_with_kms, encrypt_key_with_kms, decrypt_key_with_kms,
    encode_encryption_data, decode_encryption_data,
    EncryptionError, EncryptionKeyError, DecryptionError, KMSError,
    EncryptionManager
)
from ..utils.security import (
    generate_secure_random_string, compute_checksum, verify_checksum
)

# Global variables
_encryption_manager = None

# Helper functions
def get_encryption_service(use_kms: bool = None, kms_key_id: str = None) -> 'EncryptionService':
    """Factory function to get a configured encryption service instance.
    
    Args:
        use_kms: Whether to use AWS KMS (defaults to settings value)
        kms_key_id: KMS key ID (defaults to settings value)
        
    Returns:
        Configured encryption service instance
    """
    # Use settings if parameters are not provided
    if use_kms is None:
        use_kms = settings.USE_AWS_KMS
        
    if kms_key_id is None and use_kms:
        kms_key_id = settings.ENCRYPTION_KEY_ID
        
    return EncryptionService(use_kms=use_kms, kms_key_id=kms_key_id)

def get_encryption_manager(use_kms: bool = None, kms_key_id: str = None) -> EncryptionManager:
    """Factory function to get a singleton EncryptionManager instance.
    
    Args:
        use_kms: Whether to use AWS KMS (defaults to settings value)
        kms_key_id: KMS key ID (defaults to settings value)
        
    Returns:
        Singleton EncryptionManager instance
    """
    global _encryption_manager
    
    if _encryption_manager is None:
        # Use settings if parameters are not provided
        if use_kms is None:
            use_kms = settings.USE_AWS_KMS
            
        if kms_key_id is None and use_kms:
            kms_key_id = settings.ENCRYPTION_KEY_ID
            
        _encryption_manager = EncryptionManager(use_kms=use_kms, kms_key_id=kms_key_id)
        
    return _encryption_manager

def generate_user_encryption_key(user_id: str) -> bytes:
    """Generates a new encryption key for a user.
    
    Args:
        user_id: User identifier
        
    Returns:
        Generated encryption key
    """
    # Generate a random encryption key
    key = generate_encryption_key()
    
    # Log the event (without the key itself)
    logger.info(f"Generated new encryption key for user {user_id}")
    
    return key

def derive_user_key_from_password(password: str, salt: bytes = None, user_id: str = None) -> Tuple[bytes, bytes]:
    """Derives an encryption key from a user's password.
    
    Args:
        password: User password
        salt: Salt for key derivation (generated if not provided)
        user_id: User identifier for logging
        
    Returns:
        Tuple containing the derived key and salt
    """
    # Generate a new salt if not provided
    if salt is None:
        salt = generate_salt()
    
    # Derive a key from the password and salt
    key = derive_key_from_password(password, salt)
    
    # Log the event (without the key itself)
    if user_id:
        logger.info(f"Derived encryption key from password for user {user_id}")
    else:
        logger.info("Derived encryption key from password")
    
    return key, salt

def encode_for_storage(encryption_data: Dict) -> Dict:
    """Encodes binary encryption data to strings for storage.
    
    Args:
        encryption_data: Dictionary containing binary encryption data
        
    Returns:
        Dictionary with base64-encoded values
    """
    encoded_data = {}
    
    for key, value in encryption_data.items():
        if isinstance(value, bytes):
            encoded_data[key] = encode_encryption_data(value)
        else:
            encoded_data[key] = value
            
    return encoded_data

def decode_from_storage(encoded_data: Dict) -> Dict:
    """Decodes storage strings back to binary encryption data.
    
    Args:
        encoded_data: Dictionary with base64-encoded values
        
    Returns:
        Dictionary containing binary encryption data
    """
    decoded_data = {}
    
    for key, value in encoded_data.items():
        if isinstance(value, str) and key in ['encrypted_data', 'iv', 'tag', 'key', 'encrypted_key']:
            decoded_data[key] = decode_encryption_data(value)
        else:
            decoded_data[key] = value
            
    return decoded_data

# Main encryption service
class EncryptionService:
    """Service class for handling encryption operations in the application."""
    
    def __init__(self, use_kms: bool = None, kms_key_id: str = None):
        """Initialize the encryption service with configuration.
        
        Args:
            use_kms: Whether to use AWS KMS (defaults to settings value)
            kms_key_id: KMS key ID (defaults to settings value)
        """
        # Use settings if parameters are not provided
        self._use_kms = use_kms if use_kms is not None else settings.USE_AWS_KMS
        self._kms_key_id = kms_key_id if kms_key_id is not None else settings.ENCRYPTION_KEY_ID
        
        # Initialize the encryption manager
        self._encryption_manager = get_encryption_manager(self._use_kms, self._kms_key_id)
        
        logger.info(f"Initialized EncryptionService with KMS={self._use_kms}")
    
    def encrypt_data(self, data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
        """Encrypts data with authentication.
        
        Args:
            data: Data to encrypt
            key: Encryption key
            associated_data: Additional data to authenticate
            
        Returns:
            Dictionary containing encrypted data, IV, and authentication tag
        """
        # Validate input parameters
        if not data:
            raise EncryptionServiceError("No data provided for encryption")
        
        if not key:
            raise EncryptionServiceError("No encryption key provided")
        
        # Encrypt the data using the encryption manager
        result = self._encryption_manager.encrypt_data(data, key, associated_data)
        
        # Log the encryption operation (without sensitive data)
        logger.debug(f"Encrypted data: {len(data)} bytes -> {len(result['encrypted_data'])} bytes")
        
        return result
    
    def decrypt_data(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
                  associated_data: bytes = None, encrypted_key: bytes = None) -> bytes:
        """Decrypts data with authentication.
        
        Args:
            encrypted_data: Encrypted data
            key: Decryption key
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            encrypted_key: KMS-encrypted key (required if KMS is used)
            
        Returns:
            Decrypted data
        """
        # Validate input parameters
        if not encrypted_data:
            raise EncryptionServiceError("No encrypted data provided for decryption")
        
        if not key and not encrypted_key:
            raise EncryptionServiceError("No decryption key provided")
        
        if not iv:
            raise EncryptionServiceError("No initialization vector provided")
        
        if not tag:
            raise EncryptionServiceError("No authentication tag provided")
        
        # Decrypt the data using the encryption manager
        plaintext = self._encryption_manager.decrypt_data(
            encrypted_data, key, iv, tag, associated_data, encrypted_key
        )
        
        # Log the decryption operation (without sensitive data)
        logger.debug(f"Decrypted data: {len(encrypted_data)} bytes -> {len(plaintext)} bytes")
        
        return plaintext
    
    def encrypt_file(self, file_data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
        """Encrypts a file with authentication.
        
        Args:
            file_data: File data to encrypt
            key: Encryption key
            associated_data: Additional data to authenticate
            
        Returns:
            Dictionary containing encrypted file data, IV, and authentication tag
        """
        # Validate input parameters
        if not file_data:
            raise EncryptionServiceError("No file data provided for encryption")
        
        if not key:
            raise EncryptionServiceError("No encryption key provided")
        
        # Encrypt the file using the encryption manager
        result = self._encryption_manager.encrypt_file(file_data, key, associated_data)
        
        # Log the file encryption operation (without sensitive data)
        logger.debug(f"Encrypted file: {len(file_data)} bytes -> {len(result['encrypted_data'])} bytes")
        
        return result
    
    def decrypt_file(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
                   associated_data: bytes = None, encrypted_key: bytes = None) -> bytes:
        """Decrypts a file with authentication.
        
        Args:
            encrypted_data: Encrypted file data
            key: Decryption key
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            encrypted_key: KMS-encrypted key (required if KMS is used)
            
        Returns:
            Decrypted file data
        """
        # Validate input parameters
        if not encrypted_data:
            raise EncryptionServiceError("No encrypted file data provided for decryption")
        
        if not key and not encrypted_key:
            raise EncryptionServiceError("No decryption key provided")
        
        if not iv:
            raise EncryptionServiceError("No initialization vector provided")
        
        if not tag:
            raise EncryptionServiceError("No authentication tag provided")
        
        # Decrypt the file using the encryption manager
        plaintext = self._encryption_manager.decrypt_file(
            encrypted_data, key, iv, tag, associated_data, encrypted_key
        )
        
        # Log the file decryption operation (without sensitive data)
        logger.debug(f"Decrypted file: {len(encrypted_data)} bytes -> {len(plaintext)} bytes")
        
        return plaintext
    
    def generate_user_key(self, user_id: str, password: str = None, salt: bytes = None) -> Tuple[bytes, bytes]:
        """Generates or derives an encryption key for a user.
        
        Args:
            user_id: User identifier
            password: User password (if deriving key from password)
            salt: Salt for key derivation (generated if not provided)
            
        Returns:
            Tuple containing the key and salt (or None if generated)
        """
        if password:
            # Derive a key from the password
            key, salt = derive_user_key_from_password(password, salt, user_id)
            logger.info(f"Derived encryption key from password for user {user_id}")
        else:
            # Generate a random key
            key = generate_user_encryption_key(user_id)
            salt = None
            logger.info(f"Generated random encryption key for user {user_id}")
        
        return key, salt
    
    def encrypt_json(self, data: Dict, key: bytes, associated_data: bytes = None) -> Dict:
        """Encrypts JSON-serializable data.
        
        Args:
            data: JSON-serializable data to encrypt
            key: Encryption key
            associated_data: Additional data to authenticate
            
        Returns:
            Dictionary containing encrypted data with metadata
        """
        # Serialize the data to JSON
        json_str = json.dumps(data)
        
        # Convert the JSON string to bytes
        json_bytes = json_str.encode('utf-8')
        
        # Encrypt the bytes
        result = self.encrypt_data(json_bytes, key, associated_data)
        
        # Add metadata
        result['format'] = 'json'
        result['timestamp'] = datetime.datetime.utcnow().isoformat()
        
        # Log the JSON encryption operation (without sensitive data)
        logger.debug(f"Encrypted JSON data: {len(json_bytes)} bytes")
        
        return result
    
    def decrypt_json(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
                    associated_data: bytes = None, encrypted_key: bytes = None) -> Dict:
        """Decrypts and deserializes JSON data.
        
        Args:
            encrypted_data: Encrypted data
            key: Decryption key
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            encrypted_key: KMS-encrypted key (required if KMS is used)
            
        Returns:
            Decrypted and deserialized JSON data
        """
        # Decrypt the data
        plaintext = self.decrypt_data(encrypted_data, key, iv, tag, associated_data, encrypted_key)
        
        # Convert the decrypted bytes to a string
        json_str = plaintext.decode('utf-8')
        
        # Deserialize the JSON string
        data = json.loads(json_str)
        
        # Log the JSON decryption operation (without sensitive data)
        logger.debug(f"Decrypted JSON data: {len(encrypted_data)} bytes")
        
        return data
    
    def verify_data_integrity(self, encrypted_data: bytes, tag: bytes, checksum: bytes = None) -> bool:
        """Verifies the integrity of encrypted data.
        
        Args:
            encrypted_data: Encrypted data
            tag: Authentication tag
            checksum: Optional checksum for additional verification
            
        Returns:
            True if integrity check passes, False otherwise
        """
        # Verify checksum if provided
        if checksum:
            if not verify_checksum(encrypted_data, checksum):
                logger.warning("Data integrity check failed: checksum mismatch")
                return False
        
        # The authentication tag is verified during decryption, so we can't verify it separately
        # without the key and IV. This method can be extended with additional integrity checks.
        
        logger.debug("Data integrity check passed")
        return True
    
    def encode_for_storage(self, encryption_data: Dict) -> Dict:
        """Encodes binary encryption data to strings for storage.
        
        Args:
            encryption_data: Dictionary containing binary encryption data
            
        Returns:
            Dictionary with base64-encoded values
        """
        return encode_for_storage(encryption_data)
    
    def decode_from_storage(self, encoded_data: Dict) -> Dict:
        """Decodes storage strings back to binary encryption data.
        
        Args:
            encoded_data: Dictionary with base64-encoded values
            
        Returns:
            Dictionary containing binary encryption data
        """
        return decode_from_storage(encoded_data)

# Specialized encryption services
class JournalEncryptionService:
    """Specialized encryption service for voice journal recordings."""
    
    def __init__(self, use_kms: bool = None, kms_key_id: str = None):
        """Initialize the journal encryption service.
        
        Args:
            use_kms: Whether to use AWS KMS (defaults to settings value)
            kms_key_id: KMS key ID (defaults to settings value)
        """
        # Initialize the base encryption service
        self._encryption_service = EncryptionService(use_kms, kms_key_id)
        
        logger.info("Initialized JournalEncryptionService")
    
    def encrypt_journal(self, audio_data: bytes, key: bytes, user_id: str, metadata: Dict = None) -> Dict:
        """Encrypts a voice journal recording with user key.
        
        Args:
            audio_data: Voice recording data
            key: Encryption key
            user_id: User identifier
            metadata: Additional metadata to include
            
        Returns:
            Encryption result with metadata
        """
        # Prepare associated data for authentication
        associated_data = f"user:{user_id}".encode('utf-8')
        
        # Add timestamp and metadata
        timestamp = datetime.datetime.utcnow().isoformat()
        
        if metadata is None:
            metadata = {}
        
        metadata.update({
            'timestamp': timestamp,
            'user_id': user_id,
            'type': 'voice_journal'
        })
        
        # Encrypt the audio data
        result = self._encryption_service.encrypt_file(audio_data, key, associated_data)
        
        # Add metadata
        result.update(metadata)
        
        # Compute checksum for integrity verification
        checksum = compute_checksum(result['encrypted_data'])
        result['checksum'] = checksum
        
        # Log the journal encryption (without sensitive data)
        logger.info(f"Encrypted voice journal for user {user_id}: {len(audio_data)} bytes")
        
        return result
    
    def decrypt_journal(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
                      user_id: str, encrypted_key: bytes = None, checksum: bytes = None) -> bytes:
        """Decrypts a voice journal recording with user key.
        
        Args:
            encrypted_data: Encrypted voice recording
            key: Decryption key
            iv: Initialization vector
            tag: Authentication tag
            user_id: User identifier
            encrypted_key: KMS-encrypted key (required if KMS is used)
            checksum: Optional checksum for integrity verification
            
        Returns:
            Decrypted audio data
        """
        # Verify data integrity if checksum is provided
        if checksum:
            if not self._encryption_service.verify_data_integrity(encrypted_data, tag, checksum):
                raise EncryptionServiceError("Journal integrity check failed")
        
        # Prepare associated data for authentication
        associated_data = f"user:{user_id}".encode('utf-8')
        
        # Decrypt the audio data
        audio_data = self._encryption_service.decrypt_file(
            encrypted_data, key, iv, tag, associated_data, encrypted_key
        )
        
        # Log the journal decryption (without sensitive data)
        logger.info(f"Decrypted voice journal for user {user_id}: {len(audio_data)} bytes")
        
        return audio_data
    
    def prepare_journal_for_export(self, audio_data: bytes, key: bytes, user_id: str, 
                                export_format: str = 'encrypted', metadata: Dict = None) -> Dict:
        """Prepares a journal recording for export with encryption wrapper.
        
        Args:
            audio_data: Audio data to export
            key: Encryption key
            user_id: User identifier
            export_format: Format for export ('encrypted', 'mp3', 'aac')
            metadata: Additional metadata to include
            
        Returns:
            Export package with encrypted data and metadata
        """
        # Prepare export metadata
        export_id = str(uuid.uuid4())
        timestamp = datetime.datetime.utcnow().isoformat()
        
        if metadata is None:
            metadata = {}
        
        export_metadata = {
            'export_id': export_id,
            'timestamp': timestamp,
            'user_id': user_id,
            'format': export_format,
            'type': 'voice_journal_export'
        }
        export_metadata.update(metadata)
        
        # Prepare the export data
        if export_format == 'encrypted':
            # Prepare associated data for authentication
            associated_data = f"user:{user_id}:export:{export_id}".encode('utf-8')
            
            # Encrypt the audio data with export wrapper
            result = self._encryption_service.encrypt_file(audio_data, key, associated_data)
            
            # Add metadata
            result.update(export_metadata)
            
            # Compute checksum for integrity verification
            checksum = compute_checksum(result['encrypted_data'])
            result['checksum'] = checksum
        else:
            # For other formats, we would convert the audio data to the requested format
            # This is a placeholder for future implementation
            result = {
                'audio_data': audio_data,  # This would be converted to the requested format
                'format': export_format
            }
            result.update(export_metadata)
        
        # Log the export preparation (without sensitive data)
        logger.info(f"Prepared voice journal export for user {user_id} in {export_format} format")
        
        return result

class EmotionalDataEncryptionService:
    """Specialized encryption service for emotional data."""
    
    def __init__(self, use_kms: bool = None, kms_key_id: str = None):
        """Initialize the emotional data encryption service.
        
        Args:
            use_kms: Whether to use AWS KMS (defaults to settings value)
            kms_key_id: KMS key ID (defaults to settings value)
        """
        # Initialize the base encryption service
        self._encryption_service = EncryptionService(use_kms, kms_key_id)
        
        logger.info("Initialized EmotionalDataEncryptionService")
    
    def encrypt_emotional_data(self, emotional_data: Dict, key: bytes, user_id: str) -> Dict:
        """Encrypts emotional check-in data.
        
        Args:
            emotional_data: Emotional data to encrypt
            key: Encryption key
            user_id: User identifier
            
        Returns:
            Encryption result with metadata
        """
        # Prepare associated data for authentication
        associated_data = f"user:{user_id}:emotional_data".encode('utf-8')
        
        # Encrypt the emotional data
        result = self._encryption_service.encrypt_json(emotional_data, key, associated_data)
        
        # Add metadata
        result.update({
            'user_id': user_id,
            'type': 'emotional_data'
        })
        
        # Log the emotional data encryption (without sensitive data)
        logger.info(f"Encrypted emotional data for user {user_id}")
        
        return result
    
    def decrypt_emotional_data(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
                             user_id: str, encrypted_key: bytes = None) -> Dict:
        """Decrypts emotional check-in data.
        
        Args:
            encrypted_data: Encrypted emotional data
            key: Decryption key
            iv: Initialization vector
            tag: Authentication tag
            user_id: User identifier
            encrypted_key: KMS-encrypted key (required if KMS is used)
            
        Returns:
            Decrypted emotional data
        """
        # Prepare associated data for authentication
        associated_data = f"user:{user_id}:emotional_data".encode('utf-8')
        
        # Decrypt the emotional data
        emotional_data = self._encryption_service.decrypt_json(
            encrypted_data, key, iv, tag, associated_data, encrypted_key
        )
        
        # Log the emotional data decryption (without sensitive data)
        logger.info(f"Decrypted emotional data for user {user_id}")
        
        return emotional_data

# Exceptions
class EncryptionServiceError(Exception):
    """Exception class for encryption service errors."""
    
    def __init__(self, message: str):
        """Initialize the EncryptionServiceError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message