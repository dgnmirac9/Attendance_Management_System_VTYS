"""Authentication schemas for login and token management"""

from pydantic import BaseModel, EmailStr
from typing import Optional
from app.schemas.user import UserResponse


class LoginRequest(BaseModel):
    """Schema for user login request"""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Schema for authentication token response"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class LogoutResponse(BaseModel):
    """Schema for logout response"""
    message: str = "Logged out successfully"


class FaceRegisterRequest(BaseModel):
    """Schema for face registration request"""
    face_image: str  # Base64 encoded image


class FaceRegisterResponse(BaseModel):
    """Schema for face registration response"""
    success: bool
    message: str
    face_data_url: Optional[str] = None


class FaceVerifyRequest(BaseModel):
    """Schema for face verification request"""
    face_image: str  # Base64 encoded image
    student_id: Optional[int] = None  # Optional, for instructor verifying student


class FaceVerifyResponse(BaseModel):
    """Schema for face verification response"""
    verified: bool
    confidence: float
    student_id: Optional[int] = None
    message: str
