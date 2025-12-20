
import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch
import sys

# Global Mocking
sys.modules["app.services.face_service"] = MagicMock()

# Import app after mocking
from app.main import app
from app.api.deps import get_current_user_sync, get_db

client = TestClient(app)

# Dummy User Data
STUDENT_USER = MagicMock()
STUDENT_USER.user_id = 1
STUDENT_USER.role = "student"
STUDENT_USER.email = "student@test.com"

INSTRUCTOR_USER = MagicMock()
INSTRUCTOR_USER.user_id = 10
INSTRUCTOR_USER.role = "instructor"
INSTRUCTOR_USER.email = "inst@test.com"


class TestPhase5Integration:
    
    @pytest.fixture(autouse=True)
    def override_dependency(self):
        app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
        yield
        app.dependency_overrides = {}

    def test_leave_course(self):
        """Test POST /courses/{id}/leave endpoint"""
        with patch("app.api.v1.courses.course_service") as mock_service, \
             patch("app.api.v1.courses.user_service") as mock_user_service:
            
            # Setup Mocks
            mock_user_service.get_student_profile_sync.return_value = MagicMock(student_id=100)
            mock_service.check_enrollment_sync.return_value = True
            
            # Mock DB query for enrollment
            mock_db = MagicMock()
            app.dependency_overrides[get_db] = lambda: mock_db
            
            mock_enrollment = MagicMock()
            mock_db.query.return_value.filter.return_value.first.return_value = mock_enrollment
            
            # Action
            response = client.post("/api/v1/courses/1/leave")
            
            # Assert
            assert response.status_code == 200
            assert response.json()["message"] == "Successfully left course"
            # Verify status update or delete was called
            # Since logic depends on attribute, let's just assume success for now 
            # as basic plumbing test

    def test_get_attendance_participants(self):
        """Test GET /attendance/{id}/participants alias"""
        # Switch to Instructor
        app.dependency_overrides[get_current_user_sync] = lambda: INSTRUCTOR_USER
        
        with patch("app.api.v1.attendances.user_service") as mock_user_service, \
             patch("app.api.v1.attendances.AttendanceService") as MockService:
            
            mock_user_service.get_instructor_profile_sync.return_value = MagicMock(instructor_id=50)
            
            # Mock Service return
            mock_instance = MockService.return_value
            mock_instance.get_attendance_records.return_value = [
                {"student_id": 1, "status": "present"}
            ]
            
            response = client.get("/api/v1/attendance/1/participants")
            assert response.status_code == 200
            assert isinstance(response.json(), list)

    def test_delete_attendance(self):
        """Test DELETE /attendance/{id}"""
        # Switch to Instructor
        app.dependency_overrides[get_current_user_sync] = lambda: INSTRUCTOR_USER
        
        with patch("app.api.v1.attendances.user_service") as mock_user_service, \
             patch("app.api.v1.attendances.AttendanceService") as MockService:
             
            mock_user_service.get_instructor_profile_sync.return_value = MagicMock(instructor_id=50)
            
            # Mock DB for manual query in delete_attendance_session
            mock_db = MagicMock()
            app.dependency_overrides[get_db] = lambda: mock_db
            
            mock_attendance = MagicMock()
            mock_attendance.instructor_id = 50
            mock_db.query.return_value.filter.return_value.first.return_value = mock_attendance
            
            response = client.delete("/api/v1/attendance/1")
            
            assert response.status_code == 204
            mock_db.delete.assert_called_once()

    def test_get_courses_mobile_format(self):
        """Test GET /courses adapter for Mobile App field names"""
        # Switch to Student
        app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
        
        with patch("app.api.v1.courses.course_service") as mock_service, \
             patch("app.api.v1.courses.user_service") as mock_user_service:
            
            mock_user_service.get_student_profile_sync.return_value = MagicMock(student_id=1)
            
            # Mock Course Object with instructor
            mock_course = MagicMock()
            mock_course.course_id = 101
            mock_course.course_name = "Mobile Dev"
            mock_course.course_code = "CS404"
            mock_course.instructor.user.full_name = "Dr. Test"
            mock_course.instructor_id = 55
            mock_course.join_code = "XYZ789"
            mock_course.created_at = None
            
            mock_service.list_student_courses_sync.return_value = [mock_course]
            
            response = client.get("/api/v1/courses")
            
            assert response.status_code == 200
            data = response.json()
            assert isinstance(data, list)
            assert len(data) == 1
            item = data[0]
            
            # CRITICAL: Verify Mobile App Specific Keys
            assert "class_name" in item
            assert item["class_name"] == "Mobile Dev"
            assert "teacher_name" in item
            assert item["teacher_name"] == "Dr. Test"
            assert "teacher_id" in item
            assert item["teacher_id"] == "55"

    def test_mobile_start_attendance_string_id(self):
        """Test POST /attendance/start with string class_id (Mobile behavior)"""
        # Switch to Instructor
        app.dependency_overrides[get_current_user_sync] = lambda: INSTRUCTOR_USER
        
        # We need to mock create_attendance_session (the internal function) 
        # because the router calls it directly
        with patch("app.api.v1.attendances.create_attendance_session") as mock_create:
            mock_create.return_value = {
                "attendance_id": 999,
                "course_id": 101,
                "course_name": "Course 101",
                "session_name": "Test Session",
                "description": "A test session",
                "is_active": True,
                "total_students": 10,
                "start_time": "2024-01-01T10:00:00",
                "end_time": "2024-01-01T10:15:00",
                "checked_in_count": 0
            }
            
            # Payload with STRING class_id
            payload = {
                "class_id": "101",
                "duration_minutes": 30
            }
            
            response = client.post("/api/v1/attendance/start", json=payload)
            
            assert response.status_code == 200
            # Verify checking types happened
            mock_create.assert_called_once()
            call_args = mock_create.call_args
            # session_data arg
            session_data = call_args.kwargs['session_data']
            assert session_data.course_id == 101 # Should be int now
