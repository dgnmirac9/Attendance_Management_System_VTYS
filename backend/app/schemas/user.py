"""User schemas for request/response validation"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional
import re


class UserBase(BaseModel):
    """Base user schema with common fields"""
    email: EmailStr
    full_name: str = Field(..., min_length=1, max_length=100)


class UserCreate(UserBase):
    """Schema for user registration"""
    password: str = Field(..., min_length=8, max_length=100)
    role: str = Field(..., pattern="^(student|instructor)$")
    
    # Student-specific fields (required if role=student)
    student_number: Optional[str] = Field(None, min_length=1, max_length=20)
    department: Optional[str] = Field(None, min_length=1, max_length=100)
    class_level: Optional[int] = Field(None, ge=1, le=4)
    enrollment_year: Optional[int] = Field(None, ge=1900, le=2100)
    
    # Instructor-specific fields (optional if role=instructor)
    title: Optional[str] = Field(None, max_length=50)
    office_info: Optional[str] = Field(None, max_length=100)
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password strength"""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('Password must contain at least one letter')
        if not re.search(r'[0-9]', v):
            raise ValueError('Password must contain at least one number')
        return v
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validate email format"""
        if not v or '@' not in v:
            raise ValueError('Invalid email format')
        return v.lower()


class UserUpdate(BaseModel):
    """Schema for updating user profile"""
    full_name: Optional[str] = Field(None, min_length=1, max_length=100)


class UserResponse(UserBase):
    """Schema for user response"""
    user_id: int
    role: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserWithDetailsResponse(UserResponse):
    """Schema for user response with role-specific details"""
    student: Optional['StudentResponse'] = None
    instructor: Optional['InstructorResponse'] = None
    
    class Config:
        from_attributes = True


# Forward references will be resolved after importing student/instructor schemas
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.schemas.student import StudentResponse
    from app.schemas.instructor import InstructorResponse
