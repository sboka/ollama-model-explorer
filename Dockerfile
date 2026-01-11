# Ollama Model Explorer - Minimal Alpine Dockerfile

# Build stage
FROM python:3.13-alpine AS builder

WORKDIR /app

# Install build dependencies (needed for some Python packages)
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn && \
    # Remove unnecessary files to reduce size
    find /opt/venv -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type f -name "*.pyc" -delete 2>/dev/null || true && \
    find /opt/venv -type f -name "*.pyo" -delete 2>/dev/null || true && \
    find /opt/venv -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type d -name "test" -exec rm -rf {} + 2>/dev/null || true

# Production stage
FROM python:3.13-alpine AS production

WORKDIR /app

# socat is small and doesn't need special kernel capabilities
RUN apk add --no-cache socat

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application files
COPY --chown=appuser:appgroup app.py config.py wsgi.py entrypoint.sh ./
COPY --chown=appuser:appgroup templates/ ./templates/
COPY --chown=appuser:appgroup static/ ./static/

# Make executable
RUN chmod +x entrypoint.sh

# Switch to non-root user
USER appuser

# Environment variables
ENV FLASK_ENV=production \
    HOST=0.0.0.0 \
    PORT=5000 \
    WORKERS=4 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONOPTIMIZE=2

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

# CMD ["sh", "-c", "gunicorn --bind ${HOST}:${PORT} --workers ${WORKERS} --threads 2 --access-logfile - wsgi:app"]
ENTRYPOINT ["./entrypoint.sh"]