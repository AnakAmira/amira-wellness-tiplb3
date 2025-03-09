from typing import TypeVar, Generic, List, Optional, Dict, Any
from datetime import datetime
import uuid
import math
from pydantic import BaseModel, Field, ConfigDict, model_validator

# TypeVar for generic types
T = TypeVar('T')


class BaseSchema(BaseModel):
    """
    Base schema class with common configuration for all Pydantic models in the application.
    """
    model_config = ConfigDict(
        populate_by_name=True,  # Allow populating models by field name
        validate_assignment=True,  # Validate attribute assignments
        extra='forbid',  # Disallow extra fields
        arbitrary_types_allowed=True,  # Allow custom types
        json_schema_extra={
            "example": {}  # Example values for documentation
        }
    )


class IDSchema(BaseSchema):
    """
    Schema with UUID identifier field.
    """
    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        description="Unique identifier",
    )


class TimestampSchema(BaseSchema):
    """
    Schema with created_at and updated_at timestamp fields.
    """
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Creation timestamp",
    )
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Last update timestamp",
    )


class PaginationParams(BaseSchema):
    """
    Schema for pagination parameters in list requests.
    """
    page: int = Field(
        default=1,
        ge=1,
        description="Page number (1-indexed)",
    )
    page_size: int = Field(
        default=20,
        ge=1,
        le=100,
        description="Number of items per page",
    )
    
    @model_validator(mode='before')
    @classmethod
    def validate_pagination(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates pagination parameters are within acceptable ranges.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Dictionary with validated pagination parameters
        """
        page = values.get('page', 1)
        page_size = values.get('page_size', 20)
        
        if page < 1:
            raise ValueError("Page must be greater than or equal to 1")
        
        if page_size < 1 or page_size > 100:
            raise ValueError("Page size must be between 1 and 100")
        
        return values


class PaginatedResponse(BaseSchema, Generic[T]):
    """
    Generic paginated response model for list endpoints.
    """
    items: List[T] = Field(
        description="List of items for the current page",
    )
    total: int = Field(
        description="Total number of items",
    )
    page: int = Field(
        description="Current page number",
    )
    page_size: int = Field(
        description="Number of items per page",
    )
    pages: int = Field(
        description="Total number of pages",
    )
    
    @model_validator(mode='before')
    @classmethod
    def calculate_pages(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calculates the total number of pages based on total items and page size.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Dictionary with calculated pages field
        """
        total = values.get('total')
        page_size = values.get('page_size')
        
        if total is not None and page_size is not None and page_size > 0:
            values['pages'] = math.ceil(total / page_size)
        else:
            values['pages'] = 0
            
        return values


class TokenResponse(BaseSchema):
    """
    Schema for authentication token response.
    """
    access_token: str = Field(
        description="JWT access token",
    )
    refresh_token: str = Field(
        description="JWT refresh token",
    )
    token_type: str = Field(
        default="bearer",
        description="Token type",
    )
    expires_in: int = Field(
        description="Token expiration time in seconds",
    )


class ErrorResponse(BaseSchema):
    """
    Schema for standardized error responses.
    """
    error_code: str = Field(
        description="Error code for machine readability",
    )
    message: str = Field(
        description="Human-readable error message",
    )
    details: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Additional error details",
    )


class SuccessResponse(BaseSchema):
    """
    Schema for standardized success responses.
    """
    success: bool = Field(
        default=True,
        description="Indicates successful operation",
    )
    message: str = Field(
        description="Success message",
    )
    data: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Response data",
    )


class DateRangeParams(BaseSchema):
    """
    Schema for date range parameters in filtering requests.
    """
    start_date: Optional[datetime] = Field(
        default=None,
        description="Start date for filtering",
    )
    end_date: Optional[datetime] = Field(
        default=None,
        description="End date for filtering",
    )
    
    @model_validator(mode='before')
    @classmethod
    def validate_date_range(cls, values: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates that end_date is not before start_date.
        
        Args:
            values: Dictionary of field values
            
        Returns:
            Dictionary with validated date range parameters
        """
        start_date = values.get('start_date')
        end_date = values.get('end_date')
        
        if start_date and end_date and end_date < start_date:
            raise ValueError("End date cannot be before start date")
            
        return values