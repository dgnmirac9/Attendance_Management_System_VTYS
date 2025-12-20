with open('backend/app/api/v1/courses.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find insertion point (after line 141, before @router.get)
insert_index = 141  # After line 141 (0-indexed would be 140)

new_endpoint = '''
@router.get(
    "/",
    response_model=List[Dict[str, Any]],
    summary="Get user's courses"
)
def get_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_sync)
) -> List[Dict[str, Any]]:
    """Get courses for current user"""
    try:
        if current_user.role == "instructor":
            instructor = user_service.get_instructor_profile_sync(db, current_user.user_id)
            if not instructor:
                return []
            courses = course_service.get_instructor_courses_sync(db, instructor.instructor_id)
        elif current_user.role == "student":
            student = user_service.get_student_profile_sync(db, current_user.user_id)
            if not student:
                return []
            courses = course_service.get_student_courses_sync(db, student.student_id)
        else:
            return []
        
        result = []
        for course in courses:
            result.append({
                "id": course.course_id,
                "className": course.course_name,
                "teacherId": course.instructor_id,
                "joinCode": course.join_code,
                "studentIds": [],
                "createdAt": course.created_at.isoformat() if course.created_at else None
            })
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get courses: {str(e)}"
        )

'''

lines.insert(insert_index, new_endpoint)

with open('backend/app/api/v1/courses.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Endpoint added successfully")
