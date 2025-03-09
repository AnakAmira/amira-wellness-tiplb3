import argparse  # standard library
import sys  # standard library
import os  # standard library
import pathlib  # standard library

from ..app.db.init_db import init_db  # Import the main database initialization function
from ..app.core.config import settings  # Import application settings for database connection and environment configuration
from ..app.core.logging import logger  # Import logging functionality for script execution

# Define the base directory for the project
BASE_DIR = pathlib.Path(__file__).resolve().parent.parent


def setup_argparse() -> argparse.ArgumentParser:
    """Sets up command-line argument parsing for the script

    Returns:
        argparse.ArgumentParser: Configured argument parser
    """
    parser = argparse.ArgumentParser(description="Initialize and seed the Amira Wellness database.")
    parser.add_argument(
        "--drop-all", action="store_true", help="Drop all existing tables before creating new ones."
    )
    parser.add_argument(
        "--force", action="store_true", help="Bypass confirmation prompts."
    )
    parser.add_argument(
        "--env", type=str, help="Override the environment setting (development, staging, production)."
    )
    return parser


def confirm_action(message: str, force: bool) -> bool:
    """Asks for user confirmation before proceeding with potentially destructive actions

    Args:
        message (str): Confirmation message to display
        force (bool): If True, bypass confirmation prompt

    Returns:
        bool: True if confirmed or forced, False otherwise
    """
    if force:
        return True

    response = input(f"{message} (y/n)? ").lower()
    return response.startswith("y")


def main() -> int:
    """Main function that parses arguments and runs the database seeding process

    Returns:
        int: Exit code (0 for success, 1 for error)
    """
    parser = setup_argparse()
    args = parser.parse_args()

    if args.env:
        os.environ["ENVIRONMENT"] = args.env

    logger.info("Starting database seeding process...")

    drop_all = args.drop_all
    force = args.force

    if drop_all:
        if confirm_action("Are you sure you want to drop all tables?", force):
            logger.info("User confirmed dropping all tables.")
            try:
                init_db(drop_all=True)
                logger.info("Database seeding completed successfully.")
                return 0
            except Exception as e:
                logger.error(f"Database seeding failed: {str(e)}")
                return 1
        else:
            logger.info("User cancelled dropping all tables.")
            return 0
    else:
        try:
            init_db(drop_all=False)
            logger.info("Database seeding completed successfully.")
            return 0
        except Exception as e:
            logger.error(f"Database seeding failed: {str(e)}")
            return 1


if __name__ == "__main__":
    sys.exit(main())