from typing import Optional
from datetime import datetime
from app.schemas.base import CamelCaseModel

class AnnouncementBase(CamelCaseModel):
    title: str
    content: Optional[str] = None
    type: str = "duyuru"

class AnnouncementCreate(AnnouncementBase):
    class_id: int

class AnnouncementUpdate(AnnouncementBase):
    pass

class AnnouncementResponse(AnnouncementBase):
    announcement_id: int
    course_id: int
    instructor_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
