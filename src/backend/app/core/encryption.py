"""
Core encryption module for the Amira Wellness application.

This module provides end-to-end encryption functionality for sensitive user data,
particularly voice recordings. It implements AES-256-GCM encryption with authentication
and supports integration with AWS KMS for enhanced security.
"""

import os
import base64
import hashlib
import secrets
from typing import Dict, List, Optional, Tuple, Union, Any, BinaryIO

# Cryptography imports for encryption
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id

# AWS KMS integration
import boto3
from botocore.exceptions import ClientError

# Internal imports
from .config import settings
from .logging import logger

# Encryption parameters
KEY_LENGTH = 32  # 256 bits for AES-256
SALT_LENGTH = 16  # 128 bits for key derivation
IV_LENGTH = 12    # 96 bits for GCM mode
TAG_LENGTH = 16   # 128 bits for authentication tag

# Global KMS client
KMS_CLIENT = None


class EncryptionError(Exception):
    """Base exception class for encryption-related errors."""
    
    def __init__(self, message: str):
        """Initialize the EncryptionError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message


class EncryptionKeyError(EncryptionError):
    """Exception raised when there are issues with encryption keys."""
    
    def __init__(self, message: str):
        """Initialize the EncryptionKeyError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class DecryptionError(EncryptionError):
    """Exception raised when decryption fails."""
    
    def __init__(self, message: str):
        """Initialize the DecryptionError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class KMSError(EncryptionError):
    """Exception raised when AWS KMS operations fail."""
    
    def __init__(self, message: str):
        """Initialize the KMSError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


def generate_encryption_key() -> bytes:
    """Generates a random encryption key of appropriate length.
    
    Returns:
        Random encryption key
    """
    return secrets.token_bytes(KEY_LENGTH)


def generate_salt() -> bytes:
    """Generates a random salt for key derivation.
    
    Returns:
        Random salt
    """
    return secrets.token_bytes(SALT_LENGTH)


def derive_key_from_password(password: str, salt: bytes) -> bytes:
    """Derives an encryption key from a password and salt using Argon2id.
    
    Args:
        password: User password
        salt: Random salt
        
    Returns:
        Derived encryption key
        
    Raises:
        EncryptionKeyError: If key derivation fails
    """
    try:
        # Argon2id is a memory-hard KDF that is resistant to various attacks
        kdf = Argon2id(
            length=KEY_LENGTH,
            salt=salt,
            parallelism=4,
            memory_cost=65536,  # 64 MB
            time_cost=3         # 3 iterations
        )
        
        # Derive the key from the password
        key = kdf.derive(password.encode('utf-8'))
        
        return key
    except Exception as e:
        logger.error(f"Key derivation failed: {str(e)}")
        raise EncryptionKeyError(f"Failed to derive key from password: {str(e)}")


def encrypt(data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
    """Encrypts data using AES-256-GCM with authentication.
    
    Args:
        data: Data to encrypt
        key: Encryption key
        associated_data: Additional data to authenticate
        
    Returns:
        Dictionary containing encrypted data, IV, and authentication tag
        
    Raises:
        EncryptionError: If encryption fails
    """
    try:
        # Generate a random IV (nonce)
        iv = secrets.token_bytes(IV_LENGTH)
        
        # Create the AESGCM cipher with the key
        aesgcm = AESGCM(key)
        
        # Encrypt the data
        # The encrypt method returns the ciphertext with the authentication tag appended
        ciphertext_with_tag = aesgcm.encrypt(iv, data, associated_data)
        
        # The tag is the last TAG_LENGTH bytes
        ciphertext = ciphertext_with_tag[:-TAG_LENGTH]
        tag = ciphertext_with_tag[-TAG_LENGTH:]
        
        # Return the encrypted data, IV, and tag
        return {
            "encrypted_data": ciphertext,
            "iv": iv,
            "tag": tag
        }
    except Exception as e:
        logger.error(f"Encryption failed: {str(e)}")
        raise EncryptionError(f"Failed to encrypt data: {str(e)}")


def decrypt(encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes, 
           associated_data: bytes = None) -> bytes:
    """Decrypts data using AES-256-GCM with authentication.
    
    Args:
        encrypted_data: Encrypted data
        key: Decryption key
        iv: Initialization vector
        tag: Authentication tag
        associated_data: Additional authenticated data
        
    Returns:
        Decrypted data
        
    Raises:
        DecryptionError: If decryption fails
    """
    try:
        # Create the AESGCM cipher with the key
        aesgcm = AESGCM(key)
        
        # Combine ciphertext and tag for decryption
        ciphertext_with_tag = encrypted_data + tag
        
        # Decrypt the data
        plaintext = aesgcm.decrypt(iv, ciphertext_with_tag, associated_data)
        
        return plaintext
    except Exception as e:
        logger.error(f"Decryption failed: {str(e)}")
        raise DecryptionError(f"Failed to decrypt data: {str(e)}")


def encrypt_file(file_data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
    """Encrypts a file using AES-256-GCM with authentication.
    
    Args:
        file_data: File data to encrypt
        key: Encryption key
        associated_data: Additional data to authenticate
        
    Returns:
        Dictionary containing encrypted file data, IV, and authentication tag
        
    Raises:
        EncryptionError: If encryption fails
    """
    return encrypt(file_data, key, associated_data)


def decrypt_file(encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes,
                associated_data: bytes = None) -> bytes:
    """Decrypts a file using AES-256-GCM with authentication.
    
    Args:
        encrypted_data: Encrypted file data
        key: Decryption key
        iv: Initialization vector
        tag: Authentication tag
        associated_data: Additional authenticated data
        
    Returns:
        Decrypted file data
        
    Raises:
        DecryptionError: If decryption fails
    """
    return decrypt(encrypted_data, key, iv, tag, associated_data)


def get_kms_client(region_name: str = None) -> boto3.client:
    """Gets or creates an AWS KMS client.
    
    Args:
        region_name: AWS region name
        
    Returns:
        AWS KMS client
        
    Raises:
        KMSError: If KMS client creation fails
    """
    global KMS_CLIENT
    
    if KMS_CLIENT is not None:
        return KMS_CLIENT
    
    try:
        if region_name is None:
            region_name = settings.AWS_REGION
            
        KMS_CLIENT = boto3.client('kms', region_name=region_name)
        return KMS_CLIENT
    except Exception as e:
        logger.error(f"Failed to create KMS client: {str(e)}")
        raise KMSError(f"Failed to create KMS client: {str(e)}")


def encrypt_with_kms(data: bytes, key_id: str = None) -> Dict:
    """Encrypts data using AWS KMS.
    
    Args:
        data: Data to encrypt
        key_id: KMS key ID
        
    Returns:
        Dictionary containing KMS-encrypted data and encryption context
        
    Raises:
        KMSError: If KMS encryption fails
    """
    try:
        if key_id is None:
            key_id = settings.ENCRYPTION_KEY_ID
            
        if not key_id:
            raise KMSError("KMS key ID is required but not provided")
            
        kms_client = get_kms_client()
        
        # Define encryption context for additional security
        encryption_context = {
            'Application': 'AmiraWellness',
            'Purpose': 'DataEncryption'
        }
        
        response = kms_client.encrypt(
            KeyId=key_id,
            Plaintext=data,
            EncryptionContext=encryption_context
        )
        
        return {
            'ciphertext': response['CiphertextBlob'],
            'encryption_context': encryption_context
        }
    except ClientError as e:
        logger.error(f"KMS encryption failed: {str(e)}")
        raise KMSError(f"Failed to encrypt data with KMS: {str(e)}")
    except Exception as e:
        logger.error(f"KMS encryption failed: {str(e)}")
        raise KMSError(f"Unexpected error during KMS encryption: {str(e)}")


def decrypt_with_kms(encrypted_data: bytes, encryption_context: Dict = None) -> bytes:
    """Decrypts data using AWS KMS.
    
    Args:
        encrypted_data: KMS-encrypted data
        encryption_context: Encryption context used during encryption
        
    Returns:
        Decrypted data
        
    Raises:
        KMSError: If KMS decryption fails
    """
    try:
        kms_client = get_kms_client()
        
        if encryption_context is None:
            encryption_context = {
                'Application': 'AmiraWellness',
                'Purpose': 'DataEncryption'
            }
            
        response = kms_client.decrypt(
            CiphertextBlob=encrypted_data,
            EncryptionContext=encryption_context
        )
        
        return response['Plaintext']
    except ClientError as e:
        logger.error(f"KMS decryption failed: {str(e)}")
        raise KMSError(f"Failed to decrypt data with KMS: {str(e)}")
    except Exception as e:
        logger.error(f"KMS decryption failed: {str(e)}")
        raise KMSError(f"Unexpected error during KMS decryption: {str(e)}")


def encrypt_key_with_kms(key: bytes, key_id: str = None) -> bytes:
    """Encrypts a data encryption key using AWS KMS for envelope encryption.
    
    Args:
        key: Encryption key to encrypt
        key_id: KMS key ID
        
    Returns:
        KMS-encrypted key
        
    Raises:
        KMSError: If KMS encryption fails
    """
    try:
        result = encrypt_with_kms(key, key_id)
        return result['ciphertext']
    except Exception as e:
        logger.error(f"KMS key encryption failed: {str(e)}")
        raise KMSError(f"Failed to encrypt key with KMS: {str(e)}")


def decrypt_key_with_kms(encrypted_key: bytes) -> bytes:
    """Decrypts a data encryption key using AWS KMS for envelope encryption.
    
    Args:
        encrypted_key: KMS-encrypted key
        
    Returns:
        Decrypted key
        
    Raises:
        KMSError: If KMS decryption fails
    """
    try:
        return decrypt_with_kms(encrypted_key)
    except Exception as e:
        logger.error(f"KMS key decryption failed: {str(e)}")
        raise KMSError(f"Failed to decrypt key with KMS: {str(e)}")


def encode_encryption_data(data: bytes) -> str:
    """Encodes binary encryption data to base64 strings for storage.
    
    Args:
        data: Binary data to encode
        
    Returns:
        Base64-encoded string
    """
    return base64.b64encode(data).decode('utf-8')


def decode_encryption_data(encoded_data: str) -> bytes:
    """Decodes base64 strings back to binary encryption data.
    
    Args:
        encoded_data: Base64-encoded string
        
    Returns:
        Decoded binary data
    """
    return base64.b64decode(encoded_data)


class EncryptionManager:
    """Manager class for encryption operations with support for different encryption methods."""
    
    def __init__(self, use_kms: bool = None, kms_key_id: str = None):
        """Initialize the EncryptionManager with configuration.
        
        Args:
            use_kms: Whether to use AWS KMS (defaults to settings value)
            kms_key_id: KMS key ID (defaults to settings value)
        """
        # Use settings if parameters are not provided
        self._use_kms = use_kms if use_kms is not None else settings.USE_AWS_KMS
        self._kms_key_id = kms_key_id if kms_key_id is not None else settings.ENCRYPTION_KEY_ID
        
        logger.info(f"Initialized EncryptionManager with KMS={self._use_kms}")
        
    def encrypt_data(self, data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
        """Encrypts data using the configured encryption method.
        
        Args:
            data: Data to encrypt
            key: Encryption key
            associated_data: Additional data to authenticate
            
        Returns:
            Dictionary containing encrypted data and metadata
            
        Raises:
            EncryptionError: If encryption fails
        """
        try:
            if not data:
                raise EncryptionError("No data provided for encryption")
                
            if not key or len(key) != KEY_LENGTH:
                raise EncryptionKeyError(f"Invalid encryption key (expected {KEY_LENGTH} bytes)")
                
            # Encrypt the data using AES-GCM
            encryption_result = encrypt(data, key, associated_data)
            
            result = {
                "encrypted_data": encryption_result["encrypted_data"],
                "iv": encryption_result["iv"],
                "tag": encryption_result["tag"]
            }
            
            # If KMS is enabled, encrypt the data encryption key
            if self._use_kms:
                encrypted_key = encrypt_key_with_kms(key, self._kms_key_id)
                result["encrypted_key"] = encrypted_key
                
            return result
        except EncryptionError:
            # Re-raise existing encryption errors
            raise
        except Exception as e:
            logger.error(f"Encryption failed: {str(e)}")
            raise EncryptionError(f"Failed to encrypt data: {str(e)}")
    
    def decrypt_data(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes,
                   associated_data: bytes = None, encrypted_key: bytes = None) -> bytes:
        """Decrypts data using the configured encryption method.
        
        Args:
            encrypted_data: Encrypted data
            key: Decryption key (or None if encrypted_key is provided with KMS)
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            encrypted_key: KMS-encrypted key (required if _use_kms is True)
            
        Returns:
            Decrypted data
            
        Raises:
            DecryptionError: If decryption fails
        """
        try:
            if not encrypted_data:
                raise DecryptionError("No encrypted data provided for decryption")
                
            # If KMS is enabled and encrypted_key is provided, decrypt the key
            if self._use_kms and encrypted_key:
                key = decrypt_key_with_kms(encrypted_key)
                
            if not key or len(key) != KEY_LENGTH:
                raise EncryptionKeyError(f"Invalid decryption key (expected {KEY_LENGTH} bytes)")
                
            if not iv or len(iv) != IV_LENGTH:
                raise DecryptionError(f"Invalid IV (expected {IV_LENGTH} bytes)")
                
            if not tag or len(tag) != TAG_LENGTH:
                raise DecryptionError(f"Invalid authentication tag (expected {TAG_LENGTH} bytes)")
                
            # Decrypt the data using AES-GCM
            return decrypt(encrypted_data, key, iv, tag, associated_data)
        except (EncryptionError, DecryptionError, KMSError):
            # Re-raise existing encryption errors
            raise
        except Exception as e:
            logger.error(f"Decryption failed: {str(e)}")
            raise DecryptionError(f"Failed to decrypt data: {str(e)}")
    
    def encrypt_file(self, file_data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
        """Encrypts a file using the configured encryption method.
        
        Args:
            file_data: File data to encrypt
            key: Encryption key
            associated_data: Additional data to authenticate
            
        Returns:
            Dictionary containing encrypted file data and metadata
            
        Raises:
            EncryptionError: If encryption fails
        """
        return self.encrypt_data(file_data, key, associated_data)
    
    def decrypt_file(self, encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes,
                    associated_data: bytes = None, encrypted_key: bytes = None) -> bytes:
        """Decrypts a file using the configured encryption method.
        
        Args:
            encrypted_data: Encrypted file data
            key: Decryption key (or None if encrypted_key is provided with KMS)
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            encrypted_key: KMS-encrypted key (required if _use_kms is True)
            
        Returns:
            Decrypted file data
            
        Raises:
            DecryptionError: If decryption fails
        """
        return self.decrypt_data(encrypted_data, key, iv, tag, associated_data, encrypted_key)
    
    def generate_user_key(self, password: str, salt: bytes = None) -> Tuple[bytes, bytes]:
        """Generates or derives an encryption key for a user.
        
        Args:
            password: User password
            salt: Salt for key derivation (generated if not provided)
            
        Returns:
            Tuple containing the derived key and salt
            
        Raises:
            EncryptionKeyError: If key generation fails
        """
        try:
            # Generate a new salt if not provided
            if salt is None:
                salt = generate_salt()
                
            # Derive a key from the password
            key = derive_key_from_password(password, salt)
            
            return key, salt
        except Exception as e:
            logger.error(f"User key generation failed: {str(e)}")
            raise EncryptionKeyError(f"Failed to generate user key: {str(e)}")