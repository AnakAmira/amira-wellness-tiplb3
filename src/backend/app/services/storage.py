"""
Service layer implementation for storage operations in the Amira Wellness application.

This module provides high-level storage functionality for voice recordings and other 
application data, with support for both local and cloud storage options. This service
acts as a bridge between the low-level storage utilities and application-specific storage needs.
"""

import os
import json
import uuid
import datetime
from typing import Dict, List, Optional, Tuple, Union, BinaryIO, Any
from pathlib import Path

# Internal imports
from ..core.logging import logger, info, error, debug
from ..core.config import settings
from ..utils.storage import (
    save_file_locally,
    load_file_locally,
    delete_file_locally,
    ensure_directory_exists,
    upload_to_s3,
    download_from_s3,
    delete_from_s3,
    generate_presigned_url,
    get_file_metadata,
    generate_unique_filename,
    DEFAULT_STORAGE_DIR,
    StorageError,
    LocalStorageError,
    CloudStorageError
)
from ..core.encryption import encode_encryption_data, decode_encryption_data

# Singleton instances of storage services
_journal_storage_service = None
_tool_storage_service = None


def get_journal_storage_service() -> 'JournalStorageService':
    """Factory function to get a singleton JournalStorageService instance."""
    global _journal_storage_service
    if _journal_storage_service is None:
        _journal_storage_service = JournalStorageService()
    return _journal_storage_service


def get_tool_storage_service() -> 'ToolStorageService':
    """Factory function to get a singleton ToolStorageService instance."""
    global _tool_storage_service
    if _tool_storage_service is None:
        _tool_storage_service = ToolStorageService()
    return _tool_storage_service


def get_storage_path_for_user(user_id: str, storage_type: str) -> str:
    """Generates a storage path for a specific user.
    
    Args:
        user_id: User identifier
        storage_type: Type of storage (journals, tools, etc.)
        
    Returns:
        Storage path for the user
    """
    path = os.path.join(DEFAULT_STORAGE_DIR, storage_type, user_id)
    ensure_directory_exists(path)
    return os.path.abspath(path)


def get_s3_key_for_user(user_id: str, file_id: str, storage_type: str) -> str:
    """Generates an S3 key for a specific user and file.
    
    Args:
        user_id: User identifier
        file_id: File identifier
        storage_type: Type of storage (journals, tools, etc.)
        
    Returns:
        S3 key for the user's file
    """
    return f"{storage_type}/{user_id}/{file_id}"


class StorageServiceError(Exception):
    """Exception class for storage service errors."""
    
    def __init__(self, message: str):
        """Initialize the StorageServiceError with a message.
        
        Args:
            message: Error message
        """
        super().__init__(message)
        self.message = message


class BaseStorageService:
    """Base class for storage services with common functionality."""
    
    def __init__(self, storage_type: str, local_storage_dir: str = None, 
                 use_cloud_storage: bool = None):
        """Initialize the base storage service.
        
        Args:
            storage_type: Type of storage (journals, tools, etc.)
            local_storage_dir: Directory for local storage
            use_cloud_storage: Whether to use cloud storage (S3)
        """
        self._storage_type = storage_type
        self._local_storage_dir = local_storage_dir or DEFAULT_STORAGE_DIR
        self._s3_bucket_name = settings.S3_BUCKET_NAME
        
        # Determine if cloud storage should be used
        if use_cloud_storage is None:
            # Default to cloud storage in production environment
            self._use_cloud_storage = settings.ENVIRONMENT == "production"
        else:
            self._use_cloud_storage = use_cloud_storage
        
        # Ensure the local storage directory exists
        ensure_directory_exists(self._local_storage_dir)
        
        logger.info(
            f"Initialized {self.__class__.__name__} with storage_type={storage_type}, "
            f"local_dir={self._local_storage_dir}, use_cloud={self._use_cloud_storage}"
        )
    
    def save_file(self, file_data: bytes, user_id: str, file_id: str, 
                 metadata: Dict = None) -> Dict:
        """Saves a file to storage (local and/or cloud).
        
        Args:
            file_data: File data to store
            user_id: User identifier
            file_id: File identifier
            metadata: Additional metadata for the file
            
        Returns:
            Dictionary with storage details
            
        Raises:
            StorageServiceError: If file storage fails
        """
        try:
            # Create metadata dictionary if not provided
            if metadata is None:
                metadata = {}
            
            # Add timestamp to metadata
            metadata["timestamp"] = datetime.datetime.utcnow().isoformat()
            
            # Generate local file path
            local_path = os.path.join(
                get_storage_path_for_user(user_id, self._storage_type),
                file_id
            )
            
            # Save file locally
            local_file_path = save_file_locally(file_data, local_path)
            
            # Save metadata to a JSON file alongside the data file
            metadata_path = f"{local_path}.meta.json"
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f)
            
            result = {
                "file_id": file_id,
                "user_id": user_id,
                "local_path": local_file_path,
                "size": len(file_data),
                "metadata": metadata,
                "timestamp": metadata["timestamp"],
                "storage_type": self._storage_type
            }
            
            # Upload to cloud storage if enabled
            if self._use_cloud_storage:
                try:
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Upload file to S3
                    s3_result = upload_to_s3(
                        file_data=file_data,
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name,
                        metadata=metadata
                    )
                    
                    result["s3_key"] = s3_key
                    result["s3_bucket"] = self._s3_bucket_name
                    result["is_cloud_synced"] = True
                    
                    logger.info(f"File uploaded to S3: {s3_key}")
                except CloudStorageError as e:
                    # Log error but don't fail the operation if local storage succeeded
                    logger.error(f"Failed to upload to S3: {str(e)}")
                    result["is_cloud_synced"] = False
            else:
                result["is_cloud_synced"] = False
            
            return result
        except (LocalStorageError, CloudStorageError) as e:
            # Propagate storage errors with additional context
            error_msg = f"Failed to save file for user {user_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error saving file for user {user_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
    
    def load_file(self, user_id: str, file_id: str) -> Dict:
        """Loads a file from storage (preferring cloud if available).
        
        Args:
            user_id: User identifier
            file_id: File identifier
            
        Returns:
            Dictionary with file data and metadata
            
        Raises:
            StorageServiceError: If file loading fails
        """
        try:
            file_data = None
            metadata = {}
            loaded_from_cloud = False
            
            # Try to load from cloud storage first if enabled
            if self._use_cloud_storage:
                try:
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Download file from S3
                    s3_result = download_from_s3(
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name
                    )
                    
                    file_data = s3_result["data"]
                    metadata = s3_result.get("metadata", {})
                    loaded_from_cloud = True
                    
                    logger.info(f"File loaded from S3: {s3_key}")
                except CloudStorageError as e:
                    # Log error and fall back to local storage
                    logger.warning(f"Failed to load from S3, falling back to local: {str(e)}")
            
            # Load from local storage if cloud storage failed or is disabled
            if file_data is None:
                # Generate local file path
                local_path = os.path.join(
                    get_storage_path_for_user(user_id, self._storage_type),
                    file_id
                )
                
                # Load file from local storage
                file_data = load_file_locally(local_path)
                
                # Try to load metadata from the JSON file
                metadata_path = f"{local_path}.meta.json"
                try:
                    if os.path.exists(metadata_path):
                        with open(metadata_path, 'r') as f:
                            metadata = json.load(f)
                except Exception as e:
                    logger.warning(f"Failed to load metadata for {file_id}: {str(e)}")
                
                logger.info(f"File loaded from local storage: {local_path}")
            
            return {
                "file_id": file_id,
                "user_id": user_id,
                "data": file_data,
                "size": len(file_data),
                "metadata": metadata,
                "loaded_from_cloud": loaded_from_cloud,
                "storage_type": self._storage_type
            }
        except (LocalStorageError, CloudStorageError) as e:
            # Propagate storage errors with additional context
            error_msg = f"Failed to load file {file_id} for user {user_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error loading file {file_id} for user {user_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
    
    def delete_file(self, user_id: str, file_id: str) -> bool:
        """Deletes a file from storage (both local and cloud if applicable).
        
        Args:
            user_id: User identifier
            file_id: File identifier
            
        Returns:
            True if deletion was successful
            
        Raises:
            StorageServiceError: If file deletion fails
        """
        try:
            deletion_success = False
            
            # Delete from local storage
            try:
                # Generate local file path
                local_path = os.path.join(
                    get_storage_path_for_user(user_id, self._storage_type),
                    file_id
                )
                
                # Delete file from local storage
                deleted_locally = delete_file_locally(local_path)
                
                # Also delete metadata file if it exists
                metadata_path = f"{local_path}.meta.json"
                if os.path.exists(metadata_path):
                    os.remove(metadata_path)
                
                deletion_success = deleted_locally
                logger.info(f"File deleted from local storage: {local_path}")
            except LocalStorageError as e:
                logger.warning(f"Failed to delete file from local storage: {str(e)}")
            
            # Delete from cloud storage if enabled
            if self._use_cloud_storage:
                try:
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Delete file from S3
                    delete_from_s3(
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name
                    )
                    
                    deletion_success = True
                    logger.info(f"File deleted from S3: {s3_key}")
                except CloudStorageError as e:
                    logger.warning(f"Failed to delete file from S3: {str(e)}")
            
            return deletion_success
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error deleting file {file_id} for user {user_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
    
    def get_download_url(self, user_id: str, file_id: str, expiration: int = 3600) -> str:
        """Generates a download URL for a file (presigned S3 URL or local path).
        
        Args:
            user_id: User identifier
            file_id: File identifier
            expiration: URL expiration time in seconds
            
        Returns:
            Download URL for the file
            
        Raises:
            StorageServiceError: If URL generation fails
        """
        try:
            # Generate presigned URL for cloud storage if enabled
            if self._use_cloud_storage:
                try:
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Generate presigned URL
                    url = generate_presigned_url(
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name,
                        expiration=expiration
                    )
                    
                    logger.info(f"Generated presigned URL for: {s3_key} (expires in {expiration}s)")
                    return url
                except CloudStorageError as e:
                    logger.warning(f"Failed to generate presigned URL: {str(e)}")
            
            # Fall back to local file URL if cloud storage is disabled or fails
            local_path = os.path.join(
                get_storage_path_for_user(user_id, self._storage_type),
                file_id
            )
            
            # Use file:// URL for local files (note: this won't work in browsers for security reasons)
            file_url = f"file://{os.path.abspath(local_path)}"
            logger.info(f"Generated local file URL: {file_url}")
            return file_url
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error generating URL for file {file_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
    
    def get_file_metadata(self, user_id: str, file_id: str) -> Dict:
        """Gets metadata for a stored file.
        
        Args:
            user_id: User identifier
            file_id: File identifier
            
        Returns:
            File metadata
            
        Raises:
            StorageServiceError: If metadata retrieval fails
        """
        try:
            metadata = {}
            
            # Try to get metadata from cloud storage first if enabled
            if self._use_cloud_storage:
                try:
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Get metadata from S3
                    s3_metadata = get_file_metadata(
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name
                    )
                    
                    metadata = s3_metadata.get("custom_metadata", {})
                    metadata.update({
                        "size": s3_metadata.get("size"),
                        "content_type": s3_metadata.get("content_type"),
                        "last_modified": s3_metadata.get("last_modified"),
                        "source": "cloud"
                    })
                    
                    logger.debug(f"Retrieved metadata from S3 for {s3_key}")
                    return metadata
                except CloudStorageError as e:
                    logger.warning(f"Failed to get metadata from S3: {str(e)}")
            
            # Fall back to local metadata if cloud storage is disabled or fails
            local_path = os.path.join(
                get_storage_path_for_user(user_id, self._storage_type),
                file_id
            )
            
            # Try to load metadata from the JSON file
            metadata_path = f"{local_path}.meta.json"
            if os.path.exists(metadata_path):
                with open(metadata_path, 'r') as f:
                    metadata = json.load(f)
                
                # Add file stats
                if os.path.exists(local_path):
                    file_stats = os.stat(local_path)
                    metadata.update({
                        "size": file_stats.st_size,
                        "last_modified": datetime.datetime.fromtimestamp(
                            file_stats.st_mtime
                        ).isoformat(),
                        "source": "local"
                    })
                
                logger.debug(f"Retrieved metadata from local file for {file_id}")
            
            return metadata
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error getting metadata for file {file_id}: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)
    
    def sync_to_cloud(self, user_id: str, file_ids: List[str]) -> Dict:
        """Synchronizes local files to cloud storage.
        
        Args:
            user_id: User identifier
            file_ids: List of file identifiers to synchronize
            
        Returns:
            Dictionary with synchronization results
            
        Raises:
            StorageServiceError: If synchronization fails
        """
        if not self._use_cloud_storage:
            logger.info("Cloud storage is disabled, skipping synchronization")
            return {
                "success": False,
                "message": "Cloud storage is disabled",
                "synced_count": 0,
                "failed_count": 0,
                "skipped_count": len(file_ids)
            }
        
        try:
            results = {
                "success": True,
                "synced_count": 0,
                "failed_count": 0,
                "skipped_count": 0,
                "failures": []
            }
            
            for file_id in file_ids:
                try:
                    # Generate local file path
                    local_path = os.path.join(
                        get_storage_path_for_user(user_id, self._storage_type),
                        file_id
                    )
                    
                    # Skip if file doesn't exist locally
                    if not os.path.exists(local_path):
                        logger.warning(f"File {file_id} not found locally, skipping sync")
                        results["skipped_count"] += 1
                        continue
                    
                    # Load file data
                    file_data = load_file_locally(local_path)
                    
                    # Load metadata if available
                    metadata = {}
                    metadata_path = f"{local_path}.meta.json"
                    if os.path.exists(metadata_path):
                        with open(metadata_path, 'r') as f:
                            metadata = json.load(f)
                    
                    # Generate S3 key
                    s3_key = get_s3_key_for_user(user_id, file_id, self._storage_type)
                    
                    # Upload to S3
                    upload_to_s3(
                        file_data=file_data,
                        s3_key=s3_key,
                        bucket_name=self._s3_bucket_name,
                        metadata=metadata
                    )
                    
                    results["synced_count"] += 1
                    logger.info(f"Synchronized file {file_id} to S3")
                except Exception as e:
                    results["failed_count"] += 1
                    failure_details = {
                        "file_id": file_id,
                        "error": str(e)
                    }
                    results["failures"].append(failure_details)
                    logger.error(f"Failed to synchronize file {file_id}: {str(e)}")
            
            # Update overall success flag
            results["success"] = results["failed_count"] == 0
            
            return results
        except Exception as e:
            # Catch any other exceptions
            error_msg = f"Unexpected error during synchronization: {str(e)}"
            logger.error(error_msg)
            raise StorageServiceError(error_msg)


class JournalStorageService(BaseStorageService):
    """Specialized storage service for voice journal recordings."""
    
    def __init__(self, local_storage_dir: str = None, use_cloud_storage: bool = None):
        """Initialize the journal storage service.
        
        Args:
            local_storage_dir: Directory for local storage
            use_cloud_storage: Whether to use cloud storage (S3)
        """
        super().__init__(
            storage_type="journals",
            local_storage_dir=local_storage_dir,
            use_cloud_storage=use_cloud_storage
        )
        logger.info("Initialized JournalStorageService")
    
    def save_journal(self, audio_data: bytes, user_id: str, journal_id: str, 
                    metadata: Dict = None) -> Dict:
        """Saves a voice journal recording with metadata.
        
        Args:
            audio_data: Audio data to store
            user_id: User identifier
            journal_id: Journal identifier
            metadata: Additional metadata for the journal
            
        Returns:
            Dictionary with storage details
            
        Raises:
            StorageServiceError: If journal storage fails
        """
        # Create metadata dictionary if not provided
        if metadata is None:
            metadata = {}
        
        # Add journal-specific metadata
        journal_metadata = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "content_type": "audio/mpeg",  # Default, can be overridden by provided metadata
            "content_category": "journal",
            **metadata
        }
        
        logger.info(f"Saving journal {journal_id} for user {user_id}")
        result = self.save_file(audio_data, user_id, journal_id, journal_metadata)
        return result
    
    def load_journal(self, user_id: str, journal_id: str) -> Dict:
        """Loads a voice journal recording with metadata.
        
        Args:
            user_id: User identifier
            journal_id: Journal identifier
            
        Returns:
            Dictionary with audio data and metadata
            
        Raises:
            StorageServiceError: If journal loading fails
        """
        logger.info(f"Loading journal {journal_id} for user {user_id}")
        return self.load_file(user_id, journal_id)
    
    def delete_journal(self, user_id: str, journal_id: str) -> bool:
        """Deletes a voice journal recording.
        
        Args:
            user_id: User identifier
            journal_id: Journal identifier
            
        Returns:
            True if deletion was successful
            
        Raises:
            StorageServiceError: If journal deletion fails
        """
        logger.info(f"Deleting journal {journal_id} for user {user_id}")
        return self.delete_file(user_id, journal_id)
    
    def export_journal(self, audio_data: bytes, user_id: str, export_id: str = None, 
                      format: str = "mp3", metadata: Dict = None) -> Dict:
        """Exports a voice journal recording to a specified format.
        
        Args:
            audio_data: Audio data to export
            user_id: User identifier
            export_id: Export identifier (generated if not provided)
            format: Export format (mp3, wav, etc.)
            metadata: Additional metadata for the export
            
        Returns:
            Dictionary with export details
            
        Raises:
            StorageServiceError: If journal export fails
        """
        # Generate export ID if not provided
        if export_id is None:
            export_id = f"export_{uuid.uuid4()}.{format}"
        elif not export_id.endswith(f".{format}"):
            export_id = f"{export_id}.{format}"
        
        # Create metadata dictionary if not provided
        if metadata is None:
            metadata = {}
        
        # Add export-specific metadata
        export_metadata = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "content_type": f"audio/{format}",
            "content_category": "export",
            "original_format": metadata.get("original_format", "unknown"),
            "export_format": format,
            **metadata
        }
        
        logger.info(f"Exporting journal to {format} format for user {user_id}")
        
        # Save the exported file
        result = self.save_file(audio_data, user_id, export_id, export_metadata)
        
        # Generate download URL
        download_url = self.get_journal_download_url(user_id, export_id)
        result["download_url"] = download_url
        
        return result
    
    def get_journal_download_url(self, user_id: str, journal_id: str, 
                               expiration: int = 3600) -> str:
        """Generates a download URL for a journal recording.
        
        Args:
            user_id: User identifier
            journal_id: Journal identifier
            expiration: URL expiration time in seconds
            
        Returns:
            Download URL for the journal
            
        Raises:
            StorageServiceError: If URL generation fails
        """
        logger.info(f"Generating download URL for journal {journal_id}")
        return self.get_download_url(user_id, journal_id, expiration)
    
    def sync_journals_to_cloud(self, user_id: str, journal_ids: List[str]) -> Dict:
        """Synchronizes local journal recordings to cloud storage.
        
        Args:
            user_id: User identifier
            journal_ids: List of journal identifiers to synchronize
            
        Returns:
            Dictionary with synchronization results
            
        Raises:
            StorageServiceError: If synchronization fails
        """
        logger.info(f"Synchronizing {len(journal_ids)} journals to cloud for user {user_id}")
        return self.sync_to_cloud(user_id, journal_ids)


class ToolStorageService(BaseStorageService):
    """Specialized storage service for tool content and resources."""
    
    def __init__(self, local_storage_dir: str = None, use_cloud_storage: bool = None):
        """Initialize the tool storage service.
        
        Args:
            local_storage_dir: Directory for local storage
            use_cloud_storage: Whether to use cloud storage (S3)
        """
        super().__init__(
            storage_type="tools",
            local_storage_dir=local_storage_dir,
            use_cloud_storage=use_cloud_storage
        )
        logger.info("Initialized ToolStorageService")
    
    def save_tool_resource(self, resource_data: bytes, tool_id: str, resource_id: str,
                         metadata: Dict = None) -> Dict:
        """Saves a tool resource file (audio, image, etc.).
        
        Args:
            resource_data: Resource data to store
            tool_id: Tool identifier
            resource_id: Resource identifier
            metadata: Additional metadata for the resource
            
        Returns:
            Dictionary with storage details
            
        Raises:
            StorageServiceError: If resource storage fails
        """
        # Create metadata dictionary if not provided
        if metadata is None:
            metadata = {}
        
        # Add tool-specific metadata
        tool_metadata = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "tool_id": tool_id,
            "resource_type": metadata.get("resource_type", "unknown"),
            "content_type": metadata.get("content_type", "application/octet-stream"),
            **metadata
        }
        
        logger.info(f"Saving resource {resource_id} for tool {tool_id}")
        
        # Use a special "system" user for tool resources since they are shared
        return self.save_file(resource_data, "system", resource_id, tool_metadata)
    
    def load_tool_resource(self, tool_id: str, resource_id: str) -> Dict:
        """Loads a tool resource file.
        
        Args:
            tool_id: Tool identifier
            resource_id: Resource identifier
            
        Returns:
            Dictionary with resource data and metadata
            
        Raises:
            StorageServiceError: If resource loading fails
        """
        logger.info(f"Loading resource {resource_id} for tool {tool_id}")
        
        # Use a special "system" user for tool resources since they are shared
        return self.load_file("system", resource_id)
    
    def delete_tool_resource(self, tool_id: str, resource_id: str) -> bool:
        """Deletes a tool resource file.
        
        Args:
            tool_id: Tool identifier
            resource_id: Resource identifier
            
        Returns:
            True if deletion was successful
            
        Raises:
            StorageServiceError: If resource deletion fails
        """
        logger.info(f"Deleting resource {resource_id} for tool {tool_id}")
        
        # Use a special "system" user for tool resources since they are shared
        return self.delete_file("system", resource_id)
    
    def get_tool_resource_url(self, tool_id: str, resource_id: str,
                           expiration: int = 86400) -> str:
        """Generates a download URL for a tool resource.
        
        Args:
            tool_id: Tool identifier
            resource_id: Resource identifier
            expiration: URL expiration time in seconds (default: 24 hours)
            
        Returns:
            Download URL for the resource
            
        Raises:
            StorageServiceError: If URL generation fails
        """
        logger.info(f"Generating download URL for resource {resource_id}")
        
        # Use a special "system" user for tool resources since they are shared
        return self.get_download_url("system", resource_id, expiration)
    
    def sync_tool_resources_to_cloud(self, resource_ids: List[str]) -> Dict:
        """Synchronizes local tool resources to cloud storage.
        
        Args:
            resource_ids: List of resource identifiers to synchronize
            
        Returns:
            Dictionary with synchronization results
            
        Raises:
            StorageServiceError: If synchronization fails
        """
        logger.info(f"Synchronizing {len(resource_ids)} tool resources to cloud")
        
        # Use a special "system" user for tool resources since they are shared
        return self.sync_to_cloud("system", resource_ids)