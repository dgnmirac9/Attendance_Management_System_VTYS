"""User models: User, Student, Instructor"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class User(Base):
    """Base user model for both students and instructors"""
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    role = Column(
        String(20),
        CheckConstraint("role IN ('student', 'instructor')"),
        nullable=False,
        index=True
    )
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, nullable=True, onupdate=func.now())
    
    # Relationships
    student = relationship(
        "Student",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan"
    )
    instructor = relationship(
        "Instructor",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan"
    )
    tokens = relationship(
        "Token",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<User(user_id={self.user_id}, email='{self.email}', role='{self.role}')>"


class Student(Base):
    """Student model with academic information"""
    __tablename__ = "students"
    
    student_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True
    )
    student_number = Column(String(20), unique=True, nullable=False, index=True)
    department = Column(String(100), nullable=False)
    class_level = Column(Integer, CheckConstraint("class_level BETWEEN 1 AND 4"))
    enrollment_year = Column(Integer, nullable=False)
    face_data_url = Column(String(255), nullable=True)
    profile_image_url = Column(String(255), nullable=True)
    total_absences = Column(Integer, default=0)
    
    # Relationships
    user = relationship("User", back_populates="student")
    enrollments = relationship(
        "CourseEnrollment",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    attendance_records = relationship(
        "AttendanceRecord",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    assignment_submissions = relationship(
        "AssignmentSubmission",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    shared_notes = relationship(
        "StudentSharedNote",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    survey_responses = relationship(
        "SurveyResponse",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Student(student_id={self.student_id}, student_number='{self.student_number}')>"


class Instructor(Base):
    """Instructor model with professional information"""
    __tablename__ = "instructors"
    
    instructor_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True
    )
    title = Column(String(50), nullable=True)
    office_info = Column(String(100), nullable=True)
    profile_image_url = Column(String(255), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="instructor")
    courses = relationship(
        "Course",
        back_populates="instructor",
        cascade="all, delete-orphan"
    )
    attendances = relationship(
        "Attendance",
        back_populates="instructor",
        cascade="all, delete-orphan"
    )
    assignments = relationship(
        "Assignment",
        back_populates="instructor",
        cascade="all, delete-orphan"
    )
    announcements = relationship(
        "Announcement",
        back_populates="instructor",
        cascade="all, delete-orphan"
    )
    surveys = relationship(
        "Survey",
        back_populates="instructor",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Instructor(instructor_id={self.instructor_id}, title='{self.title}')>"
