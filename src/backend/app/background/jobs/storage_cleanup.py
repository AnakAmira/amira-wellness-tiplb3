"""
Background job for cleaning up orphaned and expired files from storage in the Amira Wellness application.

This module identifies and removes files that are no longer referenced in the database or
have been marked for deletion, ensuring efficient storage usage and proper data lifecycle
management.
"""

import os
import datetime
from datetime import timedelta
from typing import List, Dict, Set, Optional, Tuple
from pathlib import Path
from sqlalchemy import select

from ...core.logging import get_logger
from ...core.config import settings
from ...db.session import SessionLocal
from ...models.journal import Journal
from ...models.tool import Tool
from ...services.storage import get_journal_storage_service, get_tool_storage_service
from ...utils.storage import (
    list_s3_objects,
    delete_file_locally,
    delete_from_s3,
    DEFAULT_STORAGE_DIR
)

# Configure logger
logger = get_logger(__name__)

# Constants
JOURNAL_RETENTION_DAYS = 30  # How long to retain deleted journals before permanent deletion
BATCH_SIZE = 100  # Number of items to process in a single batch


def get_database_journal_files(db) -> Tuple[Set[str], Set[str]]:
    """
    Retrieves all storage paths and S3 keys from the journal database.
    
    Args:
        db: Database session
        
    Returns:
        Sets of valid storage paths and S3 keys from the database
    """
    logger.info("Retrieving valid journal files from database")
    
    # Query for all journal files that aren't marked as deleted
    journals = db.query(Journal).filter(Journal.is_deleted == False).all()
    
    # Extract storage paths and S3 keys
    storage_paths = {j.storage_path for j in journals if j.storage_path}
    s3_keys = {j.s3_key for j in journals if j.s3_key}
    
    logger.info(f"Found {len(storage_paths)} valid local journal files and {len(s3_keys)} S3 keys in database")
    return storage_paths, s3_keys


def get_database_tool_files(db) -> Tuple[Set[str], Set[str]]:
    """
    Retrieves all resource references from tool content in the database.
    
    Args:
        db: Database session
        
    Returns:
        Sets of valid storage paths and S3 keys from tool content
    """
    logger.info("Retrieving valid tool files from database")
    
    # Query for all active tools
    tools = db.query(Tool).filter(Tool.is_active == True).all()
    
    storage_paths = set()
    s3_keys = set()
    
    # Process each tool's content to find file references
    for tool in tools:
        if not tool.content:
            continue
            
        # Extract file references from content
        content = tool.content
        
        # Look for media URLs or file paths in the content
        # The structure may vary based on the content_type
        if isinstance(content, dict):
            # Check for main media URL
            if 'mediaUrl' in content and content['mediaUrl']:
                if content['mediaUrl'].startswith('s3://'):
                    # Extract S3 key from s3:// URL
                    s3_key = content['mediaUrl'].replace('s3://', '').split('/', 1)[1]
                    s3_keys.add(s3_key)
                else:
                    # Might be a local path
                    storage_paths.add(content['mediaUrl'])
            
            # Check for resources within steps
            if 'steps' in content and isinstance(content['steps'], list):
                for step in content['steps']:
                    if isinstance(step, dict) and 'mediaUrl' in step and step['mediaUrl']:
                        if step['mediaUrl'].startswith('s3://'):
                            s3_key = step['mediaUrl'].replace('s3://', '').split('/', 1)[1]
                            s3_keys.add(s3_key)
                        else:
                            storage_paths.add(step['mediaUrl'])
            
            # Check for additional resources
            if 'additionalResources' in content and isinstance(content['additionalResources'], list):
                for resource in content['additionalResources']:
                    if isinstance(resource, dict) and 'url' in resource and resource['url']:
                        if resource['url'].startswith('s3://'):
                            s3_key = resource['url'].replace('s3://', '').split('/', 1)[1]
                            s3_keys.add(s3_key)
                        else:
                            storage_paths.add(resource['url'])
    
    logger.info(f"Found {len(storage_paths)} valid local tool files and {len(s3_keys)} S3 keys in database")
    return storage_paths, s3_keys


def get_local_storage_files(base_dir: str) -> Set[str]:
    """
    Scans local storage directories to find all stored files.
    
    Args:
        base_dir: Base directory to scan
        
    Returns:
        Set of file paths in local storage
    """
    logger.info(f"Scanning local storage directory: {base_dir}")
    
    file_paths = set()
    
    # Walk through the directory structure
    for root, _, files in os.walk(base_dir):
        for file in files:
            # Skip metadata files
            if file.endswith('.meta.json'):
                continue
                
            file_path = os.path.join(root, file)
            file_paths.add(file_path)
    
    logger.info(f"Found {len(file_paths)} files in local storage")
    return file_paths


def get_s3_storage_files(bucket_name: str) -> Set[str]:
    """
    Lists all objects in the S3 bucket.
    
    Args:
        bucket_name: S3 bucket name
        
    Returns:
        Set of S3 keys in the bucket
    """
    logger.info(f"Listing objects in S3 bucket: {bucket_name}")
    
    try:
        # Get all objects in the bucket
        s3_keys = set(list_s3_objects(bucket_name))
        logger.info(f"Found {len(s3_keys)} objects in S3 bucket")
        return s3_keys
    except Exception as e:
        logger.error(f"Error listing S3 objects: {str(e)}")
        return set()


def find_orphaned_local_files(local_files: Set[str], db_local_files: Set[str]) -> Set[str]:
    """
    Identifies local files that are not referenced in the database.
    
    Args:
        local_files: Set of files in local storage
        db_local_files: Set of files referenced in the database
        
    Returns:
        Set of orphaned local files
    """
    orphaned_files = local_files - db_local_files
    logger.info(f"Found {len(orphaned_files)} orphaned local files")
    return orphaned_files


def find_orphaned_s3_files(s3_files: Set[str], db_s3_files: Set[str]) -> Set[str]:
    """
    Identifies S3 objects that are not referenced in the database.
    
    Args:
        s3_files: Set of S3 keys in the bucket
        db_s3_files: Set of S3 keys referenced in the database
        
    Returns:
        Set of orphaned S3 keys
    """
    orphaned_files = s3_files - db_s3_files
    logger.info(f"Found {len(orphaned_files)} orphaned S3 files")
    return orphaned_files


def find_expired_deleted_journals(db, retention_days: int) -> List[Dict]:
    """
    Finds journal entries marked as deleted that have exceeded the retention period.
    
    Args:
        db: Database session
        retention_days: Number of days to retain deleted journals
        
    Returns:
        List of expired journal data with storage paths and S3 keys
    """
    logger.info(f"Finding deleted journals older than {retention_days} days")
    
    # Calculate the cutoff date
    cutoff_date = datetime.datetime.utcnow() - timedelta(days=retention_days)
    
    # Query for deleted journals older than the cutoff date
    expired_journals = db.query(Journal).filter(
        Journal.is_deleted == True,
        Journal.updated_at < cutoff_date
    ).all()
    
    # Extract relevant data for deletion
    expired_data = []
    for journal in expired_journals:
        journal_data = {
            'id': str(journal.id),
            'storage_path': journal.storage_path,
            's3_key': journal.s3_key
        }
        expired_data.append(journal_data)
    
    logger.info(f"Found {len(expired_data)} expired deleted journals")
    return expired_data


def delete_local_files(file_paths: List[str]) -> Dict[str, int]:
    """
    Deletes files from local storage.
    
    Args:
        file_paths: List of file paths to delete
        
    Returns:
        Results with counts of successful and failed deletions
    """
    logger.info(f"Deleting {len(file_paths)} files from local storage")
    
    successful = 0
    failed = 0
    
    for file_path in file_paths:
        try:
            if delete_file_locally(file_path):
                successful += 1
                
                # Also delete metadata file if it exists
                meta_path = f"{file_path}.meta.json"
                if os.path.exists(meta_path):
                    os.remove(meta_path)
            else:
                failed += 1
        except Exception as e:
            logger.error(f"Error deleting local file {file_path}: {str(e)}")
            failed += 1
    
    logger.info(f"Deleted {successful} local files successfully, {failed} failed")
    return {
        'successful': successful,
        'failed': failed
    }


def delete_s3_files(s3_keys: List[str], bucket_name: str) -> Dict[str, int]:
    """
    Deletes objects from S3 storage.
    
    Args:
        s3_keys: List of S3 keys to delete
        bucket_name: S3 bucket name
        
    Returns:
        Results with counts of successful and failed deletions
    """
    logger.info(f"Deleting {len(s3_keys)} objects from S3 bucket: {bucket_name}")
    
    successful = 0
    failed = 0
    
    for s3_key in s3_keys:
        try:
            delete_from_s3(s3_key, bucket_name)
            successful += 1
        except Exception as e:
            logger.error(f"Error deleting S3 object {s3_key}: {str(e)}")
            failed += 1
    
    logger.info(f"Deleted {successful} S3 objects successfully, {failed} failed")
    return {
        'successful': successful,
        'failed': failed
    }


def permanently_delete_journals(db, expired_journals: List[Dict]) -> int:
    """
    Permanently deletes expired journal entries from the database.
    
    Args:
        db: Database session
        expired_journals: List of expired journal data
        
    Returns:
        Number of journals permanently deleted
    """
    if not expired_journals:
        logger.info("No expired journals to delete from database")
        return 0
        
    logger.info(f"Permanently deleting {len(expired_journals)} expired journals from database")
    
    # Extract journal IDs
    journal_ids = [journal['id'] for journal in expired_journals]
    
    # Delete journals in a single query
    result = db.query(Journal).filter(Journal.id.in_(journal_ids)).delete(synchronize_session=False)
    db.commit()
    
    logger.info(f"Permanently deleted {result} journals from database")
    return result


def process_batch(batch_size: int) -> Dict[str, any]:
    """
    Processes a batch of cleanup operations.
    
    Args:
        batch_size: Maximum number of items to process in a batch
        
    Returns:
        Results of the cleanup operation
    """
    logger.info(f"Processing storage cleanup batch (batch size: {batch_size})")
    
    results = {
        'orphaned_local_deleted': 0,
        'orphaned_s3_deleted': 0,
        'expired_local_deleted': 0,
        'expired_s3_deleted': 0,
        'journals_permanently_deleted': 0,
        'errors': []
    }
    
    try:
        # Create database session
        with SessionLocal() as db:
            # Get valid files from database
            db_journal_local, db_journal_s3 = get_database_journal_files(db)
            db_tool_local, db_tool_s3 = get_database_tool_files(db)
            
            # Combine all database file references
            db_local_files = db_journal_local.union(db_tool_local)
            db_s3_files = db_journal_s3.union(db_tool_s3)
            
            # Get files from storage
            local_files = get_local_storage_files(DEFAULT_STORAGE_DIR)
            s3_files = get_s3_storage_files(settings.S3_BUCKET_NAME)
            
            # Find orphaned files
            orphaned_local = find_orphaned_local_files(local_files, db_local_files)
            orphaned_s3 = find_orphaned_s3_files(s3_files, db_s3_files)
            
            # Find expired deleted journals
            expired_journals = find_expired_deleted_journals(db, JOURNAL_RETENTION_DAYS)
            
            # Delete orphaned local files (limited by batch size)
            local_delete_results = delete_local_files(list(orphaned_local)[:batch_size])
            results['orphaned_local_deleted'] = local_delete_results['successful']
            
            # Delete orphaned S3 files (limited by batch size)
            s3_delete_results = delete_s3_files(list(orphaned_s3)[:batch_size], settings.S3_BUCKET_NAME)
            results['orphaned_s3_deleted'] = s3_delete_results['successful']
            
            # Delete expired journal files
            expired_local_paths = [j['storage_path'] for j in expired_journals if j['storage_path']]
            expired_s3_keys = [j['s3_key'] for j in expired_journals if j['s3_key']]
            
            expired_local_results = delete_local_files(expired_local_paths)
            results['expired_local_deleted'] = expired_local_results['successful']
            
            expired_s3_results = delete_s3_files(expired_s3_keys, settings.S3_BUCKET_NAME)
            results['expired_s3_deleted'] = expired_s3_results['successful']
            
            # Permanently delete expired journals from database
            results['journals_permanently_deleted'] = permanently_delete_journals(db, expired_journals)
    
    except Exception as e:
        error_msg = f"Error during storage cleanup: {str(e)}"
        logger.error(error_msg)
        results['errors'].append(error_msg)
    
    # Calculate total results
    results['total_files_deleted'] = (
        results['orphaned_local_deleted'] + 
        results['orphaned_s3_deleted'] + 
        results['expired_local_deleted'] + 
        results['expired_s3_deleted']
    )
    results['success'] = len(results['errors']) == 0
    
    return results


def run_storage_cleanup_job() -> Dict[str, any]:
    """
    Main entry point for the storage cleanup background job.
    
    Returns:
        Results of the cleanup operation
    """
    logger.info("Starting storage cleanup job")
    
    start_time = datetime.datetime.utcnow()
    results = process_batch(BATCH_SIZE)
    end_time = datetime.datetime.utcnow()
    
    # Add timing information to results
    duration_seconds = (end_time - start_time).total_seconds()
    results['start_time'] = start_time.isoformat()
    results['end_time'] = end_time.isoformat()
    results['duration_seconds'] = duration_seconds
    
    logger.info(f"Completed storage cleanup job in {duration_seconds:.2f} seconds. " +
               f"Deleted {results['total_files_deleted']} files and permanently removed " +
               f"{results['journals_permanently_deleted']} expired journals")
    
    return results