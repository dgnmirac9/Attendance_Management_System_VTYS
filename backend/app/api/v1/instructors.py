"""Instructor endpoints"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.api.deps import get_db, get_current_user_sync
from app.models.user import User, Instructor
from app.schemas.user import UserUpdate
from app.services.user_service import user_service
from app.core.exceptions import AppException
from pydantic import BaseModel, Field


router = APIRouter()


# Response schemas
from app.schemas.base import CamelCaseModel

class InstructorProfileResponse(CamelCaseModel):
    """Instructor profile response"""
    instructor_id: int
    user_id: int
    instructor_number: str | None
    # Removed: department, title
    full_name: str
    email: str
    
    class Config:
        from_attributes = True


class InstructorUpdateRequest(CamelCaseModel):
    """Instructor profile update request"""
    full_name: str | None = Field(None, description="Full name")
    email: str | None = Field(None, description="Email address")
    password: str | None = Field(None, min_length=8, description="New password")
    # Removed: department, title


@router.get(
    "/me",
    response_model=InstructorProfileResponse,
    summary="Get current instructor profile",
    description="""
    Get the profile of the currently authenticated instructor.
    
    **Returns:**
    - Instructor profile with user information
    """,
    responses={
        200: {
            "description": "Instructor profile retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "instructorId": 1,
                        "userId": 2,
                        "instructorNumber": "INS001",
                        "fullName": "Dr. Jane Smith",
                        "email": "jane@example.com"
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not an instructor"
        },
        404: {
            "description": "Instructor profile not found"
        }
    }
)
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get current instructor profile"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can access this endpoint"
        )
    
    # Get instructor profile
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    return {
        "instructorId": instructor.instructor_id,
        "userId": instructor.user_id,
        "instructorNumber": getattr(instructor, 'instructor_number', None),
        # Removed: department, title
        "fullName": current_user.full_name,
        "email": current_user.email
    }


@router.put(
    "/me",
    response_model=InstructorProfileResponse,
    summary="Update current instructor profile",
    description="""
    Update the profile of the currently authenticated instructor.
    
    **Returns:**
    - Updated instructor profile
    """,
    responses={
        200: {
            "description": "Profile updated successfully"
        },
        403: {
            "description": "Forbidden - User is not an instructor"
        },
        409: {
            "description": "Conflict - Email already exists"
        }
    }
)
def update_my_profile(
    request: InstructorUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Update current instructor profile"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can access this endpoint"
        )
    
    try:
        # Convert to UserUpdate schema
        update_data = UserUpdate(
            full_name=request.full_name,
            email=request.email,
            password=request.password
            # Removed: department, title
        )
        
        # Update user
        updated_user = user_service.update_user_sync(db, current_user.user_id, update_data)
        
        # Get updated instructor profile
        instructor = user_service.get_instructor_profile_sync(db, updated_user.user_id)
        
        return {
            "instructorId": instructor.instructor_id,
            "userId": instructor.user_id,
            "instructorNumber": getattr(instructor, 'instructor_number', None),
            # Removed: department, title
            "fullName": updated_user.full_name,
            "email": updated_user.email
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Profile update failed: {str(e)}"
        )



