"""Course schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class CourseBase(BaseModel):
    """Base course schema"""
    course_name: str = Field(..., min_length=1, max_length=100)
    course_code: str = Field(..., min_length=1, max_length=20)
    semester: str = Field(..., min_length=1, max_length=20)


class CourseCreate(CourseBase):
    """Schema for creating a course"""
    description: Optional[str] = Field(None, max_length=1000)
    year: Optional[int] = Field(None, ge=1900, le=2100)
    credits: Optional[int] = Field(None, ge=1, le=10)
    max_students: Optional[int] = Field(None, ge=1, le=1000)


class CourseUpdate(BaseModel):
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
    description: Optional[str] = None
    year: Optional[int] = None
    credits: Optional[int] = None
    max_students: Optional[int] = None
    join_code: Optional[str] = None  # Hidden for students
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class CourseDetailResponse(CourseResponse):
    """Schema for detailed course response with instructor info"""
    instructor: 'InstructorBasicInfo'
    enrolled_students_count: int


class CourseEnrollRequest(BaseModel):
    """Schema for course enrollment request"""
    join_code: str = Field(..., min_length=1, max_length=10)


class InstructorBasicInfo(BaseModel):
    """Schema for basic instructor information"""
    instructor_id: int
    full_name: str
    title: Optional[str] = None
    
    class Config:
        from_attributes = True


class CourseEnrollRequest(BaseModel):
    """Schema for enrolling in a course"""
    join_code: str = Field(..., min_length=1, max_length=10)


class CourseEnrollResponse(BaseModel):
    """Schema for course enrollment response"""
    message: str
    course_id: int
    course_name: str
    enrollment_id: int
    joined_at: datetime


class CourseStudentResponse(BaseModel):
    """Schema for student information in a course"""
    student_id: int
    student_number: str
    full_name: str
    department: str
    class_level: int
    total_absences: int
    profile_image_url: Optional[str] = None
    
    class Config:
        from_attributes = True


class CourseStudentsListResponse(BaseModel):
    """Schema for list of students in a course"""
    course_id: int
    course_name: str
    total_students: int
    students: List[CourseStudentResponse]
