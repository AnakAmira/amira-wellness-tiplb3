"""
Low-level utility module for file storage operations in the Amira Wellness application.

This module provides functions for local file system operations and AWS S3 cloud storage
integration, supporting the secure storage of voice journal recordings and other application
data with encryption capabilities.
"""

import os
import shutil
from pathlib import Path
import json
import uuid
from typing import Dict, List, Optional, Tuple, Union, BinaryIO, Any

import boto3  # version: 1.28+
from botocore.exceptions import ClientError  # version: 1.31+

from ..core.logging import logger, info, error, debug
from ..core.config import settings
from ..core.encryption import encode_encryption_data, decode_encryption_data

# Default local storage directory (under user's home directory)
DEFAULT_STORAGE_DIR = os.path.join(os.path.expanduser('~'), '.amira', 'storage')

# Global S3 client
S3_CLIENT = None


class StorageError(Exception):
    """Base exception class for storage-related errors."""
    
    def __init__(self, message: str):
        """Initialize the StorageError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message


class LocalStorageError(StorageError):
    """Exception raised when local storage operations fail."""
    
    def __init__(self, message: str):
        """Initialize the LocalStorageError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


class CloudStorageError(StorageError):
    """Exception raised when cloud storage operations fail."""
    
    def __init__(self, message: str):
        """Initialize the CloudStorageError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)


def save_file_locally(file_data: bytes, file_path: str, create_dirs: bool = True) -> str:
    """Saves a file to the local filesystem.
    
    Args:
        file_data: Binary data to write to the file
        file_path: Path where the file should be saved
        create_dirs: Whether to create parent directories if they don't exist
        
    Returns:
        Absolute path to the saved file
        
    Raises:
        LocalStorageError: If saving the file fails
    """
    try:
        # Convert to absolute path
        abs_path = os.path.abspath(file_path)
        
        # Create directory if it doesn't exist
        if create_dirs:
            directory = os.path.dirname(abs_path)
            os.makedirs(directory, exist_ok=True)
        
        # Write file
        with open(abs_path, 'wb') as f:
            f.write(file_data)
            
        logger.info(f"File saved successfully to {abs_path}")
        return abs_path
    except (IOError, OSError) as e:
        error_msg = f"Failed to save file to {file_path}: {str(e)}"
        logger.error(error_msg)
        raise LocalStorageError(error_msg)


def load_file_locally(file_path: str) -> bytes:
    """Loads a file from the local filesystem.
    
    Args:
        file_path: Path to the file to load
        
    Returns:
        File data as bytes
        
    Raises:
        LocalStorageError: If loading the file fails
    """
    try:
        # Convert to absolute path
        abs_path = os.path.abspath(file_path)
        
        # Check if file exists
        if not os.path.isfile(abs_path):
            raise FileNotFoundError(f"File not found: {abs_path}")
        
        # Read file
        with open(abs_path, 'rb') as f:
            data = f.read()
            
        logger.debug(f"File loaded successfully from {abs_path}")
        return data
    except (IOError, OSError, FileNotFoundError) as e:
        error_msg = f"Failed to load file from {file_path}: {str(e)}"
        logger.error(error_msg)
        raise LocalStorageError(error_msg)


def delete_file_locally(file_path: str) -> bool:
    """Deletes a file from the local filesystem.
    
    Args:
        file_path: Path to the file to delete
        
    Returns:
        True if deletion was successful, False otherwise
        
    Raises:
        LocalStorageError: If deleting the file fails
    """
    try:
        # Convert to absolute path
        abs_path = os.path.abspath(file_path)
        
        # Check if file exists
        if not os.path.isfile(abs_path):
            logger.warning(f"File not found for deletion: {abs_path}")
            return False
        
        # Delete file
        os.remove(abs_path)
        
        logger.debug(f"File deleted successfully: {abs_path}")
        return True
    except (IOError, OSError) as e:
        error_msg = f"Failed to delete file {file_path}: {str(e)}"
        logger.error(error_msg)
        raise LocalStorageError(error_msg)


def ensure_directory_exists(directory_path: str) -> str:
    """Ensures that a directory exists, creating it if necessary.
    
    Args:
        directory_path: Path to the directory
        
    Returns:
        Absolute path to the directory
        
    Raises:
        LocalStorageError: If creating the directory fails
    """
    try:
        # Convert to absolute path
        abs_path = os.path.abspath(directory_path)
        
        # Create directory if it doesn't exist
        if not os.path.exists(abs_path):
            os.makedirs(abs_path, exist_ok=True)
            logger.debug(f"Directory created: {abs_path}")
        
        return abs_path
    except (IOError, OSError) as e:
        error_msg = f"Failed to create directory {directory_path}: {str(e)}"
        logger.error(error_msg)
        raise LocalStorageError(error_msg)


def get_s3_client(region_name: str = None) -> boto3.client:
    """Gets or creates an AWS S3 client.
    
    Args:
        region_name: AWS region name (uses settings.AWS_REGION if not provided)
        
    Returns:
        AWS S3 client
        
    Raises:
        CloudStorageError: If creating the S3 client fails
    """
    global S3_CLIENT
    
    try:
        # Return existing client if available
        if S3_CLIENT is not None:
            return S3_CLIENT
        
        # Use settings if region not provided
        if region_name is None:
            region_name = settings.AWS_REGION
        
        # Create new client
        S3_CLIENT = boto3.client('s3', region_name=region_name)
        
        logger.debug(f"S3 client created for region {region_name}")
        return S3_CLIENT
    except Exception as e:
        error_msg = f"Failed to create S3 client: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def upload_to_s3(file_data: bytes, s3_key: str, bucket_name: str = None, 
                 metadata: Dict = None, content_type: str = None) -> Dict:
    """Uploads a file to AWS S3.
    
    Args:
        file_data: Binary data to upload
        s3_key: S3 object key (path in the bucket)
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        metadata: Optional metadata to store with the object
        content_type: Optional content type (MIME type)
        
    Returns:
        Dictionary containing upload status and details
        
    Raises:
        CloudStorageError: If uploading fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Prepare upload parameters
        upload_args = {
            'Bucket': bucket_name,
            'Key': s3_key,
            'Body': file_data
        }
        
        # Add metadata if provided
        if metadata:
            # Ensure all metadata values are strings
            string_metadata = {k: str(v) for k, v in metadata.items()}
            upload_args['Metadata'] = string_metadata
        
        # Add content type if provided
        if content_type:
            upload_args['ContentType'] = content_type
        elif s3_key:
            # Try to determine content type from the key (filename)
            detected_content_type = get_content_type(s3_key)
            if detected_content_type:
                upload_args['ContentType'] = detected_content_type
        
        # Upload file
        s3_client.put_object(**upload_args)
        
        logger.info(f"File uploaded successfully to s3://{bucket_name}/{s3_key}")
        
        # Return success result
        return {
            'status': 'success',
            'bucket': bucket_name,
            'key': s3_key,
            'size': len(file_data),
            'content_type': upload_args.get('ContentType')
        }
    except ClientError as e:
        error_msg = f"S3 upload failed for {s3_key}: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to upload file to S3: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def download_from_s3(s3_key: str, bucket_name: str = None) -> Dict:
    """Downloads a file from AWS S3.
    
    Args:
        s3_key: S3 object key (path in the bucket)
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        
    Returns:
        Dictionary containing file data and metadata
        
    Raises:
        CloudStorageError: If downloading fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Download file
        response = s3_client.get_object(Bucket=bucket_name, Key=s3_key)
        
        # Read file data
        file_data = response['Body'].read()
        
        logger.debug(f"File downloaded successfully from s3://{bucket_name}/{s3_key}")
        
        # Return data and metadata
        return {
            'data': file_data,
            'metadata': response.get('Metadata', {}),
            'content_type': response.get('ContentType'),
            'size': response.get('ContentLength'),
            'last_modified': response.get('LastModified')
        }
    except ClientError as e:
        error_msg = f"S3 download failed for {s3_key}: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to download file from S3: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def delete_from_s3(s3_key: str, bucket_name: str = None) -> bool:
    """Deletes a file from AWS S3.
    
    Args:
        s3_key: S3 object key (path in the bucket)
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        
    Returns:
        True if deletion was successful
        
    Raises:
        CloudStorageError: If deletion fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Delete file
        s3_client.delete_object(Bucket=bucket_name, Key=s3_key)
        
        logger.info(f"File deleted successfully from s3://{bucket_name}/{s3_key}")
        return True
    except ClientError as e:
        error_msg = f"S3 deletion failed for {s3_key}: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to delete file from S3: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def list_s3_objects(bucket_name: str = None, prefix: str = "") -> List[str]:
    """Lists objects in an AWS S3 bucket with optional prefix.
    
    Args:
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        prefix: Optional prefix to filter objects (like a directory path)
        
    Returns:
        List of S3 object keys
        
    Raises:
        CloudStorageError: If listing fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Initialize result list and pagination
        all_keys = []
        continuation_token = None
        
        # Get objects with pagination
        while True:
            # Prepare list parameters
            list_args = {
                'Bucket': bucket_name,
                'Prefix': prefix
            }
            
            # Add continuation token if we have one
            if continuation_token:
                list_args['ContinuationToken'] = continuation_token
            
            # List objects
            response = s3_client.list_objects_v2(**list_args)
            
            # Process results
            if 'Contents' in response:
                all_keys.extend([item['Key'] for item in response['Contents']])
            
            # Check if there are more results to fetch
            if not response.get('IsTruncated'):
                break
            
            continuation_token = response.get('NextContinuationToken')
        
        logger.debug(f"Listed {len(all_keys)} objects from s3://{bucket_name}/{prefix}")
        return all_keys
    except ClientError as e:
        error_msg = f"S3 list operation failed: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to list objects from S3: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def generate_presigned_url(s3_key: str, bucket_name: str = None, 
                          operation: str = 'get_object', expiration: int = 3600,
                          params: Dict = None) -> str:
    """Generates a presigned URL for temporary S3 object access.
    
    Args:
        s3_key: S3 object key (path in the bucket)
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        operation: S3 operation ('get_object', 'put_object', etc.)
        expiration: URL expiration time in seconds (default: 1 hour)
        params: Additional parameters for the operation
        
    Returns:
        Presigned URL for the specified operation
        
    Raises:
        CloudStorageError: If URL generation fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Prepare parameters
        url_params = {
            'Bucket': bucket_name,
            'Key': s3_key
        }
        
        # Add additional parameters if provided
        if params:
            url_params.update(params)
        
        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            ClientMethod=operation,
            Params=url_params,
            ExpiresIn=expiration
        )
        
        logger.debug(f"Generated presigned URL for s3://{bucket_name}/{s3_key} " +
                    f"with expiration of {expiration} seconds")
        return presigned_url
    except ClientError as e:
        error_msg = f"Failed to generate presigned URL for {s3_key}: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to generate presigned URL: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def get_file_metadata(s3_key: str, bucket_name: str = None) -> Dict:
    """Gets metadata for a file in S3.
    
    Args:
        s3_key: S3 object key (path in the bucket)
        bucket_name: S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        
    Returns:
        Dictionary containing file metadata
        
    Raises:
        CloudStorageError: If metadata retrieval fails
    """
    try:
        # Use settings if bucket not provided
        if bucket_name is None:
            bucket_name = settings.S3_BUCKET_NAME
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Get object metadata
        response = s3_client.head_object(Bucket=bucket_name, Key=s3_key)
        
        # Extract metadata
        metadata = {
            'size': response.get('ContentLength'),
            'content_type': response.get('ContentType'),
            'last_modified': response.get('LastModified'),
            'e_tag': response.get('ETag'),
            'custom_metadata': response.get('Metadata', {})
        }
        
        logger.debug(f"Retrieved metadata for s3://{bucket_name}/{s3_key}")
        return metadata
    except ClientError as e:
        error_msg = f"Failed to get metadata for {s3_key}: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to get file metadata: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def copy_s3_object(source_key: str, destination_key: str, 
                  source_bucket: str = None, destination_bucket: str = None) -> bool:
    """Copies an object within S3 or between buckets.
    
    Args:
        source_key: Source S3 object key
        destination_key: Destination S3 object key
        source_bucket: Source S3 bucket name (uses settings.S3_BUCKET_NAME if not provided)
        destination_bucket: Destination S3 bucket name (uses source_bucket if not provided)
        
    Returns:
        True if copy was successful
        
    Raises:
        CloudStorageError: If copy operation fails
    """
    try:
        # Use settings if buckets not provided
        if source_bucket is None:
            source_bucket = settings.S3_BUCKET_NAME
        
        if destination_bucket is None:
            destination_bucket = source_bucket
        
        # Get S3 client
        s3_client = get_s3_client()
        
        # Prepare copy source
        copy_source = {
            'Bucket': source_bucket,
            'Key': source_key
        }
        
        # Copy object
        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=destination_bucket,
            Key=destination_key
        )
        
        logger.info(f"Copied s3://{source_bucket}/{source_key} to " +
                   f"s3://{destination_bucket}/{destination_key}")
        return True
    except ClientError as e:
        error_msg = f"S3 copy operation failed: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)
    except Exception as e:
        error_msg = f"Failed to copy S3 object: {str(e)}"
        logger.error(error_msg)
        raise CloudStorageError(error_msg)


def generate_unique_filename(prefix: str = "", extension: str = "") -> str:
    """Generates a unique filename with optional prefix and extension.
    
    Args:
        prefix: Optional prefix for the filename
        extension: Optional file extension (without dot)
        
    Returns:
        Unique filename
    """
    # Generate a UUID
    unique_id = str(uuid.uuid4())
    
    # Add extension if provided
    if extension:
        # Ensure extension doesn't have a leading dot
        if extension.startswith('.'):
            extension = extension[1:]
        # Add dot to extension
        extension = f".{extension}"
    
    # Combine prefix, UUID, and extension
    if prefix:
        # Ensure prefix ends with a separator
        if not prefix.endswith('_') and not prefix.endswith('-'):
            prefix = f"{prefix}_"
        return f"{prefix}{unique_id}{extension}"
    else:
        return f"{unique_id}{extension}"


def get_file_extension(filename: str) -> str:
    """Extracts the extension from a filename.
    
    Args:
        filename: Filename to extract extension from
        
    Returns:
        File extension without the dot, or empty string if no extension
    """
    if not filename:
        return ""
    
    # Split by dot and get the last part
    parts = filename.split('.')
    if len(parts) > 1:
        return parts[-1].lower()
    else:
        return ""


def get_content_type(filename: str) -> str:
    """Determines the MIME content type based on file extension.
    
    Args:
        filename: Filename to determine content type for
        
    Returns:
        MIME content type, or application/octet-stream if unknown
    """
    # Get file extension
    extension = get_file_extension(filename)
    
    # Common MIME types mapping
    mime_types = {
        # Audio
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'aac': 'audio/aac',
        'm4a': 'audio/mp4',
        'ogg': 'audio/ogg',
        'flac': 'audio/flac',
        
        # Image
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'svg': 'image/svg+xml',
        'webp': 'image/webp',
        
        # Video
        'mp4': 'video/mp4',
        'webm': 'video/webm',
        'avi': 'video/x-msvideo',
        'mov': 'video/quicktime',
        
        # Document
        'pdf': 'application/pdf',
        'doc': 'application/msword',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls': 'application/vnd.ms-excel',
        'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'ppt': 'application/vnd.ms-powerpoint',
        'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        
        # Text
        'txt': 'text/plain',
        'html': 'text/html',
        'css': 'text/css',
        'js': 'application/javascript',
        'json': 'application/json',
        'xml': 'application/xml',
        
        # Archive
        'zip': 'application/zip',
        'tar': 'application/x-tar',
        'gz': 'application/gzip',
        'rar': 'application/vnd.rar',
        
        # Other
        'csv': 'text/csv',
        'md': 'text/markdown',
    }
    
    # Return the corresponding MIME type or default
    return mime_types.get(extension.lower(), 'application/octet-stream')