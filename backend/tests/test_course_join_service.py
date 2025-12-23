
import pytest
from unittest.mock import MagicMock
from app.services.course_service import CourseService
from app.models.course import Course, CourseEnrollment
from app.core.exceptions import AppException

def test_join_course_success():
    """Test successful course join"""
    # Setup
    mock_db = MagicMock()
    service = CourseService()
    
    # Mocks
    mock_course = MagicMock(spec=Course)
    mock_course.course_id = 1
    mock_course.max_students = 10
    
    # Mock get_course_by_join_code_sync to return a course
    service.get_course_by_join_code_sync = MagicMock(return_value=mock_course)
    
    # Mock _get_enrollment_sync to return None (not enrolled)
    service._get_enrollment_sync = MagicMock(return_value=None)
    
    # Mock _get_enrollment_count_sync to return 0 (empty course)
    service._get_enrollment_count_sync = MagicMock(return_value=0)
    
    # Action
    result = service.join_course_by_code_sync(mock_db, "ABC123", student_id=5)
    
    # Assert
    assert result.course_id == 1
    assert result.student_id == 5
    assert result.enrollment_status == "active"
    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()

def test_join_course_invalid_code():
    """Test joining with invalid code raises 404"""
    mock_db = MagicMock()
    service = CourseService()
    
    # Mock return None (course not found)
    service.get_course_by_join_code_sync = MagicMock(return_value=None)
    
    with pytest.raises(AppException) as exc:
        service.join_course_by_code_sync(mock_db, "INVALID", student_id=5)
    
    assert exc.value.status_code == 404
    assert "Invalid join code" in exc.value.message

def test_join_course_already_enrolled():
    """Test joining already enrolled course raises 409"""
    mock_db = MagicMock()
    service = CourseService()
    
    mock_course = MagicMock(spec=Course)
    mock_course.course_id = 1
    
    service.get_course_by_join_code_sync = MagicMock(return_value=mock_course)
    
    # Mock enrollment exists
    mock_enrollment = MagicMock(spec=CourseEnrollment)
    service._get_enrollment_sync = MagicMock(return_value=mock_enrollment)
    
    with pytest.raises(AppException) as exc:
        service.join_course_by_code_sync(mock_db, "ABC123", student_id=5)
    
    assert exc.value.status_code == 409
    assert "already enrolled" in exc.value.message

def test_join_course_limit_reached():
    """Test joining full course raises 409"""
    mock_db = MagicMock()
    service = CourseService()
    
    mock_course = MagicMock(spec=Course)
    mock_course.course_id = 1
    mock_course.max_students = 10
    
    service.get_course_by_join_code_sync = MagicMock(return_value=mock_course)
    service._get_enrollment_sync = MagicMock(return_value=None)
    
    # Mock count equals max
    service._get_enrollment_count_sync = MagicMock(return_value=10)
    
    with pytest.raises(AppException) as exc:
        service.join_course_by_code_sync(mock_db, "ABC123", student_id=5)
    
    assert exc.value.status_code == 409
    assert "Course is full" in exc.value.message
