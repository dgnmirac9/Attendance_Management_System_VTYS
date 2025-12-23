"""Face recognition service using DeepFace"""

import numpy as np
import base64
import io
import json
from typing import Optional, List, Tuple
from PIL import Image
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select


from app.config import settings
from app.core.encryption import encryption_service
from app.core.exceptions import AppException
from app.models.user import Student


class FaceService:
    """Service for face recognition operations"""
    
    def __init__(self):
        """Initialize face recognition service"""
        self.model_name = settings.FACE_MODEL
        self.detector_backend = settings.FACE_DETECTOR_BACKEND
        self.similarity_threshold = settings.FACE_SIMILARITY_THRESHOLD
    
    def _base64_to_image(self, base64_string: str) -> np.ndarray:
        """
        Convert base64 string to image array
        
        Args:
            base64_string: Base64 encoded image string
            
        Returns:
            Image as numpy array (RGB format)
            
        Raises:
            AppException: If image conversion fails
        """
        try:
            # Remove data URL prefix if present
            if ',' in base64_string:
                base64_string = base64_string.split(',')[1]
            
            # Decode base64
            image_bytes = base64.b64decode(base64_string)
            
            # Convert to PIL Image
            image = Image.open(io.BytesIO(image_bytes))
            
            # Apply EXIF rotation if present
            from PIL import ImageOps
            image = ImageOps.exif_transpose(image)
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Convert to numpy array
            image_array = np.array(image)
            
            return image_array
            
        except Exception as e:
            raise AppException(
                message=f"Failed to convert base64 to image: {str(e)}",
                status_code=400
            )
    
    def extract_face_embedding(self, image_base64: str) -> List[float]:
        """
        Extract face embedding from image
        
        Args:
            image_base64: Base64 encoded image string
            
        Returns:
            Face embedding as list of floats
            
        Raises:
            AppException: If face extraction fails
        """
        try:
            # Convert base64 to image array
            image_array = self._base64_to_image(image_base64)
            
            # Extract face embedding using DeepFace
            from deepface import DeepFace
            embedding_objs = DeepFace.represent(
                img_path=image_array,
                model_name=self.model_name,
                detector_backend=self.detector_backend,
                enforce_detection=True  # Strict detection (mobile has retry loop)
            )
            
            # DeepFace.represent returns a list of dictionaries
            if not embedding_objs or len(embedding_objs) == 0:
                raise AppException(
                    message="No face detected in the image",
                    status_code=400
                )
            
            # Get the first face embedding
            embedding = embedding_objs[0]["embedding"]
            
            return embedding
            
        except AppException:
            raise
        except Exception as e:
            error_message = str(e).lower()
            
            if "face could not be detected" in error_message or "no face" in error_message:
                raise AppException(
                    message="No face detected in the image. Please ensure your face is clearly visible.",
                    status_code=400
                )
            else:
                raise AppException(
                    message=f"Face extraction failed: {str(e)}",
                    status_code=500
                )

    
    def encrypt_face_embedding(self, embedding: List[float]) -> str:
        """
        Encrypt face embedding for secure storage
        
        Args:
            embedding: Face embedding as list of floats
            
        Returns:
            Encrypted embedding as string
        """
        try:
            # Convert embedding to JSON string
            embedding_json = json.dumps(embedding)
            
            # Encrypt the JSON string
            encrypted = encryption_service.encrypt(embedding_json)
            
            return encrypted
            
        except Exception as e:
            raise AppException(
                message=f"Failed to encrypt face embedding: {str(e)}",
                status_code=500
            )
    
    def decrypt_face_embedding(self, encrypted_embedding: str) -> List[float]:
        """
        Decrypt face embedding from storage
        
        Args:
            encrypted_embedding: Encrypted embedding string
            
        Returns:
            Face embedding as list of floats
        """
        try:
            # Decrypt the string
            decrypted_json = encryption_service.decrypt(encrypted_embedding)
            
            # Parse JSON to list
            embedding = json.loads(decrypted_json)
            
            return embedding
            
        except Exception as e:
            raise AppException(
                message=f"Failed to decrypt face embedding: {str(e)}",
                status_code=500
            )
    
    def calculate_cosine_similarity(
        self,
        embedding1: List[float],
        embedding2: List[float]
    ) -> float:
        """
        Calculate cosine similarity between two embeddings
        
        Args:
            embedding1: First face embedding
            embedding2: Second face embedding
            
        Returns:
            Similarity score (0 to 1, higher is more similar)
        """
        try:
            # Convert to numpy arrays
            vec1 = np.array(embedding1)
            vec2 = np.array(embedding2)
            
            # Calculate cosine similarity
            dot_product = np.dot(vec1, vec2)
            norm1 = np.linalg.norm(vec1)
            norm2 = np.linalg.norm(vec2)
            
            similarity = dot_product / (norm1 * norm2)
            
            # Convert to 0-1 range (cosine similarity is -1 to 1)
            similarity = (similarity + 1) / 2
            
            return float(similarity)
            
        except Exception as e:
            raise AppException(
                message=f"Failed to calculate similarity: {str(e)}",
                status_code=500
            )
    
    def verify_face(
        self,
        image_base64: str,
        stored_embedding: List[float]
    ) -> Tuple[bool, float]:
        """
        Verify if face in image matches stored embedding
        
        Args:
            image_base64: Base64 encoded image string
            stored_embedding: Stored face embedding to compare against
            
        Returns:
            Tuple of (is_match, similarity_score)
        """
        try:
            # Extract embedding from new image
            new_embedding = self.extract_face_embedding(image_base64)
            
            # Calculate similarity
            similarity = self.calculate_cosine_similarity(new_embedding, stored_embedding)
            
            # Check if similarity meets threshold
            is_match = similarity >= self.similarity_threshold
            
            return is_match, similarity
            
        except Exception as e:
            raise AppException(
                message=f"Face verification failed: {str(e)}",
                status_code=500
            )

    
    async def check_duplicate_face(
        self,
        db: AsyncSession,
        image_base64: str,
        exclude_student_id: Optional[int] = None
    ) -> Tuple[bool, Optional[int]]:
        """
        Check if face already exists in database
        
        Args:
            db: Database session
            image_base64: Base64 encoded image string
            exclude_student_id: Student ID to exclude from check (for updates)
            
        Returns:
            Tuple of (is_duplicate, student_id_if_duplicate)
        """
        try:
            # Extract embedding from new image
            new_embedding = self.extract_face_embedding(image_base64)
            
            # Get all students with face data
            query = select(Student).where(Student.face_data_url.isnot(None))
            
            if exclude_student_id:
                query = query.where(Student.student_id != exclude_student_id)
            
            result = await db.execute(query)
            students = result.scalars().all()
            
            # Check similarity with each stored face
            for student in students:
                try:
                    # Decrypt stored embedding
                    stored_embedding = self.decrypt_face_embedding(student.face_data_url)
                    
                    # Calculate similarity
                    similarity = self.calculate_cosine_similarity(new_embedding, stored_embedding)
                    
                    # If similarity is above threshold, it's a duplicate
                    if similarity >= self.similarity_threshold:
                        return True, student.student_id
                        
                except Exception as e:
                    # Log error but continue checking other faces
                    print(f"Error checking student {student.student_id}: {str(e)}")
                    continue
            
            # No duplicate found
            return False, None
            
        except AppException:
            raise
        except Exception as e:
            raise AppException(
                message=f"Duplicate check failed: {str(e)}",
                status_code=500
            )
    
    def check_duplicate_face_sync(
        self,
        db: Session,
        image_base64: str,
        exclude_student_id: Optional[int] = None
    ) -> Tuple[bool, Optional[int]]:
        """
        Check if face already exists in database (synchronous version)
        
        Args:
            db: Database session
            image_base64: Base64 encoded image string
            exclude_student_id: Student ID to exclude from check (for updates)
            
        Returns:
            Tuple of (is_duplicate, student_id_if_duplicate)
        """
        try:
            # Extract embedding from new image
            new_embedding = self.extract_face_embedding(image_base64)
            
            # Get all students with face data
            query = db.query(Student).filter(Student.face_data_url.isnot(None))
            
            if exclude_student_id:
                query = query.filter(Student.student_id != exclude_student_id)
            
            students = query.all()
            
            # Check similarity with each stored face
            for student in students:
                try:
                    # Decrypt stored embedding
                    stored_embedding = self.decrypt_face_embedding(student.face_data_url)
                    
                    # Calculate similarity
                    similarity = self.calculate_cosine_similarity(new_embedding, stored_embedding)
                    
                    # If similarity is above threshold, it's a duplicate
                    if similarity >= self.similarity_threshold:
                        return True, student.student_id
                        
                except Exception as e:
                    # Log error but continue checking other faces
                    print(f"Error checking student {student.student_id}: {str(e)}")
                    continue
            
            # No duplicate found
            return False, None
            
        except AppException:
            raise
        except Exception as e:
            raise AppException(
                message=f"Duplicate check failed: {str(e)}",
                status_code=500
            )
    
    async def register_face(
        self,
        db: AsyncSession,
        student_id: int,
        image_base64: str,
        check_duplicate: bool = True
    ) -> str:
        """
        Register face for a student
        
        Args:
            db: Database session
            student_id: Student ID
            image_base64: Base64 encoded image string
            check_duplicate: Whether to check for duplicate faces
            
        Returns:
            Encrypted face embedding string
            
        Raises:
            AppException: If face registration fails or duplicate found
        """
        try:
            # Check for duplicate if requested
            if check_duplicate:
                is_duplicate, duplicate_student_id = await self.check_duplicate_face(
                    db, image_base64, exclude_student_id=student_id
                )
                
                if is_duplicate:
                    raise AppException(
                        message=f"This face is already registered for another student (ID: {duplicate_student_id})",
                        status_code=409
                    )
            
            # Extract face embedding
            embedding = self.extract_face_embedding(image_base64)
            
            # Encrypt embedding
            encrypted_embedding = self.encrypt_face_embedding(embedding)
            
            return encrypted_embedding
            
        except AppException:
            raise
        except Exception as e:
            raise AppException(
                message=f"Face registration failed: {str(e)}",
                status_code=500
            )
    
    def register_face_sync(
        self,
        db: Session,
        student_id: int,
        image_base64: str,
        check_duplicate: bool = True
    ) -> str:
        """
        Register face for a student (synchronous version)
        
        Args:
            db: Database session
            student_id: Student ID
            image_base64: Base64 encoded image string
            check_duplicate: Whether to check for duplicate faces
            
        Returns:
            Encrypted face embedding string
            
        Raises:
            AppException: If face registration fails or duplicate found
        """
        try:
            # Check for duplicate if requested
            if check_duplicate:
                is_duplicate, duplicate_student_id = self.check_duplicate_face_sync(
                    db, image_base64, exclude_student_id=student_id
                )
                
                if is_duplicate:
                    raise AppException(
                        message=f"This face is already registered for another student (ID: {duplicate_student_id})",
                        status_code=409
                    )
            
            # Extract face embedding
            embedding = self.extract_face_embedding(image_base64)
            
            # Encrypt embedding
            encrypted_embedding = self.encrypt_face_embedding(embedding)
            
            return encrypted_embedding
            
        except AppException:
            raise
        except Exception as e:
            raise AppException(
                message=f"Face registration failed: {str(e)}",
                status_code=500
            )


# Create singleton instance
face_service = FaceService()
