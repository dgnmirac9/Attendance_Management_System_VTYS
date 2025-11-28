# C-Lens API Documentation

## Overview

The C-Lens API is a RESTful backend service for managing educational courses with face recognition-based attendance tracking. This document provides comprehensive information about the API endpoints, authentication flow, and usage examples.

## Base URL

```
Development: http://localhost:8000
Production: https://api.clens.edu
```

## Interactive Documentation

The API provides interactive documentation through Swagger UI and ReDoc:

- **Swagger UI**: `/docs` - Interactive API explorer with request/response examples
- **ReDoc**: `/redoc` - Clean, readable API documentation
- **OpenAPI Schema**: `/openapi.json` - Machine-readable API specification

## Authentication

### Overview

The C-Lens API uses JWT (JSON Web Token) based authentication. All protected endpoints require a valid access token in the Authorization header.

### Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Database
    
    Client->>API: POST /api/v1/auth/register or /login
    API->>Database: Verify credentials
    Database-->>API: User data
    API->>API: Generate JWT token
    API->>Database: Store token
    API-->>Client: Return token + user data
    
    Client->>API: Request with Authorization header
    API->>API: Verify JWT token
    API->>Database: Check token validity
    Database-->>API: Token valid
    API-->>Client: Return requested data
    
    Client->>API: POST /api/v1/auth/logout
    API->>Database: Revoke token
    API-->>Client: Logout successful
```

### Token Format

```
Authorization: Bearer <access_token>
```

### Token Expiration

- Access tokens expire after **24 hours**
- After expiration, users must login again to obtain a new token
- Tokens can be manually revoked via the logout endpoint

## Endpoints

### Authentication Endpoints

#### 1. Register User

**Endpoint:** `POST /api/v1/auth/register`

**Description:** Register a new user account as either a student or instructor.

**Request Body (Student):**
```json
{
  "email": "student@university.edu",
  "password": "SecurePass123",
  "full_name": "John Doe",
  "role": "student",
  "student_number": "2024001",
  "department": "Computer Engineering",
  "class_level": 2,
  "enrollment_year": 2024
}
```

**Request Body (Instructor):**
```json
{
  "email": "instructor@university.edu",
  "password": "SecurePass123",
  "full_name": "Dr. Jane Smith",
  "role": "instructor",
  "title": "Prof. Dr.",
  "office_info": "A-101"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "student@university.edu",
    "full_name": "John Doe",
    "role": "student",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Validation Rules:**
- Email must be unique and valid format
- Password minimum 8 characters, must contain letter and number
- Student role requires: student_number, department, class_level, enrollment_year
- Student number must be unique
- Class level must be between 1-4

**Error Responses:**
- `400 Bad Request`: Missing required fields
- `409 Conflict`: Email or student number already exists
- `422 Unprocessable Entity`: Validation error

---

#### 2. Login

**Endpoint:** `POST /api/v1/auth/login`

**Description:** Authenticate a user and receive an access token.

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "SecurePass123"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "email": "student@university.edu",
    "full_name": "John Doe",
    "role": "student",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid email or password
- `422 Unprocessable Entity`: Validation error

---

#### 3. Logout

**Endpoint:** `POST /api/v1/auth/logout`

**Description:** Logout the current user by revoking their access token.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or missing token
- `404 Not Found`: Token not found or already revoked

---

## Rate Limiting

All endpoints are rate-limited to prevent abuse:

- **Limit:** 100 requests per minute per IP address
- **Response when exceeded:** `429 Too Many Requests`

**Rate Limit Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

## Error Handling

### Standard Error Response Format

```json
{
  "detail": "Error message description",
  "error_type": "ExceptionClassName"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid request data |
| 401 | Unauthorized - Authentication required or failed |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource conflict (e.g., duplicate email) |
| 422 | Unprocessable Entity - Validation error |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server error |

### Validation Errors

Validation errors return a detailed list of field-specific errors:

```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    },
    {
      "loc": ["body", "password"],
      "msg": "Password must contain at least one number",
      "type": "value_error"
    }
  ]
}
```

## Security

### Password Security
- Passwords are hashed using **bcrypt** with salt
- Minimum 8 characters required
- Must contain at least one letter and one number
- Passwords are never stored in plain text

### Token Security
- JWT tokens signed with HS256 algorithm
- Tokens include user_id, email, and role claims
- Tokens expire after 24 hours
- Revoked tokens are stored in database

### Face Data Security
- Face embeddings are encrypted at rest using Fernet encryption
- Face data stored separately from user records
- Duplicate face detection prevents identity fraud

### Transport Security
- HTTPS required in production
- CORS configured for allowed origins only
- SQL injection protection via parameterized queries

## Database Schema

### Main Entities

- **Users**: Base user accounts (students and instructors)
- **Students**: Student-specific information and face data
- **Instructors**: Instructor-specific information
- **Courses**: Course information and join codes
- **Course Enrollments**: Student-course relationships
- **Attendances**: Attendance sessions
- **Attendance Records**: Individual attendance check-ins
- **Assignments**: Course assignments
- **Assignment Submissions**: Student submissions and grades
- **Announcements**: Course announcements and resources
- **Student Shared Notes**: Peer-to-peer note sharing
- **Surveys**: Course surveys and feedback
- **Tokens**: JWT token management

## Usage Examples

### Example 1: Student Registration and Login

```bash
# Register a new student
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@university.edu",
    "password": "SecurePass123",
    "full_name": "John Doe",
    "role": "student",
    "student_number": "2024001",
    "department": "Computer Engineering",
    "class_level": 2,
    "enrollment_year": 2024
  }'

# Response includes access token
# {
#   "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "token_type": "bearer",
#   "user": { ... }
# }
```

### Example 2: Login and Use Protected Endpoint

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@university.edu",
    "password": "SecurePass123"
  }'

# Save the access_token from response

# Use token for protected endpoint (example for future endpoints)
curl -X GET http://localhost:8000/api/v1/students/me \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

### Example 3: Logout

```bash
# Logout (revoke token)
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."

# Response
# {
#   "message": "Logged out successfully"
# }
```

## Python Client Example

```python
import requests

class CLensClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.token = None
    
    def register_student(self, email, password, full_name, student_number, 
                        department, class_level, enrollment_year):
        """Register a new student"""
        response = requests.post(
            f"{self.base_url}/api/v1/auth/register",
            json={
                "email": email,
                "password": password,
                "full_name": full_name,
                "role": "student",
                "student_number": student_number,
                "department": department,
                "class_level": class_level,
                "enrollment_year": enrollment_year
            }
        )
        response.raise_for_status()
        data = response.json()
        self.token = data["access_token"]
        return data
    
    def login(self, email, password):
        """Login user"""
        response = requests.post(
            f"{self.base_url}/api/v1/auth/login",
            json={"email": email, "password": password}
        )
        response.raise_for_status()
        data = response.json()
        self.token = data["access_token"]
        return data
    
    def logout(self):
        """Logout user"""
        response = requests.post(
            f"{self.base_url}/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {self.token}"}
        )
        response.raise_for_status()
        self.token = None
        return response.json()
    
    def get_headers(self):
        """Get authorization headers"""
        if not self.token:
            raise ValueError("Not authenticated. Please login first.")
        return {"Authorization": f"Bearer {self.token}"}

# Usage
client = CLensClient()

# Register
result = client.register_student(
    email="john.doe@university.edu",
    password="SecurePass123",
    full_name="John Doe",
    student_number="2024001",
    department="Computer Engineering",
    class_level=2,
    enrollment_year=2024
)
print(f"Registered user: {result['user']['full_name']}")

# Logout
client.logout()

# Login again
client.login("john.doe@university.edu", "SecurePass123")
```

## JavaScript/TypeScript Client Example

```typescript
class CLensClient {
  private baseUrl: string;
  private token: string | null = null;

  constructor(baseUrl: string = "http://localhost:8000") {
    this.baseUrl = baseUrl;
  }

  async registerStudent(data: {
    email: string;
    password: string;
    full_name: string;
    student_number: string;
    department: string;
    class_level: number;
    enrollment_year: number;
  }) {
    const response = await fetch(`${this.baseUrl}/api/v1/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...data, role: "student" }),
    });

    if (!response.ok) {
      throw new Error(`Registration failed: ${response.statusText}`);
    }

    const result = await response.json();
    this.token = result.access_token;
    return result;
  }

  async login(email: string, password: string) {
    const response = await fetch(`${this.baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      throw new Error(`Login failed: ${response.statusText}`);
    }

    const result = await response.json();
    this.token = result.access_token;
    return result;
  }

  async logout() {
    if (!this.token) {
      throw new Error("Not authenticated");
    }

    const response = await fetch(`${this.baseUrl}/api/v1/auth/logout`, {
      method: "POST",
      headers: { Authorization: `Bearer ${this.token}` },
    });

    if (!response.ok) {
      throw new Error(`Logout failed: ${response.statusText}`);
    }

    this.token = null;
    return response.json();
  }

  getAuthHeaders() {
    if (!this.token) {
      throw new Error("Not authenticated. Please login first.");
    }
    return { Authorization: `Bearer ${this.token}` };
  }
}

// Usage
const client = new CLensClient();

// Register
const result = await client.registerStudent({
  email: "john.doe@university.edu",
  password: "SecurePass123",
  full_name: "John Doe",
  student_number: "2024001",
  department: "Computer Engineering",
  class_level: 2,
  enrollment_year: 2024,
});

console.log(`Registered user: ${result.user.full_name}`);
```

## Testing the API

### Using Swagger UI

1. Navigate to `http://localhost:8000/docs`
2. Click on an endpoint to expand it
3. Click "Try it out"
4. Fill in the request parameters
5. Click "Execute"
6. View the response

### Using curl

See the usage examples above for curl commands.

### Using Postman

1. Import the OpenAPI schema from `http://localhost:8000/openapi.json`
2. Create a new request
3. Set the method and URL
4. Add request body (if needed)
5. Add Authorization header for protected endpoints
6. Send the request

## Support and Contact

For API support, please contact:
- **Email**: support@clens.edu
- **Documentation**: http://localhost:8000/docs
- **GitHub**: [Repository URL]

## License

This API is licensed under the MIT License.
