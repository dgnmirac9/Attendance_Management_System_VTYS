# Pydantic Schemas

This directory contains all Pydantic schemas for request/response validation in the C-Lens backend API.

## Overview

Pydantic schemas provide:
- **Request validation**: Validate incoming API request data
- **Response serialization**: Structure API response data
- **Type safety**: Ensure data types are correct
- **Documentation**: Auto-generate OpenAPI/Swagger docs

## Schema Files

### 1. `user.py`
User-related schemas for authentication and profile management.

**Schemas:**
- `UserBase`: Base user fields (email, full_name)
- `UserCreate`: User registration with role-specific fields
- `UserUpdate`: Update user profile
- `UserResponse`: User data response
- `UserWithDetailsResponse`: User with student/instructor details

**Validation:**
- Email format validation
- Password strength (min 8 chars, letters + numbers)
- Role validation (student/instructor)

### 2. `auth.py`
Authentication and token management schemas.

**Schemas:**
- `LoginRequest`: Login credentials
- `TokenResponse`: JWT token with user data
- `LogoutResponse`: Logout confirmation
- `FaceRegisterRequest`: Face image registration
- `FaceRegisterResponse`: Face registration result
- `FaceVerifyRequest`: Face verification request
- `FaceVerifyResponse`: Face verification result

### 3. `student.py`
Student-specific schemas.

**Schemas:**
- `StudentBase`: Core student fields
- `StudentCreate`: Create student profile
- `StudentUpdate`: Update student profile
- `StudentResponse`: Student data response
- `StudentWithUserResponse`: Student with user details
- `StudentCourseResponse`: Student's course information
- `StudentAttendanceHistoryResponse`: Attendance history

### 4. `instructor.py`
Instructor-specific schemas.

**Schemas:**
- `InstructorBase`: Core instructor fields
- `InstructorCreate`: Create instructor profile
- `InstructorUpdate`: Update instructor profile
- `InstructorResponse`: Instructor data response
- `InstructorWithUserResponse`: Instructor with user details
- `InstructorCourseResponse`: Instructor's course information

### 5. `course.py`
Course management schemas.

**Schemas:**
- `CourseBase`: Core course fields
- `CourseCreate`: Create new course
- `CourseUpdate`: Update course details
- `CourseResponse`: Course data response
- `CourseDetailResponse`: Course with instructor info
- `CourseEnrollRequest`: Enroll with join code
- `CourseEnrollResponse`: Enrollment confirmation
- `CourseStudentResponse`: Student in course
- `CourseStudentsListResponse`: List of course students

### 6. `attendance.py`
Attendance tracking schemas.

**Schemas:**
- `AttendanceCreate`: Create attendance session
- `AttendanceResponse`: Attendance session data
- `AttendanceDetailResponse`: Session with statistics
- `AttendanceCloseResponse`: Close session confirmation
- `AttendanceCheckRequest`: Face-based attendance check
- `AttendanceCheckResponse`: Attendance check result
- `AttendanceRecordResponse`: Individual attendance record
- `AttendanceRecordsListResponse`: List of records

### 7. `assignment.py`
Assignment and submission schemas.

**Schemas:**
- `AssignmentBase`: Core assignment fields
- `AssignmentCreate`: Create assignment
- `AssignmentUpdate`: Update assignment
- `AssignmentResponse`: Assignment data
- `AssignmentDetailResponse`: Assignment with statistics
- `AssignmentSubmit`: Submit assignment
- `AssignmentSubmissionResponse`: Submission data
- `GradeUpdate`: Update grade
- `GradeUpdateResponse`: Grade update confirmation
- `StudentAssignmentResponse`: Student's assignment view
- `StudentAssignmentsListResponse`: List of assignments

### 8. `announcement.py`
Announcement schemas (duyuru, not, kaynak).

**Schemas:**
- `AnnouncementBase`: Core announcement fields
- `AnnouncementCreate`: Create announcement
- `AnnouncementUpdate`: Update announcement
- `AnnouncementResponse`: Announcement data
- `AnnouncementDetailResponse`: Announcement with instructor
- `CourseAnnouncementsResponse`: List of announcements

### 9. `note.py`
Student shared note schemas.

**Schemas:**
- `StudentSharedNoteBase`: Core note fields
- `StudentSharedNoteCreate`: Create shared note
- `StudentSharedNoteUpdate`: Update note
- `StudentSharedNoteResponse`: Note data
- `StudentSharedNoteDetailResponse`: Note with student info
- `CourseSharedNotesResponse`: List of notes
- `DeleteNoteResponse`: Deletion confirmation

### 10. `survey.py`
Survey and response schemas.

**Schemas:**
- `SurveyBase`: Core survey fields
- `SurveyCreate`: Create survey
- `SurveyUpdate`: Update survey
- `SurveyResponse`: Survey data
- `SurveyDetailResponse`: Survey with statistics
- `SurveyRespondRequest`: Submit response
- `SurveyResponseSubmission`: Response confirmation
- `SurveyResponseDetail`: Individual response
- `SurveyResponsesListResponse`: List of responses

## Usage Examples

### Request Validation
```python
from app.schemas.user import UserCreate

@app.post("/api/v1/auth/register")
async def register(user_data: UserCreate):
    # user_data is automatically validated
    # Invalid data returns 422 Unprocessable Entity
    pass
```

### Response Serialization
```python
from app.schemas.user import UserResponse

@app.get("/api/v1/users/me", response_model=UserResponse)
async def get_current_user():
    user = get_user_from_db()
    return user  # Automatically serialized to UserResponse
```

### Nested Schemas
```python
from app.schemas.course import CourseDetailResponse

# Automatically includes instructor info
course_detail = CourseDetailResponse(
    course_id=1,
    course_name="Data Structures",
    instructor=InstructorBasicInfo(...)
)
```

## Validation Features

### Field Validation
- **String length**: `min_length`, `max_length`
- **Numeric ranges**: `ge` (>=), `le` (<=), `gt` (>), `lt` (<)
- **Regex patterns**: `pattern` for string matching
- **Email validation**: `EmailStr` type

### Custom Validators
```python
@field_validator('password')
@classmethod
def validate_password(cls, v: str) -> str:
    # Custom validation logic
    if len(v) < 8:
        raise ValueError('Password too short')
    return v
```

### Optional Fields
```python
class UserUpdate(BaseModel):
    full_name: Optional[str] = None  # Optional field
```

## Configuration

### Pydantic Config
```python
class Config:
    from_attributes = True  # Enable ORM mode for SQLAlchemy models
```

This allows automatic conversion from SQLAlchemy models to Pydantic schemas.

## Best Practices

1. **Separate Request/Response**: Use different schemas for input and output
2. **Reuse Base Schemas**: Create base schemas for common fields
3. **Validate Early**: Let Pydantic validate at the API boundary
4. **Document Fields**: Use `Field()` with descriptions for API docs
5. **Type Hints**: Always use proper type hints for IDE support

## Related Files

- **Models**: `backend/app/models/` - SQLAlchemy database models
- **API Routes**: `backend/app/api/v1/` - API endpoints using these schemas
- **Services**: `backend/app/services/` - Business logic layer

## Requirements

These schemas align with the requirements specified in:
- `.kiro/specs/python-backend-postgresql-migration/requirements.md`
- `.kiro/specs/python-backend-postgresql-migration/design.md`
