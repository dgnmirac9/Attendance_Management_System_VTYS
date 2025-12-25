@echo off
echo ========================================
echo C-Lens Database Setup
echo ========================================
echo.

echo Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo Docker found!
echo.

echo Starting PostgreSQL and Redis containers...
docker-compose up -d

echo.
echo Waiting for database to be ready...
timeout /t 5 /nobreak >nul

echo.
echo Checking container status...
docker-compose ps

echo.
echo ========================================
echo Database is ready!
echo ========================================
echo.
echo PostgreSQL: localhost:5432
echo   Database: clens_db
echo   User: clens_user
echo   Password: password
echo.
echo Redis: localhost:6379
echo.
echo Next steps:
echo 1. Run migrations: alembic upgrade head
echo 2. Start the API: uvicorn app.main:app --reload
echo 3. Open Swagger UI: http://localhost:8000/docs
echo 4. View database tables: http://localhost:8000/api/v1/debug/tables
echo.
echo To stop the database: docker-compose down
echo To view logs: docker-compose logs -f
echo.
pause
