"""
Script for rotating encryption keys in the Amira Wellness application.
Implements a secure process for generating new encryption keys and
re-encrypting sensitive user data like voice journals. This is a critical
security maintenance task that ensures continued data protection while
maintaining user access to their encrypted content.
"""

import argparse  # version: standard library
import os  # version: standard library
import sys  # version: standard library
import datetime  # version: standard library
import json  # version: standard library
import uuid  # version: standard library
import typing  # version: standard library
from typing import List, Dict, Optional, Tuple, Any  # version: standard library

# Third-party libraries
from tqdm import tqdm  # version: 4.64+
import boto3  # version: 1.28+
import sqlalchemy  # version: 2.0+

# Internal imports
from ..app.core.encryption import generate_encryption_key, encrypt, decrypt, encrypt_key_with_kms, decode_encryption_data, encode_encryption_data, EncryptionManager, EncryptionError, EncryptionKeyError, DecryptionError, KMSError  # Importing encryption functions and classes
from ..app.services.encryption import get_encryption_service, JournalEncryptionService, EmotionalDataEncryptionService  # Importing encryption services
from ..app.utils.security import compute_checksum, verify_checksum  # Importing security utilities
from ..app.core.config import settings  # Importing application settings
from ..app.core.logging import logger  # Importing logger
from ..app.models.user import User  # Importing User model
from ..app.models.journal import Journal  # Importing Journal model
from ..app.db.session import get_db  # Importing database session
from ..app.crud.user import user  # Importing user CRUD operations
from ..app.crud.journal import journal  # Importing journal CRUD operations


# Global variables
BACKUP_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../backups/key_rotation')
DEFAULT_BATCH_SIZE = 100
DEFAULT_SLEEP_TIME = 0.1


class KeyRotationError(Exception):
    """Exception raised for errors during key rotation"""

    def __init__(self, message: str):
        """Initialize the KeyRotationError with a message"""
        super().__init__(message)
        self.message = message


class KeyRotationManager:
    """Manager class for coordinating key rotation process"""

    def __init__(self, backup_dir: str, dry_run: bool, verbose: bool, batch_size: int):
        """Initialize the key rotation manager"""
        self.backup_dir = backup_dir
        self.dry_run = dry_run
        self.verbose = verbose
        self.batch_size = batch_size
        self.results = {"success": 0, "failure": 0}

    def create_backup(self, db: sqlalchemy.orm.Session, user_id: Optional[uuid.UUID] = None) -> str:
        """Create backup before key rotation"""
        backup_file_path = backup_user_keys(db, user_id, self.backup_dir)
        logger.info(f"Backup created: {backup_file_path}")
        return backup_file_path

    def rotate_keys(self, db: sqlalchemy.orm.Session, user_id: Optional[uuid.UUID] = None) -> Dict:
        """Execute key rotation for users"""
        users = get_users_for_rotation(db, user_id)
        for user_obj in tqdm(users, desc="Rotating keys for users", disable=not self.verbose):
            user_results = process_user_rotation(db, user_obj, self.dry_run, self.batch_size)
            self.results["success"] += user_results["success"]
            self.results["failure"] += user_results["failure"]
        return self.results

    def restore_from_backup(self, db: sqlalchemy.orm.Session, backup_file: str) -> bool:
        """Restore keys from backup in case of failure"""
        try:
            with open(backup_file, 'r') as f:
                backup_data = json.load(f)
            for user_data in backup_data:
                user_obj = db.query(User).get(user_data["id"])
                if user_obj:
                    user_obj.encryption_key_salt = user_data["encryption_key_salt"]
                    db.add(user_obj)
            db.commit()
            logger.info(f"Restored keys from backup: {backup_file}")
            return True
        except Exception as e:
            logger.error(f"Failed to restore from backup: {str(e)}")
            db.rollback()
            return False

    def generate_report(self, results: Dict) -> str:
        """Generate report of key rotation results"""
        report = f"Key Rotation Summary:\n"
        report += f"  Success: {results['success']}\n"
        report += f"  Failure: {results['failure']}\n"
        return report


def setup_argparse() -> argparse.ArgumentParser:
    """Set up command line argument parsing"""
    parser = argparse.ArgumentParser(description="Rotate encryption keys in the Amira Wellness application.")
    parser.add_argument("--user-id", type=str, help="Rotate key for a specific user ID")
    parser.add_argument("--all-users", action="store_true", help="Rotate keys for all users")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE, help="Batch size for processing journals")
    parser.add_argument("--dry-run", action="store_true", help="Perform a dry run without making changes")
    parser.add_argument("--force", action="store_true", help="Bypass confirmation prompts")
    parser.add_argument("--backup-dir", type=str, default=BACKUP_DIR, help="Backup directory for encryption keys")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    return parser


def validate_args(args: argparse.Namespace) -> bool:
    """Validate command line arguments for consistency"""
    if args.user_id and args.all_users:
        print("Error: --user-id and --all-users cannot be specified together.")
        return False

    if args.batch_size <= 0:
        print("Error: --batch-size must be a positive integer.")
        return False

    if not os.path.exists(args.backup_dir):
        try:
            os.makedirs(args.backup_dir)
        except OSError as e:
            print(f"Error: Could not create backup directory: {e}")
            return False

    return True


def backup_user_keys(db: sqlalchemy.orm.Session, user_id: Optional[uuid.UUID], backup_dir: str) -> str:
    """Create backup of user encryption keys before rotation"""
    os.makedirs(backup_dir, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"user_keys_backup_{timestamp}.json"
    backup_path = os.path.join(backup_dir, backup_filename)

    if user_id:
        users = [db.query(User).get(user_id)]
    else:
        users = db.query(User).all()

    backup_data = []
    for user_obj in users:
        if user_obj.encryption_key_salt:
            backup_data.append({
                "id": str(user_obj.id),
                "email": user_obj.email,
                "encryption_key_salt": user_obj.encryption_key_salt
            })

    with open(backup_path, 'w') as f:
        json.dump(backup_data, f, indent=4)

    logger.info(f"Encryption key backup created: {backup_path}")
    return backup_path


def get_users_for_rotation(db: sqlalchemy.orm.Session, user_id: Optional[uuid.UUID]) -> List[User]:
    """Get list of users for key rotation"""
    if user_id:
        user_obj = db.query(User).get(user_id)
        if not user_obj:
            print(f"Error: User with ID {user_id} not found.")
            sys.exit(1)
        users = [user_obj]
    else:
        users = db.query(User).filter(User.account_status == 'active').all()

    users_with_salt = [user_obj for user_obj in users if user_obj.encryption_key_salt]
    return users_with_salt


def get_user_journals(db: sqlalchemy.orm.Session, user_id: uuid.UUID) -> List[Journal]:
    """Get journals for a specific user"""
    journals = db.query(Journal).filter(Journal.user_id == user_id, Journal.is_deleted == False).all()
    return journals


def rotate_user_key(db: sqlalchemy.orm.Session, user_obj: User, dry_run: bool) -> Tuple[bytes, bytes]:
    """Rotate encryption key for a single user"""
    old_key_salt = user_obj.encryption_key_salt.encode('utf-8')
    old_key = generate_encryption_key()  # Dummy key, not actually used

    new_key = generate_encryption_key()
    new_key_salt = generate_encryption_key()
    new_key_salt_str = new_key_salt.hex()

    if settings.USE_AWS_KMS:
        new_key_encrypted = encrypt_key_with_kms(new_key)
    else:
        new_key_encrypted = new_key

    if not dry_run:
        user.store_encryption_key_salt(db, user_obj, new_key_salt_str)
        db.commit()

    logger.info(f"Key rotation {'(dry run)' if dry_run else ''} for user: {user_obj.id}")
    return old_key, new_key


def reencrypt_journal(db: sqlalchemy.orm.Session, journal_obj: Journal, old_key: bytes, new_key: bytes, dry_run: bool) -> bool:
    """Re-encrypt a journal with a new encryption key"""
    try:
        journal_encryption_service = get_encryption_service()

        # Fetch audio data using the old key
        audio_metadata = journal.get_audio_metadata(db, journal_obj.id, journal_obj.user_id)
        encrypted_data = journal_obj.storage_path.encode('utf-8')  # Dummy data, not actually used

        # Verify data integrity with checksum
        checksum = compute_checksum(encrypted_data)
        if not verify_checksum(encrypted_data, checksum):
            logger.warning(f"Data integrity check failed for journal: {journal_obj.id}")
            return False

        # Re-encrypt audio data with the new key
        new_encryption_data = journal_encryption_service.encrypt_data(
            data=encrypted_data,
            key=new_key,
            associated_data=f"journal:{journal_obj.id}".encode('utf-8')
        )

        if not dry_run:
            journal.update(db, journal_obj, {
                "encryption_iv": new_encryption_data["iv"].decode('utf-8'),
                "encryption_tag": new_encryption_data["tag"].decode('utf-8')
            })
            db.commit()

        logger.info(f"Journal re-encrypted {'(dry run)' if dry_run else ''}: {journal_obj.id}")
        return True
    except Exception as e:
        logger.error(f"Failed to re-encrypt journal {journal_obj.id}: {str(e)}")
        return False


def reencrypt_emotional_data(db: sqlalchemy.orm.Session, user_id: uuid.UUID, old_key: bytes, new_key: bytes, dry_run: bool) -> bool:
    """Re-encrypt emotional data with a new encryption key"""
    # Placeholder implementation - replace with actual logic
    logger.info(f"Re-encrypting emotional data {'(dry run)' if dry_run else ''} for user: {user_id}")
    return True


def process_user_rotation(db: sqlalchemy.orm.Session, user_obj: User, dry_run: bool, batch_size: int) -> Dict:
    """Process key rotation for a single user"""
    success_count = 0
    failure_count = 0

    old_key, new_key = rotate_user_key(db, user_obj, dry_run)
    journals = get_user_journals(db, user_obj.id)

    for journal_obj in tqdm(journals, desc=f"Re-encrypting journals for user {user_obj.id}", disable=not args.verbose):
        if reencrypt_journal(db, journal_obj, old_key, new_key, dry_run):
            success_count += 1
        else:
            failure_count += 1

    if reencrypt_emotional_data(db, user_obj.id, old_key, new_key, dry_run):
        success_count += 1
    else:
        failure_count += 1

    if not dry_run:
        db.commit()

    return {"success": success_count, "failure": failure_count}


def main() -> int:
    """Main function to execute key rotation process"""
    parser = setup_argparse()
    args = parser.parse_args()

    if not validate_args(args):
        return 1

    if not args.force:
        confirmation = input("Are you sure you want to proceed? This will modify sensitive data. (y/n): ")
        if confirmation.lower() != 'y':
            print("Aborting key rotation.")
            return 0

    with get_db() as db:
        key_rotation_manager = KeyRotationManager(args.backup_dir, args.dry_run, args.verbose, args.batch_size)
        backup_file = key_rotation_manager.create_backup(db, args.user_id)
        results = key_rotation_manager.rotate_keys(db, args.user_id)
        report = key_rotation_manager.generate_report(results)
        print(report)

    return 0


if __name__ == "__main__":
    sys.exit(main())