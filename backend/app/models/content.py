"""Content sharing models: Announcement, StudentSharedNote, Survey, SurveyResponse"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Announcement(Base):
    """Announcement model for course content (announcements, notes, resources)"""
    __tablename__ = "announcements"
    
    announcement_id = Column(Integer, primary_key=True, index=True)
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
    type = Column(
        String(20),
        CheckConstraint("type IN ('duyuru', 'not', 'kaynak')"),
        nullable=False
    )
    title = Column(String(100), nullable=False)
    content = Column(Text, nullable=True)
    attachment_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    course = relationship("Course", back_populates="announcements")
    instructor = relationship("Instructor", back_populates="announcements")
    
    def __repr__(self):
        return f"<Announcement(announcement_id={self.announcement_id}, type='{self.type}', title='{self.title}')>"


class StudentSharedNote(Base):
    """Student-shared notes model for collaborative learning"""
    __tablename__ = "student_shared_notes"
    
    note_id = Column(Integer, primary_key=True, index=True)
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
    title = Column(String(100), nullable=False)
    content = Column(Text, nullable=True)
    file_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    student = relationship("Student", back_populates="shared_notes")
    course = relationship("Course", back_populates="shared_notes")
    
    def __repr__(self):
        return f"<StudentSharedNote(note_id={self.note_id}, title='{self.title}', student_id={self.student_id})>"


class Survey(Base):
    """Survey model created by instructors for feedback"""
    __tablename__ = "surveys"
    
    survey_id = Column(Integer, primary_key=True, index=True)
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
    question = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    course = relationship("Course", back_populates="surveys")
    instructor = relationship("Instructor", back_populates="surveys")
    responses = relationship(
        "SurveyResponse",
        back_populates="survey",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Survey(survey_id={self.survey_id}, question='{self.question[:50]}...')>"


class SurveyResponse(Base):
    """Student response to a survey"""
    __tablename__ = "survey_responses"
    
    response_id = Column(Integer, primary_key=True, index=True)
    survey_id = Column(
        Integer,
        ForeignKey("surveys.survey_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    student_id = Column(
        Integer,
        ForeignKey("students.student_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    answer = Column(Text, nullable=False)
    answered_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    survey = relationship("Survey", back_populates="responses")
    student = relationship("Student", back_populates="survey_responses")
    
    # Unique constraint to ensure one response per student per survey
    __table_args__ = (
        UniqueConstraint('survey_id', 'student_id', name='uq_survey_student'),
    )
    
    def __repr__(self):
        return f"<SurveyResponse(response_id={self.response_id}, survey_id={self.survey_id}, student_id={self.student_id})>"
