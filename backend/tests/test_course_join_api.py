
import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User
from app.core.exceptions import AuthorizationError

# DISABLE STARTUP EVENTS
app.router.on_startup = []

# DISABLE RATE LIMITER
if hasattr(app.state, "limiter"):
    app.state.limiter.enabled = False

client = TestClient(app, raise_server_exceptions=True)

def mock_instructor_user():
    return User(user_id=1, email="inst@test.com", role="instructor")

def mock_student_user():
    return User(user_id=2, email="student@test.com", role="student")

def mock_db_session():
    return MagicMock()

def test_join_course_api_flow():
    """
    Integration test flow with Mocked DB (Unit-Integration hybrid)
    We mock the SERVICE layer to test the API layer + Exception Handling.
    This avoids complex DB setup in tests.
    """
    from app.api.deps import get_current_user_sync, get_db

    # Override Auth
    app.dependency_overrides[get_current_user_sync] = mock_student_user
    # Override DB to mock
    app.dependency_overrides[get_db] = mock_db_session

    from unittest.mock import patch
    
    # Patch the global service instances in the endpoints file
    with patch("app.api.v1.courses.course_service") as mock_ws, \
         patch("app.api.v1.courses.user_service") as mock_us:
         
        # Mock User Service: Get Student Profile
        mock_profile = MagicMock()
        mock_profile.student_id = 123
        mock_us.get_student_profile_sync.return_value = mock_profile

        # Mock Course Service: Join Course
        # Must return an object with expected attributes
        mock_enrollment = MagicMock()
        mock_enrollment.enrollment_status = "active"
        mock_enrollment.course_id = 99
        mock_ws.join_course_by_code_sync.return_value = mock_enrollment

        # Mock Course Service: Get Course Details (called after join)
        mock_course = MagicMock()
        mock_course.course_id = 99
        mock_course.course_name = "Test Course"  # Concrete string for Pydantic
        mock_ws.get_course_by_id_sync.return_value = mock_course
        
        response = client.post(
            "/api/v1/courses/join",
            json={"join_code": "TESTCODE"}
        )
        
        # Debugging: Print response if fails
        if response.status_code != 200:
            print(f"DEBUG RESPONSE: {response.json()}")

        assert response.status_code == 200
        data = response.json()
        assert data["enrollment_status"] == "active"

    app.dependency_overrides.clear()

def test_join_course_api_error_handling():
    """Test API correctly maps Service exceptions to JSON"""
    from app.api.deps import get_current_user_sync
    app.dependency_overrides[get_current_user_sync] = mock_student_user
    
    from unittest.mock import patch
    from app.core.exceptions import AppException
    
    with patch("app.api.v1.courses.course_service") as mock_ws, \
         patch("app.api.v1.courses.user_service") as mock_us:
        
        mock_profile = MagicMock()
        mock_profile.student_id = 123
        mock_us.get_student_profile_sync.return_value = mock_profile

        # Mock Service raising 404
        mock_ws.join_course_by_code_sync.side_effect = AppException("Not Found", 404)
        
        response = client.post(
            "/api/v1/courses/join",
            json={"join_code": "INVALID"}
        )
        
        assert response.status_code == 404
        data = response.json()
        assert data["detail"] == "Not Found"
        
    app.dependency_overrides.clear()
