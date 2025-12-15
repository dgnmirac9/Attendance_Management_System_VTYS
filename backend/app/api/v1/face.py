"""Face recognition endpoints"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.api.deps import get_db, get_current_user
from app.models.user import User, Student
from app.core.exceptions import AppException
from pydantic import BaseModel, Field

# Try to import face_service
try:
    from app.services.face_service import face_service
    FACE_SERVICE_AVAILABLE = True
    print("✅ Face service loaded successfully!")
except ImportError as e:
    face_service = None
    FACE_SERVICE_AVAILABLE = False
    print(f"⚠️  Face service not available: {e}")

print("🔥 FACE.PY LOADED - Router is being initialized!")

router = APIRouter()

print(f"✅ Face router created (face_service available: {FACE_SERVICE_AVAILABLE})")


# Pydantic schemas
class FaceRegisterRequest(BaseModel):
    """Request schema for face registration"""
    image_base64: str = Field(
        ...,
        description="Base64 encoded face image (JPEG or PNG)",
        example="data:image/jpeg;base64,/9j/4AAQSkZJRg..."
    )
    check_duplicate: bool = Field(
        default=True,
        description="Check if face already exists in database"
    )


class FaceVerifyRequest(BaseModel):
    """Request schema for face verification"""
    image_base64: str = Field(
        ...,
        description="Base64 encoded face image to verify",
        example="data:image/jpeg;base64,/9j/4AAQSkZJRg..."
    )


class FaceRegisterResponse(BaseModel):
    """Response schema for face registration"""
    message: str
    student_id: int
    face_registered: bool


class FaceVerifyResponse(BaseModel):
    """Response schema for face verification"""
    is_match: bool
    similarity: float
    message: str


@router.post(
    "/register",
    response_model=FaceRegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register face for student",
    description="""
    Register a face image for the authenticated student.
    
    **Requirements:**
    - User must be authenticated (student role)
    - Face must be clearly visible in the image
    - Image must be base64 encoded (JPEG or PNG)
    - Face must not already be registered (if check_duplicate=True)
    
    **Process:**
    1. Extract face embedding from image using DeepFace
    2. Check for duplicate faces (optional)
    3. Encrypt and store face embedding
    4. Update student record
    
    **Returns:**
    - Success message
    - Student ID
    - Registration status
    """,
    responses={
        201: {
            "description": "Face registered successfully",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Face registered successfully",
                        "student_id": 1,
                        "face_registered": True
                    }
                }
            }
        },
        400: {
            "description": "Bad request - No face detected or invalid image",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "No face detected in the image. Please ensure your face is clearly visible.",
                        "error_type": "AppException"
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Only students can register faces",
                        "error_type": "HTTPException"
                    }
                }
            }
        },
        409: {
            "description": "Conflict - Face already registered",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "This face is already registered for another student (ID: 123)",
                        "error_type": "AppException"
                    }
                }
            }
        }
    }
)
def register_face(
    request: FaceRegisterRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Register face for authenticated student
    
    Args:
        request: Face registration request with base64 image
        db: Database session
        current_user: Authenticated user
        
    Returns:
        Success response with student ID
        
    Raises:
        HTTPException: If user is not a student or face registration fails
    """
    # Check if face service is available
    if not FACE_SERVICE_AVAILABLE or face_service is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Face recognition service is not available. Please install DeepFace: pip install deepface"
        )
    
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can register faces"
        )
    
    # Get student record
    student = db.query(Student).filter(Student.user_id == current_user.user_id).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student record not found"
        )
    
    try:
        # Register face using face service
        encrypted_embedding = face_service.register_face_sync(
            db=db,
            student_id=student.student_id,
            image_base64=request.image_base64,
            check_duplicate=request.check_duplicate
        )
        
        # Update student record with encrypted face data
        student.face_data_url = encrypted_embedding
        db.commit()
        
        return {
            "message": "Face registered successfully",
            "student_id": student.student_id,
            "face_registered": True
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Face registration failed: {str(e)}"
        )



@router.post(
    "/verify",
    response_model=FaceVerifyResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify face against stored data",
    description="""
    Verify if a face image matches the authenticated student's registered face.
    
    **Requirements:**
    - User must be authenticated (student role)
    - Student must have a registered face
    - Image must be base64 encoded (JPEG or PNG)
    - Face must be clearly visible in the image
    
    **Process:**
    1. Extract face embedding from provided image
    2. Decrypt stored face embedding
    3. Calculate cosine similarity
    4. Compare against threshold (0.80)
    
    **Returns:**
    - Match status (true/false)
    - Similarity score (0.0 to 1.0)
    - Descriptive message
    
    **Similarity Scores:**
    - 0.80-1.00: Match (same person)
    - 0.60-0.79: Moderate similarity
    - 0.00-0.59: No match (different person)
    """,
    responses={
        200: {
            "description": "Face verification completed",
            "content": {
                "application/json": {
                    "examples": {
                        "match": {
                            "summary": "Face matched",
                            "value": {
                                "is_match": True,
                                "similarity": 0.95,
                                "message": "Face verified successfully. Similarity: 95.00%"
                            }
                        },
                        "no_match": {
                            "summary": "Face not matched",
                            "value": {
                                "is_match": False,
                                "similarity": 0.65,
                                "message": "Face verification failed. Similarity: 65.00%"
                            }
                        }
                    }
                }
            }
        },
        400: {
            "description": "Bad request - No face detected",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "No face detected in the image",
                        "error_type": "AppException"
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student",
        },
        404: {
            "description": "Not found - No face registered",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "No face registered for this student. Please register your face first.",
                        "error_type": "HTTPException"
                    }
                }
            }
        }
    }
)
def verify_face(
    request: FaceVerifyRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Verify face against stored face data
    
    Args:
        request: Face verification request with base64 image
        db: Database session
        current_user: Authenticated user
        
    Returns:
        Verification result with similarity score
        
    Raises:
        HTTPException: If verification fails or user is not a student
    """
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can verify faces"
        )
    
    # Get student record
    student = db.query(Student).filter(Student.user_id == current_user.user_id).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student record not found"
        )
    
    # Check if student has registered face
    if not student.face_data_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No face registered for this student. Please register your face first."
        )
    
    try:
        # Decrypt stored face embedding
        stored_embedding = face_service.decrypt_face_embedding(student.face_data_url)
        
        # Verify face
        is_match, similarity = face_service.verify_face(
            image_base64=request.image_base64,
            stored_embedding=stored_embedding
        )
        
        # Create response message
        if is_match:
            message = f"Face verified successfully. Similarity: {similarity:.2%}"
        else:
            message = f"Face verification failed. Similarity: {similarity:.2%}"
        
        return {
            "is_match": is_match,
            "similarity": similarity,
            "message": message
        }
        
    except AppException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Face verification failed: {str(e)}"
        )


@router.get(
    "/status",
    status_code=status.HTTP_200_OK,
    summary="Check face registration status",
    description="""
    Check if the authenticated student has a registered face.
    
    **Returns:**
    - Registration status
    - Student information
    """,
    responses={
        200: {
            "description": "Face registration status",
            "content": {
                "application/json": {
                    "examples": {
                        "registered": {
                            "summary": "Face registered",
                            "value": {
                                "student_id": 1,
                                "student_number": "2024001",
                                "full_name": "John Doe",
                                "face_registered": True,
                                "message": "Face is registered"
                            }
                        },
                        "not_registered": {
                            "summary": "Face not registered",
                            "value": {
                                "student_id": 1,
                                "student_number": "2024001",
                                "full_name": "John Doe",
                                "face_registered": False,
                                "message": "No face registered"
                            }
                        }
                    }
                }
            }
        },
        403: {
            "description": "Forbidden - User is not a student"
        }
    }
)
def get_face_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get face registration status for authenticated student
    
    Args:
        db: Database session
        current_user: Authenticated user
        
    Returns:
        Face registration status
        
    Raises:
        HTTPException: If user is not a student
    """
    # Check if user is a student
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can check face status"
        )
    
    # Get student record
    student = db.query(Student).filter(Student.user_id == current_user.user_id).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student record not found"
        )
    
    # Check if face is registered
    face_registered = student.face_data_url is not None
    
    return {
        "student_id": student.student_id,
        "student_number": student.student_number,
        "full_name": current_user.full_name,
        "face_registered": face_registered,
        "message": "Face is registered" if face_registered else "No face registered"
    }
