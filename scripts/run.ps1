#Requires -Version 5.1
<#
.SYNOPSIS
    Run script for Ollama Model Explorer (PowerShell)

.DESCRIPTION
    Cross-platform PowerShell script to manage the application

.PARAMETER Command
    The command to execute: dev, prod, test, install, help

.PARAMETER Host
    Host to bind to (default: 0.0.0.0)

.PARAMETER Port
    Port to bind to (default: 5000)

.PARAMETER Workers
    Number of workers for production (default: 4)

.EXAMPLE
    .\run.ps1 dev
    .\run.ps1 prod -Port 8080
    .\run.ps1 install dev
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("dev", "prod", "test", "lint", "install", "help")]
    [string]$Command = "help",
    
    [string]$Host = "0.0.0.0",
    [int]$Port = 5000,
    [int]$Workers = 4,
    [switch]$Dev
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Set-Location $ProjectDir

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Test-Python {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        $python = Get-Command python3 -ErrorAction SilentlyContinue
    }
    if (-not $python) {
        Write-Err "Python not found. Please install Python 3.8 or higher."
        exit 1
    }
    $version = & $python.Source --version
    Write-Info "Using Python: $version"
    return $python.Source
}

function Initialize-Venv {
    param([string]$Python)
    
    if (-not (Test-Path ".venv")) {
        Write-Info "Creating virtual environment..."
        & $Python -m venv .venv
    }
    
    if ($IsWindows -or $env:OS -match "Windows") {
        & .\.venv\Scripts\Activate.ps1
    } else {
        & ./.venv/bin/Activate.ps1
    }
    Write-Info "Virtual environment activated"
}

function Install-Dependencies {
    param([string]$Python, [bool]$IncludeDev)
    
    Initialize-Venv -Python $Python
    Write-Info "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if ($IncludeDev) {
        pip install -r requirements-dev.txt
    }
    Write-Info "Dependencies installed successfully"
}

function Start-DevServer {
    param([string]$Python)
    
    Initialize-Venv -Python $Python
    Write-Info "Starting development server on http://${Host}:${Port}"
    $env:FLASK_ENV = "development"
    & python app.py --host $Host --port $Port --debug
}

function Start-ProdServer {
    param([string]$Python)
    
    Initialize-Venv -Python $Python
    
    $waitress = Get-Command waitress-serve -ErrorAction SilentlyContinue
    $gunicorn = Get-Command gunicorn -ErrorAction SilentlyContinue
    
    if ($IsWindows -or $env:OS -match "Windows") {
        if ($waitress) {
            Write-Info "Starting production server with Waitress on http://${Host}:${Port}"
            & waitress-serve --host=$Host --port=$Port --threads=$Workers wsgi:app
        } else {
            Write-Warn "Waitress not found. Install with: pip install waitress"
            Write-Warn "Falling back to Flask development server."
            & python app.py --host $Host --port $Port
        }
    } else {
        if ($gunicorn) {
            Write-Info "Starting production server with Gunicorn on http://${Host}:${Port}"
            & gunicorn --bind "${Host}:${Port}" --workers $Workers wsgi:app
        } elseif ($waitress) {
            Write-Info "Starting production server with Waitress on http://${Host}:${Port}"
            & waitress-serve --host=$Host --port=$Port --threads=$Workers wsgi:app
        } else {
            Write-Warn "No production server found. Install with: pip install gunicorn waitress"
            & python app.py --host $Host --port $Port
        }
    }
}

function Invoke-Tests {
    param([string]$Python)
    
    Initialize-Venv -Python $Python
    Write-Info "Running tests..."
    & pytest tests/ -v --cov=. --cov-report=term-missing
}

function Invoke-Lint {
    param([string]$Python)
    
    Initialize-Venv -Python $Python
    Write-Info "Running linters..."
    
    if (Get-Command black -ErrorAction SilentlyContinue) {
        & black --check .
    }
    if (Get-Command isort -ErrorAction SilentlyContinue) {
        & isort --check-only .
    }
    if (Get-Command flake8 -ErrorAction SilentlyContinue) {
        & flake8 .
    }
}

function Show-Help {
    Write-Host @"
Usage: .\run.ps1 <Command> [Options]

Commands:
    dev         Run development server
    prod        Run production server
    test        Run tests
    lint        Run linters
    install     Install dependencies
    help        Show this help message

Options:
    -Host       Host to bind to (default: 0.0.0.0)
    -Port       Port to bind to (default: 5000)
    -Workers    Number of workers for production (default: 4)
    -Dev        Include dev dependencies when installing

Examples:
    .\run.ps1 dev
    .\run.ps1 prod -Port 8080
    .\run.ps1 install -Dev
"@
}

# Main execution
$Python = Test-Python

switch ($Command) {
    "dev" { Start-DevServer -Python $Python }
    "prod" { Start-ProdServer -Python $Python }
    "test" { Invoke-Tests -Python $Python }
    "lint" { Invoke-Lint -Python $Python }
    "install" { Install-Dependencies -Python $Python -IncludeDev $Dev }
    "help" { Show-Help }
    default { Show-Help }
}