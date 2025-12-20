"""Face recognition endpoints"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.api.deps import get_db, get_current_user_sync
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
# Pydantic schemas
from app.schemas.base import CamelCaseModel
from fastapi import File, UploadFile, Form

class FaceRegisterResponse(CamelCaseModel):
    """Response schema for face registration"""
    message: str
    student_id: int
    face_registered: bool


class FaceVerifyResponse(CamelCaseModel):
    """Response schema for face verification"""
    verified: bool
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
    - Face must be clearly visible
    - Image file (JPEG or PNG)
    
    **Returns:**
    - Registration status
    """
)
async def register_face(
    image: UploadFile = File(...),
    checkDuplicate: bool = Form(True),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Register face for authenticated student"""
    
    # Check if face service is available
    if not FACE_SERVICE_AVAILABLE or face_service is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Face recognition service is not available"
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
        # Read image content
        image_bytes = await image.read()
        import base64
        image_base64 = "data:image/jpeg;base64," + base64.b64encode(image_bytes).decode('utf-8')

        # Register face using face service
        encrypted_embedding = face_service.register_face_sync(
            db=db,
            student_id=student.student_id,
            image_base64=image_base64,
            check_duplicate=checkDuplicate
        )
        
        # Update student record
        student.face_data_url = encrypted_embedding
        db.commit()
        
        return {
            "message": "Face registered successfully",
            "studentId": student.student_id,
            "faceRegistered": True
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
    
    **Returns:**
    - Verification status (verified: true/false)
    """
)
async def verify_face(
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Verify face against stored face data"""
    
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
            detail="No face registered for this student"
        )
    
    try:
        # Read image content
        image_bytes = await image.read()
        import base64
        image_base64 = "data:image/jpeg;base64," + base64.b64encode(image_bytes).decode('utf-8')

        # Decrypt stored face embedding
        stored_embedding = face_service.decrypt_face_embedding(student.face_data_url)
        
        # Verify face
        is_match, similarity = face_service.verify_face(
            image_base64=image_base64,
            stored_embedding=stored_embedding
        )
        
        # Create response message
        if is_match:
            message = f"Face verified successfully. Similarity: {similarity:.2%}"
        else:
            message = f"Face verification failed. Similarity: {similarity:.2%}"
        
        return {
            "verified": is_match,
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



