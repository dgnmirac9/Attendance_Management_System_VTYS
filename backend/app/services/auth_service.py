"""Authentication service for user authentication and token management"""

from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_token
)
from app.core.exceptions import AuthenticationError
from app.config import settings
from app.models.user import User
from app.models.token import Token


class AuthService:
    """Service for handling authentication operations"""
    
    def __init__(self):
        """Initialize authentication service"""
        self.access_token_expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    
    def hash_password(self, password: str) -> str:
        """
        Hash password using bcrypt
        
        Args:
            password: Plain text password
            
        Returns:
            Hashed password string
        """
        return hash_password(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """
        Verify password against hash
        
        Args:
            plain_password: Plain text password to verify
            hashed_password: Hashed password to compare against
            
        Returns:
            True if password matches, False otherwise
        """
        return verify_password(plain_password, hashed_password)
    
    def create_access_token(
        self,
        user_id: int,
        email: str,
        role: str,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """
        Create JWT access token for user
        
        Args:
            user_id: User's ID
            email: User's email
            role: User's role (student or instructor)
            expires_delta: Optional custom expiration time
            
        Returns:
            JWT token string
        """
        data = {
            "sub": str(user_id),
            "email": email,
            "role": role
        }
        
        return create_access_token(data, expires_delta)
    
    def decode_token(self, token: str) -> dict:
        """
        Decode and validate JWT token
        
        Args:
            token: JWT token string
            
        Returns:
            Decoded token payload
            
        Raises:
            AuthenticationError: If token is invalid or expired
        """
        return decode_token(token)
    
    def get_token_expiration(self) -> datetime:
        """
        Get token expiration datetime
        
        Returns:
            Datetime when token will expire
        """
        return datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
    
    async def authenticate_user(
        self,
        db: AsyncSession,
        email: str,
        password: str
    ) -> User:
        """
        Authenticate user with email and password
        
        Args:
            db: Database session
            email: User's email
            password: User's plain text password
            
        Returns:
            Authenticated user object
            
        Raises:
            AuthenticationError: If authentication fails
        """
        # Query user by email
        result = await db.execute(
            select(User).where(User.email == email)
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        # Verify password
        if not self.verify_password(password, user.password_hash):
            raise AuthenticationError("Invalid email or password")
        
        return user
    
    def authenticate_user_sync(
        self,
        db: Session,
        email: str,
        password: str
    ) -> User:
        """
        Authenticate user with email and password (synchronous version)
        
        Args:
            db: Database session
            email: User's email
            password: User's plain text password
            
        Returns:
            Authenticated user object
            
        Raises:
            AuthenticationError: If authentication fails
        """
        # Query user by email
        user = db.query(User).filter(User.email == email).first()
        
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        # Verify password
        if not self.verify_password(password, user.password_hash):
            raise AuthenticationError("Invalid email or password")
        
        return user
    
    async def store_token(
        self,
        db: AsyncSession,
        user_id: int,
        token: str
    ) -> Token:
        """
        Store token in database for tracking
        
        Args:
            db: Database session
            user_id: User's ID
            token: JWT token string
            
        Returns:
            Created token object
        """
        token_obj = Token(
            user_id=user_id,
            token=token,
            expires_at=self.get_token_expiration()
        )
        
        db.add(token_obj)
        await db.commit()
        await db.refresh(token_obj)
        
        return token_obj
    
    def store_token_sync(
        self,
        db: Session,
        user_id: int,
        token: str
    ) -> Token:
        """
        Store token in database for tracking (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            token: JWT token string
            
        Returns:
            Created token object
        """
        token_obj = Token(
            user_id=user_id,
            token=token,
            expires_at=self.get_token_expiration()
        )
        
        db.add(token_obj)
        db.commit()
        db.refresh(token_obj)
        
        return token_obj
    
    async def revoke_token(
        self,
        db: AsyncSession,
        token: str
    ) -> bool:
        """
        Revoke (delete) a token from database
        
        Args:
            db: Database session
            token: JWT token string to revoke
            
        Returns:
            True if token was revoked, False if not found
        """
        result = await db.execute(
            select(Token).where(Token.token == token)
        )
        token_obj = result.scalar_one_or_none()
        
        if token_obj:
            await db.delete(token_obj)
            await db.commit()
            return True
        
        return False
    
    def revoke_token_sync(
        self,
        db: Session,
        token: str
    ) -> bool:
        """
        Revoke (delete) a token from database (synchronous version)
        
        Args:
            db: Database session
            token: JWT token string to revoke
            
        Returns:
            True if token was revoked, False if not found
        """
        token_obj = db.query(Token).filter(Token.token == token).first()
        
        if token_obj:
            db.delete(token_obj)
            db.commit()
            return True
        
        return False
    
    async def revoke_all_user_tokens(
        self,
        db: AsyncSession,
        user_id: int
    ) -> int:
        """
        Revoke all tokens for a user
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            Number of tokens revoked
        """
        result = await db.execute(
            select(Token).where(Token.user_id == user_id)
        )
        tokens = result.scalars().all()
        
        count = len(tokens)
        for token in tokens:
            await db.delete(token)
        
        await db.commit()
        return count
    
    async def cleanup_expired_tokens(self, db: AsyncSession) -> int:
        """
        Remove expired tokens from database
        
        Args:
            db: Database session
            
        Returns:
            Number of tokens removed
        """
        now = datetime.utcnow()
        result = await db.execute(
            select(Token).where(Token.expires_at < now)
        )
        expired_tokens = result.scalars().all()
        
        count = len(expired_tokens)
        for token in expired_tokens:
            await db.delete(token)
        
        await db.commit()
        return count
    
    async def validate_token(
        self,
        db: AsyncSession,
        token: str
    ) -> Optional[User]:
        """
        Validate token and return associated user
        
        Args:
            db: Database session
            token: JWT token string
            
        Returns:
            User object if token is valid, None otherwise
            
        Raises:
            AuthenticationError: If token is invalid or expired
        """
        # Decode token
        payload = self.decode_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid token payload")
        
        # Check if token exists in database
        result = await db.execute(
            select(Token).where(Token.token == token)
        )
        token_obj = result.scalar_one_or_none()
        
        if not token_obj:
            raise AuthenticationError("Token not found or revoked")
        
        # Check if token is expired
        if token_obj.expires_at < datetime.utcnow():
            await db.delete(token_obj)
            await db.commit()
            raise AuthenticationError("Token expired")
        
        # Get user
        result = await db.execute(
            select(User).where(User.user_id == int(user_id))
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("User not found")
        
        return user


# Create singleton instance
auth_service = AuthService()
