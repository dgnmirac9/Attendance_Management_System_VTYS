"""Business logic services"""

# Services will be imported here as they are created
from app.services.auth_service import AuthService, auth_service
# from app.services.face_service import FaceRecognitionService
# from app.services.user_service import UserService
# from app.services.course_service import CourseService
# from app.services.attendance_service import AttendanceService
# from app.services.assignment_service import AssignmentService

__all__ = [
    "AuthService",
    "auth_service",
]
