from sqlalchemy import Column, DateTime, func, UUID
from sqlalchemy.orm import declared_attr
from uuid import uuid4

from ..db.session import Base

class BaseModel(Base):
    """
    Abstract base model class that provides common fields and functionality for all database models.
    All models should inherit from this class to ensure consistency across the Amira Wellness application.
    """
    # Mark as abstract base class - won't create a table
    __abstract__ = True
    
    # Common columns for all models
    id = Column(UUID, primary_key=True, default=uuid4, index=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
    
    @declared_attr
    def __tablename__(cls) -> str:
        """
        Automatically generates table name from class name.
        Converts CamelCase to snake_case.
        
        Returns:
            str: Table name in snake_case format
        """
        # Convert CamelCase to snake_case
        name = cls.__name__
        # Insert underscore before uppercase letters and convert to lowercase
        snake_case = ''.join(['_' + c.lower() if c.isupper() else c.lower() for c in name]).lstrip('_')
        return snake_case
    
    def to_dict(self) -> dict:
        """
        Converts the model instance to a dictionary representation.
        
        Returns:
            dict: Dictionary representation of the model
        """
        result = {}
        for column in self.__table__.columns:
            result[column.name] = getattr(self, column.name)
        return result
    
    def from_dict(self, data: dict) -> "BaseModel":
        """
        Updates the model instance from a dictionary.
        
        Args:
            data (dict): Dictionary containing model attributes
            
        Returns:
            BaseModel: The updated model instance for method chaining
        """
        for key, value in data.items():
            if hasattr(self, key):
                setattr(self, key, value)
        return self