#!/usr/bin/env python3
"""Activate course for attendance"""
import sys
sys.path.insert(0, '/app')

from app.database import SessionLocal
from app.models.course import Course

db = SessionLocal()
try:
    course = db.query(Course).filter(Course.course_id == 1).first()
    if course:
        course.is_active = True
        db.commit()
        print(f"Course {course.course_id} activated: is_active = {course.is_active}")
    else:
        print("Course not found")
finally:
    db.close()
