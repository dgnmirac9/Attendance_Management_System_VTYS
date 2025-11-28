"""Announcement schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class AnnouncementBase(BaseModel):
    """Base announcement schema"""
    type: str = Field(..., pattern="^(duyuru|not|kaynak)$")
    title: str = Field(..., min_length=1, max_length=100)
    content: Optional[str] = None
    attachment_url: Optional[str] = Field(None, max_length=255)


class AnnouncementCreate(AnnouncementBase):
    """Schema for creating an announcement"""
    course_id: int = Field(..., gt=0)


class AnnouncementUpdate(BaseModel):
    """Schema for updating an announcement"""
    title: Optional[str] = Field(None, min_length=1, max_length=100)
    content: Optional[str] = None
    attachment_url: Optional[str] = Field(None, max_length=255)


class AnnouncementResponse(AnnouncementBase):
    """Schema for announcement response"""
    announcement_id: int
    course_id: int
    instructor_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class AnnouncementDetailResponse(AnnouncementResponse):
    """Schema for detailed announcement with instructor info"""
    instructor_name: str
    instructor_title: Optional[str] = None


class CourseAnnouncementsResponse(BaseModel):
    """Schema for list of course announcements"""
    course_id: int
    course_name: str
    total_announcements: int
    announcements: List[AnnouncementResponse]
