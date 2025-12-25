"""Student endpoints"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any, List

from app.api.deps import get_db, get_current_user_sync
from app.models.user import User, Student
from app.schemas.user import UserUpdate
from app.services.user_service import user_service
from app.core.exceptions import AppException
from pydantic import BaseModel, Field


router = APIRouter()


# Response schemas
from app.schemas.base import CamelCaseModel

class StudentProfileResponse(CamelCaseModel):
    """Student profile response"""
    student_id: int
    user_id: int
    student_number: str
    # Removed: department
    full_name: str
    email: str
    face_registered: bool
    
    class Config:
        from_attributes = True


class StudentUpdateRequest(CamelCaseModel):
    """Student profile update request"""
    full_name: str | None = Field(None, description="Full name")
    email: str | None = Field(None, description="Email address")
    password: str | None = Field(None, min_length=8, description="New password")
    # Removed: department


@router.get(
    "/me",
    response_model=StudentProfileResponse,
    summary="Get current student profile",
    dependencies=[Depends(get_current_user_sync)],
    description="""
    Get the profile of the currently authenticated student.
    
    **Returns:**
    - Student profile with user information
    - Face registration status
    """,
    responses={
        200: {
            "description": "Student profile retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "studentId": 1,
                        "userId": 1,
                        "studentNumber": "2024001",
                        "fullName": "John Doe",
                        "email": "john@example.com",
                        "faceRegistered": True
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student"
        },
        404: {
            "description": "Student profile not found"
        }
    }
)
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get current student profile"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can access this endpoint"
        )
    
    # Get student profile
    student = user_service.get_student_profile_sync(db, current_user.user_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found"
        )
    
    return {
        "studentId": student.student_id,
        "userId": student.user_id,
        "studentNumber": student.student_number,
        # Removed: department
        "fullName": current_user.full_name,
        "email": current_user.email,
        "faceRegistered": student.face_data_url is not None
    }


@router.put(
    "/me",
    response_model=StudentProfileResponse,
    summary="Update current student profile",
    description="""
    Update the profile of the currently authenticated student.
    
    **Returns:**
    - Updated student profile
    """,
    responses={
        200: {
            "description": "Profile updated successfully"
        },
        403: {
            "description": "Forbidden - User is not a student"
        },
        409: {
            "description": "Conflict - Email already exists"
        }
    }
)
def update_my_profile(
    request: StudentUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Update current student profile"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can access this endpoint"
        )
    
    try:
        # Convert to UserUpdate schema
        update_data = UserUpdate(
            full_name=request.full_name,
            email=request.email,
            password=request.password
            # Removed: department
        )
        
        # Update user
        updated_user = user_service.update_user_sync(db, current_user.user_id, update_data)
        
        # Get updated student profile
        student = user_service.get_student_profile_sync(db, updated_user.user_id)
        
        return {
            "studentId": student.student_id,
            "userId": student.user_id,
            "studentNumber": student.student_number,
            # Removed: department
            "fullName": updated_user.full_name,
            "email": updated_user.email,
            "faceRegistered": student.face_data_url is not None
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Profile update failed: {str(e)}"
        )



