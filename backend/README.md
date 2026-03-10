# FeastFlow Backend API

Backend service for FeastFlow food delivery platform with authentication and role-based access control (RBAC).

## Features

- 🔐 JWT-based authentication
- 👥 Role-Based Access Control (RBAC)
  - Customer
  - Restaurant Owner
  - Admin
- 🗄️ PostgreSQL database
- 🔒 Secure password hashing with bcrypt
- 🍪 HTTP-only cookies for token storage
- 🛡️ Security headers with Helmet
- ✅ Input validation

## Prerequisites

- Node.js (v18+)
- PostgreSQL (v14+)
- npm or yarn

## Installation

1. Install dependencies:

```bash
cd backend
npm install
```

2. Set up environment variables:

```bash
cp .env.example .env
```

Edit `.env` and configure your database and JWT settings.

3. Create PostgreSQL database:

```sql
CREATE DATABASE feastflow;
```

4. Run migrations:

```bash
npm run migrate
```

This will create all tables and insert a default admin user:

- Email: `admin@feastflow.com`
- Password: `Admin@123`

## Development

Start the development server:

```bash
npm run dev
```

Server will run on http://localhost:5000

## API Endpoints

### Operations

#### Liveness

```
GET /api/health
```

#### Readiness

```
GET /api/ready
```

#### Runtime Status

Returns non-sensitive runtime diagnostics (uptime, memory usage, environment, version).

```
GET /api/status
```

### Authentication

#### Register

```
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "role": "customer"  // optional: customer | restaurant_owner | admin
}
```

#### Login

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}
```

#### Get Current User

```
GET /api/auth/me
Authorization: Bearer <token>
```

#### Logout

```
POST /api/auth/logout
Authorization: Bearer <token>
```

## Database Schema

### Users Table

- id (UUID, Primary Key)
- email (Unique)
- password (Hashed)
- first_name
- last_name
- role (customer | restaurant_owner | admin)
- phone_number
- is_active
- created_at
- updated_at

### Restaurants Table

- id (UUID, Primary Key)
- owner_id (Foreign Key -> users)
- name
- cuisine
- description
- address
- rating
- delivery_time
- delivery_fee

### Menu Items, Orders, and Audit Log tables

See `src/database/schema.sql` for complete schema.

## Security

- Passwords are hashed using bcrypt (10 salt rounds)
- JWT tokens with configurable expiration
- HTTP-only cookies to prevent XSS attacks
- CORS configuration for frontend integration
- Helmet for security headers
- Role-based access control middleware

## Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Start production server
- `npm run migrate` - Run database migrations

## Environment Variables

See `.env.example` for all available configuration options.
