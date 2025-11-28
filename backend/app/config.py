"""Application configuration"""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings"""
    
    # Database
    DATABASE_URL: str = "postgresql://clens_user:password@localhost:5432/clens_db"
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10
    
    # Security
    SECRET_KEY: str = "change-this-secret-key-in-production-min-32-chars"
    ENCRYPTION_KEY: str = "change-this-encryption-key-base64-44chars"
    
    # JWT
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # CORS
    # Development modunda tüm origin'lere izin ver (Android emulator için)
    CORS_ORIGINS: List[str] = ["*"]
    
    # Face Recognition
    FACE_MODEL: str = "Facenet512"
    FACE_SIMILARITY_THRESHOLD: float = 0.80
    FACE_DETECTOR_BACKEND: str = "opencv"
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 100
    
    # File Upload
    MAX_UPLOAD_SIZE: int = 10485760  # 10MB
    UPLOAD_DIR: str = "./uploads"
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"
    
    # Environment
    ENVIRONMENT: str = "development"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Create settings instance
settings = Settings()
