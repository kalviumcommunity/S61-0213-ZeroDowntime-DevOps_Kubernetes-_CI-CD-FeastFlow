@echo off
REM Quick setup script for FeastFlow (Windows)

echo 🚀 FeastFlow Quick Start
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js 18+ first.
    pause
    exit /b 1
)

echo ✅ Node.js found
echo.

REM Backend setup
echo 📦 Setting up backend...
cd backend

if not exist ".env" (
    echo ⚠️  .env file not found. Copying from .env.example...
    copy .env.example .env
    echo ⚙️  Please edit backend\.env with your database credentials
    echo    Default PostgreSQL password should be set in .env
    echo.
)

if not exist "node_modules" (
    echo Installing backend dependencies...
    call npm install
)

echo ✅ Backend setup complete
echo.

REM Frontend setup
echo 📦 Setting up frontend...
cd ..\frontend\app

if not exist ".env.local" (
    echo Creating .env.local...
    echo NEXT_PUBLIC_API_URL=http://localhost:5000/api > .env.local
)

if not exist "node_modules" (
    echo Installing frontend dependencies...
    call npm install
)

echo ✅ Frontend setup complete
echo.

REM Instructions
cd ..\..
echo ✅ Setup complete!
echo.
echo 📝 Next steps:
echo.
echo 1. Make sure PostgreSQL is running
echo.
echo 2. Create database (if not exists):
echo    psql -U postgres -c "CREATE DATABASE feastflow;"
echo.
echo 3. Run migrations:
echo    cd backend
echo    npm run migrate
echo.
echo 4. Start backend (Terminal 1):
echo    cd backend
echo    npm run dev
echo.
echo 5. Start frontend (Terminal 2):
echo    cd frontend\app
echo    npm run dev
echo.
echo 6. Open your browser:
echo    http://localhost:3000
echo.
echo 📍 Test page: http://localhost:3000/test-auth
echo 📍 Login: http://localhost:3000/login
echo 📍 Signup: http://localhost:3000/signup
echo.
echo Default admin account:
echo Email: admin@feastflow.com
echo Password: Admin@123
echo.
pause
