# Emotions API

## Introduction
The Amira Wellness Emotions API provides endpoints for recording, retrieving, analyzing, and visualizing emotional data. This API enables users to log their emotional states, track emotional patterns over time, receive personalized insights, and get tool recommendations based on their emotional needs. All endpoints require authentication unless otherwise specified.

## Base URL
```
/emotions
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
Create a new emotional check-in

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    emotion_type: EmotionType enum (required)
    intensity: integer (1-10) (required)
    context: EmotionContext enum (required)
    notes: string (optional)
    related_journal_id: UUID (optional)
    related_tool_id: UUID (optional)
example:
    emotion_type: ANXIETY
    intensity: 7
    context: STANDALONE
    notes: Feeling anxious about upcoming presentation
    related_journal_id: None
    related_tool_id: None
```

#### Responses
##### 201 Created
```
description: Emotional check-in successfully created
schema:
    id: UUID
    user_id: UUID
    emotion_type: EmotionType
    intensity: integer
    context: EmotionContext
    notes: string
    related_journal_id: UUID or null
    related_tool_id: UUID or null
    emotion_metadata:
        display_name: string
        category: EmotionCategory
        color: string (hex color code)
    created_at: datetime
    updated_at: datetime
example:
    id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
    emotion_type: ANXIETY
    intensity: 7
    context: STANDALONE
    notes: Feeling anxious about upcoming presentation
    related_journal_id: None
    related_tool_id: None
    emotion_metadata:
        display_name: Ansiedad
        category: NEGATIVE
        color: #8B0000
    created_at: 2023-06-15T10:30:00Z
    updated_at: 2023-06-15T10:30:00Z
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
        context: context must be a valid EmotionContext
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
This endpoint creates a standalone emotional check-in. For check-ins related to journaling, use the voice journaling endpoints which internally handle the emotional check-in process.

### GET /
```
GET /
```
#### Description
Get a paginated list of emotional check-ins for the current user

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
description: Paginated list of emotional check-ins
schema:
    items: array of EmotionalState objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          emotion_type: ANXIETY
          intensity: 7
          context: STANDALONE
          notes: Feeling anxious about upcoming presentation
          related_journal_id: None
          related_tool_id: None
          emotion_metadata:
              display_name: Ansiedad
              category: NEGATIVE
              color: #8B0000
          created_at: 2023-06-15T10:30:00Z
          updated_at: 2023-06-15T10:30:00Z
        - id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
          user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          emotion_type: CALM
          intensity: 5
          context: TOOL_USAGE
          notes: Feeling calmer after breathing exercise
          related_journal_id: None
          related_tool_id: h9i0j1k2-l3m4-5678-nopq-rstuvwxyz123
          emotion_metadata:
              display_name: Calma
              category: POSITIVE
              color: #5F9EA0
          created_at: 2023-06-14T15:45:00Z
          updated_at: 2023-06-14T15:45:00Z
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
This endpoint returns all emotional check-ins for the current user. For filtered results, use the POST /filter endpoint.

### POST /filter
```
POST /filter
```
#### Description
Filter emotional check-ins based on criteria

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    emotion_types: array of EmotionType (optional)
    contexts: array of EmotionContext (optional)
    min_intensity: integer (optional)
    max_intensity: integer (optional)
    start_date: datetime (optional)
    end_date: datetime (optional)
    related_journal_id: UUID (optional)
    related_tool_id: UUID (optional)
    notes_contains: string (optional)
example:
    emotion_types: [ANXIETY, FRUSTRATION]
    contexts: [STANDALONE, PRE_JOURNALING]
    min_intensity: 5
    max_intensity: 10
    start_date: 2023-06-01T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
```

#### Query Parameters
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number for pagination |
| page_size | integer | No | 10 | Number of items per page (max: 50) |

#### Responses
##### 200 OK
```
description: Filtered and paginated list of emotional check-ins
schema: Same as GET / response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        emotion_types: emotion_types must be an array of valid EmotionType values
        min_intensity: min_intensity must not be greater than max_intensity
        start_date: start_date must be a valid ISO 8601 datetime
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

### GET /{checkin_id}
```
GET /{checkin_id}
```
#### Description
Get a specific emotional check-in by ID

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| checkin_id | string (UUID) | Yes | Unique identifier of the emotional check-in |

#### Responses
##### 200 OK
```
description: Emotional check-in details
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
    detail: Not authorized to access this emotional check-in
```

##### 404 Not Found
```
description: Not Found
schema:
    detail: string
example:
    detail: Emotional check-in not found
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
Users can only access their own emotional check-ins.

### GET /distribution
```
GET /distribution
```
#### Description
Get emotion distribution for the user within a date range

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for distribution (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for distribution (default: current date) |

#### Responses
##### 200 OK
```
description: Emotion distribution data
schema:
    start_date: datetime
    end_date: datetime
    total_check_ins: integer
    distribution: array of EmotionDistribution objects
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    total_check_ins: 45
    distribution:
        - emotion_type: ANXIETY
          display_name: Ansiedad
          color: #8B0000
          category: NEGATIVE
          count: 12
          percentage: 26.67
          average_intensity: 6.5
        - emotion_type: CALM
          display_name: Calma
          category: POSITIVE
          color: #5F9EA0
          count: 10
          percentage: 22.22
          average_intensity: 5.8
        - emotion_type: FRUSTRATION
          display_name: Frustración
          category: NEGATIVE
          color: #B22222
          count: 8
          percentage: 17.78
          average_intensity: 7.2
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
This endpoint provides aggregated statistics about the user's emotional distribution over time.

### POST /trends
```
POST /trends
```
#### Description
Analyze emotional trends for the user over a specified time period

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    start_date: datetime (required)
    end_date: datetime (required)
    period_type: PeriodType enum (required, one of: DAY, WEEK, MONTH)
    emotion_types: array of EmotionType (optional)
    include_insights: boolean (optional, default: false)
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    period_type: WEEK
    emotion_types: [ANXIETY, CALM, FRUSTRATION]
    include_insights: True
```

#### Responses
##### 200 OK
```
description: Emotional trend analysis results
schema:
    start_date: datetime
    end_date: datetime
    period_type: PeriodType
    trends: array of EmotionalTrend objects
    insights: array of EmotionalInsight objects (if requested)
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    period_type: WEEK
    trends:
        - emotion_type: ANXIETY
          display_name: Ansiedad
          color: #8B0000
          data_points:
              - period_value: 2023-W20
                emotion_type: ANXIETY
                average_intensity: 7.5
                occurrence_count: 4
                min_intensity: 6
                max_intensity: 9
              - period_value: 2023-W21
                emotion_type: ANXIETY
                average_intensity: 6.8
                occurrence_count: 5
                min_intensity: 5
                max_intensity: 8
              - period_value: 2023-W22
                emotion_type: ANXIETY
                average_intensity: 6.0
                occurrence_count: 3
                min_intensity: 5
                max_intensity: 7
          trend_direction: DECREASING
          average_intensity: 6.8
        - emotion_type: CALM
          display_name: Calma
          color: #5F9EA0
          data_points:
              - period_value: 2023-W20
                emotion_type: CALM
                average_intensity: 4.5
                occurrence_count: 2
                min_intensity: 4
                max_intensity: 5
              - period_value: 2023-W21
                emotion_type: CALM
                average_intensity: 5.3
                occurrence_count: 3
                min_intensity: 4
                max_intensity: 7
              - period_value: 2023-W22
                emotion_type: CALM
                average_intensity: 6.2
                occurrence_count: 5
                min_intensity: 5
                max_intensity: 8
          trend_direction: INCREASING
          average_intensity: 5.5
    insights:
        - type: IMPROVEMENT
          title: Reducción de ansiedad
          description: Tu nivel de ansiedad ha disminuido gradualmente durante las últimas 3 semanas.
          related_emotions: [ANXIETY]
          confidence: 0.85
          recommended_actions:
              - Continúa con tus prácticas actuales de manejo de ansiedad
              - Considera añadir ejercicios de respiración diarios
        - type: CORRELATION
          title: Relación entre calma y ansiedad
          description: Cuando tu nivel de calma aumenta, tu ansiedad tiende a disminuir.
          related_emotions: [ANXIETY, CALM]
          confidence: 0.78
          recommended_actions:
              - Enfócate en actividades que aumenten tu sensación de calma
              - Prueba la meditación guiada para la ansiedad
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        period_type: period_type must be one of: DAY, WEEK, MONTH
        emotion_types: emotion_types must be an array of valid EmotionType values
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
This endpoint analyzes emotional trends over time and provides insights if requested. The period_type determines the granularity of the analysis.

### POST /patterns
```
POST /patterns
```
#### Description
Detect patterns in emotional data for the user

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    start_date: datetime (required)
    end_date: datetime (required)
    pattern_type: string (required, one of: 'daily', 'weekly', 'situational')
    min_occurrences: integer (optional, default: 3)
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    pattern_type: weekly
    min_occurrences: 3
```

#### Responses
##### 200 OK
```
description: Detected emotional patterns
schema:
    start_date: datetime
    end_date: datetime
    pattern_type: string
    patterns: array of EmotionalPattern objects
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    pattern_type: weekly
    patterns:
        - pattern_type: weekly
          pattern_key: MONDAY_MORNING
          description: Ansiedad los lunes por la mañana
          emotions: [ANXIETY, FRUSTRATION]
          occurrence_count: 4
          confidence: 0.82
          metadata:
              day_of_week: MONDAY
              time_of_day: MORNING
              average_intensity: 7.2
        - pattern_type: weekly
          pattern_key: FRIDAY_EVENING
          description: Calma los viernes por la tarde
          emotions: [CALM, JOY]
          occurrence_count: 3
          confidence: 0.75
          metadata:
              day_of_week: FRIDAY
              time_of_day: EVENING
              average_intensity: 6.5
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        pattern_type: pattern_type must be one of: daily, weekly, situational
        min_occurrences: min_occurrences must be a positive integer
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
This endpoint detects patterns in emotional data based on the specified pattern type. The min_occurrences parameter determines the minimum number of occurrences required to identify a pattern.

### GET /insights
```
GET /insights
```
#### Description
Generate insights from emotional data for the user

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for insights (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for insights (default: current date) |

#### Responses
##### 200 OK
```
description: Generated emotional insights
schema:
    start_date: datetime
    end_date: datetime
    insights: array of EmotionalInsight objects
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    insights:
        - type: PATTERN
          title: Patrón de ansiedad matutina
          description: Tiendes a experimentar ansiedad por las mañanas, especialmente los lunes.
          related_emotions: [ANXIETY]
          confidence: 0.82
          recommended_actions:
              - Considera una rutina matutina de respiración
              - Planifica tu día la noche anterior para reducir la incertidumbre
        - type: IMPROVEMENT
          title: Mejora en niveles de calma
          description: Tus niveles de calma han aumentado un 20% en el último mes.
          related_emotions: [CALM]
          confidence: 0.75
          recommended_actions:
              - Continúa con tus prácticas actuales
              - Considera aumentar la frecuencia de tus ejercicios de respiración
        - type: TRIGGER
          title: Desencadenante identificado
          description: Las reuniones de trabajo parecen desencadenar frustración.
          related_emotions: [FRUSTRATION]
          confidence: 0.68
          recommended_actions:
              - Practica técnicas de regulación emocional antes de reuniones
              - Considera hablar con un coach sobre estrategias de comunicación
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
This endpoint generates insights based on the user's emotional data. The insights include patterns, improvements, triggers, and correlations.

### POST /recommendations
```
POST /recommendations
```
#### Description
Get tool recommendations based on emotional state

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    emotion_type: EmotionType (required)
    intensity: integer (1-10) (required)
    limit: integer (optional, default: 5)
example:
    emotion_type: ANXIETY
    intensity: 7
    limit: 3
```

#### Responses
##### 200 OK
```
description: List of recommended tools
schema:
    recommendations: array of ToolRecommendation objects
example:
    recommendations:
        - tool_id: h9i0j1k2-l3m4-5678-nopq-rstuvwxyz123
          name: Respiración 4-7-8
          description: Una técnica de respiración para reducir la ansiedad y promover la calma
          category: BREATHING
          relevance_score: 0.95
          reason_for_recommendation: Highly effective for reducing anxiety
        - tool_id: i0j1k2l3-m4n5-6789-opqr-stuvwxyz1234
          name: Meditación para la Ansiedad
          description: Una meditación guiada para aliviar la ansiedad
          category: MEDITATION
          relevance_score: 0.87
          reason_for_recommendation: Helps calm anxious thoughts
        - tool_id: j1k2l3m4-n5o6-7890-pqrs-tuvwxyz12345
          name: Ejercicio de Enraizamiento
          description: Una técnica para conectar con el presente y reducir la ansiedad
          category: SOMATIC
          relevance_score: 0.82
          reason_for_recommendation: Grounds you in the present moment
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
This endpoint provides personalized tool recommendations based on the specified emotional state. The recommendations are ranked by relevance score.

### GET /health-analysis
```
GET /health-analysis
```
#### Description
Perform comprehensive analysis of a user's emotional health

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for analysis (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for analysis (default: current date) |

#### Responses
##### 200 OK
```
description: Comprehensive emotional health analysis
schema:
    start_date: datetime
    end_date: datetime
    emotion_distribution: array of EmotionDistribution objects
    emotional_balance:
        positive_percentage: float
        negative_percentage: float
        neutral_percentage: float
        balance_score: float (-1 to 1)
    trends: array of EmotionalTrend objects
    patterns: array of EmotionalPattern objects
    insights: array of EmotionalInsight objects
    recommendations: array of objects with action recommendations
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    emotion_distribution:
        - emotion_type: ANXIETY
          display_name: Ansiedad
          color: #8B0000
          category: NEGATIVE
          count: 12
          percentage: 26.67
          average_intensity: 6.5
        - emotion_type: CALM
          display_name: Calma
          category: POSITIVE
          color: #5F9EA0
          count: 10
          percentage: 22.22
          average_intensity: 5.8
    emotional_balance:
        positive_percentage: 35.56
        negative_percentage: 57.78
        neutral_percentage: 6.66
        balance_score: -0.22
    trends:
        - emotion_type: ANXIETY
          display_name: Ansiedad
          color: #8B0000
          data_points:
              - period_value: 2023-W20
                emotion_type: ANXIETY
                average_intensity: 7.5
                occurrence_count: 4
                min_intensity: 6
                max_intensity: 9
              - period_value: 2023-W21
                emotion_type: ANXIETY
                average_intensity: 6.8
                occurrence_count: 5
                min_intensity: 5
                max_intensity: 8
          trend_direction: DECREASING
          average_intensity: 6.8
    patterns:
        - pattern_type: weekly
          pattern_key: MONDAY_MORNING
          description: Ansiedad los lunes por la mañana
          emotions: [ANXIETY, FRUSTRATION]
          occurrence_count: 4
          confidence: 0.82
          metadata:
              day_of_week: MONDAY
              time_of_day: MORNING
              average_intensity: 7.2
    insights:
        - type: IMPROVEMENT
          title: Reducción de ansiedad
          description: Tu nivel de ansiedad ha disminuido gradualmente durante las últimas 3 semanas.
          related_emotions: [ANXIETY]
          confidence: 0.85
          recommended_actions:
              - Continúa con tus prácticas actuales de manejo de ansiedad
              - Considera añadir ejercicios de respiración diarios
    recommendations:
        - category: PRACTICE
          title: Práctica diaria de respiración
          description: Incorpora 5 minutos de respiración consciente cada mañana
          priority: HIGH
          related_emotions: [ANXIETY, STRESS]
          suggested_tools:
              - Respiración 4-7-8
              - Respiración cuadrada
        - category: ROUTINE
          title: Rutina de preparación para los lunes
          description: Desarrolla una rutina para prepararte para la semana el domingo por la noche
          priority: MEDIUM
          related_emotions: [ANXIETY, OVERWHELM]
          suggested_tools:
              - Planificación semanal
              - Meditación para la ansiedad
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
This endpoint provides a comprehensive analysis of the user's emotional health, including distribution, trends, patterns, insights, and recommendations. This is a resource-intensive endpoint with a lower rate limit.

### GET /by-journal/{journal_id}
```
GET /by-journal/{journal_id}
```
#### Description
Get emotional check-ins related to a specific journal entry

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| journal_id | string (UUID) | Yes | Unique identifier of the journal entry |

#### Responses
##### 200 OK
```
description: Emotional check-ins for the journal
schema:
    journal_id: UUID
    check_ins: array of EmotionalState objects
example:
    journal_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
    check_ins:
        - id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
          user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          emotion_type: ANXIETY
          intensity: 7
          context: PRE_JOURNALING
          notes: Feeling anxious about upcoming presentation
          related_journal_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          related_tool_id: None
          emotion_metadata:
              display_name: Ansiedad
              category: NEGATIVE
              color: #8B0000
          created_at: 2023-06-15T10:30:00Z
          updated_at: 2023-06-15T10:30:00Z
        - id: d4e5f6a7-b8c9-0123-defg-456789abcdef
          user_id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          emotion_type: CALM
          intensity: 5
          context: POST_JOURNALING
          notes: Feeling more centered after expressing my thoughts
          related_journal_id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          related_tool_id: None
          emotion_metadata:
              display_name: Calma
              category: POSITIVE
              color: #5F9EA0
          created_at: 2023-06-15T10:35:00Z
          updated_at: 2023-06-15T10:35:00Z
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
This endpoint retrieves the pre and post emotional check-ins associated with a specific journal entry. Users can only access check-ins related to their own journal entries.

### GET /by-tool/{tool_id}
```
GET /by-tool/{tool_id}