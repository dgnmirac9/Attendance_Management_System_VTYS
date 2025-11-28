"""Tests for authentication endpoints"""

import pytest
from fastapi import status


class TestRegisterEndpoint:
    """Tests for /api/v1/auth/register endpoint"""
    
    def test_register_student_success(self, client, sample_user_data):
        """Test successful student registration"""
        response = client.post("/api/v1/auth/register", json=sample_user_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        
        # Check response structure
        assert "access_token" in data
        assert "token_type" in data
        assert data["token_type"] == "bearer"
        assert "user" in data
        
        # Check user data
        user = data["user"]
        assert user["email"] == sample_user_data["email"].lower()
        assert user["full_name"] == sample_user_data["full_name"]
        assert user["role"] == "student"
        assert "user_id" in user
        assert "created_at" in user
    
    def test_register_instructor_success(self, client, sample_instructor_data):
        """Test successful instructor registration"""
        response = client.post("/api/v1/auth/register", json=sample_instructor_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        
        # Check response structure
        assert "access_token" in data
        assert "user" in data
        
        # Check user data
        user = data["user"]
        assert user["email"] == sample_instructor_data["email"].lower()
        assert user["role"] == "instructor"
    
    def test_register_duplicate_email(self, client, sample_user_data):
        """Test registration with duplicate email"""
        # Register first user
        response1 = client.post("/api/v1/auth/register", json=sample_user_data)
        assert response1.status_code == status.HTTP_201_CREATED
        
        # Try to register with same email
        response2 = client.post("/api/v1/auth/register", json=sample_user_data)
        assert response2.status_code == status.HTTP_409_CONFLICT
        assert "already registered" in response2.json()["detail"].lower()
    
    def test_register_duplicate_student_number(self, client, sample_user_data):
        """Test registration with duplicate student number"""
        # Register first student
        response1 = client.post("/api/v1/auth/register", json=sample_user_data)
        assert response1.status_code == status.HTTP_201_CREATED
        
        # Try to register with same student number but different email
        duplicate_data = sample_user_data.copy()
        duplicate_data["email"] = "different@example.com"
        
        response2 = client.post("/api/v1/auth/register", json=duplicate_data)
        assert response2.status_code == status.HTTP_409_CONFLICT
    
    def test_register_invalid_email(self, client, sample_user_data):
        """Test registration with invalid email"""
        invalid_data = sample_user_data.copy()
        invalid_data["email"] = "invalid-email"
        
        response = client.post("/api/v1/auth/register", json=invalid_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_register_weak_password(self, client, sample_user_data):
        """Test registration with weak password"""
        weak_data = sample_user_data.copy()
        weak_data["password"] = "weak"
        
        response = client.post("/api/v1/auth/register", json=weak_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_register_student_missing_required_fields(self, client):
        """Test student registration with missing required fields"""
        incomplete_data = {
            "email": "student@example.com",
            "password": "ValidPass123!",
            "full_name": "Test Student",
            "role": "student"
            # Missing: student_number, department, class_level, enrollment_year
        }
        
        response = client.post("/api/v1/auth/register", json=incomplete_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_register_invalid_role(self, client, sample_user_data):
        """Test registration with invalid role"""
        invalid_data = sample_user_data.copy()
        invalid_data["role"] = "admin"
        
        response = client.post("/api/v1/auth/register", json=invalid_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestLoginEndpoint:
    """Tests for /api/v1/auth/login endpoint"""
    
    def test_login_success(self, client, sample_user_data):
        """Test successful login"""
        # Register user first
        register_response = client.post("/api/v1/auth/register", json=sample_user_data)
        assert register_response.status_code == status.HTTP_201_CREATED
        
        # Login
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Check response structure
        assert "access_token" in data
        assert "token_type" in data
        assert data["token_type"] == "bearer"
        assert "user" in data
        
        # Check user data
        user = data["user"]
        assert user["email"] == sample_user_data["email"].lower()
        assert user["role"] == sample_user_data["role"]
    
    def test_login_case_insensitive_email(self, client, sample_user_data):
        """Test login with different email case"""
        # Register user
        client.post("/api/v1/auth/register", json=sample_user_data)
        
        # Login with uppercase email
        login_data = {
            "email": sample_user_data["email"].upper(),
            "password": sample_user_data["password"]
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
    
    def test_login_wrong_password(self, client, sample_user_data):
        """Test login with wrong password"""
        # Register user
        client.post("/api/v1/auth/register", json=sample_user_data)
        
        # Login with wrong password
        login_data = {
            "email": sample_user_data["email"],
            "password": "WrongPassword123!"
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Invalid email or password" in response.json()["detail"]
    
    def test_login_nonexistent_user(self, client):
        """Test login with non-existent user"""
        login_data = {
            "email": "nonexistent@example.com",
            "password": "SomePassword123!"
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_login_missing_fields(self, client):
        """Test login with missing fields"""
        # Missing password
        response = client.post("/api/v1/auth/login", json={"email": "test@example.com"})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Missing email
        response = client.post("/api/v1/auth/login", json={"password": "password"})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


class TestLogoutEndpoint:
    """Tests for /api/v1/auth/logout endpoint"""
    
    def test_logout_success(self, client, sample_user_data):
        """Test successful logout"""
        # Register and login
        register_response = client.post("/api/v1/auth/register", json=sample_user_data)
        token = register_response.json()["access_token"]
        
        # Logout
        response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "message" in data
        assert "successfully" in data["message"].lower()
    
    def test_logout_without_token(self, client):
        """Test logout without authentication token"""
        response = client.post("/api/v1/auth/logout")
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_logout_invalid_token(self, client):
        """Test logout with invalid token"""
        response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": "Bearer invalid_token"}
        )
        
        # Should fail - token not found in database or invalid format
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_404_NOT_FOUND, status.HTTP_500_INTERNAL_SERVER_ERROR]
    
    def test_logout_twice(self, client, sample_user_data):
        """Test logout with same token twice"""
        # Register and login
        register_response = client.post("/api/v1/auth/register", json=sample_user_data)
        token = register_response.json()["access_token"]
        
        # First logout
        response1 = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response1.status_code == status.HTTP_200_OK
        
        # Second logout with same token
        response2 = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response2.status_code == status.HTTP_404_NOT_FOUND


class TestAuthenticationFlow:
    """Integration tests for complete authentication flow"""
    
    def test_complete_student_flow(self, client, sample_user_data):
        """Test complete flow: register -> login -> logout"""
        # Register
        register_response = client.post("/api/v1/auth/register", json=sample_user_data)
        assert register_response.status_code == status.HTTP_201_CREATED
        register_token = register_response.json()["access_token"]
        
        # Login
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        login_response = client.post("/api/v1/auth/login", json=login_data)
        assert login_response.status_code == status.HTTP_200_OK
        login_token = login_response.json()["access_token"]
        
        # Both tokens should be valid (tokens may be same if generated at same second)
        assert register_token is not None
        assert login_token is not None
        
        # Logout with login token
        logout_response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {login_token}"}
        )
        assert logout_response.status_code == status.HTTP_200_OK
    
    def test_complete_instructor_flow(self, client, sample_instructor_data):
        """Test complete flow for instructor"""
        # Register
        register_response = client.post("/api/v1/auth/register", json=sample_instructor_data)
        assert register_response.status_code == status.HTTP_201_CREATED
        
        # Login
        login_data = {
            "email": sample_instructor_data["email"],
            "password": sample_instructor_data["password"]
        }
        login_response = client.post("/api/v1/auth/login", json=login_data)
        assert login_response.status_code == status.HTTP_200_OK
        
        # Logout
        token = login_response.json()["access_token"]
        logout_response = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert logout_response.status_code == status.HTTP_200_OK
    
    def test_multiple_users(self, client, sample_user_data, sample_instructor_data):
        """Test multiple users can register and login independently"""
        # Register student
        student_response = client.post("/api/v1/auth/register", json=sample_user_data)
        assert student_response.status_code == status.HTTP_201_CREATED
        
        # Register instructor
        instructor_response = client.post("/api/v1/auth/register", json=sample_instructor_data)
        assert instructor_response.status_code == status.HTTP_201_CREATED
        
        # Both should have different tokens
        student_token = student_response.json()["access_token"]
        instructor_token = instructor_response.json()["access_token"]
        assert student_token != instructor_token
        
        # Both can logout independently
        logout1 = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {student_token}"}
        )
        assert logout1.status_code == status.HTTP_200_OK
        
        logout2 = client.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {instructor_token}"}
        )
        assert logout2.status_code == status.HTTP_200_OK
