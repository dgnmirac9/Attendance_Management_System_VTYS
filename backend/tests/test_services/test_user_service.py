"""Tests for user service"""

import pytest
from unittest.mock import Mock, MagicMock, patch
from sqlalchemy.orm import Session

from app.services.user_service import UserService, user_service
from app.schemas.user import UserCreate, UserUpdate
from app.models.user import User, Student, Instructor
from app.core.exceptions import AppException


# Sample user data
SAMPLE_STUDENT_DATA = UserCreate(
    email="student@test.com",
    password="Test123!",
    full_name="Test Student",
    role="student",
    student_number="2024001",
    department="Computer Science"
)

SAMPLE_INSTRUCTOR_DATA = UserCreate(
    email="instructor@test.com",
    password="Test123!",
    full_name="Test Instructor",
    role="instructor",
    instructor_number="INS001",
    department="Computer Science",
    title="Professor"
)


class TestUserService:
    """Tests for UserService class"""
    
    def test_initialization(self):
        """Test service initialization"""
        service = UserService()
        assert service is not None
    
    @patch('app.services.user_service.auth_service.hash_password')
    def test_create_student_success(self, mock_hash):
        """Test successful student creation"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no existing user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        # Mock password hashing
        mock_hash.return_value = "hashed_password"
        
        # Create user
        result = service.create_user_sync(mock_db, SAMPLE_STUDENT_DATA)
        
        # Verify database operations
        assert mock_db.add.call_count == 2  # User + Student
        assert mock_db.commit.called
        assert mock_db.flush.called
    
    @patch('app.services.user_service.auth_service.hash_password')
    def test_create_instructor_success(self, mock_hash):
        """Test successful instructor creation"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no existing user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        # Mock password hashing
        mock_hash.return_value = "hashed_password"
        
        # Create user
        result = service.create_user_sync(mock_db, SAMPLE_INSTRUCTOR_DATA)
        
        # Verify database operations
        assert mock_db.add.call_count == 2  # User + Instructor
        assert mock_db.commit.called
        assert mock_db.flush.called
    
    def test_create_user_duplicate_email(self):
        """Test user creation with duplicate email"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock existing user
        existing_user = Mock(spec=User)
        existing_user.email = SAMPLE_STUDENT_DATA.email
        mock_db.query.return_value.filter.return_value.first.return_value = existing_user
        
        # Attempt to create user
        with pytest.raises(AppException) as exc_info:
            service.create_user_sync(mock_db, SAMPLE_STUDENT_DATA)
        
        assert exc_info.value.status_code == 409
        assert "Email already registered" in exc_info.value.message
    
    def test_create_student_duplicate_number(self):
        """Test student creation with duplicate student number"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no existing user but existing student number
        mock_query = mock_db.query.return_value.filter.return_value
        mock_query.first.side_effect = [None, Mock(spec=Student)]  # First for User, second for Student
        
        # Attempt to create student
        with pytest.raises(AppException) as exc_info:
            service.create_user_sync(mock_db, SAMPLE_STUDENT_DATA)
        
        assert exc_info.value.status_code == 409
        assert "Student number already registered" in exc_info.value.message
    
    def test_get_user_by_id_found(self):
        """Test getting user by ID when found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock user
        mock_user = Mock(spec=User)
        mock_user.user_id = 1
        mock_user.email = "test@test.com"
        mock_db.query.return_value.filter.return_value.first.return_value = mock_user
        
        result = service.get_user_by_id_sync(mock_db, 1)
        
        assert result == mock_user
        assert result.user_id == 1
    
    def test_get_user_by_id_not_found(self):
        """Test getting user by ID when not found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        result = service.get_user_by_id_sync(mock_db, 999)
        
        assert result is None
    
    def test_get_user_by_email_found(self):
        """Test getting user by email when found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock user
        mock_user = Mock(spec=User)
        mock_user.email = "test@test.com"
        mock_db.query.return_value.filter.return_value.first.return_value = mock_user
        
        result = service.get_user_by_email_sync(mock_db, "test@test.com")
        
        assert result == mock_user
        assert result.email == "test@test.com"
    
    def test_get_user_by_email_not_found(self):
        """Test getting user by email when not found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        result = service.get_user_by_email_sync(mock_db, "notfound@test.com")
        
        assert result is None
    
    @patch('app.services.user_service.auth_service.hash_password')
    def test_update_user_success(self, mock_hash):
        """Test successful user update"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock existing user
        mock_user = Mock(spec=User)
        mock_user.user_id = 1
        mock_user.email = "old@test.com"
        mock_user.full_name = "Old Name"
        mock_user.role = "student"
        
        # Mock student
        mock_student = Mock(spec=Student)
        mock_student.department = "Old Department"
        
        # Setup query mocks
        mock_db.query.return_value.filter.return_value.first.side_effect = [
            mock_user,  # get_user_by_id
            None,       # get_user_by_email (no duplicate)
            mock_student  # get student
        ]
        
        # Mock password hashing
        mock_hash.return_value = "new_hashed_password"
        
        # Update data
        update_data = UserUpdate(
            full_name="New Name",
            email="new@test.com",
            password="NewPass123!",
            department="New Department"
        )
        
        result = service.update_user_sync(mock_db, 1, update_data)
        
        assert mock_db.commit.called
        assert mock_db.refresh.called
    
    def test_update_user_not_found(self):
        """Test updating non-existent user"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        update_data = UserUpdate(full_name="New Name")
        
        with pytest.raises(AppException) as exc_info:
            service.update_user_sync(mock_db, 999, update_data)
        
        assert exc_info.value.status_code == 404
        assert "User not found" in exc_info.value.message
    
    def test_update_user_duplicate_email(self):
        """Test updating user with duplicate email"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock existing user
        mock_user = Mock(spec=User)
        mock_user.user_id = 1
        mock_user.email = "old@test.com"
        
        # Mock another user with target email
        mock_existing = Mock(spec=User)
        mock_existing.user_id = 2
        mock_existing.email = "taken@test.com"
        
        mock_db.query.return_value.filter.return_value.first.side_effect = [
            mock_user,      # get_user_by_id
            mock_existing   # get_user_by_email (duplicate found)
        ]
        
        update_data = UserUpdate(email="taken@test.com")
        
        with pytest.raises(AppException) as exc_info:
            service.update_user_sync(mock_db, 1, update_data)
        
        assert exc_info.value.status_code == 409
        assert "Email already registered" in exc_info.value.message
    
    def test_get_student_profile_found(self):
        """Test getting student profile when found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock student
        mock_student = Mock(spec=Student)
        mock_student.student_id = 1
        mock_student.user_id = 1
        mock_db.query.return_value.filter.return_value.first.return_value = mock_student
        
        result = service.get_student_profile_sync(mock_db, 1)
        
        assert result == mock_student
        assert result.user_id == 1
    
    def test_get_student_profile_not_found(self):
        """Test getting student profile when not found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no student
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        result = service.get_student_profile_sync(mock_db, 999)
        
        assert result is None
    
    def test_get_instructor_profile_found(self):
        """Test getting instructor profile when found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock instructor
        mock_instructor = Mock(spec=Instructor)
        mock_instructor.instructor_id = 1
        mock_instructor.user_id = 1
        mock_db.query.return_value.filter.return_value.first.return_value = mock_instructor
        
        result = service.get_instructor_profile_sync(mock_db, 1)
        
        assert result == mock_instructor
        assert result.user_id == 1
    
    def test_get_instructor_profile_not_found(self):
        """Test getting instructor profile when not found"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no instructor
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        result = service.get_instructor_profile_sync(mock_db, 999)
        
        assert result is None
    
    def test_delete_user_success(self):
        """Test successful user deletion"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock existing user
        mock_user = Mock(spec=User)
        mock_user.user_id = 1
        mock_db.query.return_value.filter.return_value.first.return_value = mock_user
        
        result = service.delete_user_sync(mock_db, 1)
        
        assert result is True
        assert mock_db.delete.called
        assert mock_db.commit.called
    
    def test_delete_user_not_found(self):
        """Test deleting non-existent user"""
        service = UserService()
        mock_db = MagicMock(spec=Session)
        
        # Mock no user
        mock_db.query.return_value.filter.return_value.first.return_value = None
        
        result = service.delete_user_sync(mock_db, 999)
        
        assert result is False
        assert not mock_db.delete.called


class TestUserServiceSingleton:
    """Tests for user_service singleton"""
    
    def test_singleton_instance(self):
        """Test that user_service is properly initialized"""
        assert user_service is not None
        assert isinstance(user_service, UserService)
