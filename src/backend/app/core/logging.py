import logging
import logging.config
import json
import typing
import os
import sys
import traceback
import uuid
import contextvars
import datetime
import re
from typing import Any, Dict, List, Optional, Union, Tuple

from .config import settings  # version: standard library

# Context variable to store correlation ID across async operations
CORRELATION_ID = contextvars.ContextVar('correlation_id', default=None)

# List of sensitive field names that should be redacted from logs
SENSITIVE_FIELDS = ["password", "token", "secret", "auth", "key", "credential", 
                   "email", "phone", "address", "credit_card", "ssn", "social_security"]

# Path to external logging configuration file
LOG_CONFIG_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logging.conf')


def setup_logging() -> None:
    """
    Initializes the logging system using configuration from the logging.conf file
    or sets up default configuration if the file doesn't exist.
    """
    if os.path.exists(LOG_CONFIG_PATH):
        # Configure logging from external file if it exists
        logging.config.fileConfig(LOG_CONFIG_PATH, disable_existing_loggers=False)
    else:
        # Basic configuration if no config file exists
        logging.basicConfig(
            level=getattr(logging, settings.LOG_LEVEL),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
            handlers=[logging.StreamHandler()]
        )
    
    # Set the root logger level based on settings
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, settings.LOG_LEVEL))
    
    # Log startup message
    logger = logging.getLogger(__name__)
    logger.info(f"Logging initialized at level {settings.LOG_LEVEL} for {settings.PROJECT_NAME}")


def get_logger(name: str) -> logging.Logger:
    """
    Creates and returns a logger instance for the specified module.
    
    Args:
        name: The name of the module requesting the logger
        
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    # Ensure logger has appropriate level set
    logger.setLevel(getattr(logging, settings.LOG_LEVEL))
    return logger


def get_correlation_id() -> str:
    """
    Gets the current correlation ID from context or generates a new one.
    
    Returns:
        Correlation ID for request tracing
    """
    correlation_id = CORRELATION_ID.get()
    if correlation_id is None:
        correlation_id = str(uuid.uuid4())
        set_correlation_id(correlation_id)
    return correlation_id


def set_correlation_id(correlation_id: str) -> None:
    """
    Sets the correlation ID in the current execution context.
    
    Args:
        correlation_id: The correlation ID to set
    """
    CORRELATION_ID.set(correlation_id)


def sanitize_log_data(data: Any, sensitive_fields: List[str] = None) -> Any:
    """
    Removes or masks sensitive information from data before logging.
    
    Args:
        data: The data to sanitize
        sensitive_fields: List of field names to redact (uses global SENSITIVE_FIELDS if None)
        
    Returns:
        Sanitized data safe for logging
    """
    if sensitive_fields is None:
        sensitive_fields = SENSITIVE_FIELDS
    
    if data is None:
        return None
    
    # Handle dictionaries recursively
    if isinstance(data, dict):
        sanitized = {}
        for key, value in data.items():
            # Check if the key matches any sensitive field patterns
            if any(sensitive in key.lower() for sensitive in sensitive_fields):
                sanitized[key] = "[REDACTED]"
            else:
                # Recursively sanitize the value
                sanitized[key] = sanitize_log_data(value, sensitive_fields)
        return sanitized
    
    # Handle lists, tuples, and sets recursively
    if isinstance(data, (list, tuple, set)):
        sanitized_items = [sanitize_log_data(item, sensitive_fields) for item in data]
        # Return the same type as the input
        if isinstance(data, list):
            return sanitized_items
        elif isinstance(data, tuple):
            return tuple(sanitized_items)
        else:  # set
            return set(sanitized_items)
    
    # Handle strings - check for patterns that might be sensitive
    if isinstance(data, str):
        # Simple pattern for potential sensitive data like tokens or keys
        sensitive_pattern = re.compile(
            r'(eyJ|[A-Za-z0-9+/]{40,}|[A-Za-z0-9]{20,}-[A-Za-z0-9]{20,})'
        )
        email_pattern = re.compile(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+')
        
        # Redact potential sensitive patterns
        data = sensitive_pattern.sub("[REDACTED]", data)
        data = email_pattern.sub("[EMAIL REDACTED]", data)
    
    return data


def log_request(request: object, logger: logging.Logger = None) -> None:
    """
    Logs HTTP request details with privacy protection.
    
    Args:
        request: The HTTP request object
        logger: Logger to use (creates one if not provided)
    """
    if logger is None:
        logger = get_logger(__name__)
    
    # Extract relevant request information with privacy protection
    try:
        # Safely extract attributes using getattr with fallbacks
        method = getattr(request, "method", "UNKNOWN")
        
        # Different frameworks store path differently
        path = getattr(request, "path", None)
        if path is None:
            path = getattr(request, "url", "UNKNOWN")
            if hasattr(path, "path"):  # Handle URL objects
                path = path.path
        
        # Handle headers - could be dict or object with dict-like interface
        headers = {}
        request_headers = getattr(request, "headers", {})
        if hasattr(request_headers, "items"):
            headers = {k.lower(): v for k, v in request_headers.items() 
                      if k.lower() not in ["authorization", "cookie"]}
        elif hasattr(request_headers, "get"):
            # Some frameworks use a get method for headers
            for header in ["user-agent", "content-type", "accept", "host", "referer"]:
                value = request_headers.get(header)
                if value:
                    headers[header] = value
        
        # Extract query parameters
        query_params = getattr(request, "query_params", None)
        if query_params is None:
            query_params = getattr(request, "args", {})
        
        # Get client IP - different frameworks store it differently
        client_ip = "UNKNOWN"
        if hasattr(request, "client"):
            client = getattr(request, "client", {})
            if hasattr(client, "host"):
                client_ip = client.host
            elif hasattr(client, "get"):
                client_ip = client.get("host", "UNKNOWN")
        elif hasattr(request, "remote_addr"):
            client_ip = request.remote_addr
        
        request_data = {
            "method": method,
            "path": path,
            "headers": headers,
            "query_params": query_params,
            "client_ip": client_ip,
        }
        
        # Sanitize request data
        sanitized_data = sanitize_log_data(request_data)
        
        # Add correlation ID to the log context
        extra = {"correlation_id": get_correlation_id()}
        
        # Log the request
        logger.info(
            f"Request: {sanitized_data['method']} {sanitized_data['path']}",
            extra={"request": sanitized_data, **extra}
        )
    except Exception as exc:
        logger.error(f"Error logging request: {str(exc)}", extra={"correlation_id": get_correlation_id()})


def log_response(response: object, duration: float, logger: logging.Logger = None) -> None:
    """
    Logs HTTP response details with privacy protection.
    
    Args:
        response: The HTTP response object
        duration: Request processing duration in seconds
        logger: Logger to use (creates one if not provided)
    """
    if logger is None:
        logger = get_logger(__name__)
    
    # Extract relevant response information with privacy protection
    try:
        # Extract status code safely
        status_code = getattr(response, "status_code", 0)
        if not status_code and hasattr(response, "status"):
            status_code = response.status
        
        # Extract headers safely
        headers = {}
        response_headers = getattr(response, "headers", {})
        if hasattr(response_headers, "items"):
            headers = {k.lower(): v for k, v in response_headers.items() 
                    if k.lower() not in ["set-cookie", "authorization"]}
        elif hasattr(response_headers, "get"):
            for header in ["content-type", "content-length", "cache-control"]:
                value = response_headers.get(header)
                if value:
                    headers[header] = value
        
        response_data = {
            "status_code": status_code,
            "headers": headers,
            "duration_ms": round(duration * 1000, 2)
        }
        
        # Sanitize response data
        sanitized_data = sanitize_log_data(response_data)
        
        # Add correlation ID and request duration to the log context
        extra = {"correlation_id": get_correlation_id(), "duration_ms": response_data["duration_ms"]}
        
        # Log the response
        logger.info(
            f"Response: {sanitized_data['status_code']} (took {sanitized_data['duration_ms']}ms)",
            extra={"response": sanitized_data, **extra}
        )
    except Exception as exc:
        logger.error(f"Error logging response: {str(exc)}", extra={"correlation_id": get_correlation_id()})


def log_exception(exc: Exception, context: Dict = None, logger: logging.Logger = None) -> None:
    """
    Logs exception details with context and privacy protection.
    
    Args:
        exc: The exception to log
        context: Additional context data
        logger: Logger to use (creates one if not provided)
    """
    if logger is None:
        logger = get_logger(__name__)
    
    if context is None:
        context = {}
    
    try:
        # Extract exception details
        exc_type = type(exc).__name__
        exc_message = str(exc)
        exc_traceback = "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))
        
        # Sanitize context data
        sanitized_context = sanitize_log_data(context)
        
        # Prepare the exception information
        exception_data = {
            "type": exc_type,
            "message": exc_message,
            "traceback": exc_traceback,
            "context": sanitized_context
        }
        
        # Add correlation ID to the log context
        extra = {"correlation_id": get_correlation_id(), "exception": exception_data}
        
        # Log the exception
        logger.error(
            f"Exception: {exc_type}: {exc_message}",
            extra=extra,
            exc_info=False  # We're already formatting the exception
        )
    except Exception as log_exc:
        # Fall back to basic logging if there's an error in the logging process
        logger.error(
            f"Error logging exception: {str(log_exc)}. Original exception: {str(exc)}",
            extra={"correlation_id": get_correlation_id()},
            exc_info=True
        )


def enrich_log_record(record: Dict) -> Dict:
    """
    Adds standard fields to log records for consistent formatting.
    
    Args:
        record: The log record to enrich
        
    Returns:
        Enriched log record with standard fields
    """
    # Add timestamp in ISO format
    record["timestamp"] = datetime.datetime.utcnow().isoformat() + "Z"
    
    # Add correlation ID if available
    correlation_id = get_correlation_id()
    if correlation_id:
        record["correlation_id"] = correlation_id
    
    # Add environment information
    record["environment"] = settings.ENVIRONMENT
    
    # Add application name
    record["app"] = settings.PROJECT_NAME
    
    return record


class JsonFormatter(logging.Formatter):
    """
    Custom log formatter that outputs logs in JSON format for structured logging.
    """
    
    def __init__(self):
        super().__init__()
    
    def format(self, record: logging.LogRecord) -> str:
        """
        Formats a log record as a JSON string.
        
        Args:
            record: The log record to format
            
        Returns:
            JSON-formatted log entry
        """
        # Create base log record
        log_record = {
            "timestamp": datetime.datetime.fromtimestamp(record.created).isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        
        # Add correlation ID if available
        correlation_id = getattr(record, "correlation_id", None) or get_correlation_id()
        if correlation_id:
            log_record["correlation_id"] = correlation_id
        
        # Add exception info if present
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        
        # Add extra fields
        for key, value in record.__dict__.items():
            if key not in ["args", "asctime", "created", "exc_info", "exc_text", "filename",
                          "funcName", "id", "levelname", "levelno", "lineno", "module",
                          "msecs", "message", "msg", "name", "pathname", "process",
                          "processName", "relativeCreated", "stack_info", "thread", "threadName"]:
                log_record[key] = value
        
        # Sanitize log data
        sanitized_record = sanitize_log_data(log_record)
        
        # Convert to JSON string with error handling for non-serializable objects
        try:
            return json.dumps(sanitized_record)
        except TypeError:
            # Fall back to safer approach if there are non-serializable objects
            return json.dumps(self._make_serializable(sanitized_record))
    
    def _make_serializable(self, obj: Any) -> Any:
        """
        Converts non-serializable objects to serializable representations.
        
        Args:
            obj: The object to make serializable
            
        Returns:
            A serializable version of the object
        """
        if isinstance(obj, dict):
            return {k: self._make_serializable(v) for k, v in obj.items()}
        elif isinstance(obj, (list, tuple)):
            return [self._make_serializable(item) for item in obj]
        elif isinstance(obj, (datetime.datetime, datetime.date)):
            return obj.isoformat()
        elif hasattr(obj, "__dict__"):
            # Handle objects by converting to dict
            return self._make_serializable(obj.__dict__)
        elif hasattr(obj, "__str__"):
            # Fall back to string representation
            return str(obj)
        else:
            # Ultimate fallback
            return repr(obj)
    
    def formatException(self, exc_info: Tuple) -> Dict:
        """
        Formats exception information for inclusion in logs.
        
        Args:
            exc_info: Exception information tuple (type, value, traceback)
            
        Returns:
            Structured exception information
        """
        exc_type, exc_value, tb = exc_info
        
        # Format traceback as list of strings
        formatted_traceback = traceback.format_exception(exc_type, exc_value, tb)
        
        return {
            "type": exc_type.__name__,
            "message": str(exc_value),
            "traceback": formatted_traceback
        }


class PrivacyFilter(logging.Filter):
    """
    Log filter that ensures sensitive data is not logged.
    """
    
    def __init__(self):
        super().__init__()
        self.sensitive_patterns = [
            re.compile(r'bearer\s+[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+', re.IGNORECASE),  # JWT
            re.compile(r'password["\':\s]*[^"\'{\s]+'),  # Passwords
            re.compile(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'),  # Emails
            re.compile(r'\b(?:\d[ -]*?){13,16}\b')  # Credit card numbers
        ]
    
    def filter(self, record: logging.LogRecord) -> bool:
        """
        Filters log records to remove sensitive information.
        
        Args:
            record: The log record to filter
            
        Returns:
            True to include the record, False to exclude it
        """
        # Sanitize extra attributes
        if hasattr(record, "__dict__"):
            for key, value in record.__dict__.items():
                if key not in ["args", "asctime", "created", "exc_info", "exc_text", "filename",
                            "funcName", "id", "levelname", "levelno", "lineno", "module",
                            "msecs", "message", "msg", "name", "pathname", "process",
                            "processName", "relativeCreated", "stack_info", "thread", "threadName"]:
                    setattr(record, key, sanitize_log_data(value))
        
        # Sanitize log message if it's a string
        if isinstance(record.msg, str):
            for pattern in self.sensitive_patterns:
                record.msg = pattern.sub("[REDACTED]", record.msg)
        
        # Always include the record (with sanitized data)
        return True


class CorrelationIdFilter(logging.Filter):
    """
    Log filter that adds correlation ID to all log records.
    """
    
    def __init__(self):
        super().__init__()
    
    def filter(self, record: logging.LogRecord) -> bool:
        """
        Adds correlation ID to log records.
        
        Args:
            record: The log record to filter
            
        Returns:
            True to include the record, False to exclude it
        """
        # Add correlation ID to the record
        if not hasattr(record, "correlation_id"):
            setattr(record, "correlation_id", get_correlation_id())
        
        # Always include the record
        return True