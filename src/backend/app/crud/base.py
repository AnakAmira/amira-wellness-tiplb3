import uuid
from typing import Any, Dict, Generic, List, Optional, Type, TypeVar, Union, Tuple

from sqlalchemy import select, update, delete, func
from sqlalchemy.orm import Session
from pydantic import BaseModel

from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException, ValidationException

# Initialize logger
logger = get_logger(__name__)

# Type variables for generic typing
ModelType = TypeVar('ModelType')
CreateSchemaType = TypeVar('CreateSchemaType', bound=BaseModel)
UpdateSchemaType = TypeVar('UpdateSchemaType', bound=BaseModel)


class CRUDBase(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    """
    Base class providing generic CRUD operations on a SQLAlchemy model.
    """

    def __init__(self, model: Type[ModelType]):
        """
        Initialize CRUD operations for a specific SQLAlchemy model.
        
        Args:
            model: The SQLAlchemy model class
        """
        self.model = model
        
    def get(self, db: Session, id: Union[uuid.UUID, str, int]) -> Optional[ModelType]:
        """
        Get a single record by ID.
        
        Args:
            db: SQLAlchemy database session
            id: ID of the record to retrieve
            
        Returns:
            The model instance if found, None otherwise
        """
        query = select(self.model).where(self.model.id == id)
        result = db.execute(query).scalars().first()
        return result
        
    def get_or_404(self, db: Session, id: Union[uuid.UUID, str, int], resource_type: Optional[str] = None) -> ModelType:
        """
        Get a single record by ID or raise ResourceNotFoundException if not found.
        
        Args:
            db: SQLAlchemy database session
            id: ID of the record to retrieve
            resource_type: Optional name of the resource type for the error message
            
        Returns:
            The model instance
            
        Raises:
            ResourceNotFoundException: If the record is not found
        """
        obj = self.get(db, id)
        if not obj:
            resource_name = resource_type or self.model.__name__.lower()
            raise ResourceNotFoundException(resource_type=resource_name, resource_id=id)
        return obj
        
    def get_multi(self, db: Session, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """
        Get multiple records with pagination.
        
        Args:
            db: SQLAlchemy database session
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of model instances
        """
        query = select(self.model).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
        
    def get_count(self, db: Session) -> int:
        """
        Get the total count of records.
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            Total count of records
        """
        query = select(func.count()).select_from(self.model)
        count = db.execute(query).scalar_one()
        return count
        
    def create(self, db: Session, obj_in: Union[CreateSchemaType, Dict[str, Any]]) -> ModelType:
        """
        Create a new record.
        
        Args:
            db: SQLAlchemy database session
            obj_in: Data to create the record with (Pydantic schema or dict)
            
        Returns:
            The created model instance
        """
        if isinstance(obj_in, dict):
            obj_data = obj_in
        else:
            obj_data = obj_in.model_dump()
            
        db_obj = self.model(**obj_data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        
        return db_obj
        
    def update(self, db: Session, db_obj: ModelType, obj_in: Union[UpdateSchemaType, Dict[str, Any]]) -> ModelType:
        """
        Update an existing record.
        
        Args:
            db: SQLAlchemy database session
            db_obj: Existing database object to update
            obj_in: Data to update the record with (Pydantic schema or dict)
            
        Returns:
            The updated model instance
        """
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.model_dump(exclude_unset=True)
            
        # Get the current data of the model instance as a dictionary
        obj_data = {c.name: getattr(db_obj, c.name) for c in db_obj.__table__.columns}
        
        # Update the dictionary with the input data
        for field in update_data:
            if field in obj_data:
                setattr(db_obj, field, update_data[field])
                
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        
        return db_obj
        
    def delete(self, db: Session, id_or_obj: Union[uuid.UUID, str, int, ModelType]) -> ModelType:
        """
        Delete a record.
        
        Args:
            db: SQLAlchemy database session
            id_or_obj: ID or instance of the record to delete
            
        Returns:
            The deleted model instance
            
        Raises:
            ResourceNotFoundException: If the record is not found
        """
        if isinstance(id_or_obj, (uuid.UUID, str, int)):
            obj = self.get(db, id_or_obj)
            if not obj:
                resource_name = self.model.__name__.lower()
                raise ResourceNotFoundException(resource_type=resource_name, resource_id=id_or_obj)
        else:
            obj = id_or_obj
            
        db.delete(obj)
        db.commit()
        
        return obj
        
    def exists(self, db: Session, id: Union[uuid.UUID, str, int]) -> bool:
        """
        Check if a record with the given ID exists.
        
        Args:
            db: SQLAlchemy database session
            id: ID of the record to check
            
        Returns:
            True if the record exists, False otherwise
        """
        query = select(func.count()).select_from(self.model).where(self.model.id == id)
        count = db.execute(query).scalar_one()
        return count > 0
        
    def get_multi_paginated(self, db: Session, page: int = 1, page_size: int = 10) -> Tuple[List[ModelType], int]:
        """
        Get multiple records with pagination and total count.
        
        Args:
            db: SQLAlchemy database session
            page: Page number (1-indexed)
            page_size: Number of records per page
            
        Returns:
            Tuple of (records, total_count)
        """
        # Calculate skip value from page and page_size
        skip = (page - 1) * page_size
        
        # Get total count
        total = self.get_count(db)
        
        # Get paginated records
        records = self.get_multi(db, skip=skip, limit=page_size)
        
        return records, total