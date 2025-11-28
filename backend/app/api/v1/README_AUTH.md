# Authentication Endpoints Implementation

## Overview
This module implements the authentication endpoints for the C-Lens API, providing user registration, login, and logout functionality.

## Endpoints

### POST /api/v1/auth/register
Registers a new user (student or instructor) in the system.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "John Doe",
  "role": "student",
  "student_number": "2024001",
  "department": "Computer Engineering",
  "class_level": 2,
  "enrollment_year": 2024
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "student",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Features:**
- Email uniqueness validation
- Student number uniqueness validation
- Password strength validation (min 8 chars, must contain letter and number)
- Role-specific field validation
- Automatic password hashing with bcrypt
- JWT token generation and storage

### POST /api/v1/auth/login
Authenticates a user and returns an access token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "student",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Features:**
- Case-insensitive email matching
- Secure password verification
- JWT token generation and storage
- User information in response

### POST /api/v1/auth/logout
Revokes the user's access token.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**Features:**
- Token revocation from database
- Secure token validation

## Requirements Coverage

### Requirement 1.3 - User Registration
✅ **Implemented**: The `/register` endpoint writes user data to PostgreSQL database
- Creates User record with hashed password
- Creates role-specific record (Student or Instructor)
- Validates all required fields
- Handles duplicate email and student number

### Requirement 1.4 - User Login
✅ **Implemented**: The `/login` endpoint reads user data from PostgreSQL database
- Queries user by email
- Verifies password against stored hash
- Returns user information and access token

### Requirement 2.1 - RESTful API Endpoints
✅ **Implemented**: All three authentication endpoints (register, login, logout)
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/logout

### Requirement 2.2 - JSON Response Format
✅ **Implemented**: All endpoints return JSON responses
- Structured response schemas using Pydantic
- Consistent error format
- Proper HTTP status codes

## Security Features

1. **Password Security**
   - Bcrypt hashing with automatic salt
   - Minimum 8 characters
   - Must contain letters and numbers
   - Never stored or logged in plain text

2. **Email Validation**
   - EmailStr validation from Pydantic
   - Case-insensitive storage and matching
   - Uniqueness constraint

3. **Token Management**
   - JWT tokens with expiration
   - Tokens stored in database for revocation
   - Secure token validation

4. **SQL Injection Protection**
   - SQLAlchemy ORM with parameterized queries
   - No raw SQL execution

5. **Error Handling**
   - Custom exception classes
   - Appropriate HTTP status codes
   - No sensitive information in error messages

## Testing

Comprehensive test suite with 20 tests covering:
- Successful registration (student and instructor)
- Duplicate email/student number handling
- Invalid input validation
- Successful login
- Wrong password handling
- Case-insensitive email matching
- Logout functionality
- Token revocation
- Complete authentication flows

All tests passing ✅

## Usage Example

```python
# Register a new student
response = requests.post(
    "http://localhost:8000/api/v1/auth/register",
    json={
        "email": "student@example.com",
        "password": "SecurePass123!",
        "full_name": "Jane Doe",
        "role": "student",
        "student_number": "2024001",
        "department": "Computer Engineering",
        "class_level": 2,
        "enrollment_year": 2024
    }
)
token = response.json()["access_token"]

# Login
response = requests.post(
    "http://localhost:8000/api/v1/auth/login",
    json={
        "email": "student@example.com",
        "password": "SecurePass123!"
    }
)
token = response.json()["access_token"]

# Logout
response = requests.post(
    "http://localhost:8000/api/v1/auth/logout",
    headers={"Authorization": f"Bearer {token}"}
)
```

## Dependencies

- FastAPI: Web framework
- SQLAlchemy: ORM for database operations
- Pydantic: Data validation
- python-jose: JWT token handling
- bcrypt: Password hashing
- app.services.auth_service: Authentication business logic
- app.models.user: User, Student, Instructor models
- app.schemas: Request/response schemas

## Next Steps

The authentication endpoints are complete and tested. Future tasks will add:
- Face recognition endpoints (task 5.2)
- Student endpoints (task 5.3)
- Instructor endpoints (task 5.4)
- Course management endpoints (task 5.5)
- And more...
