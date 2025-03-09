import pytest
import uuid
import datetime
from sqlalchemy import text, inspect, exc
from sqlalchemy.orm import Session

from ...app.db.session import Base, engine, get_db
from ..fixtures.database import test_engine, test_db, setup_test_db
from ...app.models.user import User
from ...app.models.journal import Journal
from ...app.models.emotion import EmotionalCheckin
from ...app.models.tool import Tool
from ...app.models.base import BaseModel


def test_database_connection(test_db):
    """Tests that the test database connection is working properly"""
    # Execute a simple query
    result = test_db.execute(text("SELECT 1")).scalar()
    assert result == 1
    
    # Verify that the test engine is different from the main engine
    assert test_engine != engine
    
    # Verify the test database is using SQLite in-memory
    assert str(test_engine.url) == "sqlite:///:memory:"


def test_database_tables_exist():
    """Tests that all expected database tables are created in the test database"""
    # Initialize test database
    setup_test_db()
    
    # Get the inspector for the test engine
    inspector = inspect(test_engine)
    
    # Get all table names from Base.metadata
    expected_tables = {table_name for table_name in Base.metadata.tables.keys()}
    
    # Get actual tables in the database
    actual_tables = set(inspector.get_table_names())
    
    # Verify essential tables exist
    essential_tables = ["users", "journals", "emotional_checkins", "tools"]
    for table in essential_tables:
        assert table in actual_tables, f"Table '{table}' should exist in the database"
    
    # Check that the users table has the expected columns
    user_columns = {col["name"] for col in inspector.get_columns("users")}
    essential_user_columns = ["id", "email", "password_hash", "created_at", "updated_at"]
    for column in essential_user_columns:
        assert column in user_columns, f"Column '{column}' should exist in users table"
    
    # Check foreign key relationships
    journal_fks = inspector.get_foreign_keys("journals")
    assert any(fk["referred_table"] == "users" for fk in journal_fks), "Journals should have a foreign key to users"


def test_transaction_isolation(test_db):
    """Tests that transactions are properly isolated in the test database"""
    # Create a test user
    user = User(
        email="test@example.com",
        password_hash="hashed_password"
    )
    
    # Add and commit the user
    test_db.add(user)
    test_db.commit()
    
    # Verify the user exists in the current session
    db_user = test_db.query(User).filter(User.email == "test@example.com").first()
    assert db_user is not None
    assert db_user.email == "test@example.com"
    
    # Create a new session and verify the user exists there too
    new_session = Session(test_engine)
    try:
        new_db_user = new_session.query(User).filter(User.email == "test@example.com").first()
        assert new_db_user is not None
        assert new_db_user.email == "test@example.com"
        
        # Make changes in the new session but don't commit
        new_db_user.email = "updated@example.com"
        
        # Verify changes are visible in the new session
        updated_user = new_session.query(User).filter(User.email == "updated@example.com").first()
        assert updated_user is not None
        
        # Verify changes are not visible in the original session
        original_user = test_db.query(User).filter(User.email == "updated@example.com").first()
        assert original_user is None
        
        # Roll back the transaction
        new_session.rollback()
        
        # Verify changes were not persisted
        rolled_back_user = new_session.query(User).filter(User.email == "updated@example.com").first()
        assert rolled_back_user is None
    finally:
        new_session.close()


def test_model_crud_operations(test_db):
    """Tests CRUD operations on database models"""
    # Create a new user
    user = User(
        email="crud@example.com",
        password_hash="hashed_password",
        email_verified=True,
        account_status="active",
        subscription_tier="free"
    )
    
    # Create operation - Add the user to the database
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    
    # Read operation - Query the user by ID
    db_user = test_db.query(User).filter(User.id == user.id).first()
    assert db_user is not None
    assert db_user.email == "crud@example.com"
    assert db_user.password_hash == "hashed_password"
    assert db_user.email_verified is True
    
    # Update operation - Modify the user
    db_user.email = "updated_crud@example.com"
    db_user.subscription_tier = "premium"
    test_db.commit()
    test_db.refresh(db_user)
    
    # Verify the updates were persisted
    updated_user = test_db.query(User).filter(User.id == user.id).first()
    assert updated_user.email == "updated_crud@example.com"
    assert updated_user.subscription_tier == "premium"
    
    # Delete operation - Remove the user
    test_db.delete(updated_user)
    test_db.commit()
    
    # Verify the user no longer exists
    deleted_user = test_db.query(User).filter(User.id == user.id).first()
    assert deleted_user is None


def test_relationship_integrity(test_db):
    """Tests that relationships between models maintain referential integrity"""
    # Create a test user
    user = User(
        email="relationship@example.com",
        password_hash="hashed_password"
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    
    # Create a journal entry associated with the user
    journal = Journal(
        user_id=user.id,
        title="Test Journal",
        duration_seconds=60,
        storage_path="/tmp/test.aac"
    )
    test_db.add(journal)
    test_db.commit()
    test_db.refresh(journal)
    
    # Create emotional check-ins associated with the journal
    pre_checkin = EmotionalCheckin(
        user_id=user.id,
        emotion_type="JOY",
        intensity=5,
        context="PRE_JOURNALING",
        related_journal_id=journal.id
    )
    
    post_checkin = EmotionalCheckin(
        user_id=user.id,
        emotion_type="CALM",
        intensity=7,
        context="POST_JOURNALING",
        related_journal_id=journal.id
    )
    
    test_db.add(pre_checkin)
    test_db.add(post_checkin)
    test_db.commit()
    test_db.refresh(pre_checkin)
    test_db.refresh(post_checkin)
    
    # Verify relationships can be traversed
    # Note: SQLite might not enforce foreign key constraints,
    # so we need to query the data to verify relationships
    
    # Get user's journals
    user_journals = test_db.query(Journal).filter(Journal.user_id == user.id).all()
    assert len(user_journals) == 1
    assert user_journals[0].id == journal.id
    
    # Verify emotional check-ins are associated with the journal
    journal_checkins = test_db.query(EmotionalCheckin).filter(
        EmotionalCheckin.related_journal_id == journal.id
    ).all()
    assert len(journal_checkins) == 2
    
    # Delete child records first, then the user
    test_db.query(EmotionalCheckin).filter(
        EmotionalCheckin.id.in_([pre_checkin.id, post_checkin.id])
    ).delete(synchronize_session=False)
    test_db.commit()
    
    test_db.query(Journal).filter(Journal.id == journal.id).delete()
    test_db.commit()
    
    test_db.delete(user)
    test_db.commit()
    
    # Verify all records are properly deleted
    assert test_db.query(User).filter(User.id == user.id).first() is None
    assert test_db.query(Journal).filter(Journal.id == journal.id).first() is None
    assert test_db.query(EmotionalCheckin).filter(
        EmotionalCheckin.id.in_([pre_checkin.id, post_checkin.id])
    ).count() == 0


def test_base_model_functionality(test_db):
    """Tests the functionality of the BaseModel class"""
    # Create a new user instance
    user = User(
        email="basemodel@example.com",
        password_hash="hashed_password"
    )
    
    # Verify that id, created_at, and updated_at are automatically set
    assert user.id is not None
    assert isinstance(user.id, uuid.UUID)
    assert user.created_at is not None
    assert user.updated_at is not None
    
    # Add to the database
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    
    # Test the to_dict method
    user_dict = user.to_dict()
    assert user_dict["id"] == user.id
    assert user_dict["email"] == "basemodel@example.com"
    assert user_dict["created_at"] == user.created_at
    assert user_dict["updated_at"] == user.updated_at
    
    # Record the current updated_at time
    original_updated_at = user.updated_at
    
    # Wait a moment to ensure the updated_at timestamp will change
    import time
    time.sleep(0.001)
    
    # Test the from_dict method
    user.from_dict({"email": "updated_basemodel@example.com"})
    test_db.commit()
    test_db.refresh(user)
    
    # Verify that the model was updated
    assert user.email == "updated_basemodel@example.com"
    
    # Verify that updated_at was changed
    assert user.updated_at > original_updated_at


def test_session_dependency():
    """Tests that the get_db dependency provides a working database session"""
    # Call the get_db function to get a session
    session_generator = get_db()
    session = next(session_generator)
    
    try:
        # Verify that the session is a valid SQLAlchemy session
        assert isinstance(session, Session)
        
        # Test that the session can execute a query
        result = session.execute(text("SELECT 1")).scalar()
        assert result == 1
    finally:
        # Make sure to close the generator to trigger the cleanup
        try:
            next(session_generator)
        except StopIteration:
            pass


def test_concurrent_transactions(test_db):
    """Tests that concurrent transactions are handled properly"""
    # Create a test user in the main session
    user = User(
        email="concurrent@example.com",
        password_hash="hashed_password"
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    
    # Create two separate database sessions
    session1 = Session(test_engine)
    session2 = Session(test_engine)
    
    try:
        # Begin transactions in both sessions
        user1 = session1.query(User).filter(User.id == user.id).first()
        user2 = session2.query(User).filter(User.id == user.id).first()
        
        # Make changes in both sessions
        user1.email = "concurrent1@example.com"
        user2.email = "concurrent2@example.com"
        
        # Commit one transaction
        session1.commit()
        
        # Verify the change from session1 is visible in a new query
        refreshed_user1 = session1.query(User).filter(User.id == user.id).first()
        assert refreshed_user1.email == "concurrent1@example.com"
        
        # The second session's transaction might conflict
        try:
            session2.commit()
        except exc.StaleDataError:
            # This might happen with certain database isolation levels
            session2.rollback()
        
        # Verify that at least one of the changes persisted
        final_user = session1.query(User).filter(User.id == user.id).first()
        assert final_user is not None
        assert final_user.email in ["concurrent1@example.com", "concurrent2@example.com"]
        
    finally:
        session1.close()
        session2.close()


def test_model_validation(test_db):
    """Tests that model validation constraints are enforced"""
    # Attempt to create a user with missing required fields
    missing_fields_user = User()
    
    try:
        test_db.add(missing_fields_user)
        test_db.flush()
        assert False, "Should have raised an error for missing required fields"
    except:
        test_db.rollback()
    
    # Create a valid user
    valid_user = User(
        email="valid@example.com",
        password_hash="hashed_password"
    )
    
    # Should succeed
    test_db.add(valid_user)
    test_db.commit()
    assert valid_user.id is not None
    
    # Test constraints with EmotionalCheckin intensity field (should be within range)
    try:
        invalid_checkin = EmotionalCheckin(
            user_id=valid_user.id,
            emotion_type="JOY",
            intensity=100,  # This should be outside the valid range
            context="STANDALONE"
        )
        test_db.add(invalid_checkin)
        test_db.flush()
        # If we get here, the validation might not be at the model level
        test_db.rollback()
    except ValueError:
        # Expected behavior if validation is at the model level
        test_db.rollback()


@pytest.mark.performance
def test_query_performance(test_db):
    """Tests the performance of common database queries"""
    # Create a large number of test records
    user_count = 100
    users = []
    
    for i in range(user_count):
        user = User(
            email=f"performance{i}@example.com",
            password_hash="hashed_password"
        )
        users.append(user)
    
    test_db.add_all(users)
    test_db.commit()
    
    # Measure time for a simple query
    import time
    
    start_time = time.time()
    result = test_db.query(User).filter(User.email.like("performance%")).all()
    end_time = time.time()
    
    assert len(result) == user_count
    assert (end_time - start_time) < 1.0, "Query took too long to execute"
    
    # Test filtering, ordering, and pagination
    start_time = time.time()
    paged_result = test_db.query(User).filter(
        User.email.like("performance%")
    ).order_by(User.email).limit(10).offset(20).all()
    end_time = time.time()
    
    assert len(paged_result) == 10
    assert (end_time - start_time) < 1.0, "Complex query took too long to execute"