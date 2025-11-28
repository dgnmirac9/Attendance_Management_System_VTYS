"""Setup script for C-Lens backend"""

from setuptools import setup, find_packages

setup(
    name="clens-backend",
    version="1.0.0",
    description="C-Lens face recognition attendance system backend",
    author="C-Lens Team",
    packages=find_packages(),
    python_requires=">=3.10",
    install_requires=[
        "fastapi>=0.104.1",
        "uvicorn[standard]>=0.24.0",
        "sqlalchemy>=2.0.23",
        "alembic>=1.12.1",
        "asyncpg>=0.29.0",
        "psycopg2-binary>=2.9.9",
        "python-jose[cryptography]>=3.3.0",
        "passlib[bcrypt]>=1.7.4",
        "bcrypt>=4.1.1",
        "cryptography>=41.0.7",
        "deepface>=0.0.79",
        "opencv-python>=4.8.1.78",
        "pydantic>=2.5.0",
        "pydantic-settings>=2.1.0",
        "email-validator>=2.1.0",
        "slowapi>=0.1.9",
        "redis>=5.0.1",
        "python-dotenv>=1.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.3",
            "pytest-asyncio>=0.21.1",
            "pytest-cov>=4.1.0",
            "faker>=20.1.0",
            "httpx>=0.25.2",
            "black>=23.12.0",
            "flake8>=6.1.0",
            "mypy>=1.7.1",
        ],
    },
)
