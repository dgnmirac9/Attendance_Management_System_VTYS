"""Attendance models: Attendance, AttendanceRecord"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Numeric, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Attendance(Base):
    """Attendance session model created by instructors"""
    __tablename__ = "attendances"
    
    attendance_id = Column(Integer, primary_key=True, index=True)
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
    attendance_date = Column(DateTime, server_default=func.now())
    is_active = Column(Boolean, default=True)
    
    # Relationships
    course = relationship("Course", back_populates="attendances")
    instructor = relationship("Instructor", back_populates="attendances")
    records = relationship(
        "AttendanceRecord",
        back_populates="attendance",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Attendance(attendance_id={self.attendance_id}, course_id={self.course_id}, is_active={self.is_active})>"


class AttendanceRecord(Base):
    """Individual student attendance record for a session"""
    __tablename__ = "attendance_records"
    
    record_id = Column(Integer, primary_key=True, index=True)
    attendance_id = Column(
        Integer,
        ForeignKey("attendances.attendance_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    student_id = Column(
        Integer,
        ForeignKey("students.student_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    recognized = Column(Boolean, default=False)
    accuracy_percentage = Column(Numeric(5, 2), nullable=True)
    location_info = Column(String(255), nullable=True)
    joined_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    attendance = relationship("Attendance", back_populates="records")
    student = relationship("Student", back_populates="attendance_records")
    
    # Unique constraint to prevent duplicate attendance records
    __table_args__ = (
        UniqueConstraint('attendance_id', 'student_id', name='uq_attendance_student'),
    )
    
    def __repr__(self):
        return f"<AttendanceRecord(record_id={self.record_id}, student_id={self.student_id}, recognized={self.recognized})>"
