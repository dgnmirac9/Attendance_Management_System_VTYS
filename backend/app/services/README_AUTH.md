# Authentication Service

## Overview
The `AuthService` class provides comprehensive authentication functionality for the C-Lens application, including password hashing, JWT token management, and user authentication.

## Features

### Password Security
- **Hashing**: Uses bcrypt for secure password hashing
- **Verification**: Validates passwords against stored hashes
- **Automatic Salt**: bcrypt automatically generates unique salts for each password

### JWT Token Management
- **Token Generation**: Creates JWT tokens with user information (user_id, email, role)
- **Token Validation**: Decodes and validates JWT tokens
- **Token Expiration**: Configurable expiration time (default: 7 days)
- **Token Storage**: Stores tokens in database for tracking and revocation
- **Token Revocation**: Supports individual and bulk token revocation

### User Authentication
- **Email/Password Authentication**: Validates user credentials
- **Async Support**: Provides both async and sync methods for flexibility
- **Error Handling**: Raises appropriate exceptions for authentication failures

## Usage Examples

### Password Hashing
```python
from app.services.auth_service import auth_service

# Hash a password
hashed = auth_service.hash_password("MySecurePassword123!")

# Verify a password
is_valid = auth_service.verify_password("MySecurePassword123!", hashed)
```

### Token Generation
```python
# Create a JWT token
token = auth_service.create_access_token(
    user_id=1,
    email="user@example.com",
    role="student"
)

# Decode a token
payload = auth_service.decode_token(token)
# Returns: {'sub': '1', 'email': 'user@example.com', 'role': 'student', 'exp': ...}
```

### User Authentication
```python
from app.database import get_async_db

# Authenticate user (async)
async with get_async_db() as db:
    user = await auth_service.authenticate_user(
        db=db,
        email="user@example.com",
        password="MySecurePassword123!"
    )
    
    # Store token in database
    token = auth_service.create_access_token(
        user_id=user.user_id,
        email=user.email,
        role=user.role
    )
    await auth_service.store_token(db, user.user_id, token)
```

### Token Validation
```python
# Validate token and get user
async with get_async_db() as db:
    user = await auth_service.validate_token(db, token)
```

### Token Revocation
```python
# Revoke a single token
async with get_async_db() as db:
    await auth_service.revoke_token(db, token)
    
# Revoke all tokens for a user
async with get_async_db() as db:
    count = await auth_service.revoke_all_user_tokens(db, user_id=1)
    
# Clean up expired tokens
async with get_async_db() as db:
    count = await auth_service.cleanup_expired_tokens(db)
```

## Configuration
The service uses settings from `app.config.Settings`:
- `SECRET_KEY`: Secret key for JWT signing
- `JWT_ALGORITHM`: Algorithm for JWT (default: HS256)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration time (default: 10080 = 7 days)

## Security Features
1. **bcrypt Hashing**: Industry-standard password hashing with automatic salting
2. **JWT Tokens**: Secure token-based authentication
3. **Token Expiration**: Automatic token expiration for security
4. **Token Revocation**: Ability to revoke tokens for logout/security
5. **Database Tracking**: All tokens stored in database for audit trail

## Requirements Met
- ✓ Requirement 4.1: Password hashing with bcrypt
- ✓ Requirement 2.5: JWT token generation and validation
- ✓ Modular design for easy testing and maintenance
- ✓ Both async and sync methods for flexibility

## Testing
Run the verification script to test the service:
```bash
cd backend
python verify_auth_service.py
```

## Dependencies
- `passlib[bcrypt]`: Password hashing
- `python-jose[cryptography]`: JWT token handling
- `sqlalchemy`: Database operations
- `app.core.security`: Core security utilities
- `app.core.exceptions`: Custom exception classes
