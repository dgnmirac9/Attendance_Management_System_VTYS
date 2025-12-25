"""Student schemas for request/response validation"""

from app.schemas.base import CamelCaseModel
from pydantic import Field
from typing import Optional, List
from datetime import datetime


class StudentBase(CamelCaseModel):
    """Base student schema"""
    student_number: str = Field(..., min_length=9, max_length=9, pattern=r"^\d{9}$")
    # Removed: department, class_level, enrollment_year


class StudentCreate(StudentBase):
    """Schema for creating a student (used internally after user creation)"""
    user_id: int


class StudentUpdate(CamelCaseModel):
    """Schema for updating student profile"""
    # Removed: department, class_level
    profile_image_url: Optional[str] = Field(None, max_length=255)


class StudentResponse(StudentBase):
    """Schema for student response"""
    student_id: int
    user_id: int
    face_data_url: Optional[str] = None
    profile_image_url: Optional[str] = None
    total_absences: int = 0
    has_face_data: bool = False
    
    class Config:
        from_attributes = True


class StudentWithUserResponse(StudentResponse):
    """Schema for student response with user details"""
    email: str
    full_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class StudentCourseResponse(CamelCaseModel):
    """Schema for student's course information"""
    course_id: int
    course_name: str
    course_code: str
    semester: str
    instructor_name: str
    joined_at: datetime
    
    class Config:
        from_attributes = True


class StudentAttendanceHistoryResponse(CamelCaseModel):
    """Schema for student's attendance history"""
    total_sessions: int
    attended: int
    attendance_rate: float
    records: List['AttendanceRecordResponse']


class AttendanceRecordResponse(CamelCaseModel):
    """Schema for individual attendance record"""
    attendance_id: int
    date: datetime
    recognized: bool
    accuracy_percentage: Optional[float] = None
    
    class Config:
        from_attributes = True
