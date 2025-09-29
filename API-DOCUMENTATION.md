# Pokedex Auth Service API Documentation

## Base URL
- Development: `http://localhost:4000`
- Production (Mikrus): `http://srv36.mikr.us:4000`

## Authentication
Most endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## User Roles
- `USER` - Standard user, can manage own profile
- `ADMINISTRATOR` - Full access to user management

---

## Auth Endpoints

### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "role": "USER",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "role": "USER",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### Get Current User Profile
```http
GET /auth/me
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "User profile retrieved successfully",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "role": "USER",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Get Public Key
```http
GET /auth/public-key
```

**Response (200):**
```json
{
  "success": true,
  "message": "Public key retrieved successfully",
  "data": {
    "publicKey": "-----BEGIN PUBLIC KEY-----\n...",
    "algorithm": "RS256",
    "issuer": "pokedex-auth-service",
    "audience": "pokedex-app"
  }
}
```

---

## User Management Endpoints (CRUD)

### Get All Users (Admin Only)
```http
GET /users?page=1&limit=10
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": {
    "users": [
      {
        "id": 1,
        "email": "admin@example.com",
        "role": "ADMINISTRATOR",
        "isActive": true,
        "createdAt": "2024-01-01T00:00:00.000Z",
        "updatedAt": "2024-01-01T00:00:00.000Z"
      },
      {
        "id": 2,
        "email": "user@example.com",
        "role": "USER",
        "isActive": true,
        "createdAt": "2024-01-01T00:00:00.000Z",
        "updatedAt": "2024-01-01T00:00:00.000Z"
      }
    ],
    "total": 2,
    "page": 1,
    "totalPages": 1
  }
}
```

### Search Users (Admin Only)
```http
GET /users/search?query=john&role=USER&isActive=true
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Users search completed",
  "data": [
    {
      "id": 3,
      "email": "john@example.com",
      "role": "USER",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### Get User by ID
```http
GET /users/1
Authorization: Bearer <token>
```
*Note: Users can only view their own profile unless they are administrators*

**Response (200):**
```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "role": "USER",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Create User (Admin Only)
```http
POST /users
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "role": "USER"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": 4,
    "email": "newuser@example.com",
    "role": "USER",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Update User
```http
PUT /users/4
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "updated@example.com",
  "password": "NewSecurePass123!",
  "role": "ADMINISTRATOR",
  "isActive": false
}
```
*Note: Regular users can only update their own email and password. Admins can update any field.*

**Response (200):**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": 4,
    "email": "updated@example.com",
    "role": "ADMINISTRATOR",
    "isActive": false,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Update Own Profile
```http
PUT /users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "newemail@example.com",
  "password": "NewPassword123!",
  "currentPassword": "OldPassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 2,
    "email": "newemail@example.com",
    "role": "USER",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Delete User (Admin Only)
```http
DELETE /users/4
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Validation failed",
  "details": [
    "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character"
  ]
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "Authorization header is required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": "User not found"
}
```

### 409 Conflict
```json
{
  "success": false,
  "error": "User with this email already exists"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error"
}
```

---

## Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (@$!%*?&)

---

## Rate Limiting
- Default: 100 requests per 15 minutes per IP
- Configurable via environment variables

---

## CORS
- Configured origins in production:
  - http://srv36.mikr.us:20275
  - http://srv36.mikr.us:3000
  - http://srv36.mikr.us:5173

---

## Health Check
```http
GET /health
```

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

---

## Testing with cURL

### Register Admin User
```bash
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@pokedex.com",
    "password": "AdminPass123!"
  }'
```

### Login and Save Token
```bash
TOKEN=$(curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@pokedex.com",
    "password": "AdminPass123!"
  }' | jq -r '.data.token')
```

### Get All Users
```bash
curl -X GET http://localhost:4000/users \
  -H "Authorization: Bearer $TOKEN"
```

### Create New User
```bash
curl -X POST http://localhost:4000/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@pokedex.com",
    "password": "UserPass123!",
    "role": "USER"
  }'
```

### Update User Role
```bash
curl -X PUT http://localhost:4000/users/2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "ADMINISTRATOR"
  }'
```

### Delete User
```bash
curl -X DELETE http://localhost:4000/users/3 \
  -H "Authorization: Bearer $TOKEN"
```
