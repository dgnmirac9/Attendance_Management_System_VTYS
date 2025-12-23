with open('backend/app/api/v1/courses.py', 'r', encoding='utf-8') as f:
    content = f.read()

endpoint = '''

@router.delete("/{course_id}", status_code=204)
def delete_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
):
    """Delete a course (instructor only)"""
    from app.services.course_service import course_service
    
    # Check if user is instructor
    if current_user.role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can delete courses")
    
    # Get instructor profile  
    instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
    if not instructor:
        raise HTTPException(status_code=404, detail="Instructor profile not found")
    
    # Get course and verify ownership
    course = course_service.get_course_by_id_sync(db, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    if course.instructor_id != instructor.instructor_id:
        raise HTTPException(status_code=403, detail="You can only delete your own courses")
    
    # Delete course
    from app.models.course import Course
    db.delete(course)
    db.commit()
    
    return None
'''

with open('backend/app/api/v1/courses.py', 'w', encoding='utf-8') as f:
    f.write(content + endpoint)
