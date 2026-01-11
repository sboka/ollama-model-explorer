# Ollama Model Explorer - Makefile
# Cross-platform compatible (use with GNU Make)

.PHONY: help install install-dev dev prod test lint format clean docker-build docker-run docker-stop

# Default target
help:
	@echo "Ollama Model Explorer - Available Commands"
	@echo ""
	@echo "  make install      Install production dependencies"
	@echo "  make install-dev  Install development dependencies"
	@echo "  make dev          Run development server"
	@echo "  make prod         Run production server"
	@echo "  make test         Run tests"
	@echo "  make lint         Run linters"
	@echo "  make format       Format code"
	@echo "  make clean        Clean build artifacts"
	@echo "  make docker-build Build Docker image"
	@echo "  make docker-run   Run Docker container"
	@echo "  make docker-stop  Stop Docker container"
	@echo ""

# Variables
PYTHON := python3
VENV := .venv
HOST ?= 0.0.0.0
PORT ?= 5000
WORKERS ?= 4

# Detect OS
ifeq ($(OS),Windows_NT)
	VENV_BIN := $(VENV)/Scripts
	PYTHON := python
else
	VENV_BIN := $(VENV)/bin
endif

# Virtual environment
$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(VENV_BIN)/pip install --upgrade pip

# Install dependencies
install: $(VENV)
	$(VENV_BIN)/pip install -r requirements.txt

install-dev: $(VENV)
	$(VENV_BIN)/pip install -r requirements.txt
	$(VENV_BIN)/pip install -r requirements-dev.txt

# Development server
dev: $(VENV)
	FLASK_ENV=development $(VENV_BIN)/python app.py --host $(HOST) --port $(PORT) --debug

# Production server
prod: $(VENV)
ifeq ($(OS),Windows_NT)
	$(VENV_BIN)/waitress-serve --host=$(HOST) --port=$(PORT) --threads=$(WORKERS) wsgi:app
else
	$(VENV_BIN)/gunicorn --bind $(HOST):$(PORT) --workers $(WORKERS) wsgi:app
endif

# Testing
test: $(VENV)
	$(VENV_BIN)/pytest tests/ -v --cov=. --cov-report=term-missing

# Linting
lint: $(VENV)
	$(VENV_BIN)/black --check .
	$(VENV_BIN)/isort --check-only .
	$(VENV_BIN)/flake8 .
	$(VENV_BIN)/mypy app.py config.py

# Format code
format: $(VENV)
	$(VENV_BIN)/black .
	$(VENV_BIN)/isort .

# Clean
clean:
	rm -rf $(VENV)
	rm -rf __pycache__
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf *.egg-info
	rm -rf dist
	rm -rf build
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Docker
docker-build:
	docker build -t ollama-model-explorer:latest .

docker-run:
	docker run -d \
		--name ollama-model-explorer \
		-p $(PORT):5000 \
		-e SECRET_KEY=your-secret-key \
		ollama-model-explorer:latest

docker-stop:
	docker stop ollama-model-explorer || true
	docker rm ollama-model-explorer || true

docker-compose-up:
	docker-compose up -d

docker-compose-down:
	docker-compose down