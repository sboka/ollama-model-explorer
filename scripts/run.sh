#!/usr/bin/env bash
#
# Run script for Unix-like systems (Linux, macOS)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-5000}"
WORKERS="${WORKERS:-4}"
ENV="${FLASK_ENV:-production}"

usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  dev         Run development server"
    echo "  prod        Run production server with gunicorn"
    echo "  test        Run tests"
    echo "  lint        Run linters"
    echo "  install     Install dependencies"
    echo "  help        Show this help message"
    echo ""
    echo "Options:"
    echo "  --host HOST     Host to bind to (default: $HOST)"
    echo "  --port PORT     Port to bind to (default: $PORT)"
    echo "  --workers N     Number of workers for production (default: $WORKERS)"
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON=python3
    elif command -v python &> /dev/null; then
        PYTHON=python
    else
        log_error "Python not found. Please install Python 3.8 or higher."
        exit 1
    fi
    
    log_info "Using Python: $($PYTHON --version)"
}

setup_venv() {
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment..."
        $PYTHON -m venv .venv
    fi
    
    source .venv/bin/activate
    log_info "Virtual environment activated"
}

install_deps() {
    setup_venv
    log_info "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if [ "$1" == "dev" ]; then
        pip install -r requirements-dev.txt
    fi
    
    log_info "Dependencies installed successfully"
}

run_dev() {
    setup_venv
    log_info "Starting development server on http://$HOST:$PORT"
    FLASK_ENV=development $PYTHON app.py --host "$HOST" --port "$PORT" --debug
}

run_prod() {
    setup_venv
    
    if command -v gunicorn &> /dev/null; then
        log_info "Starting production server with Gunicorn on http://$HOST:$PORT"
        gunicorn \
            --bind "$HOST:$PORT" \
            --workers "$WORKERS" \
            --access-logfile - \
            --error-logfile - \
            --capture-output \
            wsgi:app
    else
        log_warn "Gunicorn not found. Falling back to Flask development server."
        log_warn "Install gunicorn for production: pip install gunicorn"
        $PYTHON app.py --host "$HOST" --port "$PORT"
    fi
}

run_tests() {
    setup_venv
    log_info "Running tests..."
    pytest tests/ -v --cov=. --cov-report=term-missing
}

run_lint() {
    setup_venv
    log_info "Running linters..."
    
    if command -v black &> /dev/null; then
        black --check .
    fi
    
    if command -v isort &> /dev/null; then
        isort --check-only .
    fi
    
    if command -v flake8 &> /dev/null; then
        flake8 .
    fi
    
    if command -v mypy &> /dev/null; then
        mypy app.py config.py
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --workers)
            WORKERS="$2"
            shift 2
            ;;
        dev)
            check_python
            run_dev
            exit 0
            ;;
        prod)
            check_python
            run_prod
            exit 0
            ;;
        test)
            check_python
            run_tests
            exit 0
            ;;
        lint)
            check_python
            run_lint
            exit 0
            ;;
        install)
            check_python
            install_deps "$2"
            exit 0
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Default: show usage
usage