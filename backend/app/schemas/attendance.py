"""Attendance schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class AttendanceCreate(BaseModel):
    """Schema for creating an attendance session"""
    course_id: int = Field(..., gt=0)


class AttendanceResponse(BaseModel):
    """Schema for attendance session response"""
    attendance_id: int
    course_id: int
    instructor_id: int
    attendance_date: datetime
    is_active: bool
    
    class Config:
        from_attributes = True


class AttendanceDetailResponse(AttendanceResponse):
    """Schema for detailed attendance session with statistics"""
    total_students: int
    attended_students: int
    attendance_rate: float


class AttendanceCloseResponse(BaseModel):
    """Schema for closing an attendance session"""
    attendance_id: int
    is_active: bool
    message: str = "Attendance session closed"


class AttendanceCheckRequest(BaseModel):
    """Schema for checking attendance with face recognition"""
    attendance_id: int = Field(..., gt=0)
    face_image: str  # Base64 encoded image


class AttendanceCheckResponse(BaseModel):
    """Schema for attendance check response"""
    success: bool
    recognized: bool
    accuracy_percentage: Optional[float] = None
    student_id: Optional[int] = None
    message: str


class AttendanceRecordResponse(BaseModel):
    """Schema for individual attendance record"""
    record_id: int
    attendance_id: int
    student_id: int
    student_name: str
    student_number: str
    recognized: bool
    accuracy_percentage: Optional[float] = None
    location_info: Optional[str] = None
    joined_at: datetime
    
    class Config:
        from_attributes = True


class AttendanceRecordsListResponse(BaseModel):
    """Schema for list of attendance records"""
    attendance_id: int
    course_id: int
    attendance_date: datetime
    is_active: bool
    total_records: int
    records: List[AttendanceRecordResponse]


class AttendanceQRTokenResponse(BaseModel):
    """Schema for dynamic QR token"""
    qr_token: str
    expires_at: datetime
    attendance_id: int
