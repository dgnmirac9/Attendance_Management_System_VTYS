"""Course endpoints"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import Dict, Any, List, Optional

from app.api.deps import get_db, get_current_user_sync
from app.models.user import User, Student, Instructor
from app.schemas.course import CourseCreate, CourseUpdate, CourseResponse, CourseEnrollRequest
from app.services.course_service import course_service
from app.services.user_service import user_service
from app.core.exceptions import AppException
from pydantic import BaseModel, Field


router = APIRouter()


# Response schemas
class CourseListResponse(BaseModel):
    """Course list response"""
    courses: List[CourseResponse]
    total: int


class CourseEnrollmentResponse(BaseModel):
    """Course enrollment response"""
    message: str
    course_id: int
    course_name: str
    enrollment_status: str


class StudentListResponse(BaseModel):
    """Student list response"""
    student_id: int
    student_number: str
    full_name: str
    email: str
    enrollment_date: Optional[str] = None
    
    class Config:
        from_attributes = True


@router.post(
    "/",
    response_model=CourseResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new course",
    description="""
    Create a new course (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must have instructor role
    
    **Features:**
    - Automatic join code generation (6-character alphanumeric)
    - Course capacity management
    - Semester and year tracking
    
    **Returns:**
    - Complete course information including join code
    """,
    responses={
        201: {
            "description": "Course created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "course_id": 1,
                        "course_name": "Introduction to Programming",
                        "course_code": "CS101",
                        "description": "Basic programming concepts",
                        "instructor_id": 1,
                        "join_code": "ABC123",
                        "semester": "Fall",
                        "year": 2024,
                        "credits": 3,
                        "max_students": 50,
                        "is_active": True,
                        "created_at": "2024-01-01T00:00:00Z"
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not an instructor"
        }
    }
)
def create_course(
    course_data: CourseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Create a new course"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can create courses"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        # Create course
        course = course_service.create_course_sync(db, course_data, instructor.instructor_id)
        
        return {
            "course_id": course.course_id,
            "course_name": course.course_name,
            "course_code": course.course_code,
            "description": course.description,
            "instructor_id": course.instructor_id,
            "join_code": course.join_code,
            "semester": course.semester,
            "year": course.year,
            "credits": course.credits,
            "max_students": course.max_students,
            "is_active": course.is_active,
            "created_at": course.created_at.isoformat()
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Course creation failed: {str(e)}"
        )


@router.get(
    "/",
    response_model=List[Dict[str, Any]],
    summary="Get user's courses"
)
def get_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> List[Dict[str, Any]]:
    """Get courses for current user"""
    from app.models.course import Course
    
    try:
        courses = []
        
        if current_user.role == "instructor":
            instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
            if not instructor:
                return []
            # Direct database query for instructor courses (only active)
            courses = db.query(Course).filter(
                and_(
                    Course.instructor_id == instructor.instructor_id,
                    Course.is_active == True  # Only show active courses
                )
            ).all()
            
        elif current_user.role == "student":
            student = user_service.get_student_profile_sync(db, current_user.user_id)
            if not student:
                return []
            # Join with enrollments to get student courses (only active enrollments)
            from app.models.course import CourseEnrollment
            courses = db.query(Course).join(
                CourseEnrollment, Course.course_id == CourseEnrollment.course_id
            ).filter(
                and_(
                    CourseEnrollment.student_id == student.student_id,
                    CourseEnrollment.enrollment_status == "active",  # Only active enrollments
                    Course.is_active == True  # Only show active courses
                )
            ).all()
        else:
            return []
        
        result = []
        for course in courses:
            # Get instructor name and user_id
            teacher_name = ""
            teacher_user_id = None
            if course.instructor_id:
                instructor_user = db.query(User).join(
                    Instructor, User.user_id == Instructor.user_id
                ).filter(
                    Instructor.instructor_id == course.instructor_id
                ).first()
                if instructor_user:
                    teacher_name = instructor_user.full_name
                    teacher_user_id = instructor_user.user_id
            
            result.append({
                "id": course.course_id,
                "className": course.course_name,
                "teacherId": course.instructor_id,
                "teacherName": teacher_name,  # ADDED
                "joinCode": course.join_code,
                "studentIds": [],
                "createdAt": course.created_at.isoformat() if course.created_at else None
            })
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get courses: {str(e)}"
        )


@router.get(
    "/{course_id}",
    response_model=CourseResponse,
    summary="Get course details",
    description="""
    Get detailed information about a specific course.
    
    **Requirements:**
    - User must be authenticated
    - User must be enrolled in the course (student) or own the course (instructor)
    
    **Returns:**
    - Complete course information
    """,
    responses={
        200: {
            "description": "Course details retrieved successfully"
        },
        403: {
            "description": "Forbidden - Not enrolled or not course owner"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get course details"""
    
    # Get course
    course = course_service.get_course_by_id_sync(db, course_id)
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found"
        )
    
    # Check permissions
    has_access = False
    
    if current_user.role == "instructor":
        instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
        if instructor and course.instructor_id == instructor.instructor_id:
            has_access = True
    
    elif current_user.role == "student":
        student = user_service.get_student_profile_sync(db, current_user.user_id)
        if student and course_service.check_enrollment_sync(db, course_id, student.student_id):
            has_access = True
    
    if not has_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this course"
        )
    
    # Get teacher name and user_id
    teacher_name = ""
    teacher_user_id = None
    if course.instructor_id:
        instructor_user = db.query(User).join(
            Instructor, User.user_id == Instructor.user_id
        ).filter(
            Instructor.instructor_id == course.instructor_id
        ).first()
        if instructor_user:
            teacher_name = instructor_user.full_name
            teacher_user_id = instructor_user.user_id
    
    
    response_data = {
        "course_id": course.course_id,
        "course_name": course.course_name,
        "course_code": course.course_code,
        "description": course.description,
        "instructor_id": course.instructor_id,
        "teacher_id": teacher_user_id, # Return User ID
        "teacher_name": teacher_name,
        "join_code": course.join_code if current_user.role == "instructor" else None,
        "semester": course.semester,
        "year": course.year,
        "credits": course.credits,
        "max_students": course.max_students,
        "is_active": course.is_active,
        "created_at": course.created_at.isoformat()
    }
    
    print(f"DEBUG: GET /courses/{course_id} response:", response_data)
    return response_data


@router.post(
    "/join",
    response_model=CourseEnrollmentResponse,
    summary="Join course with code",
    description="""
    Join a course using the join code (student only).
    
    **Requirements:**
    - User must be authenticated
    - User must have student role
    - Valid join code
    - Course must be active
    - Course must not be full
    
    **Returns:**
    - Enrollment confirmation
    """,
    responses={
        200: {
            "description": "Successfully joined course",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Successfully joined course",
                        "course_id": 1,
                        "course_name": "Introduction to Programming",
                        "enrollment_status": "active"
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student"
        },
        404: {
            "description": "Invalid join code"
        },
        409: {
            "description": "Already enrolled or course full"
        }
    }
)
def join_course(
    enrollment_data: CourseEnrollRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Join course with join code"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can join courses"
        )
    
    # Get student record
    student = user_service.get_student_profile_sync(db, current_user.user_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found"
        )
    
    try:
        # Join course
        enrollment = course_service.join_course_by_code_sync(
            db, enrollment_data.join_code, student.student_id
        )
        
        # Get course details
        course = course_service.get_course_by_id_sync(db, enrollment.course_id)
        
        return {
            "message": "Successfully joined course",
            "course_id": course.course_id,
            "course_name": course.course_name,
            "enrollment_status": enrollment.enrollment_status
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Course enrollment failed: {str(e)}"
        )


@router.get(
    "/{course_id}/students",
    summary="Get course students",
    description="""
    Get list of students enrolled in the course (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    
    **Returns:**
    - List of enrolled students with their information
    """,
    responses={
        200: {
            "description": "Student list retrieved successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def get_course_students(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> List[Dict[str, Any]]:
    """Get list of students in course"""
    
    # Check role and get students
    try:
        if current_user.role == "instructor":
            instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
            if not instructor:
                raise HTTPException(status_code=404, detail="Instructor profile not found")
            students = course_service.get_course_students_sync(db, course_id, instructor.instructor_id)
            
        elif current_user.role == "student":
            student = user_service.get_student_profile_sync(db, current_user.user_id)
            if not student:
                 raise HTTPException(status_code=404, detail="Student profile not found")
            students = course_service.get_course_students_for_student_sync(db, course_id, student.student_id)
            
        else:
            raise HTTPException(status_code=403, detail="Unauthorized")
        
        # Format response
        student_list = []
        for student in students:
            # Get enrollment date
            from app.models.course import CourseEnrollment
            from sqlalchemy import and_
            enrollment = db.query(CourseEnrollment).filter(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.student_id == student.student_id
                )
            ).first()
            
            student_list.append({
                "student_id": student.student_id,
                "user_id": student.user_id,
                "student_number": student.student_number,
                "full_name": student.user.full_name,
                "email": student.user.email,
                "enrollment_date": enrollment.created_at.isoformat() if enrollment and enrollment.created_at else None
            })
        
        return student_list
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        import traceback
        print(f"Error checking students: {str(e)}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get course students: {str(e)}"
        )


@router.put(
    "/{course_id}",
    response_model=CourseResponse,
    summary="Update course",
    description="""
    Update course information (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    
    **Updatable Fields:**
    - Course name
    - Description
    - Semester
    - Year
    - Credits
    - Max students
    - Active status
    
    **Returns:**
    - Updated course information
    """,
    responses={
        200: {
            "description": "Course updated successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def update_course(
    course_id: int,
    course_data: CourseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Update course information"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can update courses"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        # Update course (this will check ownership)
        course = course_service.update_course_sync(db, course_id, course_data, instructor.instructor_id)
        
        return {
            "course_id": course.course_id,
            "course_name": course.course_name,
            "course_code": course.course_code,
            "description": course.description,
            "instructor_id": course.instructor_id,
            "join_code": course.join_code,
            "semester": course.semester,
            "year": course.year,
            "credits": course.credits,
            "max_students": course.max_students,
            "is_active": course.is_active,
            "created_at": course.created_at.isoformat()
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Course update failed: {str(e)}"
        )


@router.delete(
    "/{course_id}",
    summary="Delete course",
    description="""
    Delete (deactivate) a course (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    
    **Note:** This is a soft delete - the course is deactivated but not removed from database.
    
    **Returns:**
    - Deletion confirmation
    """,
    responses={
        200: {
            "description": "Course deleted successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def delete_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Delete (deactivate) course"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can delete courses"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        # Delete course (this will check ownership)
        deleted = course_service.delete_course_sync(db, course_id, instructor.instructor_id)
        
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Course not found"
            )
        
        return {
            "message": "Course deleted successfully",
            "course_id": course_id
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Course deletion failed: {str(e)}"
        )


@router.post(
    "/{course_id}/leave",
    summary="Leave course",
    description="""
    Leave a course (student only).
    
    **Requirements:**
    - User must be authenticated
    - User must be enrolled in the course
    - User must have student role
    
    **Returns:**
    - Confirmation message
    """,
    responses={
        200: {
            "description": "Left course successfully"
        },
        403: {
            "description": "Forbidden - Not a student"
        },
        404: {
            "description": "Course or enrollment not found"
        }
    }
)
def leave_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Leave a course"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can leave courses"
        )
    
    # Get student record
    student = user_service.get_student_profile_sync(db, current_user.user_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found"
        )
    
    try:
        # Check enrollment first
        enrollment = course_service._get_enrollment_sync(db, course_id, student.student_id)
        if not enrollment or enrollment.enrollment_status != "active":
             raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are not enrolled in this course"
            )

        # Deactivate enrollment
        # Note: We manually update for now since service method might be missing or async in the interface
        # Ideally this should be in course_service.leave_course_sync
        enrollment.enrollment_status = "dropped"
        db.commit()
        
        return {
            "message": "Successfully left course",
            "course_id": course_id
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to leave course: {str(e)}"
        )