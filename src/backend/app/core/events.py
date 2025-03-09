import enum
import uuid
import datetime
import asyncio
import functools
from typing import Dict, Any, List, Callable, Optional, Union

from .logging import get_logger
from .config import settings

# Create a logger for this module
logger = get_logger(__name__)


class EventType(enum.Enum):
    """
    Enumeration of event types in the Amira Wellness application.
    """
    # User events
    USER_CREATED = "user.created"
    USER_UPDATED = "user.updated"
    USER_DELETED = "user.deleted"
    
    # Journal events
    JOURNAL_CREATED = "journal.created"
    JOURNAL_UPDATED = "journal.updated"
    JOURNAL_DELETED = "journal.deleted"
    
    # Emotional check-in events
    EMOTIONAL_CHECKIN_RECORDED = "emotional_checkin.recorded"
    
    # Tool events
    TOOL_USED = "tool.used"
    TOOL_FAVORITED = "tool.favorited"
    TOOL_UNFAVORITED = "tool.unfavorited"
    
    # Progress tracking events
    STREAK_UPDATED = "streak.updated"
    STREAK_BROKEN = "streak.broken"
    ACHIEVEMENT_UNLOCKED = "achievement.unlocked"
    
    # Notification events
    NOTIFICATION_CREATED = "notification.created"
    NOTIFICATION_SENT = "notification.sent"
    
    # System events
    SYSTEM_ERROR = "system.error"


class Event:
    """
    Represents an event in the system with type, payload, and metadata.
    """
    
    def __init__(
        self, 
        event_type: EventType, 
        payload: Dict[str, Any],
        event_id: Optional[str] = None,
        correlation_id: Optional[str] = None
    ):
        """
        Initialize a new event with the specified type and payload.
        
        Args:
            event_type: The type of the event
            payload: Data associated with the event
            event_id: Optional unique identifier for the event (generated if not provided)
            correlation_id: Optional identifier for tracing related events
        """
        self.type = event_type
        self.payload = payload
        self.id = event_id or str(uuid.uuid4())
        self.timestamp = datetime.datetime.utcnow()
        self.correlation_id = correlation_id
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Converts the event to a dictionary representation.
        
        Returns:
            Dictionary representation of the event
        """
        result = {
            "id": self.id,
            "type": self.type.value,
            "payload": self.payload,
            "timestamp": self.timestamp.isoformat()
        }
        
        if self.correlation_id:
            result["correlation_id"] = self.correlation_id
            
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Event':
        """
        Creates an Event object from a dictionary representation.
        
        Args:
            data: Dictionary containing event data
            
        Returns:
            Event object created from the dictionary
        """
        event_type = EventType(data["type"])
        payload = data["payload"]
        event_id = data.get("id")
        correlation_id = data.get("correlation_id")
        
        return cls(event_type, payload, event_id, correlation_id)


class EventBus:
    """
    Central event bus that manages event publishing and subscription.
    """
    
    def __init__(self):
        """
        Initialize a new event bus with empty subscribers.
        """
        self._subscribers: Dict[EventType, List[Callable]] = {}
        self._async_handlers: Dict[Callable, bool] = {}
    
    def publish(self, event: Event, async_processing: bool = False) -> None:
        """
        Publishes an event to all subscribers of its type.
        
        Args:
            event: The event to publish
            async_processing: Whether to process the event asynchronously
        """
        if settings.ENABLE_EVENT_LOGGING:
            logger.debug(f"Publishing event: {event.type.value}", 
                        extra={"event_id": event.id, "event_type": event.type.value})
        
        subscribers = self.get_subscribers(event.type)
        
        if not subscribers:
            logger.debug(f"No subscribers for event: {event.type.value}")
            return
        
        if async_processing:
            # Process async handlers asynchronously
            for handler in subscribers:
                if self._async_handlers.get(handler, False):
                    asyncio.create_task(self._call_async_handler(handler, event))
                else:
                    try:
                        handler(event)
                    except Exception as e:
                        logger.error(
                            f"Error in event handler for {event.type.value}: {str(e)}",
                            extra={"event_id": event.id, "handler": handler.__name__},
                            exc_info=True
                        )
        else:
            # Process all handlers synchronously
            for handler in subscribers:
                try:
                    if self._async_handlers.get(handler, False):
                        # Call async handler but don't await it
                        asyncio.create_task(self._call_async_handler(handler, event))
                    else:
                        handler(event)
                except Exception as e:
                    logger.error(
                        f"Error in event handler for {event.type.value}: {str(e)}",
                        extra={"event_id": event.id, "handler": handler.__name__},
                        exc_info=True
                    )
    
    async def _call_async_handler(self, handler: Callable, event: Event) -> None:
        """
        Calls an async event handler and handles exceptions.
        
        Args:
            handler: The async handler function to call
            event: The event to pass to the handler
        """
        try:
            await handler(event)
        except Exception as e:
            logger.error(
                f"Error in async event handler for {event.type.value}: {str(e)}",
                extra={"event_id": event.id, "handler": handler.__name__},
                exc_info=True
            )
    
    def subscribe(self, event_type: EventType, handler: Callable, is_async: bool = False) -> None:
        """
        Registers a handler function for specified event type.
        
        Args:
            event_type: The event type to subscribe to
            handler: The handler function to call when the event occurs
            is_async: Whether the handler is an async function
        """
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        
        if handler not in self._subscribers[event_type]:
            self._subscribers[event_type].append(handler)
            self._async_handlers[handler] = is_async
            
            if settings.ENABLE_EVENT_LOGGING:
                logger.debug(
                    f"Subscribed handler to event: {event_type.value}",
                    extra={"handler": handler.__name__, "is_async": is_async}
                )
    
    def unsubscribe(self, event_type: EventType, handler: Callable) -> bool:
        """
        Removes a handler function from specified event type.
        
        Args:
            event_type: The event type to unsubscribe from
            handler: The handler function to remove
            
        Returns:
            True if handler was found and removed, False otherwise
        """
        if event_type not in self._subscribers:
            return False
        
        if handler in self._subscribers[event_type]:
            self._subscribers[event_type].remove(handler)
            if handler in self._async_handlers:
                del self._async_handlers[handler]
                
            if settings.ENABLE_EVENT_LOGGING:
                logger.debug(
                    f"Unsubscribed handler from event: {event_type.value}",
                    extra={"handler": handler.__name__}
                )
            return True
            
        return False
    
    def get_subscribers(self, event_type: EventType) -> List[Callable]:
        """
        Returns the list of subscribers for an event type.
        
        Args:
            event_type: The event type to get subscribers for
            
        Returns:
            List of handler functions for the event type
        """
        return self._subscribers.get(event_type, [])
    
    def clear_all_subscribers(self) -> None:
        """
        Removes all subscribers from the event bus.
        
        This is primarily useful for testing.
        """
        self._subscribers.clear()
        self._async_handlers.clear()
        logger.debug("Cleared all event subscribers")


# Create a singleton instance of the event bus
event_bus = EventBus()


def publish_event(
    event_type: EventType, 
    payload: Dict[str, Any], 
    async_processing: Optional[bool] = None
) -> str:
    """
    Publishes an event to the event bus for processing by subscribers.
    
    Args:
        event_type: The type of event to publish
        payload: Data associated with the event
        async_processing: Whether to process the event asynchronously
        
    Returns:
        ID of the published event
    """
    event = Event(event_type, payload)
    
    if settings.ENABLE_EVENT_LOGGING:
        logger.debug(
            f"Publishing event: {event_type.value}",
            extra={"event_id": event.id, "payload": payload}
        )
    
    # Use async processing by default in production environments
    if async_processing is None:
        async_processing = settings.ENVIRONMENT != "development"
    
    event_bus.publish(event, async_processing)
    return event.id


def subscribe(
    event_types: Union[EventType, List[EventType]], 
    async_handler: Optional[bool] = None
) -> Callable:
    """
    Registers a handler function to be called when specified events occur.
    
    This can be used as a decorator:
    
    @subscribe(EventType.USER_CREATED)
    def handle_user_created(event):
        # Handle the event
        pass
    
    Args:
        event_types: One or more event types to subscribe to
        async_handler: Whether the handler is an async function
        
    Returns:
        Decorator function that registers the handler
    """
    def decorator(handler: Callable) -> Callable:
        # Ensure event_types is a list
        types_list = event_types if isinstance(event_types, list) else [event_types]
        
        # Determine if handler is async if not explicitly specified
        is_async = async_handler
        if is_async is None:
            is_async = asyncio.iscoroutinefunction(handler)
        
        # Register the handler for each event type
        for event_type in types_list:
            event_bus.subscribe(event_type, handler, is_async)
        
        return handler
    
    return decorator


def unsubscribe(
    handler: Callable, 
    event_types: Optional[Union[EventType, List[EventType]]] = None
) -> bool:
    """
    Removes a handler function from the specified event types.
    
    Args:
        handler: The handler function to unsubscribe
        event_types: One or more event types to unsubscribe from.
                    If None, unsubscribes from all event types.
                    
    Returns:
        True if handler was successfully unsubscribed, False otherwise
    """
    if event_types is None:
        # Unsubscribe from all event types
        success = False
        for event_type in EventType:
            if event_bus.unsubscribe(event_type, handler):
                success = True
        return success
    
    # Ensure event_types is a list
    types_list = event_types if isinstance(event_types, list) else [event_types]
    
    # Unsubscribe from each event type
    success = False
    for event_type in types_list:
        if event_bus.unsubscribe(event_type, handler):
            success = True
    
    return success


def get_subscribers(event_type: EventType) -> List[Callable]:
    """
    Returns a list of subscribers for a specific event type.
    
    Args:
        event_type: The event type to get subscribers for
        
    Returns:
        List of handler functions subscribed to the event type
    """
    return event_bus.get_subscribers(event_type)