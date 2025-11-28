# C-Lens Backend API

Python FastAPI backend for C-Lens face recognition attendance system.

## Features

- User authentication with JWT
- Face recognition using DeepFace
- PostgreSQL database with SQLAlchemy ORM
- Course and attendance management
- Assignment tracking
- Announcements and surveys

## Prerequisites

- Python 3.10+
- PostgreSQL 15+
- Docker & Docker Compose (optional)

## Setup

### 1. Clone and Install Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Database Setup

```bash
# Run migrations
alembic upgrade head
```

### 4. Run Development Server

```bash
uvicorn app.main:app --reload
```

API will be available at http://localhost:8000
API documentation at http://localhost:8000/docs

## Docker Deployment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py
```

## Project Structure

```
backend/
├── app/
│   ├── api/          # API routes
│   ├── core/         # Core utilities
│   ├── models/       # Database models
│   ├── schemas/      # Pydantic schemas
│   ├── services/     # Business logic
│   └── utils/        # Helper functions
├── alembic/          # Database migrations
├── tests/            # Test suite
└── uploads/          # File uploads
```

## API Endpoints

### Authentication
- POST /api/v1/auth/register - Register new user
- POST /api/v1/auth/login - Login user
- POST /api/v1/auth/logout - Logout user

### Face Recognition
- POST /api/v1/face/register - Register face
- POST /api/v1/face/verify - Verify face
- POST /api/v1/face/attendance-check - Check attendance with face

### Courses
- POST /api/v1/courses - Create course
- GET /api/v1/courses/{id} - Get course details
- POST /api/v1/courses/join - Join course with code

### Attendance
- POST /api/v1/attendances - Start attendance session
- GET /api/v1/attendances/{id} - Get attendance details
- PUT /api/v1/attendances/{id}/close - Close attendance session

See full API documentation at /docs endpoint.

## License

MIT
