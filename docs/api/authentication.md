# Authentication API Documentation

## Introduction

This document provides comprehensive documentation for the Amira Wellness authentication API. These endpoints handle user authentication, account management, and security operations for the Amira Wellness platform.

The authentication API is designed with security as a primary concern, implementing industry best practices to protect the sensitive emotional wellness data stored within the application.

### Key Features

- Secure user registration and authentication
- JWT-based token authentication with refresh token rotation
- Strong password management and recovery
- Email verification
- Multi-device support
- End-to-end encryption integration

### Security Overview

The authentication system implements the following security measures:

- JWT tokens signed with RS256 algorithm
- Short-lived access tokens (15 minutes)
- Refresh token rotation for enhanced security
- Strong password requirements (minimum 10 characters, complexity rules)
- Rate limiting on sensitive operations
- Account lockout after multiple failed attempts
- Secure storage recommendations for tokens

## Base URL

All API requests should be sent to the base URL:

```
https://api.amirawellness.com/v1
```

Authentication endpoints are prefixed with `/auth`.

## Authentication Flow Overview

The Amira Wellness application uses a token-based authentication system:

1. **Registration**: Users create an account with email and password
2. **Email Verification**: Users verify their email address
3. **Authentication**: Users authenticate with email/password to receive a JWT access token and refresh token
4. **API Access**: The access token is included in all API requests
5. **Token Refresh**: When the access token expires, the refresh token is used to obtain a new access token
6. **Logout**: Tokens are invalidated when the user logs out

### Token Usage

- Include the access token in the `Authorization` header of all API requests:
  ```
  Authorization: Bearer {access_token}
  ```
- Store tokens securely using platform-appropriate methods:
  - iOS: Keychain with appropriate protection classes
  - Android: Encrypted SharedPreferences or Keystore
  - Web: HttpOnly, secure cookies, or secure localStorage implementations

### JWT Token Structure

#### Access Token Payload

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000", // User ID
  "email": "maria.garcia@example.com",
  "verified": true, // Email verification status
  "tier": "free", // Subscription tier
  "iat": 1627484742, // Issued at timestamp
  "exp": 1627485642, // Expiration timestamp
  "iss": "amira-wellness-auth", // Token issuer
  "jti": "5ccf2369-bdd7-442f-a6e2-b4201650c151" // Unique token ID
}
```

#### Refresh Token Payload

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000", // User ID
  "jti": "7e969258-4311-42ad-97ba-1a5723a35377", // Unique token ID
  "iat": 1627484742, // Issued at timestamp
  "exp": 1628694342, // Expiration timestamp (14 days later)
  "iss": "amira-wellness-auth", // Token issuer
  "token_family": "a8d47158-b25c-4ab2-af8b-b5234c45767f" // Token family for rotation tracking
}
```

The JWT tokens contain important information but should always be validated on the server side. Never trust client-side validation alone.

## API Endpoints

### Registration

Creates a new user account.

**Endpoint:** `POST /auth/register`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User's email address |
| password | string | Yes | User's password (must meet security requirements) |
| password_confirm | string | Yes | Confirmation of the password (must match password) |
| language_preference | string | No | User's preferred language (default: "es") |

#### Response

**Success (201 Created)**

```json
{
  "success": true,
  "message": "User registered successfully",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email_verification_sent": true
}
```

**Error (400 Bad Request)**

```json
{
  "success": false,
  "error": "validation_error",
  "message": "Invalid registration data",
  "details": {
    "email": "Email address is already in use",
    "password": "Password does not meet minimum requirements"
  }
}
```

#### Notes

- Password must be at least 10 characters long and meet complexity requirements
- A verification email will be sent to the provided email address
- The account will remain unverified until email confirmation

### Login

Authenticates a user and provides access and refresh tokens.

**Endpoint:** `POST /auth/login`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User's email address |
| password | string | Yes | User's password |

#### Response

**Success (200 OK)**

```json
{
  "tokens": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 900
  },
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "email_verified": true,
    "subscription_tier": "free",
    "language_preference": "es",
    "created_at": "2023-01-15T16:30:45Z"
  }
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "authentication_failed",
  "message": "Invalid email or password"
}
```

**Error (403 Forbidden)**

```json
{
  "success": false,
  "error": "account_locked",
  "message": "Account temporarily locked due to multiple failed login attempts",
  "details": {
    "unlock_time": "2023-07-15T16:30:45Z"
  }
}
```

#### Notes

- Access tokens are valid for 15 minutes
- The account will be temporarily locked after 5 failed login attempts
- If email is not verified, the response will include `"email_verified": false`

### Token Refresh

Obtains a new access token using a valid refresh token.

**Endpoint:** `POST /auth/refresh`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| refresh_token | string | Yes | Valid refresh token previously issued |

#### Response

**Success (200 OK)**

```json
{
  "tokens": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 900
  }
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "invalid_token",
  "message": "Invalid or expired refresh token"
}
```

#### Notes

- The refresh token is rotated with each use for security
- The old refresh token is invalidated when a new one is issued
- Store the new refresh token securely after each refresh operation

### Logout

Invalidates the user's refresh token and optionally all sessions.

**Endpoint:** `POST /auth/logout`

#### Request Headers

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| Authorization | Bearer {access_token} | Yes | Valid access token |

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| refresh_token | string | No | Refresh token to invalidate (if not provided, the session associated with the access token will be logged out) |
| all_devices | boolean | No | Whether to logout from all devices (default: false) |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "invalid_token",
  "message": "Invalid or expired token"
}
```

#### Notes

- If `all_devices` is set to true, all refresh tokens for the user will be invalidated
- The access token will still be technically valid until expiration but should be discarded by the client

### Password Reset Request

Initiates the password reset process by sending a reset link to the user's email.

**Endpoint:** `POST /auth/reset-password`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | Email address for password reset |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "If the email exists in our system, a password reset link has been sent"
}
```

#### Notes

- For security reasons, the API returns the same response regardless of whether the email exists
- The password reset link sent to the email will contain a secure token with limited validity (usually 1 hour)
- Rate limiting is applied to this endpoint to prevent abuse

### Password Reset Confirmation

Completes the password reset process using the token sent to the user's email.

**Endpoint:** `POST /auth/reset-password-confirm`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| token | string | Yes | Password reset token received via email |
| new_password | string | Yes | New password (must meet security requirements) |
| new_password_confirm | string | Yes | Confirmation of new password |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "Password has been reset successfully"
}
```

**Error (400 Bad Request)**

```json
{
  "success": false,
  "error": "validation_error",
  "message": "Invalid password reset data",
  "details": {
    "new_password": "Password does not meet minimum requirements",
    "new_password_confirm": "Passwords do not match"
  }
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "invalid_token",
  "message": "Invalid or expired password reset token"
}
```

#### Notes

- Password reset tokens are valid for a limited time (typically 1 hour)
- All existing refresh tokens are invalidated when the password is reset for security
- New password must meet the same security requirements as during registration

### Change Password

Changes the password for an authenticated user.

**Endpoint:** `POST /auth/change-password`

#### Request Headers

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| Authorization | Bearer {access_token} | Yes | Valid access token |

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| current_password | string | Yes | Current password for verification |
| new_password | string | Yes | New password (must meet security requirements) |
| new_password_confirm | string | Yes | Confirmation of new password |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Error (400 Bad Request)**

```json
{
  "success": false,
  "error": "validation_error",
  "message": "Invalid password change data",
  "details": {
    "new_password": "Password does not meet minimum requirements",
    "new_password_confirm": "Passwords do not match"
  }
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "invalid_credentials",
  "message": "Current password is incorrect"
}
```

#### Notes

- All existing refresh tokens are invalidated when the password is changed for security
- The user will need to login again after changing the password
- New password must meet the same security requirements as during registration

### Email Verification

Verifies a user's email address using the token sent during registration.

**Endpoint:** `POST /auth/verify-email`

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| token | string | Yes | Email verification token received via email |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

**Error (401 Unauthorized)**

```json
{
  "success": false,
  "error": "invalid_token",
  "message": "Invalid or expired email verification token"
}
```

#### Notes

- Email verification tokens are valid for a limited time (typically 24 hours)
- Users with unverified emails may have limited access to certain features

### Resend Verification Email

Resends the email verification link to the user's email address.

**Endpoint:** `POST /auth/resend-verification`

#### Request Headers

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| Authorization | Bearer {access_token} | Yes | Valid access token |

#### Response

**Success (200 OK)**

```json
{
  "success": true,
  "message": "Verification email has been sent"
}
```

**Error (400 Bad Request)**

```json
{
  "success": false,
  "error": "already_verified",
  "message": "Email is already verified"
}
```

#### Notes

- Rate limiting is applied to this endpoint to prevent abuse
- A new verification token is generated with each request

### Device Registration

Registers a device for push notifications and multi-device support.

**Endpoint:** `POST /auth/devices`

#### Request Headers

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| Authorization | Bearer {access_token} | Yes | Valid access token |

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| device_id | string | Yes | Unique identifier for the device |
| device_name | string | Yes | Human-readable device name |
| platform | string | Yes | Device platform (ios, android, web) |
| push_token | string | No | Push notification token (FCM or APNS) |
| app_version | string | No | Application version |
| os_version | string | No | Operating system version |

#### Response

**Success (201 Created)**

```json
{
  "success": true,
  "message": "Device registered successfully",
  "device": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "device_id": "AEBC7836-FAD2-4191-8E6E-D232C96B3F2D",
    "device_name": "iPhone 13 Pro",
    "platform": "ios",
    "created_at": "2023-07-15T16:30:45Z",
    "last_active_at": "2023-07-15T16:30:45Z"
  }
}
```

**Error (400 Bad Request)**

```json
{
  "success": false,
  "error": "validation_error",
  "message": "Invalid device data",
  "details": {
    "platform": "Must be one of: ios, android, web"
  }
}
```

#### Notes

- The `device_id` should be a persistent identifier for the device
- Users can have multiple registered devices (limit: 10 devices per account)
- Registering an existing `device_id` will update its information
- The `push_token` should be refreshed whenever it changes

## Security Considerations

### Rate Limiting

To protect against brute force and denial-of-service attacks, rate limits are enforced on authentication endpoints:

| Endpoint | Rate Limit | Lockout |
|----------|------------|---------|
| /auth/login | 5 attempts per minute | Temporary account lockout after 5 failed attempts |
| /auth/register | 3 attempts per minute | N/A |
| /auth/reset-password | 3 attempts per minute | N/A |

### Token Security

The authentication system uses JWT tokens with the following security characteristics:

- **Access Token Expiration**: 15 minutes
- **Refresh Token Expiration**: 14 days
- **Token Signing Algorithm**: RS256 (asymmetric)
- **Token Rotation**: Refresh tokens are rotated on each use

### Token Storage Recommendations

Tokens should be stored securely:

- **iOS**: Use Keychain with appropriate protection classes
- **Android**: Use EncryptedSharedPreferences or Android KeyStore
- **Web**: Use HttpOnly, secure cookies, or a secure localStorage implementation with additional protections

### Password Requirements

Passwords must meet the following requirements:

- Minimum length: 10 characters
- Must include a mix of character types
- Common passwords are prohibited (checked server-side)
- Previous passwords cannot be reused

### Integration with End-to-End Encryption

The authentication system is designed to work with the application's end-to-end encryption system. For details on the encryption implementation, refer to the [Encryption Documentation](../security/encryption.md).

Key considerations:
- User authentication credentials are used for deriving encryption keys
- Password changes require careful handling of encrypted data
- Authentication operations maintain the zero-knowledge design principle

## Error Handling

### Error Response Format

All error responses follow a consistent format:

```json
{
  "success": false,
  "error": "error_code",
  "message": "Human-readable error message",
  "details": {
    // Optional field-specific error details
  }
}
```

### Common Error Codes

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `validation_error` | 400 | Request data failed validation |
| `invalid_credentials` | 401 | Email or password is incorrect |
| `invalid_token` | 401 | Token is invalid, expired, or revoked |
| `account_locked` | 403 | Account is temporarily locked due to failed attempts |
| `email_not_verified` | 403 | Email verification required to access this resource |
| `rate_limited` | 429 | Too many requests, try again later |
| `server_error` | 500 | Internal server error |

### Handling Authentication Errors

When receiving a 401 error with `invalid_token` for an access token, the client should:

1. Attempt to refresh the access token using the refresh token
2. If refresh fails, redirect the user to the login screen
3. If refresh succeeds, retry the original request with the new access token

## Example Requests and Responses

### Example: User Registration

**Request**

```http
POST /auth/register HTTP/1.1
Host: api.amirawellness.com
Content-Type: application/json

{
  "email": "maria.garcia@example.com",
  "password": "S3cur3P@ssw0rd!",
  "password_confirm": "S3cur3P@ssw0rd!",
  "language_preference": "es"
}
```

**Response**

```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "success": true,
  "message": "User registered successfully",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email_verification_sent": true
}
```

### Example: User Login

**Request**

```http
POST /auth/login HTTP/1.1
Host: api.amirawellness.com
Content-Type: application/json

{
  "email": "maria.garcia@example.com",
  "password": "S3cur3P@ssw0rd!"
}
```

**Response**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "tokens": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 900
  },
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "maria.garcia@example.com",
    "email_verified": true,
    "subscription_tier": "free",
    "language_preference": "es",
    "created_at": "2023-07-15T16:30:45Z"
  }
}
```

### Example: Token Refresh

**Request**

```http
POST /auth/refresh HTTP/1.1
Host: api.amirawellness.com
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "tokens": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 900
  }
}
```

### Example: Password Reset Request

**Request**

```http
POST /auth/reset-password HTTP/1.1
Host: api.amirawellness.com
Content-Type: application/json

{
  "email": "maria.garcia@example.com"
}
```

**Response**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "message": "If the email exists in our system, a password reset link has been sent"
}
```

### Example: Device Registration

**Request**

```http
POST /auth/devices HTTP/1.1
Host: api.amirawellness.com
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "device_id": "AEBC7836-FAD2-4191-8E6E-D232C96B3F2D",
  "device_name": "iPhone 13 Pro",
  "platform": "ios",
  "push_token": "fcm:APA91bHun4MxP5egoKMwt27FdFhgCAqQHN-GWdqKMXbmvlu",
  "app_version": "1.0.0",
  "os_version": "15.4.1"
}
```

**Response**

```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "success": true,
  "message": "Device registered successfully",
  "device": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "device_id": "AEBC7836-FAD2-4191-8E6E-D232C96B3F2D",
    "device_name": "iPhone 13 Pro",
    "platform": "ios",
    "created_at": "2023-07-15T16:30:45Z",
    "last_active_at": "2023-07-15T16:30:45Z"
  }
}
```