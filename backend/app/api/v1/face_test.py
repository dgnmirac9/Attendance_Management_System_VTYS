"""Test face endpoints - minimal version"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/test")
def test_endpoint():
    """Test endpoint"""
    return {"message": "Face router is working!"}
