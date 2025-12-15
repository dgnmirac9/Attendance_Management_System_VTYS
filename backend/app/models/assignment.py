"""Assignment models: Assignment, AssignmentSubmission"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Numeric, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Assignment(Base):
    """Assignment model created by instructors"""
    __tablename__ = "assignments"
    
    assignment_id = Column(Integer, primary_key=True, index=True)
    course_id = Column(
        Integer,
        ForeignKey("courses.course_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    instructor_id = Column(
        Integer,
        ForeignKey("instructors.instructor_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    due_date = Column(DateTime, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    course = relationship("Course", back_populates="assignments")
    instructor = relationship("Instructor", back_populates="assignments")
    submissions = relationship(
        "AssignmentSubmission",
        back_populates="assignment",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Assignment(assignment_id={self.assignment_id}, title='{self.title}', course_id={self.course_id})>"


class AssignmentSubmission(Base):
    """Student submission for an assignment"""
    __tablename__ = "assignment_submissions"
    
    submission_id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(
        Integer,
        ForeignKey("assignments.assignment_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    student_id = Column(
        Integer,
        ForeignKey("students.student_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    file_url = Column(String(255), nullable=True)
    submitted_at = Column(DateTime, nullable=True)
    status = Column(
        String(20),
        CheckConstraint("status IN ('atandı', 'teslim edilmedi', 'tamamlandı')"),
        default='atandı'
    )
    grade = Column(Numeric(4, 2), nullable=True)
    
    # Relationships
    assignment = relationship("Assignment", back_populates="submissions")
    student = relationship("Student", back_populates="assignment_submissions")
    
    # Unique constraint to prevent duplicate submissions
    __table_args__ = (
        UniqueConstraint('assignment_id', 'student_id', name='uq_assignment_student'),
    )
    
    def __repr__(self):
        return f"<AssignmentSubmission(submission_id={self.submission_id}, assignment_id={self.assignment_id}, student_id={self.student_id}, status='{self.status}')>"
