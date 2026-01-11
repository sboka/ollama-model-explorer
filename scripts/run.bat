@echo off
setlocal enabledelayedexpansion

:: Run script for Windows (Command Prompt)

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

cd /d "%PROJECT_DIR%"

:: Default values
if not defined HOST set "HOST=0.0.0.0"
if not defined PORT set "PORT=5000"
if not defined WORKERS set "WORKERS=4"

:: Parse arguments
set "COMMAND=%1"

if "%COMMAND%"=="" goto :usage
if "%COMMAND%"=="help" goto :usage
if "%COMMAND%"=="--help" goto :usage
if "%COMMAND%"=="-h" goto :usage
if "%COMMAND%"=="dev" goto :dev
if "%COMMAND%"=="prod" goto :prod
if "%COMMAND%"=="test" goto :test
if "%COMMAND%"=="install" goto :install

echo [ERROR] Unknown command: %COMMAND%
goto :usage

:usage
echo Usage: %~nx0 COMMAND [OPTIONS]
echo.
echo Commands:
echo   dev         Run development server
echo   prod        Run production server with waitress
echo   test        Run tests
echo   install     Install dependencies
echo   help        Show this help message
echo.
echo Options:
echo   Set environment variables HOST, PORT, WORKERS before running
echo.
goto :eof

:check_python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.8 or higher.
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do echo [INFO] Using Python: %%i
goto :eof

:setup_venv
if not exist ".venv" (
    echo [INFO] Creating virtual environment...
    python -m venv .venv
)
call .venv\Scripts\activate.bat
echo [INFO] Virtual environment activated
goto :eof

:install
call :check_python
call :setup_venv
echo [INFO] Installing dependencies...
pip install --upgrade pip
pip install -r requirements.txt
if "%2"=="dev" (
    pip install -r requirements-dev.txt
)
echo [INFO] Dependencies installed successfully
goto :eof

:dev
call :check_python
call :setup_venv
echo [INFO] Starting development server on http://%HOST%:%PORT%
set FLASK_ENV=development
python app.py --host %HOST% --port %PORT% --debug
goto :eof

:prod
call :check_python
call :setup_venv
where waitress-serve >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Starting production server with Waitress on http://%HOST%:%PORT%
    waitress-serve --host=%HOST% --port=%PORT% --threads=%WORKERS% wsgi:app
) else (
    echo [WARN] Waitress not found. Install with: pip install waitress
    echo [WARN] Falling back to Flask development server.
    python app.py --host %HOST% --port %PORT%
)
goto :eof

:test
call :check_python
call :setup_venv
echo [INFO] Running tests...
pytest tests\ -v --cov=. --cov-report=term-missing
goto :eof