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
class InstructorProfileResponse(BaseModel):
    """Instructor profile response"""
    instructor_id: int
    user_id: int
    instructor_number: str | None
    department: str | None
    title: str | None
    full_name: str
    email: str
    
    class Config:
        from_attributes = True


class InstructorUpdateRequest(BaseModel):
    """Instructor profile update request"""
    full_name: str | None = Field(None, description="Full name")
    email: str | None = Field(None, description="Email address")
    password: str | None = Field(None, min_length=8, description="New password")
    department: str | None = Field(None, description="Department")
    title: str | None = Field(None, description="Academic title")


@router.get(
    "/me",
    response_model=InstructorProfileResponse,
    summary="Get current instructor profile",
    description="""
    Get the profile of the currently authenticated instructor.
    
    **Requirements:**
    - User must be authenticated
    - User must have instructor role
    
    **Returns:**
    - Instructor profile with user information
    """,
    responses={
        200: {
            "description": "Instructor profile retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "instructor_id": 1,
                        "user_id": 2,
                        "instructor_number": "INS001",
                        "department": "Computer Science",
                        "title": "Professor",
                        "full_name": "Dr. Jane Smith",
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
        "instructor_id": instructor.instructor_id,
        "user_id": instructor.user_id,
        "instructor_number": getattr(instructor, 'instructor_number', None),
        "department": getattr(instructor, 'department', None),
        "title": instructor.title,
        "full_name": current_user.full_name,
        "email": current_user.email
    }


@router.put(
    "/me",
    response_model=InstructorProfileResponse,
    summary="Update current instructor profile",
    description="""
    Update the profile of the currently authenticated instructor.
    
    **Requirements:**
    - User must be authenticated
    - User must have instructor role
    
    **Updatable Fields:**
    - Full name
    - Email (must be unique)
    - Password
    - Department
    - Academic title
    
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
            password=request.password,
            department=request.department,
            title=request.title
        )
        
        # Update user
        updated_user = user_service.update_user_sync(db, current_user.user_id, update_data)
        
        # Get updated instructor profile
        instructor = user_service.get_instructor_profile_sync(db, updated_user.user_id)
        
        return {
            "instructor_id": instructor.instructor_id,
            "user_id": instructor.user_id,
            "instructor_number": getattr(instructor, 'instructor_number', None),
            "department": getattr(instructor, 'department', None),
            "title": instructor.title,
            "full_name": updated_user.full_name,
            "email": updated_user.email
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
    summary="Get instructor's courses",
    description="""
    Get list of courses taught by the instructor.
    
    **Requirements:**
    - User must be authenticated
    - User must have instructor role
    
    **Returns:**
    - List of courses with enrollment statistics
    """,
    responses={
        200: {
            "description": "Courses retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "courses": [
                            {
                                "course_id": 1,
                                "course_name": "Introduction to Programming",
                                "course_code": "CS101",
                                "join_code": "ABC123",
                                "semester": "Fall",
                                "year": 2024,
                                "credits": 3,
                                "max_students": 50,
                                "enrolled_students": 25,
                                "is_active": True
                            }
                        ],
                        "total": 1
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not an instructor"
        }
    }
)
def get_my_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get instructor's courses"""
    
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
    
    try:
        from app.services.course_service import course_service
        
        # Get instructor's courses
        courses = course_service.list_instructor_courses_sync(db, instructor.instructor_id)
        
        # Format response with enrollment stats
        course_list = []
        for course in courses:
            enrolled_count = course_service._get_enrollment_count_sync(db, course.course_id)
            
            course_list.append({
                "course_id": course.course_id,
                "course_name": course.course_name,
                "course_code": course.course_code,
                "join_code": course.join_code,
                "description": course.description,
                "semester": course.semester,
                "year": course.year,
                "credits": course.credits,
                "max_students": course.max_students,
                "enrolled_students": enrolled_count,
                "is_active": course.is_active,
                "created_at": course.created_at.isoformat()
            })
        
        return {
            "courses": course_list,
            "total": len(course_list)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get courses: {str(e)}"
        )
