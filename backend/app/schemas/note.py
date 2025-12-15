"""Student shared note schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class StudentSharedNoteBase(BaseModel):
    """Base student shared note schema"""
    title: str = Field(..., min_length=1, max_length=100)
    content: Optional[str] = None
    file_url: Optional[str] = Field(None, max_length=255)


class StudentSharedNoteCreate(StudentSharedNoteBase):
    """Schema for creating a shared note"""
    course_id: int = Field(..., gt=0)


class StudentSharedNoteUpdate(BaseModel):
    """Schema for updating a shared note"""
    title: Optional[str] = Field(None, min_length=1, max_length=100)
    content: Optional[str] = None
    file_url: Optional[str] = Field(None, max_length=255)


class StudentSharedNoteResponse(StudentSharedNoteBase):
    """Schema for shared note response"""
    note_id: int
    student_id: int
    course_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class StudentSharedNoteDetailResponse(StudentSharedNoteResponse):
    """Schema for detailed shared note with student info"""
    student_name: str
    student_number: str
    department: str


class CourseSharedNotesResponse(BaseModel):
    """Schema for list of course shared notes"""
    course_id: int
    course_name: str
    total_notes: int
    notes: List[StudentSharedNoteDetailResponse]


class DeleteNoteResponse(BaseModel):
    """Schema for note deletion response"""
    note_id: int
    message: str = "Note deleted successfully"
