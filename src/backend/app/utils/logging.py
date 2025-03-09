"""
Utility module that provides simplified logging functions and helpers for the Amira Wellness application.
This module acts as a facade over the core logging functionality, making it easier for application
code to implement consistent, privacy-aware logging.
"""

import logging  # standard library
import typing  # standard library
import functools  # standard library
import time  # standard library
import inspect  # standard library
from typing import Any, Dict, List, Optional, Union, Callable, TypeVar

from ..core.logging import (
    get_logger,
    sanitize_log_data,
    get_correlation_id,
    set_correlation_id
)

# Global logger for this module
logger = get_logger(__name__)

# Type hints
T = TypeVar('T')


def configure_logger(module_name: str) -> logging.Logger:
    """
    Configures a logger for a specific module with appropriate handlers and formatters.
    
    Args:
        module_name: The name of the module requesting the logger
        
    Returns:
        Configured logger instance
    """
    return get_logger(module_name)


def log_info(message: str, context: Optional[Dict[str, Any]] = None, logger: Optional[logging.Logger] = None) -> None:
    """
    Logs a message at INFO level with optional context data.
    
    Args:
        message: The message to log
        context: Additional contextual data to include in the log
        logger: Logger to use (uses module logger if not provided)
    """
    if logger is None:
        logger = globals()['logger']
    
    if context is None:
        context = {}
    
    # Sanitize the context data to remove sensitive information
    sanitized_context = sanitize_log_data(context)
    
    # Add correlation ID to context if available
    correlation_id = get_correlation_id()
    if correlation_id:
        sanitized_context['correlation_id'] = correlation_id
    
    logger.info(message, extra=sanitized_context)


def log_warning(message: str, context: Optional[Dict[str, Any]] = None, logger: Optional[logging.Logger] = None) -> None:
    """
    Logs a message at WARNING level with optional context data.
    
    Args:
        message: The message to log
        context: Additional contextual data to include in the log
        logger: Logger to use (uses module logger if not provided)
    """
    if logger is None:
        logger = globals()['logger']
    
    if context is None:
        context = {}
    
    # Sanitize the context data to remove sensitive information
    sanitized_context = sanitize_log_data(context)
    
    # Add correlation ID to context if available
    correlation_id = get_correlation_id()
    if correlation_id:
        sanitized_context['correlation_id'] = correlation_id
    
    logger.warning(message, extra=sanitized_context)


def log_error(
    message: str, 
    context: Optional[Dict[str, Any]] = None, 
    exc: Optional[Exception] = None,
    logger: Optional[logging.Logger] = None
) -> None:
    """
    Logs a message at ERROR level with optional context data and exception details.
    
    Args:
        message: The message to log
        context: Additional contextual data to include in the log
        exc: Exception that caused the error (if applicable)
        logger: Logger to use (uses module logger if not provided)
    """
    if logger is None:
        logger = globals()['logger']
    
    if context is None:
        context = {}
    
    # Sanitize the context data to remove sensitive information
    sanitized_context = sanitize_log_data(context)
    
    # Add correlation ID to context if available
    correlation_id = get_correlation_id()
    if correlation_id:
        sanitized_context['correlation_id'] = correlation_id
    
    # Add exception details if provided
    if exc:
        sanitized_context['exception'] = {
            'type': type(exc).__name__,
            'message': str(exc)
        }
    
    logger.error(message, extra=sanitized_context, exc_info=exc is not None)


def log_critical(
    message: str, 
    context: Optional[Dict[str, Any]] = None, 
    exc: Optional[Exception] = None,
    logger: Optional[logging.Logger] = None
) -> None:
    """
    Logs a message at CRITICAL level with optional context data and exception details.
    
    Args:
        message: The message to log
        context: Additional contextual data to include in the log
        exc: Exception that caused the error (if applicable)
        logger: Logger to use (uses module logger if not provided)
    """
    if logger is None:
        logger = globals()['logger']
    
    if context is None:
        context = {}
    
    # Sanitize the context data to remove sensitive information
    sanitized_context = sanitize_log_data(context)
    
    # Add correlation ID to context if available
    correlation_id = get_correlation_id()
    if correlation_id:
        sanitized_context['correlation_id'] = correlation_id
    
    # Add exception details if provided
    if exc:
        sanitized_context['exception'] = {
            'type': type(exc).__name__,
            'message': str(exc)
        }
    
    logger.critical(message, extra=sanitized_context, exc_info=exc is not None)


def log_debug(message: str, context: Optional[Dict[str, Any]] = None, logger: Optional[logging.Logger] = None) -> None:
    """
    Logs a message at DEBUG level with optional context data.
    
    Args:
        message: The message to log
        context: Additional contextual data to include in the log
        logger: Logger to use (uses module logger if not provided)
    """
    if logger is None:
        logger = globals()['logger']
    
    if context is None:
        context = {}
    
    # Sanitize the context data to remove sensitive information
    sanitized_context = sanitize_log_data(context)
    
    # Add correlation ID to context if available
    correlation_id = get_correlation_id()
    if correlation_id:
        sanitized_context['correlation_id'] = correlation_id
    
    logger.debug(message, extra=sanitized_context)


def log_function_call(logger: Optional[logging.Logger] = None) -> Callable:
    """
    Decorator that logs function entry and exit with parameters and return value.
    
    Args:
        logger: Logger to use (uses module logger if not provided)
        
    Returns:
        Decorated function that logs its execution
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            nonlocal logger
            if logger is None:
                logger = globals()['logger']
            
            func_name = func.__name__
            module_name = func.__module__
            
            # Get parameter names
            signature = inspect.signature(func)
            param_names = list(signature.parameters.keys())
            
            # Create sanitized args and kwargs for logging
            arg_dict = {
                param_names[i]: args[i] for i in range(min(len(args), len(param_names)))
            }
            all_args = {**arg_dict, **kwargs}
            sanitized_args = sanitize_log_data(all_args)
            
            # Log function entry
            entry_context = {
                'function': func_name,
                'module': module_name,
                'parameters': sanitized_args
            }
            log_debug(f"Entering function: {func_name}", entry_context, logger)
            
            try:
                # Execute the function
                start_time = time.time()
                result = func(*args, **kwargs)
                execution_time = time.time() - start_time
                
                # Log function exit
                exit_context = {
                    'function': func_name,
                    'module': module_name,
                    'execution_time_ms': round(execution_time * 1000, 2),
                    'result': sanitize_log_data(result)
                }
                log_debug(f"Exiting function: {func_name}", exit_context, logger)
                
                return result
            except Exception as e:
                # Log exception
                error_context = {
                    'function': func_name,
                    'module': module_name,
                    'parameters': sanitized_args
                }
                log_error(f"Exception in function: {func_name}", error_context, e, logger)
                raise
        
        return wrapper
    
    return decorator


def timed_execution(logger: Optional[logging.Logger] = None) -> Callable:
    """
    Decorator that measures and logs the execution time of a function.
    
    Args:
        logger: Logger to use (uses module logger if not provided)
        
    Returns:
        Decorated function that logs its execution time
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            nonlocal logger
            if logger is None:
                logger = globals()['logger']
            
            func_name = func.__name__
            module_name = func.__module__
            
            # Execute the function and measure time
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                execution_time = time.time() - start_time
                
                # Log execution time
                log_info(
                    f"Function {func_name} executed in {round(execution_time * 1000, 2)} ms",
                    {'function': func_name, 'module': module_name, 'execution_time_ms': round(execution_time * 1000, 2)},
                    logger
                )
                
                return result
            except Exception as e:
                execution_time = time.time() - start_time
                log_error(
                    f"Function {func_name} failed after {round(execution_time * 1000, 2)} ms",
                    {'function': func_name, 'module': module_name, 'execution_time_ms': round(execution_time * 1000, 2)},
                    e,
                    logger
                )
                raise
        
        return wrapper
    
    return decorator


def with_correlation_id(correlation_id: Optional[str] = None) -> Callable:
    """
    Decorator that ensures a correlation ID is available during function execution.
    This helps with tracing requests across multiple services and components.
    
    Args:
        correlation_id: Specific correlation ID to use (generates new one if not provided)
        
    Returns:
        Decorated function with correlation ID context
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            # Set correlation ID for this execution context
            cid = correlation_id or get_correlation_id()
            set_correlation_id(cid)
            
            # Execute the function with correlation ID in context
            return func(*args, **kwargs)
        
        return wrapper
    
    return decorator


def mask_sensitive_data(data: Any, sensitive_fields: Optional[List[str]] = None) -> Any:
    """
    Utility function to mask sensitive data in strings or dictionaries.
    
    Args:
        data: The data to mask
        sensitive_fields: List of field names to consider sensitive
        
    Returns:
        Data with sensitive information masked
    """
    return sanitize_log_data(data, sensitive_fields)


class LogContext:
    """
    Context manager for adding structured context to logs within a code block.
    """
    
    def __init__(self, context: Dict[str, Any], logger: Optional[logging.Logger] = None) -> None:
        """
        Initializes the LogContext with context data and logger.
        
        Args:
            context: Context data to add to all logs within this context
            logger: Logger to use (uses module logger if not provided)
        """
        self._context = sanitize_log_data(context)
        self._logger = logger or globals()['logger']
    
    def __enter__(self) -> 'LogContext':
        """
        Enters the context manager.
        
        Returns:
            Self reference for use in with statement
        """
        log_info(f"Entering context: {self._context.get('name', 'unnamed')}", self._context, self._logger)
        return self
    
    def __exit__(self, exc_type: Optional[type], exc_val: Optional[Exception], exc_tb: Optional[Any]) -> bool:
        """
        Exits the context manager.
        
        Args:
            exc_type: Type of exception that occurred, if any
            exc_val: Exception instance that occurred, if any
            exc_tb: Traceback of exception that occurred, if any
            
        Returns:
            Whether exception was handled (always False to propagate exceptions)
        """
        if exc_val:
            log_error(
                f"Exception in context: {self._context.get('name', 'unnamed')}",
                self._context,
                exc_val,
                self._logger
            )
        else:
            log_info(f"Exiting context: {self._context.get('name', 'unnamed')}", self._context, self._logger)
        
        return False  # Don't suppress exceptions
    
    def info(self, message: str, additional_context: Optional[Dict[str, Any]] = None) -> None:
        """
        Logs a message at INFO level with the context data.
        
        Args:
            message: The message to log
            additional_context: Additional context to merge with stored context
        """
        context = {**self._context}
        if additional_context:
            context.update(sanitize_log_data(additional_context))
        
        log_info(message, context, self._logger)
    
    def warning(self, message: str, additional_context: Optional[Dict[str, Any]] = None) -> None:
        """
        Logs a message at WARNING level with the context data.
        
        Args:
            message: The message to log
            additional_context: Additional context to merge with stored context
        """
        context = {**self._context}
        if additional_context:
            context.update(sanitize_log_data(additional_context))
        
        log_warning(message, context, self._logger)
    
    def error(self, message: str, additional_context: Optional[Dict[str, Any]] = None, exc: Optional[Exception] = None) -> None:
        """
        Logs a message at ERROR level with the context data.
        
        Args:
            message: The message to log
            additional_context: Additional context to merge with stored context
            exc: Exception that caused the error (if applicable)
        """
        context = {**self._context}
        if additional_context:
            context.update(sanitize_log_data(additional_context))
        
        log_error(message, context, exc, self._logger)
    
    def debug(self, message: str, additional_context: Optional[Dict[str, Any]] = None) -> None:
        """
        Logs a message at DEBUG level with the context data.
        
        Args:
            message: The message to log
            additional_context: Additional context to merge with stored context
        """
        context = {**self._context}
        if additional_context:
            context.update(sanitize_log_data(additional_context))
        
        log_debug(message, context, self._logger)