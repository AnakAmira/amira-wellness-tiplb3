"""
Utility module for handling pagination in API requests and database queries.
Provides functions for paginating SQLAlchemy queries, calculating pagination metadata,
and creating standardized paginated responses for the Amira Wellness application.
"""

from typing import List, Optional, TypeVar, Generic, Dict, Any, Tuple, Type, Union, Callable
import math

from sqlalchemy.orm import Query
from sqlalchemy import select, func

from ..schemas.common import PaginationParams, PaginatedResponse
from ..core.logging import logger

# Default pagination settings
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

# TypeVar for generic types
T = TypeVar('T')


def paginate_query(query: Query, page: Optional[int] = None, page_size: Optional[int] = None) -> Query:
    """
    Apply pagination to a SQLAlchemy query.
    
    Args:
        query: The SQLAlchemy query to paginate
        page: Page number (1-indexed)
        page_size: Number of items per page
        
    Returns:
        Paginated query
    """
    # Apply default values if parameters are None
    if page is None or page < 1:
        page = 1
    
    if page_size is None or page_size < 1:
        page_size = DEFAULT_PAGE_SIZE
    
    # Ensure page_size doesn't exceed MAX_PAGE_SIZE
    page_size = min(page_size, MAX_PAGE_SIZE)
    
    # Calculate offset
    offset = (page - 1) * page_size
    
    # Apply pagination to query
    paginated_query = query.limit(page_size).offset(offset)
    
    logger.debug(
        f"Paginating query: page={page}, page_size={page_size}, offset={offset}",
        extra={"pagination": {"page": page, "page_size": page_size, "offset": offset}}
    )
    
    return paginated_query


def paginate_sqlalchemy2_query(select_stmt: Any, page: Optional[int] = None, 
                               page_size: Optional[int] = None) -> Any:
    """
    Apply pagination to a SQLAlchemy 2.0 style select statement.
    
    Args:
        select_stmt: The SQLAlchemy select statement to paginate
        page: Page number (1-indexed)
        page_size: Number of items per page
        
    Returns:
        Paginated select statement
    """
    # Apply default values if parameters are None
    if page is None or page < 1:
        page = 1
    
    if page_size is None or page_size < 1:
        page_size = DEFAULT_PAGE_SIZE
    
    # Ensure page_size doesn't exceed MAX_PAGE_SIZE
    page_size = min(page_size, MAX_PAGE_SIZE)
    
    # Calculate offset
    offset = (page - 1) * page_size
    
    # Apply pagination to select statement
    paginated_stmt = select_stmt.limit(page_size).offset(offset)
    
    logger.debug(
        f"Paginating SQLAlchemy 2.0 statement: page={page}, page_size={page_size}, offset={offset}",
        extra={"pagination": {"page": page, "page_size": page_size, "offset": offset}}
    )
    
    return paginated_stmt


def get_pagination_metadata(total_items: int, page: int, page_size: int) -> Dict[str, int]:
    """
    Calculate pagination metadata based on total items and pagination parameters.
    
    Args:
        total_items: Total number of items
        page: Current page number
        page_size: Number of items per page
        
    Returns:
        Dictionary with pagination metadata
    """
    # Calculate total pages
    total_pages = math.ceil(total_items / page_size) if page_size > 0 else 0
    
    # Ensure page is within valid range
    page = max(1, min(page, total_pages)) if total_pages > 0 else 1
    
    return {
        "total": total_items,
        "page": page,
        "page_size": page_size,
        "pages": total_pages
    }


def create_paginated_response(items: List[T], total: int, page: int, page_size: int) -> PaginatedResponse[T]:
    """
    Create a standardized paginated response from items and pagination metadata.
    
    Args:
        items: List of items for the current page
        total: Total number of items
        page: Current page number
        page_size: Number of items per page
        
    Returns:
        Standardized paginated response
    """
    # Calculate total pages
    pages = math.ceil(total / page_size) if page_size > 0 else 0
    
    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        pages=pages
    )


def paginate(query: Query, pagination_params: Optional[PaginationParams] = None,
             item_transformer: Optional[Callable] = None) -> Tuple[List[Any], Dict[str, int]]:
    """
    High-level function to paginate a query and return both results and pagination metadata.
    
    Args:
        query: SQLAlchemy query to paginate
        pagination_params: Pagination parameters
        item_transformer: Optional function to transform each item
        
    Returns:
        Tuple of (items, pagination_metadata)
    """
    # Get total count from the query
    total = query.count()
    
    # Extract page and page_size from pagination_params
    page, page_size = get_page_and_size(pagination_params)
    
    # Apply pagination to the query
    paginated_query = paginate_query(query, page, page_size)
    
    # Execute the query to get items
    items = paginated_query.all()
    
    # Apply item_transformer if provided
    if item_transformer:
        items = [item_transformer(item) for item in items]
    
    # Calculate pagination metadata
    metadata = get_pagination_metadata(total, page, page_size)
    
    return items, metadata


def get_page_and_size(pagination_params: Optional[PaginationParams] = None) -> Tuple[int, int]:
    """
    Extract and validate page and page_size from pagination parameters.
    
    Args:
        pagination_params: Pagination parameters
        
    Returns:
        Tuple of (page, page_size)
    """
    if pagination_params:
        page = pagination_params.page
        page_size = pagination_params.page_size
    else:
        page = 1
        page_size = DEFAULT_PAGE_SIZE
    
    # Ensure page is at least 1
    page = max(1, page)
    
    # Ensure page_size is between 1 and MAX_PAGE_SIZE
    page_size = max(1, min(page_size, MAX_PAGE_SIZE))
    
    return page, page_size


def keyset_paginate(query: Query, sort_field: str, last_value: Optional[Any] = None, 
                     limit: int = DEFAULT_PAGE_SIZE, ascending: bool = True) -> Query:
    """
    Implement keyset pagination for more efficient pagination of large datasets.
    
    Args:
        query: SQLAlchemy query to paginate
        sort_field: Field to sort and filter by
        last_value: Last value seen in the previous page
        limit: Maximum number of items to return
        ascending: Sort order (True for ascending, False for descending)
        
    Returns:
        Paginated query using keyset pagination
    """
    # Validate inputs
    if not sort_field:
        raise ValueError("sort_field is required for keyset pagination")
    
    # Ensure limit doesn't exceed MAX_PAGE_SIZE
    limit = min(limit, MAX_PAGE_SIZE)
    
    # If last_value is provided, filter results
    if last_value is not None:
        if ascending:
            # For ascending order, get items > last_value
            query = query.filter(getattr(query.column_descriptions[0]['type'], sort_field) > last_value)
        else:
            # For descending order, get items < last_value
            query = query.filter(getattr(query.column_descriptions[0]['type'], sort_field) < last_value)
    
    # Apply ordering by sort_field
    if ascending:
        query = query.order_by(getattr(query.column_descriptions[0]['type'], sort_field).asc())
    else:
        query = query.order_by(getattr(query.column_descriptions[0]['type'], sort_field).desc())
    
    # Apply limit
    query = query.limit(limit)
    
    logger.debug(
        f"Keyset pagination: sort_field={sort_field}, last_value={last_value}, limit={limit}, "
        f"ascending={ascending}",
        extra={"pagination": {
            "type": "keyset",
            "sort_field": sort_field,
            "last_value": str(last_value) if last_value is not None else None,
            "limit": limit,
            "ascending": ascending
        }}
    )
    
    return query


class Paginator(Generic[T]):
    """
    Class-based paginator for more complex pagination scenarios.
    """
    
    def __init__(self, default_page_size: int = DEFAULT_PAGE_SIZE, 
                 max_page_size: int = MAX_PAGE_SIZE):
        """
        Initialize the paginator with configuration.
        
        Args:
            default_page_size: Default number of items per page
            max_page_size: Maximum allowed number of items per page
        """
        self._default_page_size = default_page_size
        self._max_page_size = max_page_size
    
    def paginate_query(self, query: Query, page: Optional[int] = None, 
                       page_size: Optional[int] = None) -> Tuple[Query, Dict[str, int]]:
        """
        Apply pagination to a SQLAlchemy query.
        
        Args:
            query: SQLAlchemy query to paginate
            page: Page number (1-indexed)
            page_size: Number of items per page
            
        Returns:
            Tuple of (paginated_query, pagination_metadata)
        """
        # Get total count
        total = query.count()
        
        # Normalize pagination parameters
        page, page_size = self.normalize_params(page, page_size)
        
        # Apply pagination to query
        paginated_query = paginate_query(query, page, page_size)
        
        # Calculate pagination metadata
        metadata = get_pagination_metadata(total, page, page_size)
        
        return paginated_query, metadata
    
    def create_response(self, query: Query, page: Optional[int] = None, 
                        page_size: Optional[int] = None, 
                        item_transformer: Optional[Callable] = None) -> PaginatedResponse[T]:
        """
        Execute a paginated query and create a standardized response.
        
        Args:
            query: SQLAlchemy query to paginate
            page: Page number (1-indexed)
            page_size: Number of items per page
            item_transformer: Optional function to transform each item
            
        Returns:
            Standardized paginated response
        """
        # Get total count
        total = query.count()
        
        # Normalize pagination parameters
        page, page_size = self.normalize_params(page, page_size)
        
        # Apply pagination to query
        paginated_query = paginate_query(query, page, page_size)
        
        # Execute the query to get items
        items = paginated_query.all()
        
        # Apply item_transformer if provided
        if item_transformer:
            items = [item_transformer(item) for item in items]
        
        # Create paginated response
        return create_paginated_response(items, total, page, page_size)
    
    def normalize_params(self, page: Optional[int] = None, 
                         page_size: Optional[int] = None) -> Tuple[int, int]:
        """
        Normalize pagination parameters.
        
        Args:
            page: Page number (1-indexed)
            page_size: Number of items per page
            
        Returns:
            Tuple of (normalized_page, normalized_page_size)
        """
        # Apply default values if parameters are None
        if page is None or page < 1:
            page = 1
        
        if page_size is None or page_size < 1:
            page_size = self._default_page_size
        
        # Ensure page_size doesn't exceed max_page_size
        page_size = min(page_size, self._max_page_size)
        
        return page, page_size