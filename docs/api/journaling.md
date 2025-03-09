---
title: Journaling API
---

## Introduction
The Amira Wellness Journaling API provides endpoints for creating, retrieving, managing, and analyzing voice journal recordings with emotional check-ins. This API enables users to record their thoughts and feelings, track emotional shifts between pre and post journaling, and receive personalized tool recommendations based on their emotional state. All endpoints require authentication unless otherwise specified.

## Base URL
```
/journals
```

## Security
### Authentication
All endpoints require a valid access token in the `Authorization` header.
See [Authentication](docs/api/authentication.md) for authentication requirements and token handling.

### Authorization
All endpoints require a valid access token in the Authorization header

### Rate Limiting
Endpoints are rate-limited to prevent abuse. Exceeding limits will result in `429 Too Many Requests` responses.

## Endpoints

### POST /
```
POST /
```
#### Description
Create a new voice journal entry with audio data and emotional check-ins

#### Authentication Required
Yes

#### Request Body
```
content_type: multipart/form-data
schema:
    journal_data:
        type: object
        properties:
            title: string (optional)
            duration_seconds: integer (required)
            audio_format: string (required, e.g., 'aac', 'mp3')
            file_size_bytes: integer (required)
            pre_emotional_state:
                type: object
                properties:
                    emotion_type: EmotionType enum (required)
                    intensity: integer (1-10) (required)
                    notes: string (optional)
            post_emotional_state:
                type: object
                properties:
                    emotion_type: EmotionType enum (required)
                    intensity: integer (1-10) (required)
                    notes: string (optional)
    audio_file: file (required)
example:
    journal_data:
        title: Reflexiones sobre mi día
        duration_seconds: 180
        audio_format: aac
        file_size_bytes: 2457600
        pre_emotional_state:
            emotion_type: ANXIETY
            intensity: 7
            notes: Feeling anxious about upcoming presentation
        post_emotional_state:
            emotion_type: CALM
            intensity: 5
            notes: Feeling more centered after expressing my thoughts
    audio_file: [binary audio data]
```

#### Responses
##### 201 Created
```
description: Journal entry successfully created
schema:
    id: UUID
    user_id: UUID
    title: string
    duration_seconds: integer
    audio_format: string
    file_size_bytes: integer
    is_favorite: boolean
    is_uploaded: boolean
    pre_emotional_state:
        id: UUID
        emotion_type: EmotionType
        intensity: integer
        context: PRE_JOURNALING
        notes: string
        created_at: datetime
    post_emotional_state:
        id: UUID
        emotion_type: EmotionType
        intensity: integer
        context: POST_JOURNALING
        notes: string
        created_at: datetime
    created_at: datetime
    updated_at: datetime
example:
    id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
    title: Reflexiones sobre mi día
    duration_seconds: 180
    audio_format: aac
    file_size_bytes: 2457600
    is_favorite: False
    is_uploaded: True
    pre_emotional_state:
        id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
        emotion_type: ANXIETY
        intensity: 7
        context: PRE_JOURNALING
        notes: Feeling anxious about upcoming presentation
        created_at: 2023-06-15T10:30:00Z
    post_emotional_state:
        id: d4e5f6a7-b8c9-0123-defg-456789abcdef
        emotion_type: CALM
        intensity: 5
        context: POST_JOURNALING
        notes: Feeling more centered after expressing my thoughts
        created_at: 2023-06-15T10:35:00Z
    created_at: 2023-06-15T10:35:00Z
    updated_at: 2023-06-15T10:35:00Z
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        duration_seconds: duration_seconds must be positive
        audio_format: audio_format must be one of: aac, mp3, m4a
        pre_emotional_state: pre_emotional_state is required
        post_emotional_state: post_emotional_state is required
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 413 Payload Too Large
```
description: Payload Too Large
schema:
    detail: string
example:
    detail: Audio file exceeds maximum size limit of 20MB
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
The audio file is encrypted client-side before upload. The encryption_iv and encryption_tag must be included in the request for server verification. The maximum allowed file size is 20MB.

### GET /
```
GET /
```
#### Description
Get a paginated list of journal entries for the current user

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number for pagination |
| page_size | integer | No | 10 | Number of items per page (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of journal entries
schema:
    items: array of JournalSummary objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          title: Reflexiones sobre mi día
          duration_seconds: 180
          is_favorite: False
          pre_emotion_type: ANXIETY
          pre_emotion_intensity: 7
          post_emotion_type: CALM
          post_emotion_intensity: 5
          created_at: 2023-06-15T10:35:00Z
        - id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
          title: Pensamientos antes de dormir
          duration_seconds: 240
          is_favorite: True
          pre_emotion_type: OVERWHELM
          pre_emotion_intensity: 8
          post_emotion_type: CALM
          post_emotion_intensity: 6
          created_at: 2023-06-14T22:15:00Z
    total: 15
    page: 1
    page_size: 10
    pages: 2
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This endpoint returns a summary of journal entries. For detailed information about a specific journal, use the GET /{journal_id} endpoint.

### POST /filter
```
POST /filter
```
#### Description
Get journal entries with filtering options

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    start_date: datetime (optional)
    end_date: datetime (optional)
    emotion_types: array of EmotionType (optional)
    favorite_only: boolean (optional, default: false)
example:
    start_date: 2023-06-01T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    emotion_types: [ANXIETY, OVERWHELM]
    favorite_only: True
```

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number for pagination |
| page_size | integer | No | 10 | Number of items per page (max: 50) |

#### Responses
##### 200 OK
```
description: Filtered and paginated list of journal entries
schema: Same as GET / response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        emotion_types: emotion_types must be an array of valid emotion types
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
All filter parameters are optional. If not provided, no filtering is applied for that parameter.

### GET /{journal_id}
```
GET /{journal_id}
```
#### Description
Get a specific journal entry by ID

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Journal entry details
schema: Same as POST / 201 response
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to access this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
Users can only access their own journal entries.

### GET /{journal_id}/audio
```
GET /{journal_id}/audio
```
#### Description
Get the audio recording for a specific journal entry

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Audio file stream
content_type: audio/*
schema: Binary audio data
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to access this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
The audio file is returned in its original encrypted format. The client is responsible for decryption using the encryption details from the journal metadata.

### PATCH /{journal_id}
```
PATCH /{journal_id}
```
#### Description
Update a specific journal entry

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Request Body
```
content_type: application/json
schema:
    title: string (optional)
    is_favorite: boolean (optional)
example:
    title: Reflexiones importantes sobre mi día
    is_favorite: True
```

#### Responses
##### 200 OK
```
description: Journal entry updated successfully
schema: Same as POST / 201 response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        title: title must be a string
        is_favorite: is_favorite must be a boolean
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to update this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
Only the title and favorite status can be updated. The audio content and emotional check-ins cannot be modified after creation.

### POST /{journal_id}/favorite
```
POST /{journal_id}/favorite
```
#### Description
Mark a journal entry as favorite

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Journal entry marked as favorite
schema: Same as POST / 201 response
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to update this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This is a convenience endpoint for marking a journal as favorite. Alternatively, you can use the PATCH endpoint to update the is_favorite field.

### DELETE /{journal_id}/favorite
```
DELETE /{journal_id}/favorite
```
#### Description
Remove a journal entry from favorites

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Journal entry removed from favorites
schema: Same as POST / 201 response
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to update this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This is a convenience endpoint for removing a journal from favorites. Alternatively, you can use the PATCH endpoint to update the is_favorite field.

### DELETE /{journal_id}
```
DELETE /{journal_id}
```
#### Description
Delete a journal entry

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Journal entry successfully deleted
schema:
    success: boolean
    message: string
example:
    success: True
    message: Journal entry deleted successfully
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to delete this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This performs a soft delete. The journal entry is marked as deleted but remains in the database. It can be restored using the POST /{journal_id}/restore endpoint within 30 days.

### POST /{journal_id}/restore
```
POST /{journal_id}/restore
```
#### Description
Restore a deleted journal entry

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Journal entry successfully restored
schema: Same as POST / 201 response
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to restore this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found or cannot be restored
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
Journal entries can only be restored within 30 days of deletion. After that period, they are permanently removed from the system.

### GET /{journal_id}/emotional-shift
```
GET /{journal_id}/emotional-shift
```
#### Description
Get the emotional shift data between pre and post journaling states

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Emotional shift data
schema:
    pre_emotional_state: EmotionalState object
    post_emotional_state: EmotionalState object
    primary_shift: EmotionType
    intensity_change: integer
    trend_direction: string (INCREASING, DECREASING, STABLE)
    insights: array of strings
example:
    pre_emotional_state:
        id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
        emotion_type: ANXIETY
        intensity: 7
        context: PRE_JOURNALING
        notes: Feeling anxious about upcoming presentation
        created_at: 2023-06-15T10:30:00Z
    post_emotional_state:
        id: d4e5f6a7-b8c9-0123-defg-456789abcdef
        emotion_type: CALM
        intensity: 5
        context: POST_JOURNALING
        notes: Feeling more centered after expressing my thoughts
        created_at: 2023-06-15T10:35:00Z
    primary_shift: ANXIETY_TO_CALM
    intensity_change: -2
    trend_direction: IMPROVING
    insights:
        - Journaling helped reduce anxiety by 2 points
        - Transition from anxiety to calm is a positive emotional shift
        - This pattern is consistent with your previous journaling sessions
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to access this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This endpoint analyzes the emotional shift between pre and post journaling states and provides insights based on the user's emotional patterns.

### GET /stats
```
GET /stats
```
#### Description
Get journal usage statistics

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for statistics (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for statistics (default: current date) |

#### Responses
##### 200 OK
```
description: Journal usage statistics
schema:
    total_journals: integer
    total_duration_seconds: integer
    journals_by_emotion: object (emotion type to count mapping)
    journals_by_month: object (month to count mapping)
    significant_shifts: array of EmotionalShift objects
example:
    total_journals: 15
    total_duration_seconds: 3600
    journals_by_emotion:
        ANXIETY: 5
        OVERWHELM: 3
        FRUSTRATION: 2
        CALM: 3
        JOY: 2
    journals_by_month:
        2023-05: 5
        2023-06: 10
    significant_shifts:
        - pre_emotional_state:
            emotion_type: ANXIETY
            intensity: 8
          post_emotional_state:
            emotion_type: CALM
            intensity: 4
          primary_shift: ANXIETY_TO_CALM
          intensity_change: -4
          trend_direction: IMPROVING
          journal_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          created_at: 2023-06-10T15:30:00Z
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This endpoint provides aggregated statistics about the user's journaling habits and emotional patterns.

### POST /{journal_id}/export
```
POST /{journal_id}/export
```
#### Description
Export a journal entry to a downloadable format

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Request Body
```
content_type: application/json
schema:
    format: string (required, one of: 'encrypted', 'mp3', 'aac')
    include_metadata: boolean (optional, default: true)
    include_emotional_data: boolean (optional, default: true)
example:
    format: mp3
    include_metadata: True
    include_emotional_data: True
```

#### Responses
##### 200 OK
```
description: Export result with download URL
schema:
    download_url: string
    format: string
    file_size_bytes: integer
    expiration_seconds: integer
example:
    download_url: https://api.amirawellness.com/v1/journals/exports/f7g8h9i0-j1k2-3456-lmno-pqrstuvwxyz1
    format: mp3
    file_size_bytes: 2457600
    expiration_seconds: 3600
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        format: format must be one of: encrypted, mp3, aac
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to export this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
The download URL is temporary and will expire after the specified expiration_seconds. The 'encrypted' format preserves the end-to-end encryption, while other formats will be decrypted server-side (with lower security).

### GET /{journal_id}/download
```
GET /{journal_id}/download
```
#### Description
Get a temporary download URL for a journal audio file

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| expiration_seconds | integer | No | 3600 | Expiration time for the download URL in seconds (max: 86400) |

#### Responses
##### 200 OK
```
description: Download URL for the journal audio
schema:
    download_url: string
    expiration_seconds: integer
example:
    download_url: https://api.amirawellness.com/v1/journals/downloads/g8h9i0j1-k2l3-4567-mnop-qrstuvwxyz12
    expiration_seconds: 3600
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to download this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
The download URL is temporary and will expire after the specified expiration_seconds. The audio file is returned in its original encrypted format. The client is responsible for decryption.

### GET /{journal_id}/recommendations
```
GET /{journal_id}/recommendations
```
#### Description
Get tool recommendations based on journal emotional data

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| limit | integer | No | 5 | Maximum number of recommendations to return (max: 20) |

#### Responses
##### 200 OK
```
description: List of recommended tools
schema:
    recommendations: array of tool recommendation objects
example:
    recommendations:
        - tool_id: h9i0j1k2-l3m4-5678-nopq-rstuvwxyz123
          name: Respiración 4-7-8
          description: Una técnica de respiración para reducir la ansiedad y promover la calma
          category: BREATHING
          estimated_duration: 5
          relevance_score: 0.95
          reason: Highly effective for reducing anxiety
        - tool_id: i0j1k2l3-m4n5-6789-opqr-stuvwxyz1234
          name: Meditación para la Ansiedad
          description: Una meditación guiada para aliviar la ansiedad
          category: MEDITATION
          estimated_duration: 10
          relevance_score: 0.87
          reason: Helps calm anxious thoughts
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to access this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This endpoint provides personalized tool recommendations based on the emotional data from the journal entry. The recommendations are ranked by relevance score.

### POST /{journal_id}/sync
```
POST /{journal_id}/sync
```
#### Description
Synchronize a journal recording to cloud storage

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|---------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Synchronization result
schema:
    success: boolean
    message: string
    is_uploaded: boolean
    s3_key: string
example:
    success: True
    message: Journal successfully synchronized to cloud storage
    is_uploaded: True
    s3_key: journals/user-b2c3d4e5/a1b2c3d4-e5f6-7890-abcd-1234567890ab.aac
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 403 Forbidden
```
description: Forbidden
schema:
    detail: string
example:
    detail: Not authorized to sync this journal entry
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Journal entry not found
```

##### 429 Too Many Requests
```
description: Too many requests
schema:
    detail: string
example:
    detail: Rate limit exceeded. Try again in 60 seconds.
```

#### Notes
This endpoint is typically used by the mobile application to ensure that locally recorded journals are properly synchronized to cloud storage. It's useful in scenarios where the initial upload was interrupted or failed.

## Data Models

### EmotionType
```
description: Enumeration of emotion types supported by the application
values:
    - JOY
    - SADNESS
    - ANGER
    - FEAR
    - DISGUST
    - SURPRISE
    - TRUST
    - ANTICIPATION
    - GRATITUDE
    - CONTENTMENT
    - ANXIETY
    - FRUSTRATION
    - OVERWHELM
    - CALM
    - HOPE
    - LONELINESS
```

### EmotionContext
```
description: Enumeration of contexts for emotional check-ins
values:
    - PRE_JOURNALING
    - POST_JOURNALING
    - STANDALONE
    - TOOL_USAGE
    - DAILY_CHECK_IN
```

### TrendDirection
```
description: Enumeration of trend directions for emotional analysis
values:
    - INCREASING
    - DECREASING
    - STABLE
    - FLUCTUATING
```

### EmotionalStateBase
```
description: Base schema for emotional state data
properties:
    emotion_type: EmotionType (required)
    intensity: integer (1-10) (required)
    notes: string (optional)
```

### EmotionalState
```
description: Schema for emotional state data in responses
properties:
    id: UUID
    emotion_type: EmotionType
    intensity: integer (1-10)
    context: EmotionContext
    notes: string
    created_at: datetime
```

### JournalBase