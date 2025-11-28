"""Survey schemas for request/response validation"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class SurveyBase(BaseModel):
    """Base survey schema"""
    question: str = Field(..., min_length=1)


class SurveyCreate(SurveyBase):
    """Schema for creating a survey"""
    course_id: int = Field(..., gt=0)


class SurveyUpdate(BaseModel):
    """Schema for updating a survey"""
    question: Optional[str] = Field(None, min_length=1)


class SurveyResponse(SurveyBase):
    """Schema for survey response"""
    survey_id: int
    course_id: int
    instructor_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class SurveyDetailResponse(SurveyResponse):
    """Schema for detailed survey with statistics"""
    total_responses: int
    response_rate: float
    instructor_name: str


class SurveyRespondRequest(BaseModel):
    """Schema for responding to a survey"""
    answer: str = Field(..., min_length=1)


class SurveyResponseSubmission(BaseModel):
    """Schema for survey response submission"""
    response_id: int
    survey_id: int
    answered_at: datetime
    message: str = "Survey response submitted successfully"


class SurveyResponseDetail(BaseModel):
    """Schema for individual survey response"""
    response_id: int
    student_id: int
    student_name: str
    student_number: str
    answer: str
    answered_at: datetime
    
    class Config:
        from_attributes = True


class SurveyResponsesListResponse(BaseModel):
    """Schema for list of survey responses"""
    survey_id: int
    question: str
    course_id: int
    total_responses: int
    response_rate: float
    responses: List[SurveyResponseDetail]
