"""User service for user management operations"""

from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from app.models.user import User, Student, Instructor
from app.schemas.user import UserCreate, UserUpdate
from app.services.auth_service import auth_service
from app.core.exceptions import AppException


class UserService:
    """Service for handling user operations"""
    
    async def create_user(
        self,
        db: AsyncSession,
        user_data: UserCreate
    ) -> User:
        """
        Create a new user (student or instructor)
        
        Args:
            db: Database session
            user_data: User creation data
            
        Returns:
            Created user object
            
        Raises:
            AppException: If user creation fails or email already exists
        """
        # Check if email already exists
        result = await db.execute(
            select(User).where(User.email == user_data.email)
        )
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise AppException(
                message="Email already registered",
                status_code=409
            )
        
        # Hash password
        password_hash = auth_service.hash_password(user_data.password)
        
        # Create user
        user = User(
            email=user_data.email,
            password_hash=password_hash,
            full_name=user_data.full_name,
            role=user_data.role
        )
        
        db.add(user)
        await db.flush()  # Flush to get user_id
        
        # Create role-specific record
        if user_data.role == "student":
            student = Student(
                user_id=user.user_id,
                student_number=user_data.student_number
            )
            db.add(student)
        elif user_data.role == "instructor":
            instructor = Instructor(
                user_id=user.user_id,
                instructor_number=user_data.instructor_number
            )
            db.add(instructor)
        
        await db.commit()
        await db.refresh(user)
        
        return user
    
    def create_user_sync(
        self,
        db: Session,
        user_data: UserCreate
    ) -> User:
        """
        Create a new user (synchronous version)
        
        Args:
            db: Database session
            user_data: User creation data
            
        Returns:
            Created user object
            
        Raises:
            AppException: If user creation fails or email already exists
        """
        # Check if email already exists
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        
        if existing_user:
            raise AppException(
                message="Email already registered",
                status_code=409
            )
        
        # Check if student/instructor number already exists
        if user_data.role == "student" and user_data.student_number:
            existing_student = db.query(Student).filter(
                Student.student_number == user_data.student_number
            ).first()
            if existing_student:
                raise AppException(
                    message="Student number already registered",
                    status_code=409
                )
        elif user_data.role == "instructor" and user_data.instructor_number:
            existing_instructor = db.query(Instructor).filter(
                Instructor.instructor_number == user_data.instructor_number
            ).first()
            if existing_instructor:
                raise AppException(
                    message="Instructor number already registered",
                    status_code=409
                )
        
        # Hash password
        password_hash = auth_service.hash_password(user_data.password)
        
        # Create user
        user = User(
            email=user_data.email,
            password_hash=password_hash,
            full_name=user_data.full_name,
            role=user_data.role
        )
        
        db.add(user)
        db.flush()  # Flush to get user_id
        
        # Create role-specific record
        if user_data.role == "student":
            student = Student(
                user_id=user.user_id,
                student_number=user_data.student_number
            )
            db.add(student)
        elif user_data.role == "instructor":
            instructor = Instructor(
                user_id=user.user_id,
                instructor_number=user_data.instructor_number
            )
            db.add(instructor)
        
        db.commit()
        db.refresh(user)
        
        return user
    
    async def get_user_by_id(
        self,
        db: AsyncSession,
        user_id: int
    ) -> Optional[User]:
        """
        Get user by ID
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            User object or None if not found
        """
        result = await db.execute(
            select(User).where(User.user_id == user_id)
        )
        return result.scalar_one_or_none()
    
    def get_user_by_id_sync(
        self,
        db: Session,
        user_id: int
    ) -> Optional[User]:
        """
        Get user by ID (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            User object or None if not found
        """
        return db.query(User).filter(User.user_id == user_id).first()
    
    async def get_user_by_email(
        self,
        db: AsyncSession,
        email: str
    ) -> Optional[User]:
        """
        Get user by email
        
        Args:
            db: Database session
            email: User's email
            
        Returns:
            User object or None if not found
        """
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    def get_user_by_email_sync(
        self,
        db: Session,
        email: str
    ) -> Optional[User]:
        """
        Get user by email (synchronous version)
        
        Args:
            db: Database session
            email: User's email
            
        Returns:
            User object or None if not found
        """
        return db.query(User).filter(User.email == email).first()
    
    async def update_user(
        self,
        db: AsyncSession,
        user_id: int,
        user_data: UserUpdate
    ) -> User:
        """
        Update user information
        
        Args:
            db: Database session
            user_id: User's ID
            user_data: User update data
            
        Returns:
            Updated user object
            
        Raises:
            AppException: If user not found or update fails
        """
        # Get user
        user = await self.get_user_by_id(db, user_id)
        if not user:
            raise AppException(
                message="User not found",
                status_code=404
            )
        
        # Update fields if provided
        if user_data.full_name is not None:
            user.full_name = user_data.full_name
        
        if user_data.email is not None and user_data.email != user.email:
            # Check if new email already exists
            existing_user = await self.get_user_by_email(db, user_data.email)
            if existing_user:
                raise AppException(
                    message="Email already registered",
                    status_code=409
                )
            user.email = user_data.email
        
        if user_data.password is not None:
            user.password_hash = auth_service.hash_password(user_data.password)
        
        # Update role-specific fields
        if user.role == "student":
            result = await db.execute(
                select(Student).where(Student.user_id == user_id)
            )
            student = result.scalar_one_or_none()
            
            if student:
                # Removed: student fields update
                pass
        
        elif user.role == "instructor":
            result = await db.execute(
                select(Instructor).where(Instructor.user_id == user_id)
            )
            instructor = result.scalar_one_or_none()
            
            if instructor:
                # Removed: instructor fields update
                pass
        
        await db.commit()
        await db.refresh(user)
        
        return user
    
    def update_user_sync(
        self,
        db: Session,
        user_id: int,
        user_data: UserUpdate
    ) -> User:
        """
        Update user information (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            user_data: User update data
            
        Returns:
            Updated user object
            
        Raises:
            AppException: If user not found or update fails
        """
        # Get user
        user = self.get_user_by_id_sync(db, user_id)
        if not user:
            raise AppException(
                message="User not found",
                status_code=404
            )
        
        # Update fields if provided
        if user_data.full_name is not None:
            user.full_name = user_data.full_name
        
        if user_data.email is not None and user_data.email != user.email:
            # Check if new email already exists
            existing_user = self.get_user_by_email_sync(db, user_data.email)
            if existing_user:
                raise AppException(
                    message="Email already registered",
                    status_code=409
                )
            user.email = user_data.email
        
        if user_data.password is not None:
            user.password_hash = auth_service.hash_password(user_data.password)
        
        # Update role-specific fields
        if user.role == "student":
            student = db.query(Student).filter(Student.user_id == user_id).first()
            
            if student:
                # Removed: student fields update
                pass
        
        elif user.role == "instructor":
            instructor = db.query(Instructor).filter(Instructor.user_id == user_id).first()
            
            if instructor:
                # Removed: instructor fields update
                pass
        
        db.commit()
        db.refresh(user)
        
        return user
    
    async def get_student_profile(
        self,
        db: AsyncSession,
        user_id: int
    ) -> Optional[Student]:
        """
        Get student profile with user information
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            Student object or None if not found
        """
        result = await db.execute(
            select(Student).where(Student.user_id == user_id)
        )
        return result.scalar_one_or_none()
    
    def get_student_profile_sync(
        self,
        db: Session,
        user_id: int
    ) -> Optional[Student]:
        """
        Get student profile (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            Student object or None if not found
        """
        return db.query(Student).filter(Student.user_id == user_id).first()
    
    async def get_instructor_profile(
        self,
        db: AsyncSession,
        user_id: int
    ) -> Optional[Instructor]:
        """
        Get instructor profile with user information
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            Instructor object or None if not found
        """
        result = await db.execute(
            select(Instructor).where(Instructor.user_id == user_id)
        )
        return result.scalar_one_or_none()
    
    def get_instructor_profile_sync(
        self,
        db: Session,
        user_id: int
    ) -> Optional[Instructor]:
        """
        Get instructor profile (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            Instructor object or None if not found
        """
        return db.query(Instructor).filter(Instructor.user_id == user_id).first()
    
    async def delete_user(
        self,
        db: AsyncSession,
        user_id: int
    ) -> bool:
        """
        Delete user and associated records
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            True if deleted, False if not found
        """
        user = await self.get_user_by_id(db, user_id)
        if not user:
            return False
        
        await db.delete(user)
        await db.commit()
        
        return True
    
    def delete_user_sync(
        self,
        db: Session,
        user_id: int
    ) -> bool:
        """
        Delete user and associated records (synchronous version)
        
        Args:
            db: Database session
            user_id: User's ID
            
        Returns:
            True if deleted, False if not found
        """
        user = self.get_user_by_id_sync(db, user_id)
        if not user:
            return False
        
        db.delete(user)
        db.commit()
        
        return True


# Create singleton instance
user_service = UserService()
