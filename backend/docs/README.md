# C-Lens API Documentation

## Overview

This directory contains comprehensive documentation for the C-Lens API.

## Documentation Resources

### Interactive Documentation (Recommended)

Start the development server and access:

- **Swagger UI**: http://localhost:8000/docs
  - Interactive API explorer
  - Try endpoints directly in the browser
  - View request/response examples
  - Test authentication flow

- **ReDoc**: http://localhost:8000/redoc
  - Clean, readable documentation
  - Better for reading and understanding
  - Organized by tags

- **OpenAPI JSON**: http://localhost:8000/openapi.json
  - Machine-readable API specification
  - Import into Postman, Insomnia, etc.

### Written Documentation

- **[API_DOCUMENTATION.md](../API_DOCUMENTATION.md)**: Comprehensive API guide
  - Complete authentication flow
  - All endpoint details with examples
  - Error handling
  - Security information
  - Client examples (Python, JavaScript)

- **[API_QUICK_REFERENCE.md](../API_QUICK_REFERENCE.md)**: Quick reference guide
  - Quick start guide
  - Common request examples
  - Status codes
  - Validation rules
  - Common errors and solutions

## Getting Started

### 1. Start the Development Server

```bash
cd backend
uvicorn app.main:app --reload
```

Or use the convenience script:

```bash
python backend/run_dev.py
```

### 2. Access Documentation

Open your browser and navigate to:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

### 3. Test the API

#### Using Swagger UI

1. Navigate to http://localhost:8000/docs
2. Click on "POST /api/v1/auth/register"
3. Click "Try it out"
4. Fill in the request body with student or instructor data
5. Click "Execute"
6. Copy the `access_token` from the response
7. Click "Authorize" button at the top
8. Enter: `Bearer <your_access_token>`
9. Now you can test protected endpoints

#### Using curl

```bash
# Register
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@university.edu",
    "password": "SecurePass123",
    "full_name": "John Doe",
    "role": "student",
    "student_number": "2024001",
    "department": "Computer Engineering",
    "class_level": 2,
    "enrollment_year": 2024
  }'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@university.edu",
    "password": "SecurePass123"
  }'
```

## Documentation Features

### ✅ Implemented

- [x] FastAPI Swagger UI configuration
- [x] Comprehensive API description with authentication flow
- [x] OpenAPI tags for endpoint organization
- [x] Security schemes (JWT Bearer authentication)
- [x] Request/response examples
- [x] Detailed endpoint descriptions
- [x] Error response documentation
- [x] Validation error examples
- [x] Rate limiting documentation
- [x] Security best practices
- [x] Contact and license information
- [x] Written documentation (Markdown)
- [x] Quick reference guide
- [x] Client code examples (Python, JavaScript)
- [x] Testing instructions

### 📋 Documentation Structure

```
backend/
├── API_DOCUMENTATION.md          # Comprehensive guide
├── API_QUICK_REFERENCE.md        # Quick reference
├── docs/
│   └── README.md                 # This file
├── verify_docs.py                # Documentation verification script
└── app/
    └── main.py                   # FastAPI app with enhanced docs
```

## Authentication Flow Documentation

The API documentation includes detailed authentication flow:

1. **Registration**: Create a new user account (student or instructor)
2. **Login**: Authenticate and receive JWT token
3. **Protected Endpoints**: Use token in Authorization header
4. **Logout**: Revoke token

### Example Flow

```
┌─────────┐                    ┌─────────┐
│ Client  │                    │   API   │
└────┬────┘                    └────┬────┘
     │                              │
     │  POST /auth/register         │
     │─────────────────────────────>│
     │                              │
     │  {access_token, user}        │
     │<─────────────────────────────│
     │                              │
     │  GET /students/me            │
     │  Authorization: Bearer token │
     │─────────────────────────────>│
     │                              │
     │  {student_data}              │
     │<─────────────────────────────│
     │                              │
     │  POST /auth/logout           │
     │  Authorization: Bearer token │
     │─────────────────────────────>│
     │                              │
     │  {message: "Logged out"}     │
     │<─────────────────────────────│
```

## Endpoint Documentation

All endpoints include:

- **Summary**: Brief description
- **Description**: Detailed explanation with usage notes
- **Request Body**: Schema with validation rules
- **Response Models**: Success and error responses
- **Status Codes**: All possible HTTP status codes
- **Examples**: Request and response examples
- **Security**: Authentication requirements

### Example Endpoint Documentation

```python
@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="Detailed description...",
    responses={
        201: {"description": "Success", "content": {...}},
        400: {"description": "Bad Request", "content": {...}},
        409: {"description": "Conflict", "content": {...}},
    }
)
```

## Verification

To verify the documentation is properly configured:

```bash
python backend/verify_docs.py
```

This script checks:
- App configuration
- OpenAPI tags
- Security schemes
- Examples
- Endpoint documentation
- Response schemas

## Contributing

When adding new endpoints:

1. Add comprehensive docstrings
2. Include request/response examples
3. Document all status codes
4. Add validation rules
5. Update API_DOCUMENTATION.md
6. Run verification script

## Support

For questions or issues:
- Check Swagger UI: http://localhost:8000/docs
- Read API_DOCUMENTATION.md
- Check API_QUICK_REFERENCE.md
- Contact: support@clens.edu
