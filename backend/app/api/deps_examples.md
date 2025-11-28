# API Dependencies Usage Examples

This document demonstrates how to use the authentication and authorization dependencies defined in `app/api/deps.py`.

## Available Dependencies

### 1. `get_current_user`
Returns the currently authenticated user (works for both students and instructors).

### 2. `get_current_student`
Returns the currently authenticated student. Automatically checks that the user has the 'student' role.

### 3. `get_current_instructor`
Returns the currently authenticated instructor. Automatically checks that the user has the 'instructor' role.

### 4. `require_role(allowed_roles)`
Factory function to create a dependency that requires specific roles.

### 5. `get_current_user_optional`
Returns the current user if authenticated, None otherwise. Useful for public endpoints that behave differently for authenticated users.

## Usage Examples

### Example 1: Endpoint accessible by any authenticated user

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile - works for both students and instructors"""
    return {
        "user_id": current_user.user_id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role
    }
```

### Example 2: Student-only endpoint

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_student
from app.models.user import Student

router = APIRouter()

@router.get("/students/me")
async def get_student_profile(student: Student = Depends(get_current_student)):
    """Get current student profile - only accessible by students"""
    return {
        "student_id": student.student_id,
        "student_number": student.student_number,
        "department": student.department,
        "class_level": student.class_level
    }
```

### Example 3: Instructor-only endpoint

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
    """Create a new course - only accessible by instructors"""
    # instructor.instructor_id is available here
    return {"message": "Course created"}
```

### Example 4: Using require_role for flexible access control

```python
from fastapi import APIRouter, Depends
from app.api.deps import require_role
from app.models.user import User

router = APIRouter()

@router.get("/admin-dashboard")
async def admin_dashboard(
    current_user: User = Depends(require_role(['instructor']))
):
    """Admin dashboard - only instructors can access"""
    return {"message": "Welcome to admin dashboard"}

@router.get("/shared-resource")
async def shared_resource(
    current_user: User = Depends(require_role(['student', 'instructor']))
):
    """Resource accessible by both students and instructors"""
    return {"message": "Shared resource"}
```

### Example 5: Optional authentication

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
    """Public endpoint that behaves differently for authenticated users"""
    if current_user:
        return {
            "message": f"Welcome back, {current_user.full_name}!",
            "personalized": True
        }
    else:
        return {
            "message": "Welcome, guest!",
            "personalized": False
        }
```

### Example 6: Combining dependencies

```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_student
from app.database import get_async_db
from app.models.user import Student

router = APIRouter()

@router.get("/students/me/courses")
async def get_student_courses(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_async_db)
):
    """Get courses for current student - combines auth and database dependencies"""
    # Both student and db are available here
    # Query courses using student.student_id
    return {"courses": []}
```

## Error Responses

### 401 Unauthorized
Returned when:
- No token is provided
- Token is invalid or expired
- Token signature is invalid

```json
{
    "detail": "Could not validate credentials"
}
```

### 403 Forbidden
Returned when:
- User doesn't have the required role
- Student tries to access instructor-only endpoint
- Instructor tries to access student-only endpoint

```json
{
    "detail": "User is not a student"
}
```

## Testing with Authentication

### Using curl

```bash
# Login to get token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "student@example.com", "password": "password123"}'

# Use token in subsequent requests
curl -X GET http://localhost:8000/api/v1/students/me \
  -H "Authorization: Bearer <your_token_here>"
```

### Using Python requests

```python
import requests

# Login
response = requests.post(
    "http://localhost:8000/api/v1/auth/login",
    json={"email": "student@example.com", "password": "password123"}
)
token = response.json()["access_token"]

# Use token
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(
    "http://localhost:8000/api/v1/students/me",
    headers=headers
)
```

## Best Practices

1. **Use the most specific dependency**: If an endpoint is student-only, use `get_current_student` instead of `get_current_user` and manually checking the role.

2. **Combine with database session**: Most endpoints will need both authentication and database access.

3. **Handle authorization at the dependency level**: Let the dependencies handle role checking rather than doing it in the endpoint logic.

4. **Use `require_role` for flexibility**: When you need to allow multiple roles, use the `require_role` factory.

5. **Document role requirements**: Always document in the endpoint docstring which roles can access it.

6. **Test with different roles**: Ensure you test endpoints with both authorized and unauthorized users.
