from typing import List, Any
from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.content import Announcement
from app.models.course import Course
from app.api.deps import get_current_user_sync
from app.schemas.announcement import AnnouncementCreate, AnnouncementResponse

router = APIRouter()

@router.get("", response_model=List[dict])
def get_announcements(
    class_id: int = Query(..., description="Course ID to filter announcements"),
    db: Session = Depends(get_db),
    current_user: Any = Depends(get_current_user_sync)
):
    """
    Get announcements for a specific course.
    Mobile app expects a list of dictionaries.
    """
    # Verify course exists
    course = db.query(Course).filter(Course.course_id == class_id).first()
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Course not found"
        )
        
    # Check access permissions (Instructor or Enrolled Student)
    # For now, simplistic check: if authenticated, can see. 
    # Production should enforce enrollment check.
    
    announcements = db.query(Announcement).filter(
        Announcement.course_id == class_id
    ).order_by(desc(Announcement.created_at)).all()
    
    # Transform to match Mobile App expectations (Map<String, dynamic>)
    result = []
    for a in announcements:
        result.append({
            "id": a.announcement_id,
            "title": a.title,
            "content": a.content,
            "createdAt": a.created_at.isoformat() if a.created_at else None,
            "type": a.type,
            "teacherName": a.instructor.user.full_name if a.instructor and a.instructor.user else "Unknown"
        })
    
    return result

@router.post("", status_code=status.HTTP_201_CREATED)
def create_announcement(
    data: AnnouncementCreate,
    db: Session = Depends(get_db),
    current_user: Any = Depends(get_current_user_sync)
):
    """
    Create a new announcement.
    Only instructors can create announcements.
    """
    if current_user.role != 'instructor':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can create announcements"
        )
        
    # Verify instructor owns the course
    course = db.query(Course).filter(
        Course.course_id == data.class_id,
        Course.instructor_id == current_user.instructor.instructor_id
    ).first()
    
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found or unauthorized"
        )
        
    new_announcement = Announcement(
        course_id=data.class_id,
        instructor_id=current_user.instructor.instructor_id,
        title=data.title,
        content=data.content,
        type="duyuru"
    )
    
    db.add(new_announcement)
    db.commit()
    db.refresh(new_announcement)
    
    return {
        "success": True,
        "message": "Announcement created",
        "id": new_announcement.announcement_id
    }

@router.delete("/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_announcement(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: Any = Depends(get_current_user_sync)
):
    """
    Delete an announcement.
    """
    if current_user.role != 'instructor':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can delete announcements"
        )
        
    announcement = db.query(Announcement).filter(
        Announcement.announcement_id == announcement_id
    ).first()
    
    if not announcement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Announcement not found"
        )
        
    # Check ownership
    if announcement.instructor_id != current_user.instructor.instructor_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own announcements"
        )
        
    db.delete(announcement)
    db.commit()
    return None
