import time
from typing import Dict, Optional, Any, Callable

import redis  # redis-py 4.5+
from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp

from ..core.config import settings
from ..core.exceptions import RateLimitExceededException
from ..core.logging import get_logger

# Initialize logger
logger = get_logger(__name__)

# Define public paths that bypass rate limiting
PUBLIC_PATHS = [
    f"{settings.API_V1_STR}/auth/login", 
    f"{settings.API_V1_STR}/auth/register",
    f"{settings.API_V1_STR}/auth/refresh", 
    f"{settings.API_V1_STR}/auth/password-reset",
    f"{settings.API_V1_STR}/auth/password-reset-confirm", 
    f"{settings.API_V1_STR}/auth/verify-email",
    f"{settings.API_V1_STR}/health", 
    "/docs", 
    "/redoc", 
    "/openapi.json"
]

# Dictionary to store rate limiters by client ID
RATE_LIMITERS: Dict[str, 'RateLimiter'] = {}


def is_path_public(path: str) -> bool:
    """
    Determines if a request path should bypass rate limiting.
    
    Args:
        path: The request path
        
    Returns:
        True if the path is public, False otherwise
    """
    # Check exact path matches
    if path in PUBLIC_PATHS:
        return True
    
    # Check path prefixes
    for public_path in ["/docs", "/redoc", "/openapi.json", "/static"]:
        if path.startswith(public_path):
            return True
    
    return False


def get_client_identifier(request: Request) -> str:
    """
    Extracts a unique identifier for the client from the request.
    
    Args:
        request: The HTTP request
        
    Returns:
        Client identifier (IP address or user ID if authenticated)
    """
    # If user is authenticated, use user ID as identifier
    if hasattr(request.state, "user") and request.state.user is not None:
        return f"user:{request.state.user.id}"
    
    # Otherwise, use IP address
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # Get the first IP in case of proxy chains
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        # Fall back to direct client IP
        client_ip = request.client.host if request.client else "unknown"
    
    return f"ip:{client_ip}"


def get_or_create_limiter(client_id: str, rate_limit: int) -> 'RateLimiter':
    """
    Gets an existing rate limiter or creates a new one for the client.
    
    Args:
        client_id: Unique identifier for the client
        rate_limit: Maximum requests per minute
        
    Returns:
        Rate limiter instance for the client
    """
    # Check if a rate limiter already exists for this client
    if client_id in RATE_LIMITERS:
        return RATE_LIMITERS[client_id]
    
    # Create a new rate limiter
    limiter = RateLimiter(rate_limit)
    RATE_LIMITERS[client_id] = limiter
    return limiter


class RateLimiter:
    """
    Token bucket implementation for tracking and enforcing rate limits.
    
    This class manages a token bucket that refills at a constant rate and allows
    consuming tokens when making requests. If the bucket doesn't have enough tokens,
    the request is rejected.
    """
    
    def __init__(self, tokens_per_minute: int):
        """
        Initialize a new rate limiter with specified capacity and refill rate.
        
        Args:
            tokens_per_minute: Maximum number of requests allowed per minute
        """
        self.capacity = tokens_per_minute
        self.tokens = tokens_per_minute  # Start with a full bucket
        self.rate = tokens_per_minute / 60.0  # Tokens per second
        self.last_refill = time.time()
    
    def refill(self) -> None:
        """
        Refill the token bucket based on elapsed time.
        """
        now = time.time()
        elapsed = now - self.last_refill
        refill_amount = elapsed * self.rate
        
        if refill_amount > 0:
            self.tokens = min(self.capacity, self.tokens + refill_amount)
            self.last_refill = now
    
    def consume(self, tokens_to_consume: int = 1) -> tuple:
        """
        Attempts to consume a token from the bucket.
        
        Args:
            tokens_to_consume: Number of tokens to consume (default: 1)
            
        Returns:
            (bool, int) - Success flag and retry-after seconds if failed
        """
        self.refill()
        
        if self.tokens >= tokens_to_consume:
            self.tokens -= tokens_to_consume
            return True, 0
        
        # Calculate time until enough tokens are available
        deficit = tokens_to_consume - self.tokens
        wait_time = int(deficit / self.rate) + 1  # Round up to be safe
        
        return False, wait_time


class RedisRateLimiter:
    """
    Distributed rate limiter implementation using Redis.
    
    This class provides a distributed token bucket algorithm implementation
    using Redis to store the state, allowing rate limiting to work across
    multiple application instances.
    """
    
    def __init__(
        self, 
        tokens_per_minute: int, 
        redis_client: redis.Redis, 
        key_prefix: str = "rate_limit:"
    ):
        """
        Initializes a new Redis-based rate limiter.
        
        Args:
            tokens_per_minute: Maximum number of requests allowed per minute
            redis_client: Redis client instance
            key_prefix: Prefix for Redis keys (default: 'rate_limit:')
        """
        self.redis_client = redis_client
        self.tokens_per_minute = tokens_per_minute
        self.key_prefix = key_prefix
    
    def get_keys(self, client_id: str) -> tuple:
        """
        Generates Redis keys for the given client ID.
        
        Args:
            client_id: Unique identifier for the client
            
        Returns:
            (str, str) - Tokens key and timestamp key
        """
        tokens_key = f"{self.key_prefix}{client_id}:tokens"
        timestamp_key = f"{self.key_prefix}{client_id}:timestamp"
        return tokens_key, timestamp_key
    
    def consume(self, client_id: str, tokens_to_consume: int = 1) -> tuple:
        """
        Attempts to consume a token using Redis for distributed tracking.
        
        Args:
            client_id: Unique identifier for the client
            tokens_to_consume: Number of tokens to consume (default: 1)
            
        Returns:
            (bool, int) - Success flag and retry-after seconds if failed
        """
        tokens_key, timestamp_key = self.get_keys(client_id)
        now = time.time()
        rate = self.tokens_per_minute / 60.0  # Tokens per second
        
        # Use Redis transaction to ensure atomicity
        with self.redis_client.pipeline() as pipe:
            try:
                # Watch the keys to ensure the transaction is atomic
                pipe.watch(tokens_key, timestamp_key)
                
                # Get current token count and last refill timestamp
                current_tokens = float(pipe.get(tokens_key) or self.tokens_per_minute)
                last_refill = float(pipe.get(timestamp_key) or now)
                
                # Calculate token refill
                elapsed = now - last_refill
                refill_amount = elapsed * rate
                
                # Update token count
                if refill_amount > 0:
                    current_tokens = min(self.tokens_per_minute, current_tokens + refill_amount)
                    last_refill = now
                
                # Check if we have enough tokens
                if current_tokens >= tokens_to_consume:
                    # We have enough tokens, so consume them
                    pipe.multi()
                    pipe.set(tokens_key, current_tokens - tokens_to_consume)
                    pipe.set(timestamp_key, last_refill)
                    pipe.execute()
                    return True, 0
                else:
                    # Not enough tokens, calculate wait time
                    deficit = tokens_to_consume - current_tokens
                    wait_time = int(deficit / rate) + 1  # Round up to be safe
                    return False, wait_time
                
            except Exception as e:
                # If there's an error, log it and allow the request
                logger.error(f"Redis rate limiter error: {str(e)}")
                return True, 0


class RateLimiterMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware that enforces rate limits on API requests.
    
    This middleware uses a token bucket algorithm to limit the rate of requests
    to the API. It supports both in-memory and Redis-based rate limiting.
    """
    
    def __init__(
        self, 
        app: ASGIApp, 
        default_rate_limit: Optional[int] = None,
        redis_client: Optional[redis.Redis] = None
    ):
        """
        Initializes the rate limiter middleware.
        
        Args:
            app: The ASGI application
            default_rate_limit: Default rate limit in requests per minute (default: from settings)
            redis_client: Optional Redis client for distributed rate limiting
        """
        super().__init__(app)
        self.default_rate_limit = default_rate_limit or settings.RATE_LIMIT_PER_MINUTE
        self.redis_client = redis_client
        self.use_redis = redis_client is not None
        self.logger = get_logger(__name__)
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Processes HTTP requests and enforces rate limits.
        
        Args:
            request: The HTTP request
            call_next: The next middleware in the chain
            
        Returns:
            The HTTP response from the application or rate limit error
        """
        # Skip rate limiting for public paths
        if is_path_public(request.url.path):
            return await call_next(request)
        
        # Get client identifier (IP address or user ID)
        client_id = get_client_identifier(request)
        
        # Get appropriate rate limiter
        rate_limiter = self.get_rate_limiter(client_id)
        
        # Try to consume a token
        allowed, retry_after = rate_limiter.consume()
        
        if allowed:
            # Request is allowed, continue processing
            return await call_next(request)
        
        # Request is not allowed, return 429 Too Many Requests
        self.logger.warning(
            f"Rate limit exceeded for client {client_id}, retry after {retry_after}s",
            extra={"client_id": client_id, "retry_after": retry_after}
        )
        
        # Raise the RateLimitExceededException which will be handled by exception handlers
        raise RateLimitExceededException(retry_after)
    
    def get_rate_limiter(self, client_id: str):
        """
        Gets the appropriate rate limiter for a client.
        
        Args:
            client_id: Unique identifier for the client
            
        Returns:
            Union[RateLimiter, RedisRateLimiter]: Rate limiter instance
        """
        if self.use_redis:
            return RedisRateLimiter(self.default_rate_limit, self.redis_client)
        
        return get_or_create_limiter(client_id, self.default_rate_limit)