"""Course service for course management operations"""

import string
import random
from typing import Optional, List
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.course import Course, CourseEnrollment
from app.models.user import User, Student, Instructor
from app.schemas.course import CourseCreate, CourseUpdate
from app.core.exceptions import AppException


class CourseService:
    """Service for handling course operations"""
    
    def generate_join_code(self, length: int = 6) -> str:
        """
        Generate a unique join code for course enrollment
        
        Args:
            length: Length of the join code (default 6)
            
        Returns:
            Random alphanumeric join code
        """
        characters = string.ascii_uppercase + string.digits
        return ''.join(random.choice(characters) for _ in range(length))
    
    async def create_course(
        self,
        db: AsyncSession,
        course_data: CourseCreate,
        instructor_id: int
    ) -> Course:
        """
        Create a new course
        
        Args:
            db: Database session
            course_data: Course creation data
            instructor_id: ID of the instructor creating the course
            
        Returns:
            Created course object
            
        Raises:
            AppException: If course creation fails
        """
        try:
            # Generate unique join code
            join_code = self.generate_join_code()
            
            # Ensure join code is unique
            while await self._join_code_exists(db, join_code):
                join_code = self.generate_join_code()
            
            # Create course
            course = Course(
                course_name=course_data.course_name,
                course_code=course_data.course_name[:3].upper() + str(random.randint(100, 999)) if len(course_data.course_name) >= 3 else "CSE" + str(random.randint(100, 999)),
                description=course_data.description,
                instructor_id=instructor_id,
                join_code=join_code,
                semester=course_data.semester,
                year=datetime.now().year,
                credits=course_data.credits,
                max_students=course_data.max_students,
                is_active=True
            )
            
            db.add(course)
            await db.commit()
            await db.refresh(course)
            
            return course
            
        except Exception as e:
            await db.rollback()
            raise AppException(
                message=f"Course creation failed: {str(e)}",
                status_code=500
            )
    
    def create_course_sync(
        self,
        db: Session,
        course_data: CourseCreate,
        instructor_id: int
    ) -> Course:
        """
        Create a new course (synchronous version)
        
        Args:
            db: Database session
            course_data: Course creation data
            instructor_id: ID of the instructor creating the course
            
        Returns:
            Created course object
            
        Raises:
            AppException: If course creation fails
        """
        try:
            # Generate unique join code
            join_code = self.generate_join_code()
            
            # Ensure join code is unique
            while self._join_code_exists_sync(db, join_code):
                join_code = self.generate_join_code()
            
            # Create course
            course = Course(
                course_name=course_data.course_name,
                course_code=course_data.course_name[:3].upper() + str(random.randint(100, 999)) if len(course_data.course_name) >= 3 else "CSE" + str(random.randint(100, 999)),
                description=course_data.description,
                instructor_id=instructor_id,
                join_code=join_code,
                semester=course_data.semester,
                year=datetime.now().year,
                credits=course_data.credits,
                max_students=course_data.max_students,
                is_active=True
            )
            
            db.add(course)
            db.commit()
            db.refresh(course)
            
            return course
            
        except Exception as e:
            db.rollback()
            raise AppException(
                message=f"Course creation failed: {str(e)}",
                status_code=500
            )
    
    async def get_course_by_id(
        self,
        db: AsyncSession,
        course_id: int
    ) -> Optional[Course]:
        """
        Get course by ID
        
        Args:
            db: Database session
            course_id: Course ID
            
        Returns:
            Course object or None if not found
        """
        result = await db.execute(
            select(Course).where(Course.course_id == course_id)
        )
        return result.scalar_one_or_none()
    
    def get_course_by_id_sync(
        self,
        db: Session,
        course_id: int
    ) -> Optional[Course]:
        """
        Get course by ID (synchronous version)
        
        Args:
            db: Database session
            course_id: Course ID
            
        Returns:
            Course object or None if not found
        """
        return db.query(Course).filter(Course.course_id == course_id).first()
    
    async def get_course_by_join_code(
        self,
        db: AsyncSession,
        join_code: str
    ) -> Optional[Course]:
        """
        Get course by join code
        
        Args:
            db: Database session
            join_code: Course join code
            
        Returns:
            Course object or None if not found
        """
        result = await db.execute(
            select(Course).where(
                and_(
                    Course.join_code == join_code,
                    Course.is_active == True
                )
            )
        )
        return result.scalar_one_or_none()
    
    def get_course_by_join_code_sync(
        self,
        db: Session,
        join_code: str
    ) -> Optional[Course]:
        """
        Get course by join code (synchronous version)
        
        Args:
            db: Database session
            join_code: Course join code
            
        Returns:
            Course object or None if not found
        """
        return db.query(Course).filter(
            and_(
                Course.join_code == join_code,
                Course.is_active == True
            )
        ).first()
    
    async def update_course(
        self,
        db: AsyncSession,
        course_id: int,
        course_data: CourseUpdate,
        instructor_id: int
    ) -> Course:
        """
        Update course information
        
        Args:
            db: Database session
            course_id: Course ID
            course_data: Course update data
            instructor_id: ID of the instructor (for authorization)
            
        Returns:
            Updated course object
            
        Raises:
            AppException: If course not found or update fails
        """
        course = await self.get_course_by_id(db, course_id)
        if not course:
            raise AppException(
                message="Course not found",
                status_code=404
            )
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to update this course",
                status_code=403
            )
        
        # Update fields if provided
        if course_data.course_name is not None:
            course.course_name = course_data.course_name
        if course_data.description is not None:
            course.description = course_data.description
        if course_data.semester is not None:
            course.semester = course_data.semester
        if course_data.year is not None:
            course.year = course_data.year
        if course_data.credits is not None:
            course.credits = course_data.credits
        if course_data.max_students is not None:
            course.max_students = course_data.max_students
        if course_data.is_active is not None:
            course.is_active = course_data.is_active
        
        await db.commit()
        await db.refresh(course)
        
        return course
    
    async def delete_course(
        self,
        db: AsyncSession,
        course_id: int,
        instructor_id: int
    ) -> bool:
        """
        Delete (deactivate) a course
        
        Args:
            db: Database session
            course_id: Course ID
            instructor_id: ID of the instructor (for authorization)
            
        Returns:
            True if deleted, False if not found
            
        Raises:
            AppException: If permission denied
        """
        course = await self.get_course_by_id(db, course_id)
        if not course:
            return False
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to delete this course",
                status_code=403
            )
        
        # Soft delete (deactivate)
        course.is_active = False
        await db.commit()
        
        return True
    
    async def list_instructor_courses(
        self,
        db: AsyncSession,
        instructor_id: int,
        include_inactive: bool = False
    ) -> List[Course]:
        """
        List courses taught by an instructor
        
        Args:
            db: Database session
            instructor_id: Instructor ID
            include_inactive: Whether to include inactive courses
            
        Returns:
            List of courses
        """
        query = select(Course).where(Course.instructor_id == instructor_id)
        
        if not include_inactive:
            query = query.where(Course.is_active == True)
        
        result = await db.execute(query.order_by(Course.created_at.desc()))
        return result.scalars().all()
    
    def list_instructor_courses_sync(
        self,
        db: Session,
        instructor_id: int,
        include_inactive: bool = False
    ) -> List[Course]:
        """
        List courses taught by an instructor (synchronous version)
        
        Args:
            db: Database session
            instructor_id: Instructor ID
            include_inactive: Whether to include inactive courses
            
        Returns:
            List of courses
        """
        query = db.query(Course).filter(Course.instructor_id == instructor_id)
        
        if not include_inactive:
            query = query.filter(Course.is_active == True)
        
        return query.order_by(Course.created_at.desc()).all()
    
    async def join_course_by_code(
        self,
        db: AsyncSession,
        join_code: str,
        student_id: int
    ) -> CourseEnrollment:
        """
        Enroll student in course using join code
        
        Args:
            db: Database session
            join_code: Course join code
            student_id: Student ID
            
        Returns:
            Course enrollment object
            
        Raises:
            AppException: If course not found, already enrolled, or course full
        """
        # Find course by join code
        course = await self.get_course_by_join_code(db, join_code)
        if not course:
            raise AppException(
                message="Invalid join code or course not active",
                status_code=404
            )
        
        # Check if already enrolled
        existing_enrollment = await self._get_enrollment(db, course.course_id, student_id)
        if existing_enrollment:
            if existing_enrollment.enrollment_status == "active":
                raise AppException(
                    message="You are already enrolled in this course",
                    status_code=409
                )
            # If dropped, reactivate
            existing_enrollment.enrollment_status = "active"
            existing_enrollment.joined_at = datetime.now() # Update join time
            await db.commit()
            await db.refresh(existing_enrollment)
            return existing_enrollment
        
        # Check course capacity
        if course.max_students:
            current_count = await self._get_enrollment_count(db, course.course_id)
            if current_count >= course.max_students:
                raise AppException(
                    message="Course is full",
                    status_code=409
                )
        
        # Create enrollment
        enrollment = CourseEnrollment(
            course_id=course.course_id,
            student_id=student_id,
            enrollment_status="active"
        )
        
        db.add(enrollment)
        await db.commit()
        await db.refresh(enrollment)
        
        return enrollment
    
    def join_course_by_code_sync(
        self,
        db: Session,
        join_code: str,
        student_id: int
    ) -> CourseEnrollment:
        """
        Enroll student in course using join code (synchronous version)
        
        Args:
            db: Database session
            join_code: Course join code
            student_id: Student ID
            
        Returns:
            Course enrollment object
            
        Raises:
            AppException: If course not found, already enrolled, or course full
        """
        # Find course by join code
        course = self.get_course_by_join_code_sync(db, join_code)
        if not course:
            raise AppException(
                message="Invalid join code or course not active",
                status_code=404
            )
        
        # Check if already enrolled
        existing_enrollment = self._get_enrollment_sync(db, course.course_id, student_id)
        if existing_enrollment:
            if existing_enrollment.enrollment_status == "active":
                raise AppException(
                    message="You are already enrolled in this course",
                    status_code=409
                )
            # If dropped, reactivate
            existing_enrollment.enrollment_status = "active"
            existing_enrollment.joined_at = datetime.now()
            db.commit()
            db.refresh(existing_enrollment)
            return existing_enrollment
        
        # Check course capacity
        if course.max_students:
            current_count = self._get_enrollment_count_sync(db, course.course_id)
            if current_count >= course.max_students:
                raise AppException(
                    message="Course is full",
                    status_code=409
                )
        
        # Create enrollment
        enrollment = CourseEnrollment(
            course_id=course.course_id,
            student_id=student_id,
            enrollment_status="active"
        )
        
        db.add(enrollment)
        db.commit()
        db.refresh(enrollment)
        
        return enrollment
    
    async def get_course_students(
        self,
        db: AsyncSession,
        course_id: int,
        instructor_id: int
    ) -> List[Student]:
        """
        Get list of students enrolled in a course
        
        Args:
            db: Database session
            course_id: Course ID
            instructor_id: Instructor ID (for authorization)
            
        Returns:
            List of enrolled students
            
        Raises:
            AppException: If course not found or permission denied
        """
        course = await self.get_course_by_id(db, course_id)
        if not course:
            raise AppException(
                message="Course not found",
                status_code=404
            )
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to view this course's students",
                status_code=403
            )
        
        # Get enrolled students
        result = await db.execute(
            select(Student)
            .join(CourseEnrollment, Student.student_id == CourseEnrollment.student_id)
            .where(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.enrollment_status == "active"
                )
            )
            .order_by(Student.student_number)
        )
        
        return result.scalars().all()
    
    def get_course_students_sync(
        self,
        db: Session,
        course_id: int,
        instructor_id: int
    ) -> List[Student]:
        """
        Get list of students enrolled in a course (synchronous version)
        
        Args:
            db: Database session
            course_id: Course ID
            instructor_id: Instructor ID (for authorization)
            
        Returns:
            List of enrolled students
            
        Raises:
            AppException: If course not found or permission denied
        """
        course = self.get_course_by_id_sync(db, course_id)
        if not course:
            raise AppException(
                message="Course not found",
                status_code=404
            )
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to view this course's students",
                status_code=403
            )
        
        # Get enrolled students
        from app.models.user import Student
        students = db.query(Student)\
            .join(CourseEnrollment, Student.student_id == CourseEnrollment.student_id)\
            .filter(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.enrollment_status == "active"
                )
            )\
            .order_by(Student.student_number)\
            .all()
        
        return students
    
    def get_course_students_for_student_sync(
        self,
        db: Session,
        course_id: int,
        student_id: int
    ) -> List[Student]:
        """
        Get list of students enrolled in a course (for student view)
        
        Args:
            db: Database session
            course_id: Course ID
            student_id: Requesting Student ID (for enrollment check)
            
        Returns:
            List of enrolled students
            
        Raises:
            AppException: If course not found or not enrolled
        """
        # Check enrollment
        if not self.check_enrollment_sync(db, course_id, student_id):
            raise AppException(
                message="You are not enrolled in this course",
                status_code=403
            )
        
        # Get enrolled students
        from app.models.user import Student
        students = db.query(Student)\
            .join(CourseEnrollment, Student.student_id == CourseEnrollment.student_id)\
            .filter(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.enrollment_status == "active"
                )
            )\
            .order_by(Student.student_number)\
            .all()
        
        return students
    
    def update_course_sync(
        self,
        db: Session,
        course_id: int,
        course_data: CourseUpdate,
        instructor_id: int
    ) -> Course:
        """
        Update course information (synchronous version)
        
        Args:
            db: Database session
            course_id: Course ID
            course_data: Course update data
            instructor_id: ID of the instructor (for authorization)
            
        Returns:
            Updated course object
            
        Raises:
            AppException: If course not found or update fails
        """
        course = self.get_course_by_id_sync(db, course_id)
        if not course:
            raise AppException(
                message="Course not found",
                status_code=404
            )
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to update this course",
                status_code=403
            )
        
        # Update fields if provided
        if course_data.course_name is not None:
            course.course_name = course_data.course_name
        if course_data.description is not None:
            course.description = course_data.description
        if course_data.semester is not None:
            course.semester = course_data.semester
        if course_data.year is not None:
            course.year = course_data.year
        if course_data.credits is not None:
            course.credits = course_data.credits
        if course_data.max_students is not None:
            course.max_students = course_data.max_students
        if course_data.is_active is not None:
            course.is_active = course_data.is_active
        
        db.commit()
        db.refresh(course)
        
        return course
    
    def delete_course_sync(
        self,
        db: Session,
        course_id: int,
        instructor_id: int
    ) -> bool:
        """
        Delete (deactivate) a course (synchronous version)
        
        Args:
            db: Database session
            course_id: Course ID
            instructor_id: ID of the instructor (for authorization)
            
        Returns:
            True if deleted, False if not found
            
        Raises:
            AppException: If permission denied
        """
        course = self.get_course_by_id_sync(db, course_id)
        if not course:
            return False
        
        # Check if instructor owns the course
        if course.instructor_id != instructor_id:
            raise AppException(
                message="You don't have permission to delete this course",
                status_code=403
            )
        
        # Soft delete (deactivate)
        course.is_active = False
        db.commit()
        
        return True
    
    async def list_student_courses(
        self,
        db: AsyncSession,
        student_id: int
    ) -> List[Course]:
        """
        List courses a student is enrolled in
        
        Args:
            db: Database session
            student_id: Student ID
            
        Returns:
            List of enrolled courses
        """
        result = await db.execute(
            select(Course)
            .join(CourseEnrollment, Course.course_id == CourseEnrollment.course_id)
            .where(
                and_(
                    CourseEnrollment.student_id == student_id,
                    CourseEnrollment.enrollment_status == "active",
                    Course.is_active == True
                )
            )
            .order_by(Course.course_name)
        )
        
        return result.scalars().all()
    
    def list_student_courses_sync(
        self,
        db: Session,
        student_id: int
    ) -> List[Course]:
        """
        List courses a student is enrolled in (synchronous version)
        
        Args:
            db: Database session
            student_id: Student ID
            
        Returns:
            List of enrolled courses
        """
        return db.query(Course)\
            .join(CourseEnrollment, Course.course_id == CourseEnrollment.course_id)\
            .filter(
                and_(
                    CourseEnrollment.student_id == student_id,
                    CourseEnrollment.enrollment_status == "active",
                    Course.is_active == True
                )
            )\
            .order_by(Course.course_name)\
            .all()
    
    async def check_enrollment(
        self,
        db: AsyncSession,
        course_id: int,
        student_id: int
    ) -> bool:
        """
        Check if student is enrolled in course
        
        Args:
            db: Database session
            course_id: Course ID
            student_id: Student ID
            
        Returns:
            True if enrolled, False otherwise
        """
        enrollment = await self._get_enrollment(db, course_id, student_id)
        return enrollment is not None and enrollment.enrollment_status == "active"
    
    def _get_enrollment_sync(
        self,
        db: Session,
        course_id: int,
        student_id: int
    ) -> Optional[CourseEnrollment]:
        """
        Get enrollment record (internal helper)
        
        Args:
            db: Database session
            course_id: Course ID
            student_id: Student ID
            
        Returns:
            Enrollment object or None
        """
        return db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == course_id,
                CourseEnrollment.student_id == student_id
            )
        ).first()

    def check_enrollment_sync(
        self,
        db: Session,
        course_id: int,

        student_id: int
    ) -> bool:
        """
        Check if student is enrolled in course (synchronous version)
        
        Args:
            db: Database session
            course_id: Course ID
            student_id: Student ID
            
        Returns:
            True if enrolled, False otherwise
        """
        enrollment = self._get_enrollment_sync(db, course_id, student_id)
        return enrollment is not None and enrollment.enrollment_status == "active"
    
    # Helper methods
    async def _join_code_exists(self, db: AsyncSession, join_code: str) -> bool:
        """Check if join code already exists"""
        result = await db.execute(
            select(Course).where(Course.join_code == join_code)
        )
        return result.scalar_one_or_none() is not None
    
    def _join_code_exists_sync(self, db: Session, join_code: str) -> bool:
        """Check if join code already exists (sync)"""
        return db.query(Course).filter(Course.join_code == join_code).first() is not None
    
    async def _get_enrollment(
        self,
        db: AsyncSession,
        course_id: int,
        student_id: int
    ) -> Optional[CourseEnrollment]:
        """Get enrollment record"""
        result = await db.execute(
            select(CourseEnrollment).where(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.student_id == student_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    def _get_enrollment_sync(
        self,
        db: Session,
        course_id: int,
        student_id: int
    ) -> Optional[CourseEnrollment]:
        """Get enrollment record (sync)"""
        return db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == course_id,
                CourseEnrollment.student_id == student_id
            )
        ).first()
    
    async def _get_enrollment_count(self, db: AsyncSession, course_id: int) -> int:
        """Get number of active enrollments"""
        result = await db.execute(
            select(CourseEnrollment).where(
                and_(
                    CourseEnrollment.course_id == course_id,
                    CourseEnrollment.enrollment_status == "active"
                )
            )
        )
        return len(result.scalars().all())
    
    def _get_enrollment_count_sync(self, db: Session, course_id: int) -> int:
        """Get number of active enrollments (sync)"""
        return db.query(CourseEnrollment).filter(
            and_(
                CourseEnrollment.course_id == course_id,
                CourseEnrollment.enrollment_status == "active"
            )
        ).count()


# Create singleton instance
course_service = CourseService()