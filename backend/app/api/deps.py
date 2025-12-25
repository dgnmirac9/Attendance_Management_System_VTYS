"""API dependencies for authentication and authorization"""

from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.database import get_async_db, get_db
from app.models.user import User, Student, Instructor
from app.core.security import decode_token
from app.core.exceptions import AuthenticationError, AuthorizationError


# HTTP Bearer token security scheme
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_async_db)
) -> User:
    """
    Dependency to get current authenticated user from JWT token
    
    Args:
        credentials: HTTP Bearer token credentials
        db: Database session
        
    Returns:
        Current authenticated user
        
    Raises:
        HTTPException: If authentication fails (401)
    """
    try:
        # Extract token from credentials
        token = credentials.credentials
        
        # Decode and validate token
        payload = decode_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid token payload")
        
        # Get user from database
        result = await db.execute(
            select(User).where(User.user_id == int(user_id))
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("User not found")
        
        return user
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_student(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
) -> Student:
    """
    Dependency to get current authenticated student
    Requires user to have 'student' role
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Current authenticated student
        
    Raises:
        HTTPException: If user is not a student (403)
    """
    try:
        # Check if user has student role
        if current_user.role != "student":
            raise AuthorizationError("User is not a student")
        
        # Get student record
        result = await db.execute(
            select(Student).where(Student.user_id == current_user.user_id)
        )
        student = result.scalar_one_or_none()
        
        if not student:
            raise AuthorizationError("Student record not found")
        
        return student
        
    except AuthorizationError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


async def get_current_instructor(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
) -> Instructor:
    """
    Dependency to get current authenticated instructor
    Requires user to have 'instructor' role
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Current authenticated instructor
        
    Raises:
        HTTPException: If user is not an instructor (403)
    """
    try:
        # Check if user has instructor role
        if current_user.role != "instructor":
            raise AuthorizationError("User is not an instructor")
        
        # Get instructor record
        result = await db.execute(
            select(Instructor).where(Instructor.user_id == current_user.user_id)
        )
        instructor = result.scalar_one_or_none()
        
        if not instructor:
            raise AuthorizationError("Instructor record not found")
        
        return instructor
        
    except AuthorizationError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


def require_role(allowed_roles: list[str]):
    """
    Dependency factory to require specific roles
    
    Args:
        allowed_roles: List of allowed roles (e.g., ['student', 'instructor'])
        
    Returns:
        Dependency function that validates user role
        
    Example:
        @router.get("/admin-only")
        async def admin_endpoint(user: User = Depends(require_role(['instructor']))):
            return {"message": "Admin access granted"}
    """
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        """
        Check if current user has required role
        
        Args:
            current_user: Current authenticated user
            
        Returns:
            Current user if role is allowed
            
        Raises:
            HTTPException: If user doesn't have required role (403)
        """
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {', '.join(allowed_roles)}"
            )
        return current_user
    
    return role_checker


# Optional authentication - returns None if no token provided
async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: AsyncSession = Depends(get_async_db)
) -> Optional[User]:
    """
    Dependency to get current user if authenticated, None otherwise
    Useful for endpoints that work differently for authenticated vs anonymous users
    
    Args:
        credentials: Optional HTTP Bearer token credentials
        db: Database session
        
    Returns:
        Current authenticated user or None
    """
    if not credentials:
        return None
    
    try:
        # Extract token from credentials
        token = credentials.credentials
        
        # Decode and validate token
        payload = decode_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            return None
        
        # Get user from database
        result = await db.execute(
            select(User).where(User.user_id == int(user_id))
        )
        user = result.scalar_one_or_none()
        
        return user
        
    except Exception:
        return None



# ============================================================================
# SYNCHRONOUS VERSIONS (for backward compatibility with sync endpoints)
# ============================================================================

def get_current_user_sync(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Synchronous version of get_current_user dependency
    
    Args:
        credentials: HTTP Bearer token credentials
        db: Synchronous database session
        
    Returns:
        Current authenticated user
        
    Raises:
        HTTPException: If authentication fails (401)
    """
    try:
        # Extract token from credentials
        token = credentials.credentials
        
        # Decode and validate token
        payload = decode_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid token payload")
        
        # Get user from database
        user = db.query(User).filter(User.user_id == int(user_id)).first()
        
        if not user:
            raise AuthenticationError("User not found")
        
        return user
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_student_sync(
    current_user: User = Depends(get_current_user_sync),
    db: Session = Depends(get_db)
) -> Student:
    """
    Synchronous version of get_current_student dependency
    
    Args:
        current_user: Current authenticated user
        db: Synchronous database session
        
    Returns:
        Current authenticated student
        
    Raises:
        HTTPException: If user is not a student (403)
    """
    try:
        # Check if user has student role
        if current_user.role != "student":
            raise AuthorizationError("User is not a student")
        
        # Get student record
        student = db.query(Student).filter(Student.user_id == current_user.user_id).first()
        
        if not student:
            raise AuthorizationError("Student record not found")
        
        return student
        
    except AuthorizationError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


def get_current_instructor_sync(
    current_user: User = Depends(get_current_user_sync),
    db: Session = Depends(get_db)
) -> Instructor:
    """
    Synchronous version of get_current_instructor dependency
    
    Args:
        current_user: Current authenticated user
        db: Synchronous database session
        
    Returns:
        Current authenticated instructor
        
    Raises:
        HTTPException: If user is not an instructor (403)
    """
    try:
        # Check if user has instructor role
        if current_user.role != "instructor":
            raise AuthorizationError("User is not an instructor")
        
        # Get instructor record
        instructor = db.query(Instructor).filter(Instructor.user_id == current_user.user_id).first()
        
        if not instructor:
            raise AuthorizationError("Instructor record not found")
        
        return instructor
        
    except AuthorizationError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
