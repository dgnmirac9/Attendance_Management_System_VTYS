"""
Attendance endpoints

Bu modül yoklama (attendance) işlemleri için API endpoint'lerini içerir:
- Attendance session oluşturma ve yönetimi
- Face-based check-in işlemleri
- Attendance kayıtları ve raporları
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from datetime import datetime

from app.api.deps import get_db, get_current_user_sync
from app.models.user import User, Student, Instructor
from app.services.attendance_service import AttendanceService
from app.services.user_service import user_service
from app.core.exceptions import (
    AttendanceNotFoundError,
    AttendanceSessionClosedError,
    StudentNotEnrolledError,
    DuplicateAttendanceError,
    FaceVerificationError,
    AppException
)


router = APIRouter()


# Request/Response schemas
class AttendanceSessionCreate(BaseModel):
    """Attendance session creation request"""
    course_id: int = Field(..., description="Course ID")
    session_name: str = Field(..., min_length=1, max_length=100, description="Session name")
    description: Optional[str] = Field(None, max_length=500, description="Session description")
    duration_minutes: Optional[int] = Field(None, ge=5, le=240, description="Session duration (None = unlimited until manually closed)")


from app.schemas.base import CamelCaseModel

class AttendanceSessionResponse(CamelCaseModel):
    """Attendance session response"""
    attendance_id: int
    course_id: int
    course_name: str
    session_name: str
    description: Optional[str]
    start_time: str
    end_time: str
    is_active: bool
    total_students: int
    checked_in_count: int
    
    class Config:
        from_attributes = True


class FaceCheckInRequest(BaseModel):
    """Face check-in request"""
    attendance_id: int = Field(..., description="Attendance session ID")


class CheckInResponse(BaseModel):
    """Check-in response"""
    success: bool
    message: str
    record_id: Optional[int] = None
    check_in_time: Optional[str] = None
    similarity_score: Optional[float] = None
    student_name: Optional[str] = None


class AttendanceRecordResponse(BaseModel):
    """Attendance record response"""
    record_id: int
    student_id: int
    student_number: str
    student_name: str
    check_in_time: str
    similarity_score: float
    is_verified: bool
    
    class Config:
        from_attributes = True


class AttendanceHistoryResponse(BaseModel):
    """Attendance history response"""
    record_id: int
    course_id: int
    course_name: str
    session_name: str
    check_in_time: str
    similarity_score: float
    is_verified: bool
    
    class Config:
        from_attributes = True


class AttendanceStatsResponse(BaseModel):
    """Attendance statistics response"""
    course_id: int
    total_sessions: int
    active_sessions: int
    enrolled_students: int
    total_attendance_records: int
    attendance_rate_percentage: float


@router.post(
    "/",
    response_model=AttendanceSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create attendance session",
    description="""
    Create a new attendance session for a course (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    - Course must be active
    
    **Features:**
    - Configurable session duration (5-120 minutes)
    - Automatic session expiration
    - Real-time attendance tracking
    
    **Returns:**
    - Complete attendance session information
    """,
    responses={
        201: {
            "description": "Attendance session created successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def create_attendance_session(
    session_data: AttendanceSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Create a new attendance session"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can create attendance sessions"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        # Create attendance session
        attendance_service = AttendanceService(db)
        attendance = attendance_service.create_attendance_session(
            course_id=session_data.course_id,
            instructor_id=instructor.instructor_id,
            session_name=session_data.session_name,
            description=session_data.description,
            duration_minutes=session_data.duration_minutes
        )
        
        # Get course name and stats
        from app.services.course_service import course_service
        course = course_service.get_course_by_id_sync(db, session_data.course_id)
        
        # Count enrolled students
        from app.models.course import CourseEnrollment
        total_students = db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == session_data.course_id,
                CourseEnrollment.enrollment_status == "active"
            )
        ).count()
        
        return {
            "attendance_id": attendance.attendance_id,
            "course_id": attendance.course_id,
            "course_name": course.course_name if course else "Unknown Course",
            "session_name": attendance.session_name,
            "description": attendance.description,
            "start_time": attendance.start_time.isoformat(),
            "end_time": attendance.end_time.isoformat(),
            "is_active": attendance.is_active,
            "total_students": total_students,
            "checked_in_count": 0
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Attendance session creation failed: {str(e)}"
        )


@router.get(
    "/{attendance_id}",
    response_model=AttendanceSessionResponse,
    summary="Get attendance session",
    description="""
    Get attendance session details.
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor or enrolled student
    
    **Returns:**
    - Attendance session information with current statistics
    """,
    responses={
        200: {
            "description": "Attendance session retrieved successfully"
        },
        403: {
            "description": "Forbidden - No access to this session"
        },
        404: {
            "description": "Attendance session not found"
        }
    }
)
def get_attendance_session(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get attendance session details"""
    
    try:
        attendance_service = AttendanceService(db)
        attendance = attendance_service.get_attendance_session(attendance_id)
        
        if not attendance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attendance session not found"
            )
        
        # Check permissions
        has_access = False
        
        if current_user.role == "instructor":
            instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
            if instructor and attendance.course.instructor_id == instructor.instructor_id:
                has_access = True
        
        elif current_user.role == "student":
            student = user_service.get_student_profile_sync(db, current_user.user_id)
            if student:
                from app.services.course_service import course_service
                if course_service.check_enrollment_sync(db, attendance.course_id, student.student_id):
                    has_access = True
        
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this attendance session"
            )
        
        # Get statistics
        from app.models.course import CourseEnrollment
        from app.models.attendance import AttendanceRecord
        
        total_students = db.query(CourseEnrollment).filter(
            CourseEnrollment.course_id == attendance.course_id,
            CourseEnrollment.enrollment_status == "active"
        ).count()
        
        checked_in_count = db.query(AttendanceRecord).filter(
            AttendanceRecord.attendance_id == attendance_id
        ).count()
        
        return {
            "attendance_id": attendance.attendance_id,
            "course_id": attendance.course_id,
            "course_name": attendance.course.course_name,
            "session_name": attendance.session_name,
            "description": attendance.description,
            "start_time": attendance.start_time.isoformat(),
            "end_time": attendance.end_time.isoformat(),
            "is_active": attendance.is_active,
            "total_students": total_students,
            "checked_in_count": checked_in_count
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get attendance session: {str(e)}"
        )


@router.put(
    "/{attendance_id}/close",
    response_model=AttendanceSessionResponse,
    summary="Close attendance session",
    description="""
    Close an active attendance session (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    - Session must be active
    
    **Returns:**
    - Updated attendance session information
    """,
    responses={
        200: {
            "description": "Attendance session closed successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Attendance session not found"
        }
    }
)
def close_attendance_session(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Close attendance session"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can close attendance sessions"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        attendance_service = AttendanceService(db)
        attendance = attendance_service.close_attendance_session(attendance_id, instructor.instructor_id)
        
        # Get statistics
        from app.models.course import CourseEnrollment
        from app.models.attendance import AttendanceRecord
        
        total_students = db.query(CourseEnrollment).filter(
            CourseEnrollment.course_id == attendance.course_id,
            CourseEnrollment.enrollment_status == "active"
        ).count()
        
        checked_in_count = db.query(AttendanceRecord).filter(
            AttendanceRecord.attendance_id == attendance_id
        ).count()
        
        return {
            "attendance_id": attendance.attendance_id,
            "course_id": attendance.course_id,
            "course_name": attendance.course.course_name,
            "session_name": attendance.session_name,
            "description": attendance.description,
            "start_time": attendance.start_time.isoformat(),
            "end_time": attendance.end_time.isoformat(),
            "is_active": attendance.is_active,
            "total_students": total_students,
            "checked_in_count": checked_in_count
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to close attendance session: {str(e)}"
        )


@router.post(
    "/check-in",
    response_model=CheckInResponse,
    summary="Face-based check-in",
    description="""
    Check in to an attendance session using face recognition (student only).
    
    **Requirements:**
    - User must be authenticated
    - User must be a student
    - Student must be enrolled in the course
    - Attendance session must be active
    - Face must be registered
    
    **Process:**
    1. Validates attendance session is active
    2. Verifies student enrollment
    3. Performs face recognition
    4. Records attendance with similarity score
    
    **Returns:**
    - Check-in confirmation with details
    """,
    responses={
        200: {
            "description": "Check-in successful"
        },
        400: {
            "description": "Session closed or face verification failed"
        },
        403: {
            "description": "Not enrolled or not a student"
        },
        404: {
            "description": "Session not found"
        },
        409: {
            "description": "Already checked in"
        }
    }
)
def face_check_in(
    check_in_data: FaceCheckInRequest,
    face_image: UploadFile = File(..., description="Face image for verification"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Face-based attendance check-in"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can check in to attendance sessions"
        )
    
    # Get student record
    student = user_service.get_student_profile_sync(db, current_user.user_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found"
        )
    
    # Validate file type
    if not face_image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    try:
        # Read face image data
        face_image_data = face_image.file.read()
        
        # Perform face-based check-in
        attendance_service = AttendanceService(db)
        result = attendance_service.check_in_with_face(
            attendance_id=check_in_data.attendance_id,
            student_id=student.student_id,
            face_image_data=face_image_data
        )
        
        return result
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Check-in failed: {str(e)}"
        )


@router.get(
    "/{attendance_id}/records",
    response_model=List[AttendanceRecordResponse],
    summary="Get attendance records",
    description="""
    Get attendance records for a session (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    
    **Returns:**
    - List of attendance records with student information
    """,
    responses={
        200: {
            "description": "Attendance records retrieved successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Attendance session not found"
        }
    }
)
def get_attendance_records(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> List[Dict[str, Any]]:
    """Get attendance records for session"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can view attendance records"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        attendance_service = AttendanceService(db)
        records = attendance_service.get_attendance_records(attendance_id, instructor.instructor_id)
        
        return records
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get attendance records: {str(e)}"
        )


@router.get(
    "/student/history",
    response_model=List[AttendanceHistoryResponse],
    summary="Get student attendance history",
    description="""
    Get attendance history for the current student.
    
    **Requirements:**
    - User must be authenticated
    - User must be a student
    
    **Parameters:**
    - course_id (optional): Filter by specific course
    - limit (optional): Maximum number of records (default: 50)
    
    **Returns:**
    - List of attendance history records
    """,
    responses={
        200: {
            "description": "Attendance history retrieved successfully"
        },
        403: {
            "description": "Forbidden - Not a student"
        }
    }
)
def get_student_attendance_history(
    course_id: Optional[int] = None,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> List[Dict[str, Any]]:
    """Get student attendance history"""
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can view their attendance history"
        )
    
    # Get student record
    student = user_service.get_student_profile_sync(db, current_user.user_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found"
        )
    
    try:
        attendance_service = AttendanceService(db)
        history = attendance_service.get_student_attendance_history(
            student_id=student.student_id,
            course_id=course_id,
            limit=limit
        )
        
        return history
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get attendance history: {str(e)}"
        )


@router.get(
    "/course/{course_id}/stats",
    response_model=AttendanceStatsResponse,
    summary="Get course attendance statistics",
    description="""
    Get attendance statistics for a course (instructor only).
    
    **Requirements:**
    - User must be authenticated
    - User must be the course instructor
    
    **Returns:**
    - Comprehensive attendance statistics
    """,
    responses={
        200: {
            "description": "Attendance statistics retrieved successfully"
        },
        403: {
            "description": "Forbidden - Not the course instructor"
        },
        404: {
            "description": "Course not found"
        }
    }
)
def get_course_attendance_stats(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get course attendance statistics"""
    
    # Check if user is an instructor
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can view attendance statistics"
        )
    
    # Get instructor record
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Instructor profile not found"
        )
    
    try:
        attendance_service = AttendanceService(db)
        stats = attendance_service.calculate_attendance_statistics(course_id, instructor.instructor_id)
        
        return stats
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get attendance statistics: {str(e)}"
        )

# Mobile App Endpoint for Attendance History
@router.get("/mobile/course/{course_id}/sessions")
def get_mobile_course_sessions(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
):
    """
    Get all attendance sessions for a course (formatted for mobile)
    """
    from app.models.attendance import Attendance, AttendanceRecord
    from app.services.course_service import course_service
    from sqlalchemy import desc
    
    # Check permissions
    if current_user.role == "instructor":
        instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
        if not instructor:
            raise HTTPException(status_code=403, detail="Instructor profile not found")
        
        # Verify course ownership
        course = course_service.get_course_by_id_sync(db, course_id)
        if not course or course.instructor_id != instructor.instructor_id:
             raise HTTPException(status_code=403, detail="Not authorized for this course")
             
    elif current_user.role == "student":
        student = user_service.get_student_profile_sync(db, current_user.user_id)
        if not student:
            raise HTTPException(status_code=403, detail="Student profile not found")
            
        # Verify enrollment (Simplified)
        pass
        
    else:
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        # Get all sessions for this course
        sessions = db.query(Attendance).filter(
            Attendance.course_id == course_id
        ).order_by(desc(Attendance.created_at)).all()
        
        results = []
        for session in sessions:
            attendee_count = db.query(AttendanceRecord).filter(
                AttendanceRecord.attendance_id == session.attendance_id
            ).count()
            
            # Check if current user attended (for students)
            is_present = False
            if current_user.role == "student":
                student = user_service.get_student_profile_sync(db, current_user.user_id)
                if student:
                    for record in session.records:
                        if record.student_id == student.student_id:
                            is_present = True
                            break
            
            results.append({
                "attendanceId": session.attendance_id,
                "startTime": session.start_time.isoformat(),
                "sessionName": session.session_name,
                "attendeeCount": attendee_count,
                "isActive": session.is_active,
                "attendees": [current_user.user_id] if is_present else []
            })
        
        return results
    except Exception as e:
        print(f"Error fetching sessions: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{attendance_id}", status_code=status.HTTP_200_OK)
def delete_attendance(
    attendance_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync),
):
    """Delete an attendance session"""
    if current_user.role != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors can delete attendance sessions"
        )
        
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(status_code=404, detail="Instructor profile not found")
        
    try:
        attendance_service_instance = AttendanceService(db)
        success = attendance_service_instance.delete_attendance_session(attendance_id, instructor.instructor_id)
        if not success:
            raise HTTPException(status_code=404, detail="Attendance session not found or unauthorized")
            
        return {"message": "Attendance session deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
