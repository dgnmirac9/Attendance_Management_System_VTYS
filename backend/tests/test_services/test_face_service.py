"""Tests for face recognition service"""

import pytest
import base64
import json
from unittest.mock import Mock, patch, MagicMock
from app.services.face_service import FaceService, face_service
from app.core.exceptions import AppException


# Sample base64 encoded 1x1 pixel image (valid JPEG)
SAMPLE_IMAGE_BASE64 = "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k="

# Sample face embedding (512 dimensions)
SAMPLE_EMBEDDING = [0.1] * 512


class TestFaceService:
    """Tests for FaceService class"""
    
    def test_initialization(self):
        """Test service initialization"""
        service = FaceService()
        assert service.model_name == "Facenet512"
        assert service.detector_backend == "opencv"
        assert service.similarity_threshold == 0.80
    
    def test_base64_to_image_valid(self):
        """Test converting valid base64 to image"""
        service = FaceService()
        
        # Test with data URL prefix
        image_with_prefix = f"data:image/jpeg;base64,{SAMPLE_IMAGE_BASE64}"
        result = service._base64_to_image(image_with_prefix)
        assert result is not None
        assert result.shape == (1, 1, 3)  # 1x1 RGB image
        
        # Test without prefix
        result = service._base64_to_image(SAMPLE_IMAGE_BASE64)
        assert result is not None
    
    def test_base64_to_image_invalid(self):
        """Test converting invalid base64 to image"""
        service = FaceService()
        
        with pytest.raises(AppException) as exc_info:
            service._base64_to_image("invalid_base64_string")
        
        assert exc_info.value.status_code == 400
        assert "Failed to convert base64 to image" in exc_info.value.message
    
    @patch('app.services.face_service.DeepFace.represent')
    def test_extract_face_embedding_success(self, mock_represent):
        """Test successful face embedding extraction"""
        service = FaceService()
        
        # Mock DeepFace response
        mock_represent.return_value = [{"embedding": SAMPLE_EMBEDDING}]
        
        result = service.extract_face_embedding(SAMPLE_IMAGE_BASE64)
        
        assert result == SAMPLE_EMBEDDING
        assert len(result) == 512
        mock_represent.assert_called_once()
    
    @patch('app.services.face_service.DeepFace.represent')
    def test_extract_face_embedding_no_face(self, mock_represent):
        """Test face extraction when no face detected"""
        service = FaceService()
        
        # Mock DeepFace response with no faces
        mock_represent.return_value = []
        
        with pytest.raises(AppException) as exc_info:
            service.extract_face_embedding(SAMPLE_IMAGE_BASE64)
        
        assert exc_info.value.status_code == 400
        assert "No face detected" in exc_info.value.message

    
    @patch('app.services.face_service.DeepFace.represent')
    def test_extract_face_embedding_error(self, mock_represent):
        """Test face extraction with DeepFace error"""
        service = FaceService()
        
        # Mock DeepFace error
        mock_represent.side_effect = Exception("Face could not be detected")
        
        with pytest.raises(AppException) as exc_info:
            service.extract_face_embedding(SAMPLE_IMAGE_BASE64)
        
        assert exc_info.value.status_code == 400
        assert "face is clearly visible" in exc_info.value.message.lower()
    
    def test_encrypt_decrypt_embedding(self):
        """Test encryption and decryption of embeddings"""
        service = FaceService()
        
        # Encrypt
        encrypted = service.encrypt_face_embedding(SAMPLE_EMBEDDING)
        assert encrypted is not None
        assert isinstance(encrypted, str)
        assert encrypted != json.dumps(SAMPLE_EMBEDDING)
        
        # Decrypt
        decrypted = service.decrypt_face_embedding(encrypted)
        assert decrypted == SAMPLE_EMBEDDING
    
    def test_calculate_cosine_similarity_identical(self):
        """Test cosine similarity with identical embeddings"""
        service = FaceService()
        
        similarity = service.calculate_cosine_similarity(SAMPLE_EMBEDDING, SAMPLE_EMBEDDING)
        
        # Identical embeddings should have similarity close to 1.0
        assert 0.99 <= similarity <= 1.0
    
    def test_calculate_cosine_similarity_different(self):
        """Test cosine similarity with different embeddings"""
        service = FaceService()
        
        embedding1 = [0.1] * 512
        embedding2 = [-0.1] * 512
        
        similarity = service.calculate_cosine_similarity(embedding1, embedding2)
        
        # Opposite embeddings should have low similarity
        assert 0.0 <= similarity <= 0.5
    
    @patch('app.services.face_service.FaceService.extract_face_embedding')
    def test_verify_face_match(self, mock_extract):
        """Test face verification with matching faces"""
        service = FaceService()
        
        # Mock extraction to return same embedding
        mock_extract.return_value = SAMPLE_EMBEDDING
        
        is_match, similarity = service.verify_face(SAMPLE_IMAGE_BASE64, SAMPLE_EMBEDDING)
        
        assert is_match is True
        assert similarity >= service.similarity_threshold
    
    @patch('app.services.face_service.FaceService.extract_face_embedding')
    def test_verify_face_no_match(self, mock_extract):
        """Test face verification with non-matching faces"""
        service = FaceService()
        
        # Mock extraction to return different embedding
        different_embedding = [-0.1] * 512
        mock_extract.return_value = different_embedding
        
        is_match, similarity = service.verify_face(SAMPLE_IMAGE_BASE64, SAMPLE_EMBEDDING)
        
        assert is_match is False
        assert similarity < service.similarity_threshold
    
    @pytest.mark.asyncio
    @patch('app.services.face_service.FaceService.extract_face_embedding')
    async def test_check_duplicate_face_no_duplicate(self, mock_extract):
        """Test duplicate check with no duplicates"""
        service = FaceService()
        
        # Mock database session
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_db.execute.return_value = mock_result
        
        # Mock extraction
        mock_extract.return_value = SAMPLE_EMBEDDING
        
        is_duplicate, student_id = await service.check_duplicate_face(mock_db, SAMPLE_IMAGE_BASE64)
        
        assert is_duplicate is False
        assert student_id is None
    
    @pytest.mark.asyncio
    @patch('app.services.face_service.FaceService.extract_face_embedding')
    @patch('app.services.face_service.FaceService.decrypt_face_embedding')
    @patch('app.services.face_service.FaceService.calculate_cosine_similarity')
    async def test_check_duplicate_face_found(self, mock_similarity, mock_decrypt, mock_extract):
        """Test duplicate check with duplicate found"""
        service = FaceService()
        
        # Mock student with face data
        mock_student = Mock()
        mock_student.student_id = 123
        mock_student.face_data_url = "encrypted_data"
        
        # Mock database session
        mock_db = MagicMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [mock_student]
        mock_db.execute.return_value = mock_result
        
        # Mock functions
        mock_extract.return_value = SAMPLE_EMBEDDING
        mock_decrypt.return_value = SAMPLE_EMBEDDING
        mock_similarity.return_value = 0.95  # High similarity
        
        is_duplicate, student_id = await service.check_duplicate_face(mock_db, SAMPLE_IMAGE_BASE64)
        
        assert is_duplicate is True
        assert student_id == 123
    
    @pytest.mark.asyncio
    @patch('app.services.face_service.FaceService.check_duplicate_face')
    @patch('app.services.face_service.FaceService.extract_face_embedding')
    @patch('app.services.face_service.FaceService.encrypt_face_embedding')
    async def test_register_face_success(self, mock_encrypt, mock_extract, mock_check_dup):
        """Test successful face registration"""
        service = FaceService()
        
        # Mock database session
        mock_db = MagicMock()
        
        # Mock functions
        mock_check_dup.return_value = (False, None)  # No duplicate
        mock_extract.return_value = SAMPLE_EMBEDDING
        mock_encrypt.return_value = "encrypted_embedding"
        
        result = await service.register_face(mock_db, 1, SAMPLE_IMAGE_BASE64)
        
        assert result == "encrypted_embedding"
        mock_check_dup.assert_called_once()
        mock_extract.assert_called_once()
        mock_encrypt.assert_called_once()
    
    @pytest.mark.asyncio
    @patch('app.services.face_service.FaceService.check_duplicate_face')
    async def test_register_face_duplicate_found(self, mock_check_dup):
        """Test face registration with duplicate found"""
        service = FaceService()
        
        # Mock database session
        mock_db = MagicMock()
        
        # Mock duplicate found
        mock_check_dup.return_value = (True, 456)
        
        with pytest.raises(AppException) as exc_info:
            await service.register_face(mock_db, 1, SAMPLE_IMAGE_BASE64)
        
        assert exc_info.value.status_code == 409
        assert "already registered" in exc_info.value.message
        assert "456" in exc_info.value.message


class TestFaceServiceSingleton:
    """Tests for face_service singleton"""
    
    def test_singleton_instance(self):
        """Test that face_service is properly initialized"""
        assert face_service is not None
        assert isinstance(face_service, FaceService)
        assert face_service.model_name == "Facenet512"
