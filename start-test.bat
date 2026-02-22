@echo off
REM FeastFlow Authentication Integration Test Script (Windows)
REM This script starts both backend and frontend for testing

echo  Starting FeastFlow Authentication Test...
echo.

REM Check if backend dependencies are installed
if not exist "backend\node_modules" (
    echo  Installing backend dependencies...
    cd backend
    call npm install
    cd ..
)

REM Check if frontend dependencies are installed
if not exist "frontend\app\node_modules" (
    echo  Installing frontend dependencies...
    cd frontend\app
    call npm install
    cd ..\..
)

echo.
echo  Setup complete!
echo.
echo Starting services...
echo.
echo  Backend will run on: http://localhost:5000
echo  Frontend will run on: http://localhost:3000
echo  Test page: http://localhost:3000/test-auth
echo.
echo Press Ctrl+C in each terminal window to stop services
echo.

REM Start backend in new terminal
start "FeastFlow Backend" cmd /k "cd backend && npm run dev"

REM Wait a bit for backend to start
timeout /t 3 /nobreak >nul

REM Start frontend in new terminal
start "FeastFlow Frontend" cmd /k "cd frontend\app && npm run dev"

echo.
echo  Services starting in separate windows!
echo.
echo Test the integration:
echo 1. Open http://localhost:3000/test-auth
echo 2. Check the API status
echo 3. Try the test buttons
echo 4. Visit http://localhost:3000/signup to create an account
echo 5. Visit http://localhost:3000/login to sign in
echo.
echo Close the terminal windows to stop services
pause
