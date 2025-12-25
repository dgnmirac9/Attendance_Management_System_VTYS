"""Instructor schemas for request/response validation"""

from app.schemas.base import CamelCaseModel
from pydantic import Field
from typing import Optional, List
from datetime import datetime


class InstructorBase(CamelCaseModel):
    """Base instructor schema"""
    # Removed: title, office_info


class InstructorCreate(InstructorBase):
    """Schema for creating an instructor (used internally after user creation)"""
    user_id: int


class InstructorUpdate(CamelCaseModel):
    """Schema for updating instructor profile"""
    # Removed: title, office_info
    profile_image_url: Optional[str] = Field(None, max_length=255)


class InstructorResponse(InstructorBase):
    """Schema for instructor response"""
    instructor_id: int
    user_id: int
    profile_image_url: Optional[str] = None
    
    class Config:
        from_attributes = True


class InstructorWithUserResponse(InstructorResponse):
    """Schema for instructor response with user details"""
    email: str
    full_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class InstructorCourseResponse(CamelCaseModel):
    """Schema for instructor's course information"""
    course_id: int
    course_name: str
    course_code: str
    semester: str
    join_code: str
    enrolled_students: int
    created_at: datetime
    
    class Config:
        from_attributes = True
