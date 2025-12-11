"""Test authentication endpoint"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.api.deps import get_db, get_current_user_sync
from app.models.user import User


router = APIRouter()


@router.get(
    "/test-token",
    summary="Test your JWT token",
    description="""
    Test if your JWT token is valid and working correctly.
    
    **How to use:**
    1. Login to get a token
    2. Click "Authorize" button (top right)
    3. Paste your token (without "Bearer")
    4. Click "Authorize" then "Close"
    5. Try this endpoint
    
    **Returns:**
    - Your user information if token is valid
    - Detailed error message if token is invalid
    
    **Common Issues:**
    - "Token is empty" → You didn't authorize or token wasn't saved
    - "Token decode failed" → Token is malformed or expired
    - "User not found" → Token is valid but user was deleted
    """,
    responses={
        200: {
            "description": "Token is valid",
            "content": {
                "application/json": {
                    "example": {
                        "message": "Token is valid!",
                        "user_id": 1,
                        "email": "test@test.com",
                        "full_name": "Test User",
                        "role": "student",
                        "token_info": {
                            "token_length": 150,
                            "token_preview": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                        }
                    }
                }
            }
        },
        401: {
            "description": "Token is invalid",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Token decode failed: Signature has expired. Please login again to get a new token."
                    }
                }
            }
        }
    }
)
def test_token(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """
    Test if JWT token is valid
    
    This endpoint helps debug authentication issues by:
    - Validating the token format
    - Checking if token can be decoded
    - Verifying user exists in database
    - Returning detailed user information
    """
    return {
        "message": "✅ Token is valid!",
        "user_id": current_user.user_id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role,
        "created_at": current_user.created_at.isoformat(),
        "info": {
            "status": "authenticated",
            "message": "Your token is working correctly. You can now use other protected endpoints."
        }
    }


@router.get(
    "/whoami",
    summary="Who am I?",
    description="""
    Quick endpoint to check who you are authenticated as.
    
    **Returns:**
    - Your basic user information
    """,
    responses={
        200: {
            "description": "User information",
            "content": {
                "application/json": {
                    "example": {
                        "user_id": 1,
                        "email": "test@test.com",
                        "full_name": "Test User",
                        "role": "student"
                    }
                }
            }
        }
    }
)
def whoami(
    current_user: User = Depends(get_current_user_sync)
) -> Dict[str, Any]:
    """Get current user information"""
    return {
        "user_id": current_user.user_id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role
    }
