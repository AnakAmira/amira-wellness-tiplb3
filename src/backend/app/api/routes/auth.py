# typing: standard library
from typing import Dict, Optional

# fastapi: 0.104+
from fastapi import APIRouter, Depends, Request, Response, status
from sqlalchemy.orm import Session  # sqlalchemy.orm 2.0+

# Internal imports
from ..api.deps import get_db, get_current_user, get_client_rate_limit_key
from ..schemas.auth import (
    LoginRequest,
    RefreshTokenRequest,
    LogoutRequest,
    PasswordResetRequest,
    PasswordResetConfirmRequest,
    VerifyEmailRequest,
    DeviceRegistrationRequest,
    AuthResponse,
)
from ..schemas.user import UserCreate, UserPasswordUpdate
from ..services.auth import (
    login_user,
    register_user,
    refresh_token,
    logout_user,
    reset_password_request,
    reset_password_confirm,
    change_password,
    verify_email,
    send_verification_email,
    register_device,
)
from ..models.device import DevicePlatform
from ..models.user import User
from ..core.logging import get_logger
from ..middleware.rate_limiter import RateLimiter

# Initialize logger
logger = get_logger(__name__)

# Authentication API router
router = APIRouter(prefix="/auth", tags=["Authentication"])

# Rate limiters for authentication endpoints
login_limiter = RateLimiter(name="login", limit=5, period=60)
register_limiter = RateLimiter(name="register", limit=3, period=60)
reset_password_limiter = RateLimiter(name="reset_password", limit=3, period=60)


@router.post("/login", response_model=AuthResponse, status_code=status.HTTP_200_OK)
async def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
    fastapi_request: Request = Depends(),
    rate_limit_key: str = Depends(get_client_rate_limit_key),
) -> AuthResponse:
    """
    Authenticate user and generate access and refresh tokens
    """
    logger.info(f"Login attempt for email: {request.email[:4]}******")
    auth_response = login_user(db, request.email, request.password)
    return auth_response


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    fastapi_request: Request = Depends(),
    rate_limit_key: str = Depends(get_client_rate_limit_key),
) -> dict:
    """
    Register a new user account
    """
    logger.info(f"Registration attempt for email: {user_data.email[:4]}******")
    user = register_user(db, user_data)
    send_verification_email(db, user.id)
    return {"user_id": str(user.id), "message": "Registration successful. Please check your email to verify your account."}


@router.post("/refresh", status_code=status.HTTP_200_OK)
async def refresh(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Refresh access token using a valid refresh token
    """
    tokens = refresh_token(db, request.refresh_token)
    return tokens


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    request: LogoutRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Logout user by blacklisting refresh tokens
    """
    user_id = current_user.id
    refresh_token = request.refresh_token
    all_devices = False  # Default to False if not provided
    logout_user(db, user_id, refresh_token, all_devices)
    return {"message": "Logout successful"}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(
    request: PasswordResetRequest,
    db: Session = Depends(get_db),
    fastapi_request: Request = Depends(),
    rate_limit_key: str = Depends(get_client_rate_limit_key),
) -> dict:
    """
    Initiate password reset process
    """
    logger.info(f"Password reset request for email: {request.email[:4]}******")
    reset_password_request(db, request.email)
    return {"message": "Password reset email sent if the account exists."}


@router.post("/reset-password-confirm", status_code=status.HTTP_200_OK)
async def reset_password_confirm(
    request: PasswordResetConfirmRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Complete password reset with token
    """
    reset_password_confirm(db, request.token, request.new_password)
    return {"message": "Password reset successful"}


@router.post("/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    request: UserPasswordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Change user password with current password verification
    """
    user_id = current_user.id
    change_password(db, user_id, request)
    return {"message": "Password changed successfully"}


@router.post("/verify-email", status_code=status.HTTP_200_OK)
async def verify_email(
    request: VerifyEmailRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Verify user email with verification token
    """
    verify_email(db, request.token)
    return {"message": "Email verified successfully"}


@router.post("/resend-verification", status_code=status.HTTP_200_OK)
async def resend_verification_email(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Resend email verification token to user
    """
    user_id = current_user.id
    send_verification_email(db, user_id)
    return {"message": "Verification email resent successfully"}


@router.post("/devices", status_code=status.HTTP_201_CREATED)
async def register_device(
    request: DeviceRegistrationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    fastapi_request: Request = Depends(),
) -> dict:
    """
    Register a device for a user
    """
    user_id = current_user.id
    device_id = request.device_id
    device_name = request.device_name
    platform = request.platform
    push_token = request.push_token
    app_version = request.app_version
    os_version = request.os_version
    ip_address = fastapi_request.client.host if fastapi_request.client else None

    device = register_device(db, user_id, device_id, device_name, platform, push_token, app_version, os_version, ip_address)
    return {"message": "Device registered successfully", "device_id": str(device.id)}


@router.get("/health", status_code=status.HTTP_200_OK)
async def health_check() -> dict:
    """
    Health check endpoint for authentication service
    """
    return {"service": "authentication", "status": "healthy"}