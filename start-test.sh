#!/bin/bash

# FeastFlow Authentication Integration Test Script
# This script starts both backend and frontend for testing

echo "🚀 Starting FeastFlow Authentication Test..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if backend dependencies are installed
if [ ! -d "backend/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
    cd backend && npm install
    cd ..
fi

# Check if frontend dependencies are installed
if [ ! -d "frontend/app/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing frontend dependencies...${NC}"
    cd frontend/app && npm install
    cd ../..
fi

# Check if PostgreSQL is running
echo -e "${YELLOW}🔍 Checking PostgreSQL connection...${NC}"
if ! psql -U postgres -lqt | cut -d \| -f 1 | grep -qw feastflow; then
    echo -e "${RED}❌ Database 'feastflow' not found!${NC}"
    echo "Please create it with: psql -U postgres -c 'CREATE DATABASE feastflow;'"
    exit 1
fi

echo -e "${GREEN}✅ Database found${NC}"

# Check if migrations have been run
echo -e "${YELLOW}🔍 Checking if migrations have been run...${NC}"
cd backend
npm run migrate 2>/dev/null
cd ..

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Starting services..."
echo ""
echo "📍 Backend will run on: http://localhost:5000"
echo "📍 Frontend will run on: http://localhost:3000"
echo "📍 Test page: http://localhost:3000/test-auth"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Start backend in background
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

# Wait a bit for backend to start
sleep 3

# Start frontend in background
cd frontend/app
npm run dev &
FRONTEND_PID=$!
cd ../..

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    echo "✅ Services stopped"
    exit 0
}

trap cleanup INT TERM

# Keep script running
echo "✅ Services are running!"
echo ""
echo "Test the integration:"
echo "1. Open http://localhost:3000/test-auth"
echo "2. Check the API status"
echo "3. Try the test buttons"
echo "4. Visit http://localhost:3000/signup to create an account"
echo "5. Visit http://localhost:3000/login to sign in"
echo ""

wait
