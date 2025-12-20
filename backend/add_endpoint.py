with open('backend/app/api/v1/attendances.py', 'r', encoding='utf-8') as f:
    content = f.read()

endpoint = '''

# Mobile App Endpoint for Attendance History
@router.get("/mobile/course/{course_id}/sessions")
def get_mobile_course_sessions(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
):
    """Get all attendance sessions for a course (mobile app)"""
    from app.models.attendance import Attendance, AttendanceRecord
    from app.services.course_service import course_service
    from sqlalchemy import desc
    
    # Verify course access
    course = course_service.get_course_by_id_sync(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
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
'''

with open('backend/app/api/v1/attendances.py', 'w', encoding='utf-8') as f:
    f.write(content + endpoint)
