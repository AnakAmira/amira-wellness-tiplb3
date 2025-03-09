"""
Security utilities module for the Amira Wellness application.

This module provides utility functions and classes for security operations,
including encryption, hashing, secure random generation, and data integrity
verification. It serves as a bridge between core security modules and
application-specific security needs, supporting the privacy-first approach
of the application.
"""

import os  # standard library
import hashlib  # standard library
import hmac  # standard library
import base64  # standard library
import secrets  # standard library
import uuid  # standard library
from typing import Union, Dict, Any, Optional, Tuple, List  # standard library

# Internal imports
from ..core.logging import logger
from ..core.config import settings
from ..core.encryption import (
    encrypt, decrypt, encode_encryption_data, decode_encryption_data, EncryptionError
)

# Global constants
HASH_ALGORITHM = 'sha256'
HMAC_ALGORITHM = 'sha256'
SECURE_FILENAME_LENGTH = 32


class SecurityError(Exception):
    """Base exception class for security-related errors."""
    
    def __init__(self, message: str):
        """Initialize the SecurityError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message


class IntegrityError(SecurityError):
    """Exception raised when data integrity verification fails."""
    
    def __init__(self, message: str):
        """Initialize the IntegrityError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class PathTraversalError(SecurityError):
    """Exception raised when a path traversal attack is detected."""
    
    def __init__(self, message: str):
        """Initialize the PathTraversalError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


def generate_secure_random(length: int) -> bytes:
    """Generates cryptographically secure random bytes.
    
    Args:
        length: Length of random bytes to generate
        
    Returns:
        Secure random bytes of specified length
    """
    return secrets.token_bytes(length)


def generate_secure_random_string(length: int) -> str:
    """Generates a cryptographically secure random string.
    
    Args:
        length: Length of random string to generate
        
    Returns:
        Secure random string of specified length
    """
    # Use token_urlsafe which produces about 4/3 characters per byte
    # Truncate or pad to get exact length
    random_string = secrets.token_urlsafe(length)
    
    # Adjust to the exact length requested
    if len(random_string) < length:
        # This is unlikely to happen but handles the case for completeness
        random_string += secrets.token_urlsafe(length - len(random_string))
    
    return random_string[:length]


def generate_secure_filename(prefix: str = "", extension: str = "") -> str:
    """Generates a secure random filename with optional prefix and extension.
    
    Args:
        prefix: Optional prefix for the filename
        extension: Optional file extension
        
    Returns:
        Secure random filename
    """
    # Generate a secure random string for the filename
    filename = generate_secure_random_string(SECURE_FILENAME_LENGTH)
    
    # Add extension if provided
    if extension:
        # Ensure extension starts with a dot
        if not extension.startswith('.'):
            extension = f".{extension}"
        filename = f"{filename}{extension}"
    
    # Add prefix if provided
    if prefix:
        filename = f"{prefix}{filename}"
    
    return filename


def compute_checksum(data: bytes, algorithm: str = HASH_ALGORITHM) -> str:
    """Computes a checksum hash of data for integrity verification.
    
    Args:
        data: Data to hash
        algorithm: Hash algorithm to use (default: SHA-256)
        
    Returns:
        Hexadecimal checksum string
    """
    hash_obj = hashlib.new(algorithm)
    hash_obj.update(data)
    return hash_obj.hexdigest()


def verify_checksum(data: bytes, expected_checksum: str, algorithm: str = HASH_ALGORITHM) -> bool:
    """Verifies that data matches a previously computed checksum.
    
    Args:
        data: Data to verify
        expected_checksum: Previously computed checksum to compare against
        algorithm: Hash algorithm to use (default: SHA-256)
        
    Returns:
        True if checksum matches, False otherwise
    """
    computed_checksum = compute_checksum(data, algorithm)
    return secure_compare(computed_checksum, expected_checksum)


def create_hmac(data: bytes, key: bytes, algorithm: str = HMAC_ALGORITHM) -> bytes:
    """Creates an HMAC for data authentication.
    
    Args:
        data: Data to authenticate
        key: HMAC key
        algorithm: HMAC algorithm to use (default: SHA-256)
        
    Returns:
        HMAC digest
    """
    return hmac.new(key, data, algorithm).digest()


def verify_hmac(data: bytes, key: bytes, expected_hmac: bytes, 
               algorithm: str = HMAC_ALGORITHM) -> bool:
    """Verifies an HMAC for data authentication.
    
    Args:
        data: Data to verify
        key: HMAC key
        expected_hmac: Expected HMAC digest
        algorithm: HMAC algorithm to use (default: SHA-256)
        
    Returns:
        True if HMAC is valid, False otherwise
    """
    computed_hmac = create_hmac(data, key, algorithm)
    return hmac.compare_digest(computed_hmac, expected_hmac)


def encrypt_data(data: bytes, key: bytes, associated_data: bytes = None) -> Dict:
    """Encrypts data with additional authentication data.
    
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
        # Call the core encrypt function from the encryption module
        return encrypt(data, key, associated_data)
    except EncryptionError:
        # Re-raise the original exception
        raise
    except Exception as e:
        # Log and wrap other exceptions
        logger.error(f"Encryption failed: {str(e)}")
        raise EncryptionError(f"Failed to encrypt data: {str(e)}")


def decrypt_data(encrypted_data: bytes, key: bytes, iv: bytes, tag: bytes,
                associated_data: bytes = None) -> bytes:
    """Decrypts data with authentication.
    
    Args:
        encrypted_data: Encrypted data
        key: Decryption key
        iv: Initialization vector
        tag: Authentication tag
        associated_data: Additional authenticated data
        
    Returns:
        Decrypted data
        
    Raises:
        EncryptionError: If decryption fails
    """
    try:
        # Call the core decrypt function from the encryption module
        return decrypt(encrypted_data, key, iv, tag, associated_data)
    except EncryptionError:
        # Re-raise the original exception
        raise
    except Exception as e:
        # Log and wrap other exceptions
        logger.error(f"Decryption failed: {str(e)}")
        raise EncryptionError(f"Failed to decrypt data: {str(e)}")


def encode_binary_to_base64(data: bytes) -> str:
    """Encodes binary data to base64 string.
    
    Args:
        data: Binary data to encode
        
    Returns:
        Base64-encoded string
    """
    return base64.b64encode(data).decode('utf-8')


def decode_base64_to_binary(encoded_data: str) -> bytes:
    """Decodes base64 string to binary data.
    
    Args:
        encoded_data: Base64-encoded string
        
    Returns:
        Decoded binary data
    """
    return base64.b64decode(encoded_data)


def secure_compare(a: Union[str, bytes], b: Union[str, bytes]) -> bool:
    """Performs a constant-time comparison of two strings or bytes to prevent timing attacks.
    
    Args:
        a: First string or bytes to compare
        b: Second string or bytes to compare
        
    Returns:
        True if equal, False otherwise
    """
    # Ensure both values are bytes
    if isinstance(a, str):
        a = a.encode('utf-8')
    if isinstance(b, str):
        b = b.encode('utf-8')
    
    # Use hmac.compare_digest for constant-time comparison
    return hmac.compare_digest(a, b)


def generate_uuid() -> str:
    """Generates a random UUID.
    
    Returns:
        String representation of a UUID
    """
    return str(uuid.uuid4())


def sanitize_filename(filename: str) -> str:
    """Sanitizes a filename to prevent path traversal and other attacks.
    
    Args:
        filename: Filename to sanitize
        
    Returns:
        Sanitized filename
        
    Raises:
        SecurityError: If filename is invalid or dangerous
    """
    if not filename:
        raise SecurityError("Empty filename provided")
    
    # Remove any directory traversal components
    # Get the basename only, no paths
    filename = os.path.basename(filename)
    
    # Remove any potentially dangerous characters
    # Allow only alphanumeric, dash, underscore, and period
    sanitized = ''.join(c for c in filename if c.isalnum() or c in '-_.')
    
    if not sanitized:
        raise SecurityError("Filename contains only invalid characters")
    
    # Limit the length of the filename
    if len(sanitized) > 255:  # Common filename length limit on many file systems
        sanitized = sanitized[:255]
    
    return sanitized


def sanitize_path(path: str, base_directory: str) -> str:
    """Sanitizes a file path to prevent path traversal attacks.
    
    Args:
        path: Path to sanitize
        base_directory: Base directory that the path must be within
        
    Returns:
        Sanitized absolute path
        
    Raises:
        PathTraversalError: If path traversal is detected
        SecurityError: If the path is invalid
    """
    if not path:
        raise SecurityError("Empty path provided")
    
    if not base_directory:
        raise SecurityError("Base directory not provided")
    
    # Convert to absolute paths
    base_directory = os.path.abspath(base_directory)
    path = os.path.abspath(os.path.join(base_directory, path))
    
    # Check if the resolved path is within the base directory
    if not path.startswith(base_directory):
        logger.warning(f"Path traversal attempt detected: {path}")
        raise PathTraversalError(f"Path traversal detected. Path must be within {base_directory}")
    
    return path


def is_secure_password(password: str) -> bool:
    """Checks if a password meets security requirements.
    
    Args:
        password: Password to check
        
    Returns:
        True if password is secure, False otherwise
    """
    if not password:
        return False
    
    # Check minimum length (10 characters)
    if len(password) < 10:
        return False
    
    # Check for presence of uppercase letters
    if not any(c.isupper() for c in password):
        return False
    
    # Check for presence of lowercase letters
    if not any(c.islower() for c in password):
        return False
    
    # Check for presence of digits
    if not any(c.isdigit() for c in password):
        return False
    
    # Check for presence of special characters
    special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?/~`'\""
    if not any(c in special_chars for c in password):
        return False
    
    return True


class DataEncryptor:
    """Helper class for data encryption operations."""
    
    def __init__(self, key: bytes):
        """Initialize the DataEncryptor with an encryption key.
        
        Args:
            key: Encryption key
            
        Raises:
            EncryptionError: If the key is invalid
        """
        # Validate key length (32 bytes for AES-256)
        if not key or len(key) != 32:
            raise EncryptionError("Invalid encryption key. Must be 32 bytes for AES-256.")
        
        # Store the encryption key securely
        self._key = key
    
    def encrypt(self, data: bytes, associated_data: bytes = None) -> Dict:
        """Encrypt data with the stored key.
        
        Args:
            data: Data to encrypt
            associated_data: Additional data to authenticate
            
        Returns:
            Encryption result with ciphertext, IV, and tag
            
        Raises:
            EncryptionError: If encryption fails
        """
        return encrypt_data(data, self._key, associated_data)
    
    def decrypt(self, encrypted_data: bytes, iv: bytes, tag: bytes, 
               associated_data: bytes = None) -> bytes:
        """Decrypt data with the stored key.
        
        Args:
            encrypted_data: Encrypted data
            iv: Initialization vector
            tag: Authentication tag
            associated_data: Additional authenticated data
            
        Returns:
            Decrypted data
            
        Raises:
            EncryptionError: If decryption fails
        """
        return decrypt_data(encrypted_data, self._key, iv, tag, associated_data)
    
    def encrypt_json(self, data: Dict, associated_data: bytes = None) -> Dict:
        """Encrypt JSON-serializable data.
        
        Args:
            data: JSON-serializable data to encrypt
            associated_data: Additional data to authenticate
            
        Returns:
            Encryption result with encoded components
            
        Raises:
            EncryptionError: If encryption fails
        """
        import json
        
        try:
            # Convert the JSON data to a string
            json_str = json.dumps(data)
            # Encode the string to bytes
            json_bytes = json_str.encode('utf-8')
            
            # Encrypt the bytes
            encryption_result = self.encrypt(json_bytes, associated_data)
            
            # Encode binary components to base64 for storage
            return {
                "encrypted_data": encode_binary_to_base64(encryption_result["encrypted_data"]),
                "iv": encode_binary_to_base64(encryption_result["iv"]),
                "tag": encode_binary_to_base64(encryption_result["tag"])
            }
        except Exception as e:
            logger.error(f"JSON encryption failed: {str(e)}")
            raise EncryptionError(f"Failed to encrypt JSON data: {str(e)}")
    
    def decrypt_json(self, encrypted_data: Dict, associated_data: bytes = None) -> Dict:
        """Decrypt and deserialize JSON data.
        
        Args:
            encrypted_data: Encryption result with encoded components
            associated_data: Additional authenticated data
            
        Returns:
            Decrypted JSON data
            
        Raises:
            EncryptionError: If decryption fails
        """
        import json
        
        try:
            # Decode base64 components to binary
            binary_encrypted_data = decode_base64_to_binary(encrypted_data["encrypted_data"])
            binary_iv = decode_base64_to_binary(encrypted_data["iv"])
            binary_tag = decode_base64_to_binary(encrypted_data["tag"])
            
            # Decrypt the data
            decrypted_bytes = self.decrypt(
                binary_encrypted_data, binary_iv, binary_tag, associated_data
            )
            
            # Decode the bytes to a string
            json_str = decrypted_bytes.decode('utf-8')
            
            # Parse the string as JSON
            return json.loads(json_str)
        except Exception as e:
            logger.error(f"JSON decryption failed: {str(e)}")
            raise EncryptionError(f"Failed to decrypt JSON data: {str(e)}")


class SecureFileHandler:
    """Helper class for secure file operations."""
    
    def __init__(self, base_directory: str):
        """Initialize the SecureFileHandler with a base directory.
        
        Args:
            base_directory: Base directory for file operations
            
        Raises:
            SecurityError: If the base directory is invalid
        """
        if not base_directory:
            raise SecurityError("Base directory not provided")
        
        # Ensure the base directory exists
        if not os.path.exists(base_directory):
            try:
                os.makedirs(base_directory, exist_ok=True)
            except Exception as e:
                raise SecurityError(f"Failed to create base directory: {str(e)}")
        
        # Validate the base directory is secure
        self._base_directory = os.path.abspath(base_directory)
    
    def secure_read(self, file_path: str, mode: str = "rb") -> bytes:
        """Securely read a file with path validation.
        
        Args:
            file_path: Path to the file to read
            mode: File opening mode
            
        Returns:
            File contents
            
        Raises:
            SecurityError: If the file path is invalid
            FileNotFoundError: If the file does not exist
            IOError: If there is an error reading the file
        """
        # Sanitize the path
        safe_path = sanitize_path(file_path, self._base_directory)
        
        # Ensure the file exists
        if not os.path.isfile(safe_path):
            raise FileNotFoundError(f"File not found: {safe_path}")
        
        # Read the file
        try:
            with open(safe_path, mode) as f:
                return f.read()
        except Exception as e:
            logger.error(f"File read error: {str(e)}")
            raise IOError(f"Failed to read file: {str(e)}")
    
    def secure_write(self, file_path: str, data: bytes, mode: str = "wb") -> int:
        """Securely write data to a file with path validation.
        
        Args:
            file_path: Path to the file to write
            data: Data to write
            mode: File opening mode
            
        Returns:
            Number of bytes written
            
        Raises:
            SecurityError: If the file path is invalid
            IOError: If there is an error writing the file
        """
        # Sanitize the path
        safe_path = sanitize_path(file_path, self._base_directory)
        
        # Ensure the directory exists
        directory = os.path.dirname(safe_path)
        if not os.path.exists(directory):
            try:
                os.makedirs(directory, exist_ok=True)
            except Exception as e:
                raise IOError(f"Failed to create directory: {str(e)}")
        
        # Write the file
        try:
            with open(safe_path, mode) as f:
                return f.write(data)
        except Exception as e:
            logger.error(f"File write error: {str(e)}")
            raise IOError(f"Failed to write file: {str(e)}")
    
    def secure_delete(self, file_path: str) -> bool:
        """Securely delete a file with path validation.
        
        Args:
            file_path: Path to the file to delete
            
        Returns:
            True if deletion was successful
            
        Raises:
            SecurityError: If the file path is invalid
            FileNotFoundError: If the file does not exist
            IOError: If there is an error deleting the file
        """
        # Sanitize the path
        safe_path = sanitize_path(file_path, self._base_directory)
        
        # Ensure the file exists
        if not os.path.isfile(safe_path):
            raise FileNotFoundError(f"File not found: {safe_path}")
        
        # Delete the file
        try:
            os.remove(safe_path)
            return True
        except Exception as e:
            logger.error(f"File deletion error: {str(e)}")
            raise IOError(f"Failed to delete file: {str(e)}")
    
    def secure_path_join(self, base: str, path: str) -> str:
        """Securely join path components.
        
        Args:
            base: Base directory or path
            path: Path component to join
            
        Returns:
            Secure joined path
            
        Raises:
            SecurityError: If the joined path is invalid
        """
        # Join the path components
        joined_path = os.path.join(base, path)
        
        # Sanitize the resulting path
        return sanitize_path(joined_path, self._base_directory)