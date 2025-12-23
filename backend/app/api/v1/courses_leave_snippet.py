
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
        # Note: We need to implement leave_course logic in course_service if not exists
        # course_service.leave_course_sync(db, course_id, student.student_id)
        
        # Manual update for now since service method might be missing or async
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
