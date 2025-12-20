
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from unittest.mock import MagicMock, patch
import sys

# Mock FaceService to avoid loading heavy ML libraries during tests
# MUST be done before importing app.main which imports services
sys.modules["app.services.face_service"] = MagicMock()

from app.main import app as fastapi_app
from app.api.deps import get_db, get_current_user_sync
from app.models.user import User, Student, Instructor
from app.models.course import Course, CourseEnrollment
from app.models.attendance import Attendance, AttendanceRecord
import app.services.attendance_service # Ensure module is loaded for patching
from datetime import datetime, timedelta

# Create a clean test client
client = TestClient(fastapi_app)

# Mock User Data
STUDENT_USER = User(
    user_id=1,
    email="student@test.com",
    full_name="Test Student",
    role="student",
    password_hash="hashed_secret"
)

INSTRUCTOR_USER = User(
    user_id=2,
    email="instructor@test.com",
    full_name="Test Instructor",
    role="instructor",
    password_hash="hashed_secret"
)

# Mock Profiles
STUDENT_PROFILE = Student(
    user_id=1,
    student_id=10,
    student_number="2021123456"
)

INSTRUCTOR_PROFILE = Instructor(
    user_id=2,
    instructor_id=20,
    instructor_number="INS001"
)

@pytest.fixture
def mock_db_session():
    """Mock database session"""
    mock_db = MagicMock(spec=Session)
    return mock_db

# Override dependencies
def override_get_db():
    return MagicMock(spec=Session)

def override_get_current_student():
    return STUDENT_USER

def override_get_current_instructor():
    return INSTRUCTOR_USER

# We will apply overrides in tests to permit different users

# -----------------------------------------------------------------------------
# STUDENT ENDPOINTS TESTS
# -----------------------------------------------------------------------------

def test_get_student_profile_success(mock_db_session):
    """Test getting student profile"""
    
    # Setup Dependency Overrides
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
    
    # Mock Service Calls
    with patch("app.api.v1.students.user_service") as mock_service:
        # Mock get_student_profile_sync to return our profile
        # Note: The api code accesses profile.student_id etc.
        # We need to make sure the returned object has these attributes.
        # It also accesses `student.face_data_url`
        
        # Configure the mock object
        profile_mock = MagicMock()
        profile_mock.student_id = 10
        profile_mock.user_id = 1
        profile_mock.student_number = "2021123456"
        profile_mock.face_data_url = None # Not registered
        
        mock_service.get_student_profile_sync.return_value = profile_mock
        
        response = client.get("/api/v1/students/me")
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "student@test.com"
        assert data["student_number"] == "2021123456"
        assert data["face_registered"] is False


def test_update_student_profile_success(mock_db_session):
    """Test updating student profile"""
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
    
    with patch("app.api.v1.students.user_service") as mock_service:
        # 1. Update returns the Updated User
        updated_user = MagicMock()
        updated_user.user_id = 1
        updated_user.full_name = "Updated Name"
        updated_user.email = "new@test.com"
        mock_service.update_user_sync.return_value = updated_user
        
        # 2. Then it fetches the Profile again
        profile_mock = MagicMock()
        profile_mock.student_id = 10
        profile_mock.face_data_url = "some_data" # Registered now maybe
        profile_mock.student_number = "2021123456"
        mock_service.get_student_profile_sync.return_value = profile_mock
        
        payload = {
            "full_name": "Updated Name",
            "email": "new@test.com"
        }
        
        response = client.put("/api/v1/students/me", json=payload)
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
        assert data["email"] == "new@test.com"
        assert data["face_registered"] is True


def test_get_student_courses(mock_db_session):
    """Test getting student courses"""
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
    
    # We patch where it is defined because it is imported dynamically inside the function
    with patch("app.services.course_service.course_service") as global_mock_cs, \
         patch("app.api.v1.students.user_service") as mock_user_service:
         
        profile_mock = MagicMock()
        profile_mock.student_id = 10
        mock_user_service.get_student_profile_sync.return_value = profile_mock
        
        c1 = MagicMock()
        c1.course_id = 101
        c1.course_name = "Math 101"
        c1.course_code = "MAT101"
        c1.semester = "Fall"
        c1.year = 2024
        c1.credits = 3
        c1.is_active = True
        c1.instructor.user.full_name = "Dr. Math"
        
        global_mock_cs.list_student_courses_sync.return_value = [c1]
        
        response = client.get("/api/v1/students/me/courses")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["courses"][0]["course_name"] == "Math 101"
        assert data["courses"][0]["instructor_name"] == "Dr. Math"


def test_get_student_attendance_history(mock_db_session):
    """Test getting student attendance history"""
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: STUDENT_USER
    
    
    # Patch the class as it is imported in the module scope (or inside function)
    # Since we added 'from app.services.attendance_service import AttendanceService' inside the function in students.py?
    # No, we added it inside the function? Checking code...
    # We added:
    #     from app.services.attendance_service import AttendanceService
    #     attendance_service = AttendanceService(db)
    # inside the function get_my_attendance_history.
    # So patching 'app.services.attendance_service.AttendanceService' should work IF the module is loadable.
    # BUT 'app.api.v1.students.AttendanceService' won't exist if it's imported inside a function.
    # So we MUST patch 'app.services.attendance_service.AttendanceService'
    
    with patch("app.api.v1.students.user_service") as mock_user_service, \
         patch("app.services.attendance_service.AttendanceService") as MockAttendanceService:
        
        # Mock profile
        profile_mock = MagicMock()
        profile_mock.student_id = 10
        mock_user_service.get_student_profile_sync.return_value = profile_mock
        
        # Mock Attendance Service Instance
        mock_service_instance = MockAttendanceService.return_value
        
        # Return dummy history
        history_record = {
            "record_id": 999,
            "course_id": 101,
            "course_name": "Math 101",
            "session_name": "Week 1",
            "check_in_time": "2024-01-01T10:00:00",
            "similarity_score": 0.95,
            "is_verified": True
        }
        mock_service_instance.get_student_attendance_history.return_value = [history_record]
        
        response = client.get("/api/v1/students/me/attendance-history")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 1
        assert data[0]["course_name"] == "Math 101"


# -----------------------------------------------------------------------------
# INSTRUCTOR ENDPOINTS TESTS
# -----------------------------------------------------------------------------

def test_get_instructor_profile(mock_db_session):
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: INSTRUCTOR_USER
    
    with patch("app.api.v1.instructors.user_service") as mock_service:
        profile_mock = MagicMock()
        profile_mock.instructor_id = 20
        profile_mock.user_id = 2
        profile_mock.instructor_number = "INS001"
        # Mock getattr behavior if possible, or just standard field access
        # The API uses getattr(instructor, 'instructor_number', None)
        
        mock_service.get_instructor_profile_sync.return_value = profile_mock
        
        response = client.get("/api/v1/instructors/me")
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "instructor@test.com"
        assert data["instructor_number"] == "INS001"

def test_get_instructor_courses(mock_db_session):
    fastapi_app.dependency_overrides[get_db] = lambda: mock_db_session
    fastapi_app.dependency_overrides[get_current_user_sync] = lambda: INSTRUCTOR_USER
    
    with patch("app.api.v1.instructors.user_service") as mock_user_service, \
         patch("app.services.course_service.course_service") as mock_course_service:
         
         profile_mock = MagicMock()
         profile_mock.instructor_id = 20
         mock_user_service.get_instructor_profile_sync.return_value = profile_mock
         
         c1 = MagicMock()
         c1.course_id = 500
         c1.course_name = "Advanced AI"
         c1.created_at = datetime.now()
         
         mock_course_service.list_instructor_courses_sync.return_value = [c1]
         # API calls course_service._get_enrollment_count_sync for each course
         mock_course_service._get_enrollment_count_sync.return_value = 25
         
         response = client.get("/api/v1/instructors/me/courses")
         assert response.status_code == 200
         data = response.json()
         assert data["total"] == 1
         assert data["courses"][0]["course_name"] == "Advanced AI"
         assert data["courses"][0]["enrolled_students"] == 25
