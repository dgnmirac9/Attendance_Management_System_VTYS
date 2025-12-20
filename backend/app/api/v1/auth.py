"""Authentication endpoints for user registration, login, and logout"""

from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import Optional

from app.database import get_db
from app.schemas.auth import LoginRequest, TokenResponse, LogoutResponse, PasswordChangeRequest
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
    - student_number (unique)
    
    **Instructor Registration Requirements:**
    - email (unique)
    - password (min 8 chars, must contain letter and number)
    - full_name
    - role: "instructor"
    
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
                        "detail": "Student registration requires: student_number",
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
    email: str = Form(...),
    password: str = Form(...),
    fullName: str = Form(..., alias="fullName"),
    role: str = Form(..., pattern="^(student|instructor)$"),
    studentNumber: Optional[str] = Form(None, alias="studentNumber"),
    faceImage: Optional[UploadFile] = File(None, alias="faceImage"),
    db: Session = Depends(get_db)
):
    """Register a new user (student or instructor) with optional face image"""
    # Map camelCase args to internal snake_case variables for logic
    full_name = fullName
    student_number = studentNumber
    face_image = faceImage
    import base64
    from app.services.face_service import face_service
    
    try:
        # 1. Validate Input using Pydantic Model
        user_data = UserCreate(
            email=email,
            password=password,
            full_name=full_name,
            role=role,
            student_number=student_number
        )
        
        # 2. Check if email already exists
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise AppException("Email already registered", status_code=status.HTTP_409_CONFLICT)
        
        # 3. Role-specific validation
        if user_data.role == "student":
            if not user_data.student_number:
                raise AppException(
                    "Student registration requires: student_number",
                    status_code=status.HTTP_400_BAD_REQUEST
                )
            
            # Check duplicate student number
            existing_student = db.query(Student).filter(
                Student.student_number == user_data.student_number
            ).first()
            if existing_student:
                raise AppException(
                    "Student number already registered",
                    status_code=status.HTTP_409_CONFLICT
                )
        
        # 4. Create User
        hashed_password = auth_service.hash_password(user_data.password)
        
        user = User(
            email=user_data.email.lower(),
            password_hash=hashed_password,
            full_name=user_data.full_name,
            role=user_data.role
        )
        
        db.add(user)
        db.flush()
        
        # 5. Create Role Record
        if user_data.role == "student":
            student = Student(
                user_id=user.user_id,
                student_number=user_data.student_number
            )
            db.add(student)
            db.flush() # Flush to get student_id
            
            # 6. Handle Face Image (if provided)
            if face_image:
                try:
                    # Read file
                    contents = await face_image.read()
                    # Convert to Base64
                    image_base64 = base64.b64encode(contents).decode('utf-8')
                    
                    # Register Face (Sync)
                    face_service.register_face_sync(
                        db=db,
                        student_id=student.student_id,
                        image_base64=image_base64,
                        check_duplicate=True
                    )
                    print(f"Face registered for student {student.student_id}")
                    
                except Exception as e:
                    # Log but allow registration to proceed? 
                    # OR Fail registration?
                    # Better to fail if user explicitly uploaded a face 
                    print(f"Face registration failed: {e}")
                    raise AppException(f"Face registration failed: {str(e)}", status_code=400)
        
        elif user_data.role == "instructor":
            instructor = Instructor(
                user_id=user.user_id
            )
            db.add(instructor)
        
        db.commit()
        db.refresh(user)
        
        # 7. Create Access Token
        access_token = auth_service.create_access_token(
            user_id=user.user_id,
            email=user.email,
            role=user.role
        )
        
        auth_service.store_token_sync(db, user.user_id, access_token)
        
        # 8. Response
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
        if "student_number" in str(e.orig):
            raise AppException("Student number already exists", status_code=409)
        raise AppException("Registration data conflict", status_code=409)
        
    except AppException:
        db.rollback()
        raise
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
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


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
    description="""
    Get the profile information of the currently authenticated user.
    
    **Returns:**
    - User ID
    - Email
    - Full Name
    - Role
    - Registration Date
    """,
    responses={
        200: {
            "description": "User profile retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "user_id": 1,
                        "email": "student@university.edu",
                        "full_name": "John Doe",
                        "role": "student",
                        "created_at": "2024-01-01T00:00:00Z"
                    }
                }
            }
        },
        401: {
            "description": "Not authenticated"
        }
    }
)
async def get_me(
    current_user: User = Depends(get_current_user_sync)
):
    """Get current authenticated user profile"""
    return UserResponse(
        user_id=current_user.user_id,
        email=current_user.email,
        full_name=current_user.full_name,
        role=current_user.role,
        created_at=current_user.created_at
    )


@router.put(
    "/password",
    summary="Change password",
    description="""
    Change the password for the currently authenticated user.
    
    **Requirements:**
    - User must be authenticated
    - Old password must be correct
    - New password must meet password requirements
    
    **Returns:**
    - Success message
    """,
    responses={
        200: {
            "description": "Password changed successfully"
        },
        401: {
            "description": "Invalid old password or not authenticated"
        }
    }
)
async def change_password(
    request: PasswordChangeRequest,
    current_user: User = Depends(get_current_user_sync),
    db: Session = Depends(get_db)
):
    """Change user password"""
    try:
        old_password = request.old_password
        new_password = request.new_password
        
        if not old_password or not new_password:
             raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Both old_password and new_password are required"
            )
        
        # Verify old password
        if not auth_service.verify_password(old_password, current_user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid old password"
            )
        
        # Hash new password
        new_password_hash = auth_service.hash_password(new_password)
        
        # Update password
        current_user.password_hash = new_password_hash
        db.commit()
        
        return {"message": "Password changed successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Password change failed: {str(e)}"
        )

