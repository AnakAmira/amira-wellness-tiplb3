import pytest  # pytest: 7.x
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from ...app.db.base import Base
from ...app.api.deps import get_db
from ...app.core.config import settings  # type: ignore

TEST_DB_URL = settings.TEST_DATABASE_URL


def setup_test_db():
    """Function to set up the test database for integration tests"""
    # Import necessary database models
    # (Models are imported in base.py)

    # Create tables in the test database
    engine = create_engine(TEST_DB_URL)
    Base.metadata.create_all(bind=engine)

    # Set up initial test data if needed
    # (Example: Create a default admin user)
    # from ...app.models.user import User
    # from ...app.core.security import get_password_hash
    # SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    # with SessionLocal() as db:
    #     if not db.query(User).filter(User.email == "admin@example.com").first():
    #         hashed_password = get_password_hash("admin123")
    #         admin_user = User(email="admin@example.com", password_hash=hashed_password, is_superuser=True)
    #         db.add(admin_user)
    #         db.commit()


__all__ = ["setup_test_db", "pytest"]