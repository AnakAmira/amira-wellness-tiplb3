import argparse  # argparse: standard library
import sys  # sys: standard library
from getpass import getpass  # getpass: standard library

from ..app.core.config import settings  # src/backend/app/core/config.py
from ..app.core.security import get_password_hash  # src/backend/app/core/security.py
from ..app.db.session import SessionLocal  # src/backend/app/db/session.py
from ..app.models.user import User  # src/backend/app/models/user.py
from ..app.crud import user  # src/backend/app/crud/user.py
from ..app.core.logging import logger  # src/backend/app/core/logging.py
from ..app.constants.languages import DEFAULT_LANGUAGE  # src/backend/app/constants/languages.py
from ..app.services.encryption import generate_user_encryption_key  # src/backend/app/services/encryption.py


def setup_argparse() -> argparse.ArgumentParser:
    """Sets up command-line argument parsing for the script.

    Returns:
        argparse.ArgumentParser: Configured argument parser.
    """
    parser = argparse.ArgumentParser(description="Create an administrator user in the Amira Wellness application.")
    parser.add_argument("--email", required=True, help="Email address for the administrator user.")
    parser.add_argument("--password", help="Password for the administrator user (optional, will prompt if not provided).")
    parser.add_argument("--force", action="store_true", help="Bypass confirmation prompts (use with caution).")
    return parser


def create_admin_user(email: str, password: str) -> User:
    """Creates an administrator user in the database.

    Args:
        email (str): Email address for the administrator user.
        password (str): Password for the administrator user.

    Returns:
        User: Created admin user instance.
    """
    db = SessionLocal()  # Create a database session using SessionLocal
    try:
        existing_user = user.get_by_email(db, email)  # Check if user with the provided email already exists
        if existing_user:  # If user exists, log a message and return the existing user
            logger.info(f"Admin user with email {email} already exists.")
            return existing_user

        password_hash = get_password_hash(password)  # Generate password hash using get_password_hash
        encryption_key_salt = generate_user_encryption_key(email)  # Generate encryption key salt using generate_user_encryption_key

        admin_user_data = {  # Create admin user data dictionary with required fields
            "email": email,
            "password_hash": password_hash,
            "encryption_key_salt": encryption_key_salt,
            "email_verified": True,  # Set admin-specific attributes (email_verified=True, account_status='active', subscription_tier='premium')
            "account_status": "active",
            "subscription_tier": "premium",
            "language_preference": DEFAULT_LANGUAGE
        }

        db_user = user.create(db, admin_user_data)  # Create the user using user.create
        db.commit()  # Commit the session and close it
        logger.info(f"Successfully created admin user with email: {email}")  # Log successful admin user creation
        return db_user  # Return the created user instance
    except Exception as e:
        logger.error(f"Error creating admin user: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def main() -> int:
    """Main function that parses arguments and runs the admin user creation process.

    Returns:
        int: Exit code (0 for success, 1 for error).
    """
    try:
        parser = setup_argparse()  # Set up argument parser using setup_argparse()
        args = parser.parse_args()  # Parse command-line arguments

        admin_email = args.email  # Get admin email from arguments

        if args.password:  # If password is provided in arguments, use it
            admin_password = args.password
        else:  # Otherwise, prompt for password securely using getpass
            admin_password = getpass("Enter password for admin user: ")

        create_admin_user(admin_email, admin_password)  # Call create_admin_user with email and password

        logger.info("Admin user creation script completed successfully.")  # Log successful completion
        return 0  # Return exit code 0 for success
    except Exception as e:  # Catch and log any exceptions
        logger.error(f"An error occurred: {e}")
        return 1  # Return exit code 1 for errors


if __name__ == "__main__":
    sys.exit(main())  # if __name__ == '__main__': sys.exit(main())