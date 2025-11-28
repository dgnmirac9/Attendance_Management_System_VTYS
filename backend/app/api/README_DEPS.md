# API Dependencies Documentation

## Overview

The `app/api/deps.py` module provides authentication and authorization dependencies for FastAPI endpoints. These dependencies handle JWT token validation, user authentication, and role-based access control.

## Implementation Details

### Task: 6.1 JWT authentication dependency oluştur

**Status:** ✅ Completed

**Requirements Addressed:**
- Requirement 2.5: JWT token management and validation
- Requirement 4.3: Role-based access control (student/instructor)

### Components Implemented

#### 1. Core Dependencies

##### `get_current_user` (Async)
- Validates JWT token from Authorization header
- Retrieves user from database
- Returns authenticated User object
- Raises 401 if authentication fails
- **Use for:** Async endpoints that need authentication

##### `get_current_user_sync` (Sync)
- Synchronous version of `get_current_user`
- **Use for:** Sync endpoints or testing

#### 2. Role-Based Dependencies

##### `get_current_student` (Async)
- Validates user has 'student' role
- Returns Student object with academic information
- Raises 403 if user is not a student
- **Use for:** Student-only endpoints

##### `get_current_student_sync` (Sync)
- Synchronous version of `get_current_student`

##### `get_current_instructor` (Async)
- Validates user has 'instructor' role
- Returns Instructor object with professional information
- Raises 403 if user is not an instructor
- **Use for:** Instructor-only endpoints

##### `get_current_instructor_sync` (Sync)
- Synchronous version of `get_current_instructor`

#### 3. Flexible Access Control

##### `require_role(allowed_roles: list[str])`
- Factory function for custom role requirements
- Accepts list of allowed roles
- Returns dependency that validates user role
- **Use for:** Endpoints accessible by multiple roles

##### `get_current_user_optional` (Async)
- Returns User if authenticated, None otherwise
- Does not raise error if no token provided
- **Use for:** Public endpoints with optional authentication

## Usage Examples

### Basic Authentication

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "user_id": current_user.user_id,
        "email": current_user.email,
        "role": current_user.role
    }
```

### Student-Only Endpoint

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_student
from app.models.user import Student

router = APIRouter()

@router.get("/students/me")
async def get_student_info(student: Student = Depends(get_current_student)):
    return {
        "student_id": student.student_id,
        "student_number": student.student_number,
        "department": student.department
    }
```

### Instructor-Only Endpoint

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_instructor
from app.models.user import Instructor

router = APIRouter()

@router.post("/courses")
async def create_course(
    instructor: Instructor = Depends(get_current_instructor),
    course_data: CourseCreate = ...
):
    # Only instructors can create courses
    return {"message": "Course created"}
```

### Multiple Roles

```python
from fastapi import APIRouter, Depends
from app.api.deps import require_role
from app.models.user import User

router = APIRouter()

@router.get("/shared-resource")
async def get_shared_resource(
    current_user: User = Depends(require_role(['student', 'instructor']))
):
    # Both students and instructors can access
    return {"data": "shared resource"}
```

### Optional Authentication

```python
from fastapi import APIRouter, Depends
from typing import Optional
from app.api.deps import get_current_user_optional
from app.models.user import User

router = APIRouter()

@router.get("/public-content")
async def get_public_content(
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    if current_user:
        return {"message": f"Welcome back, {current_user.full_name}!"}
    else:
        return {"message": "Welcome, guest!"}
```

## Error Responses

### 401 Unauthorized
Returned when:
- No Authorization header provided
- Token is invalid or expired
- Token signature verification fails
- User not found in database

```json
{
    "detail": "Could not validate credentials"
}
```

### 403 Forbidden
Returned when:
- User doesn't have required role
- Student tries to access instructor-only endpoint
- Instructor tries to access student-only endpoint

```json
{
    "detail": "User is not a student"
}
```

## Security Features

1. **JWT Token Validation**: All tokens are validated using the SECRET_KEY from configuration
2. **Database Verification**: User existence is verified in database for each request
3. **Role Enforcement**: Role-based access control prevents unauthorized access
4. **Bearer Token Scheme**: Standard HTTP Bearer authentication
5. **Automatic Error Handling**: Consistent error responses for auth failures

## Testing

All dependencies are tested through the authentication endpoint tests:
- `tests/test_auth.py` - 20 tests covering registration, login, logout, and authentication flows

### Test Coverage
- ✅ Token validation
- ✅ User authentication
- ✅ Role-based access control
- ✅ Multiple user sessions
- ✅ Token revocation
- ✅ Invalid token handling

## Integration with Existing Code

The logout endpoint in `app/api/v1/auth.py` has been updated to use the new `get_current_user_sync` dependency:

```python
async def logout(
    current_user: User = Depends(get_current_user_sync),
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Logout user by revoking their access token"""
    # Implementation...
```

## Best Practices

1. **Use Specific Dependencies**: Prefer `get_current_student` over `get_current_user` for student-only endpoints
2. **Async vs Sync**: Use async versions for new endpoints, sync versions for backward compatibility
3. **Combine with Database**: Most endpoints will need both auth and database dependencies
4. **Document Role Requirements**: Always document which roles can access an endpoint
5. **Test Both Roles**: Test endpoints with both authorized and unauthorized users

## Files Created/Modified

### Created:
- ✅ `backend/app/api/deps.py` - Main dependencies module
- ✅ `backend/app/api/deps_examples.md` - Detailed usage examples
- ✅ `backend/app/api/README_DEPS.md` - This documentation

### Modified:
- ✅ `backend/app/api/v1/auth.py` - Updated logout endpoint to use new dependency

## Next Steps

Future endpoints should use these dependencies for authentication and authorization:
- Student endpoints (5.3) - Use `get_current_student`
- Instructor endpoints (5.4) - Use `get_current_instructor`
- Course endpoints (5.5) - Use `require_role` for mixed access
- Attendance endpoints (5.6) - Use role-specific dependencies
- Assignment endpoints (5.7) - Use role-specific dependencies

## References

- Requirements: 2.5 (JWT tokens), 4.3 (Role-based access)
- Design Document: Section on Authentication & Authorization
- FastAPI Security: https://fastapi.tiangolo.com/tutorial/security/
