"""FastAPI application entry point"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.utils import get_openapi
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.core.exceptions import AppException

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

# API Description with authentication flow documentation
api_description = """
# C-Lens Face Recognition Attendance System API

A comprehensive backend system for managing educational courses with face recognition-based attendance tracking.

## Features

* **User Management**: Student and instructor registration with role-based access
* **Face Recognition**: DeepFace-powered facial recognition for secure attendance
* **Course Management**: Create courses, manage enrollments with join codes
* **Attendance Tracking**: Real-time face-based attendance with accuracy metrics
* **Assignment Management**: Create, submit, and grade assignments
* **Content Sharing**: Announcements, notes, and surveys for course communication
* **Secure Authentication**: JWT-based authentication with token management

## Authentication Flow

### 1. Registration
Register a new user account (student or instructor):
```
POST /api/v1/auth/register
```

**Student Registration Example:**
```json
{
  "email": "student@university.edu",
  "password": "SecurePass123",
  "full_name": "John Doe",
  "role": "student",
  "student_number": "2024001",
  "department": "Computer Engineering",
  "class_level": 2,
  "enrollment_year": 2024
}
```

**Instructor Registration Example:**
```json
{
  "email": "instructor@university.edu",
  "password": "SecurePass123",
  "full_name": "Dr. Jane Smith",
  "role": "instructor",
  "title": "Prof. Dr.",
  "office_info": "A-101"
}
```

### 2. Login
Authenticate and receive an access token:
```
POST /api/v1/auth/login
```

**Request:**
```json
{
  "email": "student@university.edu",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "student@university.edu",
    "full_name": "John Doe",
    "role": "student",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### 3. Using Protected Endpoints
Include the access token in the Authorization header for all protected endpoints:
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

### 4. Logout
Revoke the access token:
```
POST /api/v1/auth/logout
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

## Rate Limiting

All endpoints are rate-limited to 100 requests per minute per IP address to prevent abuse.

## Error Responses

The API uses standard HTTP status codes:

* **200 OK**: Request succeeded
* **201 Created**: Resource created successfully
* **400 Bad Request**: Invalid request data
* **401 Unauthorized**: Authentication required or failed
* **403 Forbidden**: Insufficient permissions
* **404 Not Found**: Resource not found
* **409 Conflict**: Resource conflict (e.g., duplicate email)
* **422 Unprocessable Entity**: Validation error
* **429 Too Many Requests**: Rate limit exceeded
* **500 Internal Server Error**: Server error

**Error Response Format:**
```json
{
  "detail": "Error message description",
  "error_type": "ExceptionClassName"
}
```

## Security

* Passwords are hashed using bcrypt
* JWT tokens expire after 24 hours
* Face embeddings are encrypted at rest
* HTTPS required in production
* SQL injection protection via parameterized queries
* CORS configured for allowed origins only

## Database

PostgreSQL 15+ with the following main entities:
* Users (students and instructors)
* Courses and enrollments
* Attendance sessions and records
* Assignments and submissions
* Announcements and shared notes
* Surveys and responses

## Face Recognition

Powered by DeepFace library with support for multiple models:
* Face detection and embedding extraction
* Similarity comparison with configurable thresholds
* Duplicate face detection
* Encrypted storage of face embeddings
"""

# Create FastAPI app with enhanced documentation
app = FastAPI(
    title="C-Lens API",
    description=api_description,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    contact={
        "name": "C-Lens Development Team",
        "email": "support@clens.edu",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    openapi_tags=[
        {
            "name": "Authentication",
            "description": "User registration, login, and logout operations. All users must authenticate to access protected endpoints.",
        },
        {
            "name": "Face Recognition",
            "description": "Face registration and verification endpoints using DeepFace. Used for attendance tracking and identity verification.",
        },
        {
            "name": "Students",
            "description": "Student profile management and academic information retrieval.",
        },
        {
            "name": "Instructors",
            "description": "Instructor profile management and course oversight.",
        },
        {
            "name": "Courses",
            "description": "Course creation, enrollment management, and course information.",
        },
        {
            "name": "Attendances",
            "description": "Attendance session management and face-based check-in operations.",
        },
        {
            "name": "Assignments",
            "description": "Assignment creation, submission, and grading operations.",
        },
        {
            "name": "Announcements",
            "description": "Course announcements, notes, and resource sharing.",
        },
        {
            "name": "Notes",
            "description": "Student-to-student note sharing within courses.",
        },
        {
            "name": "Surveys",
            "description": "Course surveys and feedback collection.",
        },
        {
            "name": "Debug",
            "description": "**Development Only** - Database inspection and debugging tools. View tables, data, and statistics.",
        },
    ],
)

# Add rate limiter to app state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    """Handle custom application exceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message, "error_type": exc.__class__.__name__},
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle unexpected exceptions"""
    # Log the error here
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# Startup event - Create tables if they don't exist
@app.on_event("startup")
async def startup_event():
    """Create database tables on startup"""
    from app.database import engine, Base
    from app.models import user, course, attendance, assignment, content, token
    
    print("🔧 Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created/verified")


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT,
    }


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "C-Lens API",
        "version": "1.0.0",
        "docs": "/docs",
    }


# Custom OpenAPI schema with enhanced security documentation
def custom_openapi():
    """Generate custom OpenAPI schema with enhanced documentation"""
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=app.openapi_tags,
        contact=app.contact,
        license_info=app.license_info,
    )
    
    # Add security schemes
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "Enter your JWT token obtained from /api/v1/auth/login endpoint. Format: Bearer <token>",
        }
    }
    
    # Add security to all protected endpoints (except auth endpoints and health/root)
    for path, path_item in openapi_schema["paths"].items():
        # Skip authentication endpoints, health check, and root
        if "/auth/" in path or path in ["/health", "/", "/docs", "/redoc", "/openapi.json"]:
            continue
        
        # Add security requirement to all methods
        for method_name, method in path_item.items():
            # Skip non-method items (like parameters, servers, etc.)
            if method_name not in ["get", "post", "put", "delete", "patch", "options", "head"]:
                continue
            
            if isinstance(method, dict):
                # Force add security to this endpoint
                method["security"] = [{"BearerAuth": []}]
    
    # Add example responses
    openapi_schema["components"]["examples"] = {
        "StudentRegistration": {
            "summary": "Student Registration",
            "value": {
                "email": "student@university.edu",
                "password": "SecurePass123",
                "full_name": "John Doe",
                "role": "student",
                "student_number": "2024001",
                "department": "Computer Engineering",
                "class_level": 2,
                "enrollment_year": 2024
            }
        },
        "InstructorRegistration": {
            "summary": "Instructor Registration",
            "value": {
                "email": "instructor@university.edu",
                "password": "SecurePass123",
                "full_name": "Dr. Jane Smith",
                "role": "instructor",
                "title": "Prof. Dr.",
                "office_info": "A-101"
            }
        },
        "LoginRequest": {
            "summary": "Login Request",
            "value": {
                "email": "student@university.edu",
                "password": "SecurePass123"
            }
        },
        "TokenResponse": {
            "summary": "Successful Authentication",
            "value": {
                "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                "token_type": "bearer",
                "user": {
                    "user_id": 1,
                    "email": "student@university.edu",
                    "full_name": "John Doe",
                    "role": "student",
                    "created_at": "2024-01-01T00:00:00Z"
                }
            }
        },
        "ErrorResponse": {
            "summary": "Error Response",
            "value": {
                "detail": "Invalid credentials",
                "error_type": "AuthenticationError"
            }
        },
        "ValidationError": {
            "summary": "Validation Error",
            "value": {
                "detail": [
                    {
                        "loc": ["body", "email"],
                        "msg": "value is not a valid email address",
                        "type": "value_error.email"
                    }
                ]
            }
        }
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi


# Include API routers
from app.api.v1 import auth, debug

print(f"🔍 Importing routers...")
print(f"  - Auth router: {len(auth.router.routes)} routes")
print(f"  - Debug router: {len(debug.router.routes)} routes")

# Try to import face router
try:
    from app.api.v1 import face
    print(f"  - Face router: {len(face.router.routes)} routes")
    FACE_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Face router import failed: {e}")
    face = None
    FACE_ROUTER_AVAILABLE = False

# Try to import students router
try:
    from app.api.v1 import students
    print(f"  - Students router: {len(students.router.routes)} routes")
    STUDENTS_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Students router import failed: {e}")
    students = None
    STUDENTS_ROUTER_AVAILABLE = False

# Try to import instructors router
try:
    from app.api.v1 import instructors
    print(f"  - Instructors router: {len(instructors.router.routes)} routes")
    INSTRUCTORS_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Instructors router import failed: {e}")
    instructors = None
    INSTRUCTORS_ROUTER_AVAILABLE = False

# Try to import test_auth router
try:
    from app.api.v1 import test_auth
    print(f"  - Test Auth router: {len(test_auth.router.routes)} routes")
    TEST_AUTH_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Test Auth router import failed: {e}")
    test_auth = None
    TEST_AUTH_ROUTER_AVAILABLE = False

# Try to import courses router
try:
    from app.api.v1 import courses
    print(f"  - Courses router: {len(courses.router.routes)} routes")
    COURSES_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Courses router import failed: {e}")
    courses = None
    COURSES_ROUTER_AVAILABLE = False

# Try to import attendances router
try:
    from app.api.v1 import attendances
    print(f"  - Attendances router: {len(attendances.router.routes)} routes")
    ATTENDANCES_ROUTER_AVAILABLE = True
except Exception as e:
    print(f"  ⚠️  Attendances router import failed: {e}")
    attendances = None
    ATTENDANCES_ROUTER_AVAILABLE = False

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])

if FACE_ROUTER_AVAILABLE and face:
    app.include_router(face.router, prefix="/api/v1/face", tags=["Face Recognition"])
    print(f"✅ Face router included!")
else:
    print(f"⚠️  Face router NOT included - face recognition features disabled")

if STUDENTS_ROUTER_AVAILABLE and students:
    app.include_router(students.router, prefix="/api/v1/students", tags=["Students"])
    print(f"✅ Students router included!")
else:
    print(f"⚠️  Students router NOT included")

if INSTRUCTORS_ROUTER_AVAILABLE and instructors:
    app.include_router(instructors.router, prefix="/api/v1/instructors", tags=["Instructors"])
    print(f"✅ Instructors router included!")
else:
    print(f"⚠️  Instructors router NOT included")

if TEST_AUTH_ROUTER_AVAILABLE and test_auth:
    app.include_router(test_auth.router, prefix="/api/v1/test", tags=["🧪 Test Authentication"])
    print(f"✅ Test Auth router included!")
else:
    print(f"⚠️  Test Auth router NOT included")

if COURSES_ROUTER_AVAILABLE and courses:
    app.include_router(courses.router, prefix="/api/v1/courses", tags=["Courses"])
    print(f"✅ Courses router included!")
else:
    print(f"⚠️  Courses router NOT included")

if ATTENDANCES_ROUTER_AVAILABLE and attendances:
    app.include_router(attendances.router, prefix="/api/v1/attendances", tags=["Attendances"])
    print(f"✅ Attendances router included!")
else:
    print(f"⚠️  Attendances router NOT included")

print(f"✅ Routers included successfully!")
print(f"  - Total app routes: {len(app.routes)}")

# Debug endpoints (development only)
if settings.ENVIRONMENT == "development":
    app.include_router(debug.router, prefix="/api/v1/debug", tags=["Debug"])

# Additional routers will be added in later tasks
# from app.api.v1 import users, courses, attendances, assignments
# app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
# app.include_router(courses.router, prefix="/api/v1/courses", tags=["Courses"])
# app.include_router(attendances.router, prefix="/api/v1/attendances", tags=["Attendances"])
# app.include_router(assignments.router, prefix="/api/v1/assignments", tags=["Assignments"])
