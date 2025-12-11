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
class StudentProfileResponse(BaseModel):
    """Student profile response"""
    student_id: int
    user_id: int
    student_number: str
    department: str
    full_name: str
    email: str
    face_registered: bool
    
    class Config:
        from_attributes = True


class StudentUpdateRequest(BaseModel):
    """Student profile update request"""
    full_name: str | None = Field(None, description="Full name")
    email: str | None = Field(None, description="Email address")
    password: str | None = Field(None, min_length=8, description="New password")
    department: str | None = Field(None, description="Department")


@router.get(
    "/me",
    response_model=StudentProfileResponse,
    summary="Get current student profile",
    dependencies=[Depends(get_current_user_sync)],
    description="""
    Get the profile of the currently authenticated student.
    
    **Requirements:**
    - User must be authenticated
    - User must have student role
    
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
                        "student_id": 1,
                        "user_id": 1,
                        "student_number": "2024001",
                        "department": "Computer Science",
                        "full_name": "John Doe",
                        "email": "john@example.com",
                        "face_registered": True
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
        "student_id": student.student_id,
        "user_id": student.user_id,
        "student_number": student.student_number,
        "department": student.department,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "face_registered": student.face_data_url is not None
    }


@router.put(
    "/me",
    response_model=StudentProfileResponse,
    summary="Update current student profile",
    description="""
    Update the profile of the currently authenticated student.
    
    **Requirements:**
    - User must be authenticated
    - User must have student role
    
    **Updatable Fields:**
    - Full name
    - Email (must be unique)
    - Password
    - Department
    
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
            password=request.password,
            department=request.department
        )
        
        # Update user
        updated_user = user_service.update_user_sync(db, current_user.user_id, update_data)
        
        # Get updated student profile
        student = user_service.get_student_profile_sync(db, updated_user.user_id)
        
        return {
            "student_id": student.student_id,
            "user_id": student.user_id,
            "student_number": student.student_number,
            "department": student.department,
            "full_name": updated_user.full_name,
            "email": updated_user.email,
            "face_registered": student.face_data_url is not None
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Profile update failed: {str(e)}"
        )


@router.get(
    "/me/courses",
    summary="Get student's enrolled courses",
    description="""
    Get list of courses the student is enrolled in.
    
    **Requirements:**
    - User must be authenticated
    - User must have student role
    
    **Returns:**
    - List of enrolled courses
    
    **Note:** This endpoint will be fully implemented when Course service is ready.
    """,
    responses={
        200: {
            "description": "Courses retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Course service not yet implemented",
                        "courses": []
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student"
        }
    }
)
def get_my_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get student's enrolled courses"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can access this endpoint"
        )
    
    # TODO: Implement when course service is ready
    return {
        "message": "Course service not yet implemented",
        "courses": []
    }


@router.get(
    "/me/attendance-history",
    summary="Get student's attendance history",
    description="""
    Get attendance history for the student across all courses.
    
    **Requirements:**
    - User must be authenticated
    - User must have student role
    
    **Returns:**
    - List of attendance records
    
    **Note:** This endpoint will be fully implemented when Attendance service is ready.
    """,
    responses={
        200: {
            "description": "Attendance history retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Attendance service not yet implemented",
                        "attendance_records": []
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student"
        }
    }
)
def get_my_attendance_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get student's attendance history"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can access this endpoint"
        )
    
    # TODO: Implement when attendance service is ready
    return {
        "message": "Attendance service not yet implemented",
        "attendance_records": []
    }
