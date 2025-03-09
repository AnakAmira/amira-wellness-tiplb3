#!/usr/bin/env python3
"""
Database backup script for the Amira Wellness application.

This script automates the process of creating secure, encrypted backups of the PostgreSQL
database and storing them both locally and in cloud storage. It supports scheduled backups,
retention policies, and backup verification.
"""

import os
import sys
import argparse
import datetime
import subprocess
import shutil
import re
import tempfile
from typing import Dict, List, Optional, Union, Any

# Import sqlparse for SQL parsing during backup verification
import sqlparse  # version: 0.4+

# Import app configuration and utilities
from ..app.core.config import settings
from ..app.core.logging import logger
from ..app.utils.storage import (
    upload_to_s3,
    ensure_directory_exists,
    list_s3_objects,
    delete_from_s3
)

# Default backup directory
DEFAULT_BACKUP_DIR = os.path.join(os.path.expanduser('~'), '.amira', 'backups')

# Backup filename prefix
BACKUP_PREFIX = 'amira_db_backup_'

# Default backup retention period in days
BACKUP_RETENTION_DAYS = 30

# S3 backup prefix
S3_BACKUP_PREFIX = 'database/backups/'


def parse_db_url(db_url: str) -> Dict:
    """
    Parses the database connection string to extract connection parameters.
    
    Args:
        db_url: Database connection URL
        
    Returns:
        Dictionary containing database connection parameters
    """
    try:
        # Extract connection parts using regex
        pattern = r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)'
        match = re.match(pattern, db_url)
        
        if not match:
            logger.error(f"Failed to parse database URL: {db_url}")
            return {}
        
        username, password, host, port, dbname = match.groups()
        
        return {
            'username': username,
            'password': password,
            'host': host,
            'port': port,
            'dbname': dbname
        }
    except Exception as e:
        logger.error(f"Error parsing database URL: {str(e)}")
        return {}


def create_backup_filename(prefix: str, extension: str) -> str:
    """
    Generates a unique backup filename with timestamp.
    
    Args:
        prefix: Filename prefix
        extension: File extension
        
    Returns:
        Unique backup filename
    """
    # Get current timestamp
    timestamp = datetime.datetime.now().isoformat(timespec='seconds')
    # Replace colons with underscores for filename compatibility
    timestamp = timestamp.replace(':', '_').replace('.', '_')
    
    # Create filename with prefix, timestamp, and extension
    filename = f"{prefix}{timestamp}.{extension}"
    
    return filename


def create_db_backup(db_params: Dict, output_file: str, format: str) -> bool:
    """
    Creates a database backup using pg_dump.
    
    Args:
        db_params: Database connection parameters
        output_file: Path to output file
        format: Backup format (plain, custom, directory, tar)
        
    Returns:
        True if backup was successful, False otherwise
    """
    try:
        # Construct pg_dump command
        cmd = [
            'pg_dump',
            '-h', db_params['host'],
            '-p', db_params['port'],
            '-U', db_params['username'],
            '-d', db_params['dbname'],
            '-f', output_file,
            '-F', format  # Format (p: plain text, c: custom, d: directory, t: tar)
        ]
        
        # Set PGPASSWORD environment variable for password
        env = os.environ.copy()
        env['PGPASSWORD'] = db_params['password']
        
        # Execute pg_dump
        logger.info(f"Creating database backup: {output_file}")
        result = subprocess.run(
            cmd,
            env=env,
            capture_output=True,
            text=True
        )
        
        # Check if successful
        if result.returncode == 0:
            logger.info(f"Backup created successfully: {output_file}")
            return True
        else:
            logger.error(f"Backup failed: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Error creating backup: {str(e)}")
        return False


def compress_backup(input_file: str, output_file: str) -> bool:
    """
    Compresses a backup file using gzip.
    
    Args:
        input_file: Path to input file
        output_file: Path to output file
        
    Returns:
        True if compression was successful, False otherwise
    """
    try:
        # Run gzip command to compress the file
        logger.info(f"Compressing backup: {input_file}")
        result = subprocess.run(
            ['gzip', '-9', '-c', input_file],
            stdout=open(output_file, 'wb'),
            stderr=subprocess.PIPE
        )
        
        # Check if successful
        if result.returncode == 0:
            logger.info(f"Compression successful: {output_file}")
            return True
        else:
            logger.error(f"Compression failed: {result.stderr.decode()}")
            return False
    except Exception as e:
        logger.error(f"Error compressing backup: {str(e)}")
        return False


def encrypt_backup(input_file: str, output_file: str, password: str) -> bool:
    """
    Encrypts a backup file using OpenSSL.
    
    Args:
        input_file: Path to input file
        output_file: Path to output file
        password: Encryption password
        
    Returns:
        True if encryption was successful, False otherwise
    """
    try:
        # Run OpenSSL command to encrypt the file
        logger.info(f"Encrypting backup: {input_file}")
        cmd = [
            'openssl', 'enc', '-aes-256-cbc',
            '-salt',
            '-in', input_file,
            '-out', output_file,
            '-pass', f'pass:{password}'
        ]
        
        result = subprocess.run(
            cmd,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Check if successful
        if result.returncode == 0:
            logger.info(f"Encryption successful: {output_file}")
            return True
        else:
            logger.error(f"Encryption failed: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Error encrypting backup: {str(e)}")
        return False


def upload_backup_to_s3(file_path: str, bucket_name: str, s3_key: str) -> bool:
    """
    Uploads a backup file to S3 storage.
    
    Args:
        file_path: Path to local file
        bucket_name: S3 bucket name
        s3_key: S3 object key
        
    Returns:
        True if upload was successful, False otherwise
    """
    try:
        # Read the file
        with open(file_path, 'rb') as file:
            file_data = file.read()
        
        # Upload to S3
        logger.info(f"Uploading backup to S3: {s3_key}")
        result = upload_to_s3(file_data, s3_key, bucket_name)
        
        if result:
            logger.info(f"Upload successful: s3://{bucket_name}/{s3_key}")
            return True
        else:
            logger.error(f"Upload failed: s3://{bucket_name}/{s3_key}")
            return False
    except Exception as e:
        logger.error(f"Error uploading backup to S3: {str(e)}")
        return False


def verify_backup(backup_file: str, db_params: Dict) -> bool:
    """
    Verifies a backup file by testing restoration to a temporary database.
    
    Args:
        backup_file: Path to backup file
        db_params: Database connection parameters
        
    Returns:
        True if verification was successful, False otherwise
    """
    # Generate a temporary database name for verification
    temp_db_name = f"verify_{db_params['dbname']}_{int(datetime.datetime.now().timestamp())}"
    
    try:
        logger.info(f"Verifying backup: {backup_file}")
        
        # Create temporary database
        create_db_cmd = [
            'createdb',
            '-h', db_params['host'],
            '-p', db_params['port'],
            '-U', db_params['username'],
            temp_db_name
        ]
        
        # Set PGPASSWORD environment variable for password
        env = os.environ.copy()
        env['PGPASSWORD'] = db_params['password']
        
        # Create temporary database
        result = subprocess.run(
            create_db_cmd,
            env=env,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            logger.error(f"Failed to create temporary database: {result.stderr}")
            return False
        
        # Determine restore command based on file extension
        shell = False
        if backup_file.endswith('.sql'):
            # Plain SQL file
            restore_cmd = [
                'psql',
                '-h', db_params['host'],
                '-p', db_params['port'],
                '-U', db_params['username'],
                '-d', temp_db_name,
                '-f', backup_file
            ]
        elif backup_file.endswith('.gz'):
            # Compressed SQL file
            restore_cmd = f"gunzip -c {backup_file} | psql -h {db_params['host']} -p {db_params['port']} -U {db_params['username']} -d {temp_db_name}"
            shell = True
        elif backup_file.endswith('.dump'):
            # Custom format
            restore_cmd = [
                'pg_restore',
                '-h', db_params['host'],
                '-p', db_params['port'],
                '-U', db_params['username'],
                '-d', temp_db_name,
                backup_file
            ]
        else:
            logger.error(f"Unsupported backup format for verification: {backup_file}")
            return False
        
        # Restore the backup to the temporary database
        if isinstance(restore_cmd, list):
            result = subprocess.run(
                restore_cmd,
                env=env,
                capture_output=True,
                text=True,
                shell=False
            )
        else:
            result = subprocess.run(
                restore_cmd,
                env=env,
                capture_output=True,
                text=True,
                shell=True
            )
        
        if result.returncode != 0:
            logger.error(f"Failed to restore backup for verification: {result.stderr}")
            return False
        
        # Run a simple test query to verify the database
        test_query = "SELECT COUNT(*) FROM information_schema.tables;"
        test_cmd = [
            'psql',
            '-h', db_params['host'],
            '-p', db_params['port'],
            '-U', db_params['username'],
            '-d', temp_db_name,
            '-c', test_query,
            '-t'  # Tuple only output
        ]
        
        result = subprocess.run(
            test_cmd,
            env=env,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            logger.error(f"Verification query failed: {result.stderr}")
            return False
        
        # Check if we got a numeric result
        count = result.stdout.strip()
        if not count.isdigit():
            logger.error(f"Unexpected result from verification query: {count}")
            return False
        
        logger.info(f"Backup verification successful. Restored database has {count} tables.")
        return True
    except Exception as e:
        logger.error(f"Error verifying backup: {str(e)}")
        return False
    finally:
        # Clean up temporary database
        try:
            drop_db_cmd = [
                'dropdb',
                '-h', db_params['host'],
                '-p', db_params['port'],
                '-U', db_params['username'],
                temp_db_name
            ]
            
            subprocess.run(
                drop_db_cmd,
                env=env,
                capture_output=True,
                text=True
            )
            
            logger.info(f"Temporary verification database dropped: {temp_db_name}")
        except Exception as e:
            logger.warning(f"Error dropping temporary database: {str(e)}")


def cleanup_old_backups(backup_dir: str, retention_days: int) -> int:
    """
    Deletes old backup files based on retention policy.
    
    Args:
        backup_dir: Directory containing backups
        retention_days: Number of days to keep backups
        
    Returns:
        Number of deleted backup files
    """
    try:
        # Calculate cutoff date
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=retention_days)
        
        # Get all backup files
        deleted_count = 0
        for filename in os.listdir(backup_dir):
            if not filename.startswith(BACKUP_PREFIX):
                continue
                
            file_path = os.path.join(backup_dir, filename)
            
            # Get file modification time
            file_time = datetime.datetime.fromtimestamp(os.path.getmtime(file_path))
            
            # Delete if older than retention period
            if file_time < cutoff_date:
                os.remove(file_path)
                logger.info(f"Deleted old backup: {file_path}")
                deleted_count += 1
        
        logger.info(f"Cleanup completed: {deleted_count} old backups deleted")
        return deleted_count
    except Exception as e:
        logger.error(f"Error cleaning up old backups: {str(e)}")
        return 0


def cleanup_old_s3_backups(bucket_name: str, prefix: str, retention_days: int) -> int:
    """
    Deletes old backup files from S3 based on retention policy.
    
    Args:
        bucket_name: S3 bucket name
        prefix: S3 prefix (folder path)
        retention_days: Number of days to keep backups
        
    Returns:
        Number of deleted backup files
    """
    try:
        # Calculate cutoff date
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=retention_days)
        
        # List objects in S3
        objects = list_s3_objects(bucket_name, prefix)
        
        # Delete old backups
        deleted_count = 0
        for key in objects:
            if not os.path.basename(key).startswith(BACKUP_PREFIX):
                continue
            
            # Get object metadata to check date
            try:
                # For simplicity, we're using the key name which contains timestamp
                # In a real implementation, we would get the object's metadata
                # For now, we'll parse the timestamp from the filename
                match = re.search(r'amira_db_backup_(\d{4}-\d{2}-\d{2}T\d{2}_\d{2}_\d{2})', key)
                if match:
                    timestamp_str = match.group(1).replace('_', ':')
                    timestamp = datetime.datetime.fromisoformat(timestamp_str)
                    
                    if timestamp < cutoff_date:
                        delete_from_s3(key, bucket_name)
                        logger.info(f"Deleted old S3 backup: {key}")
                        deleted_count += 1
            except Exception as e:
                logger.warning(f"Error processing S3 object {key}: {str(e)}")
                continue
        
        logger.info(f"S3 cleanup completed: {deleted_count} old backups deleted")
        return deleted_count
    except Exception as e:
        logger.error(f"Error cleaning up old S3 backups: {str(e)}")
        return 0


def parse_arguments() -> argparse.Namespace:
    """
    Parses command-line arguments for the backup script.
    
    Returns:
        Parsed command-line arguments
    """
    parser = argparse.ArgumentParser(description='PostgreSQL database backup tool for Amira Wellness')
    
    parser.add_argument(
        '--backup-dir',
        type=str,
        default=DEFAULT_BACKUP_DIR,
        help=f'Directory to store backups (default: {DEFAULT_BACKUP_DIR})'
    )
    
    parser.add_argument(
        '--format',
        type=str,
        choices=['plain', 'custom', 'directory', 'tar'],
        default='plain',
        help='Backup format (default: plain)'
    )
    
    parser.add_argument(
        '--compress',
        action='store_true',
        help='Compress the backup file with gzip'
    )
    
    parser.add_argument(
        '--encrypt',
        action='store_true',
        help='Encrypt the backup file'
    )
    
    parser.add_argument(
        '--encrypt-password',
        type=str,
        help='Password for backup encryption'
    )
    
    parser.add_argument(
        '--verify',
        action='store_true',
        help='Verify backup after creation'
    )
    
    parser.add_argument(
        '--retention-days',
        type=int,
        default=BACKUP_RETENTION_DAYS,
        help=f'Number of days to keep backups (default: {BACKUP_RETENTION_DAYS})'
    )
    
    parser.add_argument(
        '--no-s3',
        action='store_true',
        help='Skip uploading to S3'
    )
    
    return parser.parse_args()


def main() -> int:
    """
    Main function that orchestrates the backup process.
    
    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    try:
        # Parse command-line arguments
        args = parse_arguments()
        
        # Parse database URL from settings
        db_url = settings.SQLALCHEMY_DATABASE_URI
        db_params = parse_db_url(db_url)
        
        if not db_params:
            logger.error("Failed to parse database connection string")
            return 1
        
        # Create backup directory if it doesn't exist
        backup_dir = ensure_directory_exists(args.backup_dir)
        
        # Determine backup format and file extension
        format_map = {
            'plain': 'p',
            'custom': 'c',
            'directory': 'd',
            'tar': 't'
        }
        
        extension_map = {
            'plain': 'sql',
            'custom': 'dump',
            'directory': 'dir',
            'tar': 'tar'
        }
        
        format_code = format_map[args.format]
        extension = extension_map[args.format]
        
        # Create backup filename
        backup_filename = create_backup_filename(BACKUP_PREFIX, extension)
        backup_path = os.path.join(backup_dir, backup_filename)
        
        # Create database backup
        if not create_db_backup(db_params, backup_path, format_code):
            logger.error("Backup creation failed")
            return 1
        
        final_backup_path = backup_path
        
        # Compress backup if requested
        if args.compress:
            compressed_path = f"{backup_path}.gz"
            if compress_backup(backup_path, compressed_path):
                # Remove original uncompressed file
                os.remove(backup_path)
                final_backup_path = compressed_path
            else:
                logger.error("Backup compression failed")
                return 1
        
        # Encrypt backup if requested
        if args.encrypt:
            if not args.encrypt_password:
                logger.error("Encryption password must be provided with --encrypt-password")
                return 1
                
            encrypted_path = f"{final_backup_path}.enc"
            if encrypt_backup(final_backup_path, encrypted_path, args.encrypt_password):
                # Remove unencrypted file
                os.remove(final_backup_path)
                final_backup_path = encrypted_path
            else:
                logger.error("Backup encryption failed")
                return 1
        
        # Verify backup if requested
        if args.verify:
            # Skip verification for encrypted backups
            if args.encrypt:
                logger.warning("Skipping verification for encrypted backup")
            else:
                if not verify_backup(final_backup_path, db_params):
                    logger.error("Backup verification failed")
                    return 1
        
        # Upload to S3 if in production or staging environment and not disabled
        if not args.no_s3 and settings.ENVIRONMENT in ['production', 'staging']:
            s3_key = f"{S3_BACKUP_PREFIX}{os.path.basename(final_backup_path)}"
            bucket_name = settings.S3_BUCKET_NAME
            
            if not upload_backup_to_s3(final_backup_path, bucket_name, s3_key):
                logger.error("Failed to upload backup to S3")
                return 1
                
            # Clean up old S3 backups
            cleanup_old_s3_backups(bucket_name, S3_BACKUP_PREFIX, args.retention_days)
        
        # Clean up old local backups
        cleanup_old_backups(backup_dir, args.retention_days)
        
        logger.info(f"Backup completed successfully: {final_backup_path}")
        return 0
    except Exception as e:
        logger.error(f"Backup process failed: {str(e)}")
        return 1


if __name__ == "__main__":
    sys.exit(main())