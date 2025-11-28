"""Student schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class StudentBase(BaseModel):
    """Base student schema"""
    student_number: str = Field(..., min_length=1, max_length=20)
    department: str = Field(..., min_length=1, max_length=100)
    class_level: int = Field(..., ge=1, le=4)
    enrollment_year: int = Field(..., ge=1900, le=2100)


class StudentCreate(StudentBase):
    """Schema for creating a student (used internally after user creation)"""
    user_id: int


class StudentUpdate(BaseModel):
    """Schema for updating student profile"""
    department: Optional[str] = Field(None, min_length=1, max_length=100)
    class_level: Optional[int] = Field(None, ge=1, le=4)
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


class StudentCourseResponse(BaseModel):
    """Schema for student's course information"""
    course_id: int
    course_name: str
    course_code: str
    semester: str
    instructor_name: str
    joined_at: datetime
    
    class Config:
        from_attributes = True


class StudentAttendanceHistoryResponse(BaseModel):
    """Schema for student's attendance history"""
    total_sessions: int
    attended: int
    attendance_rate: float
    records: List['AttendanceRecordResponse']


class AttendanceRecordResponse(BaseModel):
    """Schema for individual attendance record"""
    attendance_id: int
    date: datetime
    recognized: bool
    accuracy_percentage: Optional[float] = None
    
    class Config:
        from_attributes = True
