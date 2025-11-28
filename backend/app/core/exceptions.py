"""Custom exception classes"""


class AppException(Exception):
    """Base exception for application"""
    
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class AuthenticationError(AppException):
    """Authentication failed"""
    
    def __init__(self, message: str = "Authentication failed"):
        super().__init__(message, status_code=401)


class AuthorizationError(AppException):
    """Authorization failed"""
    
    def __init__(self, message: str = "Not authorized"):
        super().__init__(message, status_code=403)


class UserAlreadyExistsError(AppException):
    """User already exists"""
    
    def __init__(self, message: str = "User already exists"):
        super().__init__(message, status_code=409)


class DuplicateFaceError(AppException):
    """Face already registered"""
    
    def __init__(self, message: str = "Face already registered"):
        super().__init__(message, status_code=409)


class FaceDetectionError(AppException):
    """Face detection failed"""
    
    def __init__(self, message: str = "Face detection failed"):
        super().__init__(message, status_code=400)


class NotFoundError(AppException):
    """Resource not found"""
    
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message, status_code=404)


class ValidationError(AppException):
    """Validation error"""
    
    def __init__(self, message: str = "Validation error"):
        super().__init__(message, status_code=422)
