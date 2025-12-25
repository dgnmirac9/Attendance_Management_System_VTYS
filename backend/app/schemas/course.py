"""Course schemas for request/response validation"""

from app.schemas.base import CamelCaseModel
from pydantic import Field
from typing import Optional, List
from datetime import datetime


class CourseBase(CamelCaseModel):
    """Base course schema"""
    course_name: str = Field(..., min_length=1, max_length=100)
    semester: str = Field(..., min_length=1, max_length=20)
    # Removed: course_code (automatic)


class CourseCreate(CourseBase):
    """Schema for creating a course"""
    description: Optional[str] = Field(None, max_length=1000)
    credits: Optional[int] = Field(None, ge=1, le=10)
    # Removed: year (automatic), course_code (automatic)
    max_students: Optional[int] = Field(None, ge=1, le=1000)


class CourseUpdate(CamelCaseModel):
    """Schema for updating a course"""
    course_name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=1000)
    semester: Optional[str] = Field(None, min_length=1, max_length=20)
    year: Optional[int] = Field(None, ge=1900, le=2100)
    credits: Optional[int] = Field(None, ge=1, le=10)
    max_students: Optional[int] = Field(None, ge=1, le=1000)
    is_active: Optional[bool] = None


class CourseResponse(CourseBase):
    """Schema for course response"""
    course_id: int
    instructor_id: int
    teacher_id: Optional[int] = None # ADDED - Instructor's USER ID for ownership check
    teacher_name: Optional[str] = None
    course_code: str
    description: Optional[str] = None
    year: Optional[int] = None
    credits: Optional[int] = None
    max_students: Optional[int] = None
    join_code: Optional[str] = None  # Hidden for students
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class InstructorBasicInfo(CamelCaseModel):
    """Schema for basic instructor information"""
    instructor_id: int
    full_name: str
    title: Optional[str] = None
    
    class Config:
        from_attributes = True


class CourseDetailResponse(CourseResponse):
    """Schema for detailed course response with instructor info"""
    instructor: 'InstructorBasicInfo'
    enrolled_students_count: int


class CourseEnrollRequest(CamelCaseModel):
    """Schema for enrolling in a course"""
    join_code: str = Field(..., min_length=1, max_length=10)


class CourseEnrollResponse(CamelCaseModel):
    """Schema for course enrollment response"""
    message: str
    course_id: int
    course_name: str
    enrollment_id: int
    joined_at: datetime


class CourseStudentResponse(CamelCaseModel):
    """Schema for student information in a course"""
    student_id: int
    student_number: str
    full_name: str
    total_absences: int
    # Removed: department, class_level
    profile_image_url: Optional[str] = None
    
    class Config:
        from_attributes = True


class CourseStudentsListResponse(CamelCaseModel):
    """Schema for list of students in a course"""
    course_id: int
    course_name: str
    total_students: int
    students: List[CourseStudentResponse]
