# Face Recognition Service

## Overview

The Face Recognition Service provides face detection, embedding extraction, verification, and duplicate checking using DeepFace library with Facenet512 model.

## Features

- **Face Embedding Extraction**: Extract 512-dimensional face embeddings from images
- **Face Verification**: Compare faces with configurable similarity threshold (default: 0.80)
- **Encryption**: Secure storage of face embeddings using Fernet encryption
- **Duplicate Detection**: Prevent multiple registrations of the same face
- **Error Handling**: Comprehensive error handling with meaningful messages

## Configuration

Face recognition settings are configured in `app/config.py`:

```python
FACE_MODEL: str = "Facenet512"              # DeepFace model
FACE_SIMILARITY_THRESHOLD: float = 0.80     # Similarity threshold (0-1)
FACE_DETECTOR_BACKEND: str = "opencv"       # Face detector backend
ENCRYPTION_KEY: str = "..."                 # Encryption key for face data
```

## Usage

### Initialize Service

```python
from app.services.face_service import face_service
```

### Extract Face Embedding

```python
# Extract embedding from base64 image
embedding = face_service.extract_face_embedding(image_base64)
# Returns: List[float] with 512 dimensions
```

### Encrypt/Decrypt Embeddings

```python
# Encrypt for storage
encrypted = face_service.encrypt_face_embedding(embedding)

# Decrypt from storage
embedding = face_service.decrypt_face_embedding(encrypted)
```

### Verify Face

```python
# Compare face in image with stored embedding
is_match, similarity = face_service.verify_face(image_base64, stored_embedding)
# Returns: (bool, float) - match status and similarity score
```

### Check for Duplicates

```python
# Async version
is_duplicate, student_id = await face_service.check_duplicate_face(
    db, image_base64, exclude_student_id=None
)

# Sync version
is_duplicate, student_id = face_service.check_duplicate_face_sync(
    db, image_base64, exclude_student_id=None
)
```

### Register Face

```python
# Async version
encrypted_embedding = await face_service.register_face(
    db, student_id, image_base64, check_duplicate=True
)

# Sync version
encrypted_embedding = face_service.register_face_sync(
    db, student_id, image_base64, check_duplicate=True
)
```

## Image Format

Images should be provided as base64 encoded strings:

```python
# With data URL prefix (will be automatically removed)
image_base64 = "data:image/jpeg;base64,/9j/4AAQSkZJRg..."

# Or without prefix
image_base64 = "/9j/4AAQSkZJRg..."
```

## Error Handling

The service raises `AppException` with appropriate status codes:

- **400 Bad Request**: No face detected, invalid image format
- **409 Conflict**: Duplicate face found
- **500 Internal Server Error**: Processing errors

```python
from app.core.exceptions import AppException

try:
    embedding = face_service.extract_face_embedding(image_base64)
except AppException as e:
    print(f"Error: {e.message}, Status: {e.status_code}")
```

## Similarity Calculation

The service uses cosine similarity to compare face embeddings:

1. Calculate dot product of two embedding vectors
2. Normalize by vector magnitudes
3. Convert from [-1, 1] range to [0, 1] range
4. Compare against threshold (default: 0.80)

**Similarity Scores:**
- 1.0: Identical faces
- 0.80-0.99: Very high similarity (likely same person)
- 0.60-0.79: Moderate similarity
- 0.00-0.59: Low similarity (different people)

## Security

- Face embeddings are encrypted using Fernet (symmetric encryption)
- Encryption key is stored in environment variables
- Original images are not stored, only embeddings
- Embeddings are 512-dimensional float arrays

## Performance

- Face detection: ~100-500ms per image
- Embedding extraction: ~200-800ms per image
- Similarity calculation: <1ms per comparison
- Duplicate check: O(n) where n = number of registered faces

## Dependencies

- `deepface`: Face recognition library
- `tensorflow`: Deep learning framework
- `opencv-python`: Image processing
- `cryptography`: Encryption
- `numpy`: Numerical operations
- `Pillow`: Image handling

## Testing

Run tests with:

```bash
pytest tests/test_services/test_face_service.py -v
```

## Troubleshooting

### "No face detected in the image"

- Ensure face is clearly visible and well-lit
- Face should be front-facing
- Image resolution should be at least 224x224 pixels

### "Face extraction failed"

- Check image format (JPEG, PNG supported)
- Verify base64 encoding is correct
- Ensure image is not corrupted

### "Duplicate face found"

- This face is already registered for another student
- Use `exclude_student_id` parameter when updating existing face

## Future Improvements

- [ ] Support for multiple faces in single image
- [ ] Face quality assessment
- [ ] Liveness detection
- [ ] Face alignment preprocessing
- [ ] Batch processing for multiple faces
- [ ] Caching for frequently accessed embeddings
