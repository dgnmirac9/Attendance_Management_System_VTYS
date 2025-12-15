"""Assignment schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class AssignmentBase(BaseModel):
    """Base assignment schema"""
    title: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    due_date: datetime


class AssignmentCreate(AssignmentBase):
    """Schema for creating an assignment"""
    course_id: int = Field(..., gt=0)


class AssignmentUpdate(BaseModel):
    """Schema for updating an assignment"""
    title: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    due_date: Optional[datetime] = None


class AssignmentResponse(AssignmentBase):
    """Schema for assignment response"""
    assignment_id: int
    course_id: int
    instructor_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class AssignmentDetailResponse(AssignmentResponse):
    """Schema for detailed assignment with submission statistics"""
    submission_count: int
    total_students: int
    submission_rate: float


class AssignmentSubmit(BaseModel):
    """Schema for submitting an assignment"""
    file_url: Optional[str] = Field(None, max_length=255)


class AssignmentSubmissionResponse(BaseModel):
    """Schema for assignment submission response"""
    submission_id: int
    assignment_id: int
    student_id: int
    file_url: Optional[str] = None
    submitted_at: Optional[datetime] = None
    status: str
    grade: Optional[Decimal] = None
    
    class Config:
        from_attributes = True


class AssignmentSubmissionDetailResponse(AssignmentSubmissionResponse):
    """Schema for detailed submission with student and assignment info"""
    student_name: str
    student_number: str
    assignment_title: str
    assignment_due_date: datetime


class GradeUpdate(BaseModel):
    """Schema for updating assignment grade"""
    grade: Decimal = Field(..., ge=0, le=100)


class GradeUpdateResponse(BaseModel):
    """Schema for grade update response"""
    submission_id: int
    grade: Decimal
    message: str = "Grade updated successfully"


class StudentAssignmentResponse(BaseModel):
    """Schema for student's assignment view"""
    assignment_id: int
    title: str
    description: Optional[str] = None
    due_date: datetime
    created_at: datetime
    submission: Optional[AssignmentSubmissionResponse] = None
    
    class Config:
        from_attributes = True


class StudentAssignmentsListResponse(BaseModel):
    """Schema for list of student's assignments"""
    course_id: int
    course_name: str
    total_assignments: int
    completed: int
    pending: int
    assignments: List[StudentAssignmentResponse]
