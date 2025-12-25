"""Authentication schemas for login and token management"""

from app.schemas.base import CamelCaseModel
from pydantic import EmailStr, BaseModel
from typing import Optional
from app.schemas.user import UserResponse


class LoginRequest(CamelCaseModel):
    """Schema for user login request"""
    email: EmailStr
    password: str


class PasswordChangeRequest(CamelCaseModel):
    """Schema for password change request"""
    old_password: str
    new_password: str


class TokenResponse(CamelCaseModel):
    """Schema for authentication token response"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class LogoutResponse(CamelCaseModel):
    """Schema for logout response"""
    message: str = "Logged out successfully"


class FaceRegisterRequest(CamelCaseModel):
    """Schema for face registration request"""
    face_image: str  # Base64 encoded image


class FaceRegisterResponse(CamelCaseModel):
    """Schema for face registration response"""
    success: bool
    message: str
    face_data_url: Optional[str] = None


class FaceVerifyRequest(CamelCaseModel):
    """Schema for face verification request"""
    face_image: str  # Base64 encoded image
    student_id: Optional[int] = None  # Optional, for instructor verifying student


class FaceVerifyResponse(CamelCaseModel):
    """Schema for face verification response"""
    verified: bool
    confidence: float
    student_id: Optional[int] = None
    message: str
