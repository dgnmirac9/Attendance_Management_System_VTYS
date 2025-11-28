"""Authentication endpoints for user registration, login, and logout"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.schemas.auth import LoginRequest, TokenResponse, LogoutResponse
from app.schemas.user import UserCreate, UserResponse
from app.schemas.student import StudentResponse
from app.schemas.instructor import InstructorResponse
from app.services.auth_service import auth_service
from app.models.user import User, Student, Instructor
from app.core.exceptions import AuthenticationError, AppException
from app.api.deps import get_current_user_sync

router = APIRouter()
security = HTTPBearer()


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="""
    Register a new user account as either a student or instructor.
    
    Upon successful registration, the user is automatically logged in and receives an access token.
    
    **Student Registration Requirements:**
    - email (unique)
    - password (min 8 chars, must contain letter and number)
    - full_name
    - role: "student"
    - student_number (unique)
    - department
    - class_level (1-4)
    - enrollment_year
    
    **Instructor Registration Requirements:**
    - email (unique)
    - password (min 8 chars, must contain letter and number)
    - full_name
    - role: "instructor"
    - title (optional, e.g., "Prof. Dr.")
    - office_info (optional, e.g., "A-101")
    
    **Password Requirements:**
    - Minimum 8 characters
    - Must contain at least one letter
    - Must contain at least one number
    
    **Returns:**
    - access_token: JWT token for authentication
    - token_type: "bearer"
    - user: User profile information
    """,
    responses={
        201: {
            "description": "User successfully registered and authenticated",
            "content": {
                "application/json": {
                    "example": {
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
                }
            }
        },
        400: {
            "description": "Invalid request data or missing required fields",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Student registration requires: student_number, department, class_level, enrollment_year",
                        "error_type": "AppException"
                    }
                }
            }
        },
        409: {
            "description": "Email or student number already exists",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Email already registered",
                        "error_type": "AppException"
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "password"],
                                "msg": "Password must contain at least one number",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        }
    }
)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Register a new user (student or instructor)"""
    try:
        # Check if email already exists
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise AppException("Email already registered", status_code=status.HTTP_409_CONFLICT)
        
        # Validate role-specific fields
        if user_data.role == "student":
            if not all([
                user_data.student_number,
                user_data.department,
                user_data.class_level,
                user_data.enrollment_year
            ]):
                raise AppException(
                    "Student registration requires: student_number, department, class_level, enrollment_year",
                    status_code=status.HTTP_400_BAD_REQUEST
                )
        
        # Hash password
        hashed_password = auth_service.hash_password(user_data.password)
        
        # Create user
        user = User(
            email=user_data.email.lower(),
            password_hash=hashed_password,
            full_name=user_data.full_name,
            role=user_data.role
        )
        
        db.add(user)
        db.flush()  # Flush to get user_id without committing
        
        # Create role-specific record
        if user_data.role == "student":
            student = Student(
                user_id=user.user_id,
                student_number=user_data.student_number,
                department=user_data.department,
                class_level=user_data.class_level,
                enrollment_year=user_data.enrollment_year
            )
            db.add(student)
        
        elif user_data.role == "instructor":
            instructor = Instructor(
                user_id=user.user_id,
                title=user_data.title,
                office_info=user_data.office_info
            )
            db.add(instructor)
        
        db.commit()
        db.refresh(user)
        
        # Create access token
        access_token = auth_service.create_access_token(
            user_id=user.user_id,
            email=user.email,
            role=user.role
        )
        
        # Store token in database
        auth_service.store_token_sync(db, user.user_id, access_token)
        
        # Prepare user response
        user_response = UserResponse(
            user_id=user.user_id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            created_at=user.created_at
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=user_response
        )
    
    except IntegrityError as e:
        db.rollback()
        # Check if it's a duplicate student_number
        if "student_number" in str(e.orig):
            raise AppException(
                "Student number already exists",
                status_code=status.HTTP_409_CONFLICT
            )
        raise AppException(
            "Registration failed due to data conflict",
            status_code=status.HTTP_409_CONFLICT
        )
    
    except AppException:
        db.rollback()
        raise
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login user",
    description="""
    Authenticate a user with email and password credentials.
    
    Upon successful authentication, returns a JWT access token that must be included
    in the Authorization header for all protected endpoints.
    
    **Token Usage:**
    ```
    Authorization: Bearer <access_token>
    ```
    
    **Token Expiration:**
    - Access tokens expire after 24 hours
    - After expiration, users must login again
    
    **Security:**
    - Passwords are verified using bcrypt
    - Failed login attempts are logged
    - Rate limiting applies (100 requests/minute)
    """,
    responses={
        200: {
            "description": "Successfully authenticated",
            "content": {
                "application/json": {
                    "example": {
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
                }
            }
        },
        401: {
            "description": "Invalid credentials",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Invalid email or password"
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
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
        }
    }
)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """Authenticate user and return access token"""
    try:
        # Authenticate user
        user = auth_service.authenticate_user_sync(
            db=db,
            email=login_data.email.lower(),
            password=login_data.password
        )
        
        # Create access token
        access_token = auth_service.create_access_token(
            user_id=user.user_id,
            email=user.email,
            role=user.role
        )
        
        # Store token in database
        auth_service.store_token_sync(db, user.user_id, access_token)
        
        # Prepare user response
        user_response = UserResponse(
            user_id=user.user_id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            created_at=user.created_at
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=user_response
        )
    
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.post(
    "/logout",
    response_model=LogoutResponse,
    summary="Logout user",
    description="""
    Logout the current user by revoking their access token.
    
    This endpoint requires a valid JWT token in the Authorization header.
    Once logged out, the token can no longer be used to access protected endpoints.
    
    **Required Header:**
    ```
    Authorization: Bearer <access_token>
    ```
    
    **Security:**
    - Token is immediately revoked from the database
    - Revoked tokens cannot be reused
    - Users must login again to obtain a new token
    """,
    responses={
        200: {
            "description": "Successfully logged out",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Logged out successfully"
                    }
                }
            }
        },
        401: {
            "description": "Invalid or missing token",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Not authenticated"
                    }
                }
            }
        },
        404: {
            "description": "Token not found or already revoked",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Token not found or already revoked"
                    }
                }
            }
        }
    }
)
async def logout(
    current_user: User = Depends(get_current_user_sync),
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Logout user by revoking their access token"""
    try:
        token = credentials.credentials
        
        # Revoke token
        revoked = auth_service.revoke_token_sync(db, token)
        
        if not revoked:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Token not found or already revoked"
            )
        
        return LogoutResponse(message="Logged out successfully")
    
    except HTTPException:
        raise
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout failed: {str(e)}"
        )
