# Quick Start Guide

## Prerequisites

- Python 3.10 or higher
- PostgreSQL 15 or higher
- Docker and Docker Compose (optional)

## Option 1: Local Development Setup

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# On Windows
venv\Scripts\activate

# On Linux/Mac
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
# Copy example environment file
copy .env.example .env

# Edit .env file with your configuration
# Update DATABASE_URL, SECRET_KEY, ENCRYPTION_KEY
```

### 4. Set Up Database

Make sure PostgreSQL is running, then create the database:

```sql
CREATE DATABASE clens_db;
CREATE USER clens_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE clens_db TO clens_user;
```

### 5. Run Migrations

```bash
# Initialize Alembic (only needed once, already done)
# alembic init alembic

# Create initial migration (will be done in task 2.8)
# alembic revision --autogenerate -m "Initial migration"

# Apply migrations
alembic upgrade head
```

### 6. Start Development Server

```bash
uvicorn app.main:app --reload
```

Or using Make:

```bash
make dev
```

The API will be available at:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Option 2: Docker Setup

### 1. Configure Environment

```bash
copy .env.example .env
# Edit .env with your settings
```

### 2. Build and Start Containers

```bash
docker-compose up -d
```

### 3. View Logs

```bash
docker-compose logs -f backend
```

### 4. Stop Containers

```bash
docker-compose down
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_health.py
```

Or using Make:

```bash
make test
make test-cov
```

## Verify Installation

Test the health endpoint:

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development"
}
```

## Next Steps

1. Complete Task 2: Create database models and migrations
2. Complete Task 3: Create Pydantic schemas
3. Complete Task 4: Implement core services
4. Complete Task 5: Create API endpoints

## Troubleshooting

### Database Connection Error

- Verify PostgreSQL is running
- Check DATABASE_URL in .env file
- Ensure database and user exist

### Import Errors

- Verify virtual environment is activated
- Run `pip install -r requirements.txt` again

### Port Already in Use

- Change port in uvicorn command: `--port 8001`
- Or stop the process using port 8000

## Useful Commands

```bash
# Format code
make format

# Lint code
make lint

# Clean generated files
make clean

# Create new migration
make migrate-create message="description"

# Apply migrations
make migrate
```
