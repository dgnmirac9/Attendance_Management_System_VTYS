"""Course models: Course, CourseEnrollment"""

import secrets
import string
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, UniqueConstraint, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


def generate_join_code(length: int = 6) -> str:
    """Generate a random join code for course enrollment"""
    characters = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(characters) for _ in range(length))


class Course(Base):
    """Course model with instructor and enrollment information"""
    __tablename__ = "courses"
    
    course_id = Column(Integer, primary_key=True, index=True)
    instructor_id = Column(
        Integer,
        ForeignKey("instructors.instructor_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    course_name = Column(String(100), nullable=False)
    course_code = Column(String(20), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    semester = Column(String(20), nullable=False)
    year = Column(Integer, nullable=False)
    credits = Column(Integer, nullable=True)
    max_students = Column(Integer, nullable=True)
    join_code = Column(String(10), unique=True, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    
    # Relationships
    instructor = relationship("Instructor", back_populates="courses")
    enrollments = relationship(
        "CourseEnrollment",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    attendances = relationship(
        "Attendance",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    assignments = relationship(
        "Assignment",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    announcements = relationship(
        "Announcement",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    shared_notes = relationship(
        "StudentSharedNote",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    surveys = relationship(
        "Survey",
        back_populates="course",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Course(course_id={self.course_id}, course_code='{self.course_code}', name='{self.course_name}')>"
    
    @staticmethod
    def create_unique_join_code():
        """Create a unique join code"""
        return generate_join_code()


class CourseEnrollment(Base):
    """Course enrollment model (Many-to-Many: Students <-> Courses)"""
    __tablename__ = "course_enrollments"
    
    enrollment_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer,
        ForeignKey("students.student_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    course_id = Column(
        Integer,
        ForeignKey("courses.course_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    enrollment_status = Column(String(20), default="active", nullable=False)
    joined_at = Column(DateTime, server_default=func.now())
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    student = relationship("Student", back_populates="enrollments")
    course = relationship("Course", back_populates="enrollments")
    
    # Unique constraint to prevent duplicate enrollments
    __table_args__ = (
        UniqueConstraint('student_id', 'course_id', name='uq_student_course'),
    )
    
    def __repr__(self):
        return f"<CourseEnrollment(enrollment_id={self.enrollment_id}, student_id={self.student_id}, course_id={self.course_id})>"
