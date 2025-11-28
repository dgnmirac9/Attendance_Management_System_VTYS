# C-Lens API Quick Reference

## Quick Start

### 1. Access Interactive Documentation
```
Swagger UI: http://localhost:8000/docs
ReDoc: http://localhost:8000/redoc
```

### 2. Authentication Flow

```bash
# Register
POST /api/v1/auth/register
Body: { email, password, full_name, role, ... }
Returns: { access_token, user }

# Login
POST /api/v1/auth/login
Body: { email, password }
Returns: { access_token, user }

# Use Token
Header: Authorization: Bearer <access_token>

# Logout
POST /api/v1/auth/logout
Header: Authorization: Bearer <access_token>
```

## Authentication Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/api/v1/auth/register` | No | Register new user |
| POST | `/api/v1/auth/login` | No | Login user |
| POST | `/api/v1/auth/logout` | Yes | Logout user |

## Request Examples

### Student Registration
```json
POST /api/v1/auth/register
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

### Instructor Registration
```json
POST /api/v1/auth/register
{
  "email": "instructor@university.edu",
  "password": "SecurePass123",
  "full_name": "Dr. Jane Smith",
  "role": "instructor",
  "title": "Prof. Dr.",
  "office_info": "A-101"
}
```

### Login
```json
POST /api/v1/auth/login
{
  "email": "student@university.edu",
  "password": "SecurePass123"
}
```

## Response Format

### Success Response
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
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

### Error Response
```json
{
  "detail": "Error message",
  "error_type": "ExceptionClassName"
}
```

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation Error |
| 429 | Rate Limit Exceeded |
| 500 | Server Error |

## Validation Rules

### Password
- Minimum 8 characters
- Must contain at least one letter
- Must contain at least one number

### Email
- Must be valid email format
- Must be unique

### Student Fields
- `student_number`: Required, unique
- `department`: Required
- `class_level`: Required, 1-4
- `enrollment_year`: Required

### Instructor Fields
- `title`: Optional
- `office_info`: Optional

## Rate Limiting

- **Limit**: 100 requests/minute per IP
- **Headers**: 
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Security

### Token Usage
```
Authorization: Bearer <access_token>
```

### Token Expiration
- Expires after 24 hours
- Must login again after expiration

### Password Security
- Hashed with bcrypt
- Never stored in plain text

## Common Errors

### 401 Unauthorized
```json
{
  "detail": "Invalid email or password"
}
```
**Solution**: Check credentials and try again

### 409 Conflict
```json
{
  "detail": "Email already registered"
}
```
**Solution**: Use a different email or login instead

### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "password"],
      "msg": "Password must contain at least one number",
      "type": "value_error"
    }
  ]
}
```
**Solution**: Fix the validation errors and retry

### 429 Rate Limit Exceeded
```json
{
  "detail": "Rate limit exceeded"
}
```
**Solution**: Wait and retry after the reset time

## Testing Tools

### curl
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"pass123"}'
```

### Python
```python
import requests

response = requests.post(
    "http://localhost:8000/api/v1/auth/login",
    json={"email": "user@example.com", "password": "pass123"}
)
token = response.json()["access_token"]
```

### JavaScript
```javascript
const response = await fetch("http://localhost:8000/api/v1/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email: "user@example.com", password: "pass123" })
});
const { access_token } = await response.json();
```

## Environment Variables

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/clens
SECRET_KEY=your-secret-key-here
ENCRYPTION_KEY=your-encryption-key-here
ENVIRONMENT=development
CORS_ORIGINS=["http://localhost:3000"]
```

## Health Check

```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development"
}
```

## Support

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Full Documentation**: See API_DOCUMENTATION.md
