# Tools API

## Introduction
The Amira Wellness Tools API provides endpoints for accessing, managing, and interacting with the tool library. This API enables users to browse emotional regulation tools by category, mark tools as favorites, track tool usage, and receive personalized recommendations based on their emotional state. All endpoints require authentication unless otherwise specified.

## Base URL
```
/tools
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

### GET /
```
GET /
```
#### Description
Get a paginated list of tools with optional filtering

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| categories | array of ToolCategory | No |  | Filter by tool categories |
| content_types | array of ToolContentType | No |  | Filter by content types |
| difficulties | array of ToolDifficulty | No |  | Filter by difficulty levels |
| target_emotions | array of EmotionType | No |  | Filter by target emotions |
| max_duration | integer | No |  | Maximum duration in minutes |
| is_premium | boolean | No |  | Filter by premium status |
| favorites_only | boolean | No |  | Show only favorited tools |
| search_query | string | No |  | Search term for tool name or description |
| page | integer | No | 1 | Page number for pagination |
| page_size | integer | No | 10 | Number of items per page (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of tools
schema:
    items: array of Tool objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          name: Respiración 4-7-8
          description: Una técnica de respiración para reducir la ansiedad y promover la calma
          category: BREATHING
          content_type: GUIDED_EXERCISE
          content:
              steps:
                  - order: 1
                    title: Preparación
                    description: Siéntate en una posición cómoda con la espalda recta
                    duration: 30
                  - order: 2
                    title: Inhala
                    description: Inhala por la nariz durante 4 segundos
                    duration: 4
                  - order: 3
                    title: Mantén
                    description: Mantén la respiración durante 7 segundos
                    duration: 7
                  - order: 4
                    title: Exhala
                    description: Exhala por la boca durante 8 segundos
                    duration: 8
              repetitions: 5
          estimated_duration: 5
          difficulty: BEGINNER
          target_emotions: [ANXIETY, STRESS, OVERWHELM]
          icon_url: https://assets.amirawellness.com/tools/breathing_4-7-8.png
          is_active: True
          is_premium: False
          is_favorited: True
          usage_count: 12
          category_metadata:
              display_name: Respiración
              display_name_en: Breathing
              description: Ejercicios de respiración para reducir la ansiedad y promover la calma
              color: "#A7D2E8"
          content_type_metadata:
              display_name: Ejercicio Guiado
              display_name_en: Guided Exercise
              icon: guided.png
          created_at: 2023-01-15T10:30:00Z
          updated_at: 2023-01-15T10:30:00Z
        - id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          name: Meditación para la Ansiedad
          description: Una meditación guiada para aliviar la ansiedad
          category: MEDITATION
          content_type: AUDIO
          content:
              audio_url: https://assets.amirawellness.com/meditations/anxiety_meditation_es.mp3
              transcript: Comienza encontrando una posición cómoda...
          estimated_duration: 10
          difficulty: BEGINNER
          target_emotions: [ANXIETY, FEAR, STRESS]
          icon_url: https://assets.amirawellness.com/tools/anxiety_meditation.png
          is_active: True
          is_premium: False
          is_favorited: False
          usage_count: 5
          category_metadata:
              display_name: Meditación
              display_name_en: Meditation
              description: Prácticas de meditación para cultivar la atención plena
              color: "#C8A2C8"
          content_type_metadata:
              display_name: Audio
              display_name_en: Audio
              icon: audio.png
          created_at: 2023-01-20T14:45:00Z
          updated_at: 2023-01-20T14:45:00Z
    total: 45
    page: 1
    page_size: 10
    pages: 5
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        categories: categories must be an array of valid ToolCategory values
        max_duration: max_duration must be a positive integer
        page_size: page_size must not exceed 50
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
This endpoint returns tools with pagination and optional filtering. The is_favorited field indicates whether the current user has favorited each tool.

### GET /{tool_id}
```
GET /{tool_id}
```
#### Description
Get a specific tool by ID

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| tool_id | string (UUID) | Yes | Unique identifier of the tool |

#### Responses
##### 200 OK
```
description: Tool details
schema: Tool object
example:
    id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    name: Respiración 4-7-8
    description: Una técnica de respiración para reducir la ansiedad y promover la calma
    category: BREATHING
    content_type: GUIDED_EXERCISE
    content:
        steps:
            - order: 1
              title: Preparación
              description: Siéntate en una posición cómoda con la espalda recta
              duration: 30
            - order: 2
              title: Inhala
              description: Inhala por la nariz durante 4 segundos
              duration: 4
            - order: 3
              title: Mantén
              description: Mantén la respiración durante 7 segundos
              duration: 7
            - order: 4
              title: Exhala
              description: Exhala por la boca durante 8 segundos
              duration: 8
        repetitions: 5
    estimated_duration: 5
    difficulty: BEGINNER
    target_emotions: [ANXIETY, STRESS, OVERWHELM]
    icon_url: https://assets.amirawellness.com/tools/breathing_4-7-8.png
    is_active: True
    is_premium: False
    is_favorited: True
    usage_count: 12
    category_metadata:
        display_name: Respiración
        display_name_en: Breathing
        description: Ejercicios de respiración para reducir la ansiedad y promover la calma
        color: "#A7D2E8"
    content_type_metadata:
        display_name: Ejercicio Guiado
        display_name_en: Guided Exercise
        icon: guided.png
    created_at: 2023-01-15T10:30:00Z
    updated_at: 2023-01-15T10:30:00Z
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Tool not found
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
This endpoint returns detailed information about a specific tool. The is_favorited field indicates whether the current user has favorited the tool.

### GET /category/{category}
```
GET /category/{category}
```
#### Description
Get tools by category

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| category | string (ToolCategory) | Yes | Tool category (BREATHING, MEDITATION, SOMATIC, JOURNALING, GRATITUDE) |

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| skip | integer | No | 0 | Number of items to skip |
| limit | integer | No | 10 | Maximum number of items to return (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of tools in the category
schema: Same as GET / response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        category: category must be a valid ToolCategory
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
This endpoint returns tools filtered by a specific category. The response includes pagination information.

### GET /emotion/{emotion_type}
```
GET /emotion/{emotion_type}
```
#### Description
Get tools targeting a specific emotion

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| emotion_type | string (EmotionType) | Yes | Emotion type (e.g., ANXIETY, STRESS, SADNESS) |

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| skip | integer | No | 0 | Number of items to skip |
| limit | integer | No | 10 | Maximum number of items to return (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of tools targeting the emotion
schema: Same as GET / response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        emotion_type: emotion_type must be a valid EmotionType
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
This endpoint returns tools that target a specific emotion. The response includes pagination information.

### GET /favorites
```
GET /favorites
```
#### Description
Get tools favorited by the current user

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| skip | integer | No | 0 | Number of items to skip |
| limit | integer | No | 10 | Maximum number of items to return (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of favorited tools
schema: Same as GET / response
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
This endpoint returns tools that the current user has marked as favorites. The response includes pagination information.

### POST /favorites/{tool_id}
```
POST /favorites/{tool_id}
```
#### Description
Toggle favorite status of a tool for the current user

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| tool_id | string (UUID) | Yes | Unique identifier of the tool |

#### Responses
##### 200 OK
```
description: New favorite status
schema:
    is_favorited: boolean
example:
    is_favorited: True
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Tool not found
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
This endpoint toggles the favorite status of a tool for the current user. If the tool was not favorited, it will be added to favorites. If it was already favorited, it will be removed from favorites.

### POST /usage
```
POST /usage
```
#### Description
Record a user's usage of a tool

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    tool_id: UUID (required)
    duration_seconds: integer (required)
    completion_status: string (required, one of: 'COMPLETED', 'PARTIAL', 'ABANDONED')
    pre_checkin_id: UUID (optional)
    post_checkin_id: UUID (optional)
example:
    tool_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    duration_seconds: 300
    completion_status: COMPLETED
    pre_checkin_id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
    post_checkin_id: d4e5f6a7-b8c9-0123-defg-456789abcdef
```

#### Responses
##### 201 Created
```
description: Created usage record
schema:
    id: UUID
    user_id: UUID
    tool_id: UUID
    duration_seconds: integer
    completed_at: datetime
    completion_status: string
    pre_checkin_id: UUID or null
    post_checkin_id: UUID or null
    created_at: datetime
    tool: Tool object (optional)
    pre_checkin: EmotionalState object (optional)
    post_checkin: EmotionalState object (optional)
example:
    id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
    user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
    tool_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    duration_seconds: 300
    completed_at: 2023-06-15T10:35:00Z
    completion_status: COMPLETED
    pre_checkin_id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
    post_checkin_id: d4e5f6a7-b8c9-0123-defg-456789abcdef
    created_at: 2023-06-15T10:35:00Z
    tool:
        id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
        name: Respiración 4-7-8
        category: BREATHING
        category_metadata:
            display_name: Respiración
            color: "#A7D2E8"
    pre_checkin:
        emotion_type: ANXIETY
        intensity: 7
    post_checkin:
        emotion_type: CALM
        intensity: 5
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        tool_id: tool_id is required
        duration_seconds: duration_seconds must be a positive integer
        completion_status: completion_status must be one of: COMPLETED, PARTIAL, ABANDONED
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Tool not found
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
This endpoint records a user's usage of a tool. The pre_checkin_id and post_checkin_id fields are optional and can be used to link emotional check-ins to the tool usage.

### GET /usage
```
GET /usage
```
#### Description
Get a user's tool usage history

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| tool_id | string (UUID) | No |  | Filter by tool ID |
| categories | array of ToolCategory | No |  | Filter by tool categories |
| completion_statuses | array of string | No |  | Filter by completion statuses |
| min_duration | integer | No |  | Minimum duration in seconds |
| max_duration | integer | No |  | Maximum duration in seconds |
| start_date | string (ISO 8601 datetime) | No |  | Start date for filtering |
| end_date | string (ISO 8601 datetime) | No |  | End date for filtering |
| page | integer | No | 1 | Page number for pagination |
| page_size | integer | No | 10 | Number of items per page (max: 50) |

#### Responses
##### 200 OK
```
description: Paginated list of tool usage records
schema:
    items: array of ToolUsage objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
          user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          tool_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          duration_seconds: 300
          completed_at: 2023-06-15T10:35:00Z
          completion_status: COMPLETED
          pre_checkin_id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
          post_checkin_id: d4e5f6a7-b8c9-0123-defg-456789abcdef
          created_at: 2023-06-15T10:35:00Z
          tool:
              id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
              name: Respiración 4-7-8
              category: BREATHING
              category_metadata:
                  display_name: Respiración
                  color: "#A7D2E8"
          pre_checkin:
              emotion_type: ANXIETY
              intensity: 7
          post_checkin:
              emotion_type: CALM
              intensity: 5
    total: 25
    page: 1
    page_size: 10
    pages: 3
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
This endpoint returns a user's tool usage history with optional filtering. The response includes pagination information.

### GET /usage/stats/{tool_id}
```
GET /usage/stats/{tool_id}
```
#### Description
Get usage statistics for a specific tool

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| tool_id | string (UUID) | Yes | Unique identifier of the tool |

#### Responses
##### 200 OK
```
description: Tool usage statistics
schema:
    total_usages: integer
    total_duration_seconds: integer
    usages_by_category: object (category name to count)
    usages_by_completion_status: object (status to count)
    most_used_tools: array of objects with tool usage data
    usage_by_time_of_day: object (time of day to count)
    usage_by_day_of_week: object (day of week to count)
example:
    total_usages: 120
    total_duration_seconds: 36000
    usages_by_category:
        BREATHING: 45
        MEDITATION: 35
        SOMATIC: 20
        JOURNALING: 15
        GRATITUDE: 5
    usages_by_completion_status:
        COMPLETED: 95
        PARTIAL: 20
        ABANDONED: 5
    most_used_tools:
        - tool_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          name: Respiración 4-7-8
          category: BREATHING
          usage_count: 25
          average_duration_seconds: 300
        - tool_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          name: Meditación para la Ansiedad
          category: MEDITATION
          usage_count: 18
          average_duration_seconds: 600
    usage_by_time_of_day:
        MORNING: 45
        AFTERNOON: 30
        EVENING: 35
        NIGHT: 10
    usage_by_day_of_week:
        MONDAY: 25
        TUESDAY: 20
        WEDNESDAY: 15
        THURSDAY: 18
        FRIDAY: 12
        SATURDAY: 15
        SUNDAY: 15
```

##### 401 Unauthorized
```
description: Unauthorized
schema:
    detail: string
example:
    detail: Not authenticated
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Tool not found
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
This endpoint returns usage statistics for a specific tool across all users. This endpoint is primarily for administrative purposes.

### POST /recommendations
```
POST /recommendations
```
#### Description
Get recommended tools based on emotional state

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    emotion_type: EmotionType (required)
    intensity: integer (1-10) (required)
    limit: integer (optional, default: 5)
    include_premium: boolean (optional, default: false)
example:
    emotion_type: ANXIETY
    intensity: 7
    limit: 3
    include_premium: False
```

#### Responses
##### 200 OK
```
description: Tool recommendations
schema:
    emotion_type: EmotionType
    intensity: integer
    recommendations: array of ToolRecommendation objects
example:
    emotion_type: ANXIETY
    intensity: 7
    recommendations:
        - tool_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          name: Respiración 4-7-8
          description: Una técnica de respiración para reducir la ansiedad y promover la calma
          category: BREATHING
          category_display_name: Respiración
          content_type: GUIDED_EXERCISE
          estimated_duration: 5
          relevance_score: 0.95
          reason_for_recommendation: Highly effective for reducing anxiety
          is_premium: False
          is_favorited: True
        - tool_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          name: Meditación para la Ansiedad
          description: Una meditación guiada para aliviar la ansiedad
          category: MEDITATION
          category_display_name: Meditación
          content_type: AUDIO
          estimated_duration: 10
          relevance_score: 0.87
          reason_for_recommendation: Helps calm anxious thoughts
          is_premium: False
          is_favorited: False
        - tool_id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
          name: Ejercicio de Enraizamiento
          description: Una técnica para conectar con el presente y reducir la ansiedad
          category: SOMATIC
          category_display_name: Ejercicios Somáticos
          content_type: GUIDED_EXERCISE
          estimated_duration: 8
          relevance_score: 0.82
          reason_for_recommendation: Grounds you in the present moment
          is_premium: False
          is_favorited: False
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        emotion_type: emotion_type must be a valid EmotionType
        intensity: intensity must be between 1 and 10
        limit: limit must be a positive integer
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
This endpoint provides personalized tool recommendations based on the specified emotional state. The recommendations are ranked by relevance score and take into account the user's preferences and usage history.

### GET /categories
```
GET /categories
```
#### Description
Get all tool categories with metadata

#### Authentication Required
False

#### Responses
##### 200 OK
```
description: List of tool categories with metadata
schema: array of category objects
example:
    - id: BREATHING
      display_name: Respiración
      display_name_en: Breathing
      description: Ejercicios de respiración para reducir la ansiedad y promover la calma
      description_en: Breathing exercises to reduce anxiety and promote calm
      icon: breathing.png
      color: "#A7D2E8"
    - id: MEDITATION
      display_name: Meditación
      display_name_en: Meditation
      description: Prácticas de meditación para cultivar la atención plena
      description_en: Meditation practices to cultivate mindfulness
      icon: meditation.png
      color: "#C8A2C8"
    - id: SOMATIC
      display_name: Ejercicios Somáticos
      display_name_en: Somatic Exercises
      description: Ejercicios físicos para liberar tensión y conectar con el cuerpo
      description_en: Physical exercises to release tension and connect with the body
      icon: somatic.png
      color: "#FFDAB9"
    - id: JOURNALING
      display_name: Journaling
      display_name_en: Journaling
      description: Prompts de escritura para la reflexión y expresión emocional
      description_en: Writing prompts for reflection and emotional expression
      icon: journaling.png
      color: "#B0E0E6"
    - id: GRATITUDE
      display_name: Gratitud
      display_name_en: Gratitude
      description: Prácticas para cultivar la gratitud y apreciación
      description_en: Practices to cultivate gratitude and appreciation
      icon: gratitude.png
      color: "#FFD700"
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
This endpoint returns all tool categories with their metadata. This endpoint does not require authentication.

### GET /content-types
```
GET /content-types
```
#### Description
Get all tool content types with metadata

#### Authentication Required
False

#### Responses
##### 200 OK
```
description: List of tool content types with metadata
schema: array of content type objects
example:
    - id: TEXT
      display_name: Texto
      display_name_en: Text
      icon: text.png
    - id: AUDIO
      display_name: Audio
      display_name_en: Audio
      icon: audio.png
    - id: VIDEO
      display_name: Video
      display_name_en: Video
      icon: video.png
    - id: INTERACTIVE
      display_name: Interactivo
      display_name_en: Interactive
      icon: interactive.png
    - id: GUIDED_EXERCISE
      display_name: Ejercicio Guiado
      display_name_en: Guided Exercise
      icon: guided.png
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
This endpoint returns all tool content types with their metadata. This endpoint does not require authentication.

### GET /stats
```
GET /stats
```
#### Description
Get overall statistics for the tool library (admin only)

#### Authentication Required
Yes

#### Responses
##### 200 OK