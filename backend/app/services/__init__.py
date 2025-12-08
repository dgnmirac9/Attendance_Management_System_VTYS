"""Business logic services"""

# Services will be imported here as they are created
from app.services.auth_service import AuthService, auth_service

# Try to import face_service, but don't fail if DeepFace is not installed
try:
    from app.services.face_service import FaceService, face_service
    FACE_SERVICE_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  Warning: Face service not available - {e}")
    print("   Install DeepFace to enable face recognition features")
    FaceService = None
    face_service = None
    FACE_SERVICE_AVAILABLE = False

# from app.services.user_service import UserService
# from app.services.course_service import CourseService
# from app.services.attendance_service import AttendanceService
# from app.services.assignment_service import AssignmentService

__all__ = [
    "AuthService",
    "auth_service",
    "FaceService",
    "face_service",
    "FACE_SERVICE_AVAILABLE",
]
