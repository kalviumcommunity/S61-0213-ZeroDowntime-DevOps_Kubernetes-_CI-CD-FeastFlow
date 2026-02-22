#!/bin/bash

# Quick start script for FeastFlow
echo "🚀 FeastFlow Quick Start"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."

if ! command_exists node; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

if ! command_exists psql; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL first."
    exit 1
fi

echo "✅ Node.js and PostgreSQL found"
echo ""

# Backend setup
echo "📦 Setting up backend..."
cd backend

if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "⚙️  Please edit backend/.env with your database credentials"
    echo "   Default PostgreSQL password is 'postgres123'"
    echo ""
fi

if [ ! -d "node_modules" ]; then
    echo "Installing backend dependencies..."
    npm install
fi

echo "✅ Backend setup complete"
echo ""

# Frontend setup
echo "📦 Setting up frontend..."
cd ../frontend/app

if [ ! -f ".env.local" ]; then
    echo "Creating .env.local..."
    echo "NEXT_PUBLIC_API_URL=http://localhost:5000/api" > .env.local
fi

if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

echo "✅ Frontend setup complete"
echo ""

# Instructions
cd ../..
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Make sure PostgreSQL is running"
echo ""
echo "2. Create database (if not exists):"
echo "   psql -U postgres -c \"CREATE DATABASE feastflow;\""
echo ""
echo "3. Run migrations:"
echo "   cd backend && npm run migrate"
echo ""
echo "4. Start backend (Terminal 1):"
echo "   cd backend && npm run dev"
echo ""
echo "5. Start frontend (Terminal 2):"
echo "   cd frontend/app && npm run dev"
echo ""
echo "6. Open your browser:"
echo "   http://localhost:3000"
echo ""
echo "📍 Test page: http://localhost:3000/test-auth"
echo "📍 Login: http://localhost:3000/login"
echo "📍 Signup: http://localhost:3000/signup"
echo ""
echo "Default admin account:"
echo "Email: admin@feastflow.com"
echo "Password: Admin@123"
