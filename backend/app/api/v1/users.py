from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from pydantic import BaseModel

from app.database import get_db
from app.api.deps import get_current_user_sync
from app.models.user import User
from app.schemas.user import UserResponse

router = APIRouter()

class UserBulkRequest(BaseModel):
    user_ids: List[str]  # Mobile sends strings, often

@router.post("/bulk", response_model=List[UserResponse])
def get_users_bulk(
    request: UserBulkRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
):
    """Get multiple users by ID"""
    try:
        # Convert strings to ints if necessary
        ids = [int(uid) for uid in request.user_ids if uid.isdigit()]
        
        users = db.query(User).filter(User.user_id.in_(ids)).all()
        
        return [
            UserResponse(
                user_id=user.user_id,
                email=user.email,
                full_name=user.full_name,
                role=user.role,
                created_at=user.created_at
            ) for user in users
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )
