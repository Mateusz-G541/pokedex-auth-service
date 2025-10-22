# Pokedex Auth Service

A secure authentication microservice for the Pokedex application using JWT with RSA signing, built with Node.js, Express, TypeScript, and MySQL.

## Features

- **JWT Authentication** with RS256 (RSA) signing
- **User Registration & Login** with email/password
- **Password Security** using bcrypt hashing
- **Token Validation** endpoint for other microservices
- **MySQL Database** with Prisma ORM
- **Docker Support** with Docker Compose
- **Security Hardening** with Helmet, CORS, and rate limiting
- **Input Validation** with Joi schemas
- **Comprehensive Error Handling**

## API Endpoints

### Public Endpoints
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and get JWT token
- `GET /auth/public-key` - Get public key for token validation
- `GET /health` - Health check

### Protected Endpoints
- `GET /auth/me` - Get authenticated user profile (requires Bearer token)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)
- OpenSSL (for key generation)

### 1. Clone and Setup
```bash
cd pokedex-auth-service
cp .env.example .env
```

### 2. Generate RSA Keys

**Windows (PowerShell):**
```powershell
.\scripts\generate-keys.ps1
```

**Linux/macOS:**
```bash
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

### 3. Start with Docker
```bash
docker-compose up -d
```

### 4. Run Database Migrations
```bash
# Wait for MySQL to be ready, then run:
docker-compose exec auth-service npx prisma migrate deploy
```

### 5. Test the Service
```bash
curl http://localhost:4000/health
```

## Development Setup

### Local Development
```bash
# Install dependencies
npm install

# Generate RSA keys
./scripts/generate-keys.sh

# Start MySQL with Docker
docker-compose up mysql -d

# Run migrations
npx prisma migrate dev

# Start development server
npm run dev
```

### Database Commands
```bash
# Generate Prisma client
npm run db:generate

# Create and apply migration
npm run db:migrate

# Deploy migrations (production)
npm run db:deploy
```

## Environment Variables

```env
# Database
DATABASE_URL="mysql://auth_user:auth_password@mysql:3306/auth_db"

# Server
PORT=4000
NODE_ENV=development

# JWT
JWT_PRIVATE_KEY_PATH="./keys/private.pem"
JWT_PUBLIC_KEY_PATH="./keys/public.pem"
JWT_EXPIRES_IN="24h"

# Security
BCRYPT_ROUNDS=12
CORS_ORIGIN="http://localhost:3000,http://localhost:5173"
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

## Integration with Other Services

### Pokemon API Service Integration

Copy the token validation middleware to your pokemon-api-service:

```bash
cp middleware/token-validation.ts ../pokemon-api-service/src/middleware/
```

Add to your pokemon-api-service environment:
```env
AUTH_SERVICE_URL=http://localhost:4000
```

Use in your routes:
```typescript
import { authenticateToken } from './middleware/token-validation';

// Protect routes
router.get('/protected-endpoint', authenticateToken, controller.method);
```

### Frontend Integration

#### Registration Example
```javascript
const response = await fetch('http://localhost:4000/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'SecurePass123!'
  })
});

const data = await response.json();
if (data.success) {
  localStorage.setItem('token', data.data.token);
}
```

#### Login Example
```javascript
const response = await fetch('http://localhost:4000/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'SecurePass123!'
  })
});

const data = await response.json();
if (data.success) {
  localStorage.setItem('token', data.data.token);
}
```

#### Authenticated Requests
```javascript
const token = localStorage.getItem('token');
const response = await fetch('http://localhost:3000/api/protected-endpoint', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

## Testing

### Using Postman
Import the collection from `postman/auth-service.postman_collection.json`

### Manual Testing
```bash
# Register user
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123!"}'

# Login
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123!"}'

# Get profile (replace TOKEN with actual token)
curl -X GET http://localhost:4000/auth/me \
  -H "Authorization: Bearer TOKEN"

# Get public key
curl -X GET http://localhost:4000/auth/public-key
```

## Password Requirements

- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (@$!%*?&)

## Security Features

- **RSA JWT Signing** - Asymmetric key signing for secure token validation
- **Password Hashing** - bcrypt with configurable rounds
- **Rate Limiting** - Configurable request limits per IP
- **CORS Protection** - Configurable allowed origins
- **Helmet Security** - Security headers and protection
- **Input Validation** - Joi schema validation
- **Error Handling** - Secure error responses without sensitive data

## Production Deployment

### Mikr.us VPS Deployment (Recommended)

Deploy using Docker and Docker Hub registry:

**Quick Start:**
```bash
# On your VPS
curl -O https://raw.githubusercontent.com/Mateusz-G541/pokedex-auth-service/main/setup-mikrus.sh
chmod +x setup-mikrus.sh
./setup-mikrus.sh
```

**Full Documentation:**
- [Quick Deploy Guide](./QUICK-DEPLOY.md) - Fast deployment steps
- [Deployment Guide](./DEPLOYMENT.md) - Complete deployment documentation

### Manual Production Setup

1. **Generate secure RSA keys** with 4096 bits:
```bash
openssl genrsa -out keys/private.pem 4096
openssl rsa -in keys/private.pem -pubout -out keys/public.pem
```

2. **Set production environment variables**
3. **Use SSL/TLS** for HTTPS
4. **Configure proper CORS origins**
5. **Set up monitoring and logging**
6. **Regular security updates**

## Troubleshooting

### Common Issues

1. **Keys not found**: Run the key generation script
2. **Database connection**: Check MySQL is running and credentials are correct
3. **Port conflicts**: Change PORT in .env file
4. **CORS errors**: Update CORS_ORIGIN in .env file

### Logs
```bash
# View service logs
docker-compose logs auth-service

# View database logs
docker-compose logs mysql
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │  Pokemon API     │    │  Auth Service   │
│   (React)       │    │  Service         │    │  (Express)      │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │ Auth Forms  │ │    │ │ Token        │ │    │ │ JWT Service │ │
│ │             │ │────┼▶│ Validation   │ │────┼▶│             │ │
│ └─────────────┘ │    │ │ Middleware   │ │    │ └─────────────┘ │
│                 │    │ └──────────────┘ │    │                 │
└─────────────────┘    └──────────────────┘    │ ┌─────────────┐ │
                                               │ │ MySQL DB    │ │
                                               │ │ (Users)     │ │
                                               │ └─────────────┘ │
                                               └─────────────────┘
```

## License

MIT
