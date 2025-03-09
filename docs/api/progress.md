# Progress API

## Introduction
The Amira Wellness Progress API provides endpoints for tracking, analyzing, and visualizing user progress through the application. This API enables users to monitor their streaks, achievements, emotional trends, activity patterns, and usage statistics. The Progress API is a key component of the gamification and motivation features of the Amira Wellness platform. All endpoints require authentication unless otherwise specified.

## Base URL
```
/progress
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

### GET /streak
```
GET /streak
```
#### Description
Get a user's current streak information

#### Authentication Required
Yes

#### Responses
##### 200 OK
```
description: User's streak information
schema:
    current_streak: integer
    longest_streak: integer
    last_activity_date: date
    total_days_active: integer
    streak_history: object (dates as keys, boolean values)
    grace_period_used_count: integer
    grace_period_reset_date: date or null
    grace_period_active: boolean
    next_milestone: integer
    milestone_progress: float (0-1)
example:
    current_streak: 5
    longest_streak: 14
    last_activity_date: 2023-06-15
    total_days_active: 25
    streak_history:
        2023-06-15: True
        2023-06-14: True
        2023-06-13: True
        2023-06-12: True
        2023-06-11: True
    grace_period_used_count: 1
    grace_period_reset_date: 2023-07-01
    grace_period_active: False
    next_milestone: 7
    milestone_progress: 0.71
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
This endpoint returns the user's current streak information, including the current streak count, longest streak, and progress toward the next milestone.

### POST /streak
```
POST /streak
```
#### Description
Update a user's streak with activity

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    activity_date: date (required)
    use_grace_period: boolean (optional, default: false)
example:
    activity_date: 2023-06-16
    use_grace_period: False
```

#### Responses
##### 200 OK
```
description: Updated streak information
schema: Same as GET /streak response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        activity_date: activity_date cannot be in the future
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
This endpoint updates the user's streak based on activity. It is typically called automatically when a user performs activities like voice journaling, emotional check-ins, or tool usage.

### DELETE /streak
```
DELETE /streak
```
#### Description
Reset a user's streak to zero

#### Authentication Required
Yes

#### Responses
##### 200 OK
```
description: Reset streak information
schema: Same as GET /streak response but with current_streak reset to 0
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
This endpoint resets the user's current streak to zero. This is typically used for testing or administrative purposes.

### POST /streak/grace-period
```
POST /streak/grace-period
```
#### Description
Use a grace period for a user's streak

#### Authentication Required
Yes

#### Responses
##### 200 OK
```
description: Result of grace period usage attempt
schema:
    success: boolean
    message: string
    grace_period_used_count: integer
    grace_period_reset_date: date or null
example:
    success: True
    message: Grace period successfully applied
    grace_period_used_count: 2
    grace_period_reset_date: 2023-07-01
```

##### 400 Bad Request
```
description: Bad Request
schema:
    success: boolean
    message: string
example:
    success: False
    message: No grace periods available. Maximum usage reached.
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
This endpoint allows a user to use a grace period to prevent breaking their streak when they miss a day. Users have a limited number of grace periods available per month.

### GET /streak/next-milestone
```
GET /streak/next-milestone
```
#### Description
Get the next milestone for a user's streak

#### Authentication Required
Yes

#### Responses
##### 200 OK
```
description: Next milestone information
schema:
    milestone: integer
    current_streak: integer
    progress: float (0-1)
example:
    milestone: 7
    current_streak: 5
    progress: 0.71
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
This endpoint returns information about the next streak milestone the user can achieve. Milestones are at 3, 7, 14, 30, 60, and 90 days.

### GET /achievements
```
GET /achievements
```
#### Description
Get a paginated list of user achievements

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
description: Paginated list of user achievements
schema:
    items: array of Achievement objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: a1b2c3d4-e5f6-7890-abcd-1234567890ab
          achievement_type: STREAK_7_DAYS
          name: Racha de 7 días
          description: Mantuviste una racha de actividad durante 7 días consecutivos
          icon_url: https://assets.amirawellness.com/achievements/streak_7_days.png
          category: STREAK
          is_hidden: False
          points: 50
          earned_at: 2023-06-10T00:00:00Z
        - id: b2c3d4e5-f6a7-8901-bcde-23456789abcd
          achievement_type: STREAK_3_DAYS
          name: Racha de 3 días
          description: Mantuviste una racha de actividad durante 3 días consecutivos
          icon_url: https://assets.amirawellness.com/achievements/streak_3_days.png
          category: STREAK
          is_hidden: False
          points: 25
          earned_at: 2023-06-06T00:00:00Z
    total: 2
    page: 1
    page_size: 10
    pages: 1
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
This endpoint returns a paginated list of achievements earned by the user. Achievements are awarded for reaching streak milestones, completing specific activities, and other accomplishments.

### GET /activities
```
GET /activities
```
#### Description
Get a paginated list of user activities

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
description: Paginated list of user activities
schema:
    items: array of Activity objects
    total: integer (total number of items)
    page: integer (current page)
    page_size: integer (items per page)
    pages: integer (total number of pages)
example:
    items:
        - id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
          activity_type: VOICE_JOURNAL
          related_item_id: d4e5f6a7-b8c9-0123-defg-456789abcdef0
          description: Grabación de diario de voz
          metadata:
              duration_seconds: 180
              emotional_shift:
                  pre_emotion: ANXIETY
                  post_emotion: CALM
                  intensity_change: -2
          created_at: 2023-06-15T10:30:00Z
        - id: d4e5f6a7-b8c9-0123-defg-456789abcdef0
          activity_type: TOOL_USAGE
          related_item_id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
          description: Uso de herramienta: Respiración 4-7-8
          metadata:
              duration_seconds: 300
              completion_status: COMPLETED
          created_at: 2023-06-14T15:45:00Z
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
This endpoint returns a paginated list of activities performed by the user. Activities include voice journaling, emotional check-ins, tool usage, and achievement earning.

### POST /activities
```
POST /activities
```
#### Description
Record a user activity

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    activity_type: ActivityType enum (required)
    related_item_id: UUID (optional)
    description: string (optional)
    metadata: object (optional)
example:
    activity_type: TOOL_USAGE
    related_item_id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
    description: Uso de herramienta: Respiración 4-7-8
    metadata:
        duration_seconds: 300
        completion_status: COMPLETED
```

#### Responses
##### 201 Created
```
description: Recorded activity
schema:
    id: UUID
    activity_type: ActivityType
    related_item_id: UUID or null
    description: string
    metadata: object
    created_at: datetime
    streak_updated: boolean
    current_streak: integer
example:
    id: d4e5f6a7-b8c9-0123-defg-456789abcdef0
    activity_type: TOOL_USAGE
    related_item_id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
    description: Uso de herramienta: Respiración 4-7-8
    metadata:
        duration_seconds: 300
        completion_status: COMPLETED
    created_at: 2023-06-14T15:45:00Z
    streak_updated: True
    current_streak: 4
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        activity_type: activity_type must be a valid ActivityType
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
This endpoint records a user activity and updates the user's streak. It is typically called automatically when a user performs activities like voice journaling, emotional check-ins, or tool usage.

### GET /activities/date-range
```
GET /activities/date-range
```
#### Description
Get user activities within a date range

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | Yes | Start date for the date range |
| end_date | string (ISO 8601 datetime) | Yes | End date for the date range |
| activity_type | string (ActivityType) | No | Filter by activity type |

#### Responses
##### 200 OK
```
description: List of activities within the date range
schema: array of Activity objects
example:
    - id: c3d4e5f6-a7b8-9012-cdef-3456789abcde
      activity_type: VOICE_JOURNAL
      related_item_id: d4e5f6a7-b8c9-0123-defg-456789abcdef0
      description: Grabación de diario de voz
      metadata:
          duration_seconds: 180
          emotional_shift:
              pre_emotion: ANXIETY
              post_emotion: CALM
              intensity_change: -2
      created_at: 2023-06-15T10:30:00Z
    - id: d4e5f6a7-b8c9-0123-defg-456789abcdef0
      activity_type: TOOL_USAGE
      related_item_id: e5f6a7b8-c9d0-1234-efgh-56789abcdef0
      description: Uso de herramienta: Respiración 4-7-8
      metadata:
          duration_seconds: 300
          completion_status: COMPLETED
      created_at: 2023-06-14T15:45:00Z
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        end_date: end_date must be a valid ISO 8601 datetime
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
This endpoint returns a list of activities performed by the user within the specified date range. Activities can be filtered by activity type.

### GET /activities/distribution/day
```
GET /activities/distribution/day
```
#### Description
Get activity distribution by day of week

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for the date range (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for the date range (default: current date) |

#### Responses
##### 200 OK
```
description: Activity distribution by day of week
schema:
    start_date: datetime
    end_date: datetime
    distribution: object with day names as keys and counts as values
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    distribution:
        MONDAY: 12
        TUESDAY: 8
        WEDNESDAY: 10
        THURSDAY: 7
        FRIDAY: 9
        SATURDAY: 5
        SUNDAY: 4
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        end_date: end_date must be a valid ISO 8601 datetime
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
This endpoint returns the distribution of user activities by day of the week within the specified date range.

### GET /activities/distribution/time
```
GET /activities/distribution/time
```
#### Description
Get activity distribution by time of day

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for the date range (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for the date range (default: current date) |

#### Responses
##### 200 OK
```
description: Activity distribution by time of day
schema:
    start_date: datetime
    end_date: datetime
    distribution: object with time periods as keys and counts as values
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
    distribution:
        MORNING: 15
        AFTERNOON: 20
        EVENING: 12
        NIGHT: 8
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        end_date: end_date must be a valid ISO 8601 datetime
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
This endpoint returns the distribution of user activities by time of day within the specified date range. Time periods are MORNING (6:00-11:59), AFTERNOON (12:00-17:59), EVENING (18:00-23:59), and NIGHT (0:00-5:59).

### GET /statistics/{period_type}/{period_value}
```
GET /statistics/{period_type}/{period_value}
```
#### Description
Get usage statistics for a period

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| period_type | string | Yes | Type of period (DAY, WEEK, MONTH, YEAR) |
| period_value | string | Yes | Value of period (e.g., '2023-06-15', '2023-W24', '2023-06', '2023') |

#### Responses
##### 200 OK
```
description: Usage statistics for the period
schema:
    total_journal_entries: integer
    total_journaling_minutes: integer
    total_check_ins: integer
    total_tool_usage: integer
    tool_usage_by_category: array of CategoryUsage objects
    active_time_of_day: TimeOfDay
    most_productive_day: DayOfWeek
example:
    total_journal_entries: 5
    total_journaling_minutes: 25
    total_check_ins: 12
    total_tool_usage: 8
    tool_usage_by_category:
        - category: BREATHING
          usage_count: 4
          total_duration: 20
        - category: MEDITATION
          usage_count: 2
          total_duration: 15
        - category: JOURNALING
          usage_count: 2
          total_duration: 10
    active_time_of_day: EVENING
    most_productive_day: MONDAY
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        period_type: period_type must be one of: DAY, WEEK, MONTH, YEAR
        period_value: period_value must be in the correct format for the period type
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
    detail: Statistics not found for the specified period
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
This endpoint returns usage statistics for the specified period. Period types are DAY, WEEK, MONTH, and YEAR. Period values should be formatted as '2023-06-15' for DAY, '2023-W24' for WEEK, '2023-06' for MONTH, and '2023' for YEAR.

### POST /statistics/{period_type}/{period_value}
```
POST /statistics/{period_type}/{period_value}
```
#### Description
Update usage statistics for a period

#### Authentication Required
Yes

#### Path Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| period_type | string | Yes | Type of period (DAY, WEEK, MONTH, YEAR) |
| period_value | string | Yes | Value of period (e.g., '2023-06-15', '2023-W24', '2023-06', '2023') |

#### Responses
##### 200 OK
```
description: Updated usage statistics
schema: Same as GET /statistics/{period_type}/{period_value} response
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        period_type: period_type must be one of: DAY, WEEK, MONTH, YEAR
        period_value: period_value must be in the correct format for the period type
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
This endpoint updates usage statistics for the specified period based on user activities. It is typically called automatically when activities are recorded.

### GET /emotional-trends
```
GET /emotional-trends
```
#### Description
Get emotional trends for a date range

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | Yes | Start date for the date range |
| end_date | string (ISO 8601 datetime) | Yes | End date for the date range |

#### Responses
##### 200 OK
```
description: Emotional trends for the date range
schema:
    trends: array of EmotionalTrend objects
    start_date: datetime
    end_date: datetime
example:
    trends:
        - emotion_type: ANXIETY
          data_points:
              - date: 2023-06-01
                value: 7.5
                context: Average of 2 check-ins
              - date: 2023-06-08
                value: 6.0
                context: Average of 3 check-ins
              - date: 2023-06-15
                value: 4.5
                context: Average of 2 check-ins
          overall_trend: DECREASING
          average_intensity: 6.0
          peak_intensity: 8.0
          peak_date: 2023-06-02
        - emotion_type: CALM
          data_points:
              - date: 2023-06-01
                value: 4.0
                context: Average of 1 check-in
              - date: 2023-06-08
                value: 5.5
                context: Average of 2 check-ins
              - date: 2023-06-15
                value: 7.0
                context: Average of 3 check-ins
          overall_trend: INCREASING
          average_intensity: 5.5
          peak_intensity: 8.0
          peak_date: 2023-06-15
    start_date: 2023-06-01T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        end_date: end_date must be a valid ISO 8601 datetime
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
This endpoint returns emotional trends for the user within the specified date range. Trends include data points, overall trend direction, average intensity, and peak intensity for each emotion type.

### POST /insights
```
POST /insights
```
#### Description
Generate insights from progress data

#### Authentication Required
Yes

#### Request Body
```
content_type: application/json
schema:
    start_date: datetime (required)
    end_date: datetime (required)
example:
    start_date: 2023-05-15T00:00:00Z
    end_date: 2023-06-15T23:59:59Z
```

#### Responses
##### 200 OK
```
description: Generated insights
schema:
    insights: array of ProgressInsight objects
example:
    insights:
        - type: PATTERN
          title: Patrón de actividad matutina
          description: Tiendes a usar la aplicación más por las mañanas, especialmente los lunes.
          supporting_data: 65% de tus actividades ocurren entre las 6:00 y las 12:00.
          actionable_steps:
              - Continúa con tu rutina matutina
              - Considera añadir una actividad nocturna para equilibrar tu día
          related_tools:
              - Meditación matutina
              - Ejercicio de gratitud nocturno
        - type: IMPROVEMENT
          title: Mejora en niveles de calma
          description: Tus niveles de calma han aumentado un 20% en el último mes.
          supporting_data: La intensidad promedio de calma aumentó de 4.5 a 5.5.
          actionable_steps:
              - Continúa con tus prácticas actuales
              - Considera aumentar la frecuencia de tus ejercicios de respiración
          related_tools:
              - Respiración 4-7-8
              - Meditación para la calma
```

##### 400 Bad Request
```
description: Validation error
schema:
    detail: string or object with validation errors
example:
    detail:
        start_date: start_date must be a valid ISO 8601 datetime
        end_date: end_date must be a valid ISO 8601 datetime
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
This endpoint generates insights from the user's progress data within the specified date range. Insights include patterns, improvements, correlations, and recommendations.

### GET /insights
```
GET /insights
```
#### Description
Get existing progress insights

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| limit | integer | No | 10 | Maximum number of insights to return |

#### Responses
##### 200 OK
```
description: Progress insights
schema: array of ProgressInsight objects
example: Same as POST /insights response
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
This endpoint returns existing progress insights for the user. Insights are ordered by confidence score, with the most confident insights first.

### GET /dashboard
```
GET /dashboard
```
#### Description
Get comprehensive progress dashboard data

#### Authentication Required
Yes

#### Query Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| start_date | string (ISO 8601 datetime) | No | Start date for the dashboard data (default: 30 days ago) |
| end_date | string (ISO 8601 datetime) | No | End date for the dashboard data (default: current date) |

#### Responses
##### 200 OK