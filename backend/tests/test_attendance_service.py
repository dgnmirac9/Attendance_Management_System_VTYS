import sys
import pytest
from unittest.mock import MagicMock

# Mock heavy dependencies before import
sys.modules["app.services.face_service"] = MagicMock()

from datetime import datetime
from app.services.attendance_service import AttendanceService
from app.models.attendance import Attendance, AttendanceRecord
from app.core.exceptions import AppException

def test_create_session_success():
    """Test successful attendance session creation"""
    mock_db = MagicMock()
    service = AttendanceService(db=mock_db)
    
    # Setup mocks
    mock_course = MagicMock()
    mock_course.instructor_id = 1
    mock_course.is_active = True
    # Service uses db query directly, not get_course_by_id. 
    # But let's check creating session code. 
    # It calls self.db.query(Course)! 
    # So mocking get_course_by_id_sync has NO EFFECT.
    # We must mock db.query.
    
    # Mock Course Query Result
    mock_db.query.return_value.filter.return_value.first.return_value = mock_course
    
    # Mock active session check (None = no active session)
    # create_attendance_session doesn't check active sessions in the snippet provided previously.
    # But if it did... 
    # Just mocking db.query is enough for Course check.
    
    # Mock active session check (None = no active session)
    # service.get_active_session_sync = MagicMock(return_value=None)
    
    result = service.create_attendance_session(
        course_id=10, instructor_id=1, session_name="Test Session", description="Desc", duration_minutes=15
    )
    
    assert result.course_id == 10
    assert result.instructor_id == 1
    assert result.is_active is True
    mock_db.add.assert_called()

def test_start_session_unauthorized():
    """Test standard instructor check logic (although enforced by API usually)"""
    mock_db = MagicMock()
    service = AttendanceService(db=mock_db)
    
    mock_course = MagicMock()
    mock_course.instructor_id = 999
    # Mock Course finding - Return None to trigger "Not found or unauthorized"
    mock_db.query.return_value.filter.return_value.first.return_value = None
    
    with pytest.raises(AppException) as exc:
        service.create_attendance_session(
            course_id=10, instructor_id=1, session_name="Test", duration_minutes=15
        )
    assert exc.value.status_code == 404

def test_check_in_success():
    """Test successful face check-in"""
    mock_db = MagicMock()
    service = AttendanceService(db=mock_db)
    
    # Mock Session
    mock_session = MagicMock(spec=Attendance)
    mock_session.session_id = 5
    mock_session.is_active = True
    mock_session.end_time = datetime.max # Future
    mock_session.current_qr_token = None
    service.get_attendance_session = MagicMock(return_value=mock_session)
    
    # Mock Student
    mock_student = MagicMock()
    mock_student.student_id = 50
    
    # Mock Enrollment check
    mock_enrollment = MagicMock()
    mock_enrollment.student.user.full_name = "Test Student"
    # Implementation uses db query for enrollment.
    # We configured db.query side_effect for this.
    # service._check_enrollment_sync = MagicMock(return_value=True)  <-- This won't work if it's not called.
    pass
    
    # Needs to bypass query chaining correctly or match exact queries
    # Since we can't easily match exactly, we'll spy on db.query
    # But db is a Mock. 
    # Let's just mock the 'first()' call to return the enrollment if called for enrollment.
    # Logic in service: query(CourseEnrollment).filter().first()
    # It also queries AttendanceRecord
    
    # We'll use side_effect for db.query(...).filter(...).first()
    # This is complex with Mocks. 
    # Simplified: We rely on the fact that existing_record is None (default mock return)
    # and enrollment is found.
    # The existing code calls .first() on filters.
    # If we just return mock_enrollment for everything, it might break 'existing_record' check (it would find one).
    
    # Solution: Mock db.query side_effect
    pass
    
    # Override query logic is too hard here without extensive setup.
    # We will assume happy path if we can fix the query return.
    
    # Re-write the db mock setup for this test function specifically
    mock_query = mock_db.query.return_value
    mock_filter = mock_query.filter.return_value
    
    # Enroll found, Record NOT found
    # first() called twice. sequence: [enrollment, existing_record] (actually logic: 1. check enrollment, 2. check record)
    mock_filter.first.side_effect = [mock_enrollment, None]
    
    # Calculate Distance (Mock to return small distance)
    service._calculate_distance = MagicMock(return_value=10.0) # 10 meters
    
    service.get_attendance_session = MagicMock(return_value=mock_session)
    
    result = service.check_in_with_face(
        attendance_id=5, 
        student_id=50, 
        face_image_data=b"mockdata"
    )
    
    assert result["success"] is True
    assert result["student_name"] == "Test Student"
