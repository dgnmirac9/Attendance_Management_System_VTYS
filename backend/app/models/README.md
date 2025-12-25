# Database Models

This directory contains all SQLAlchemy ORM models for the C-Lens application.

## Models Overview

### User Management
- **User** (`user.py`): Base user model for authentication
- **Student** (`user.py`): Student-specific information and relationships
- **Instructor** (`user.py`): Instructor-specific information and relationships

### Course Management
- **Course** (`course.py`): Course information with join code generation
- **CourseEnrollment** (`course.py`): Many-to-many relationship between students and courses

### Attendance System
- **Attendance** (`attendance.py`): Attendance sessions created by instructors
- **AttendanceRecord** (`attendance.py`): Individual student attendance records with face recognition data

### Assignment System
- **Assignment** (`assignment.py`): Assignments created by instructors
- **AssignmentSubmission** (`assignment.py`): Student submissions with grading

### Content Sharing
- **Announcement** (`content.py`): Course announcements, notes, and resources
- **StudentSharedNote** (`content.py`): Student-shared notes for collaborative learning
- **Survey** (`content.py`): Instructor surveys for feedback
- **SurveyResponse** (`content.py`): Student responses to surveys

### Authentication
- **Token** (`token.py`): JWT token management for sessions

## Database Schema

All models follow these conventions:
- Primary keys use the pattern `{table_name}_id`
- Foreign keys use `ondelete='CASCADE'` for referential integrity
- Timestamps use `server_default=func.now()` for automatic creation times
- Indexes are created on frequently queried columns
- Unique constraints prevent duplicate data
- Check constraints enforce data validity

## Relationships

The models use SQLAlchemy relationships with proper cascade settings:
- `cascade="all, delete-orphan"` for parent-child relationships
- `back_populates` for bidirectional relationships

## Migration

The initial migration file is located at:
`backend/alembic/versions/2024_11_05_1430-001_initial_migration_with_all_models.py`

To apply migrations when PostgreSQL is available:
```bash
alembic upgrade head
```

To create a new migration after model changes:
```bash
alembic revision --autogenerate -m "Description of changes"
```
