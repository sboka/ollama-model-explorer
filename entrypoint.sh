#!/bin/sh
set -e

echo "Starting proxy: localhost:11434 -> host.docker.internal:11434"
socat TCP-LISTEN:11434,fork,reuseaddr,bind=127.0.0.1 TCP:host.docker.internal:11434 &

echo "Starting Ollama Model Explorer on port ${PORT}..."
exec gunicorn \
    --bind ${HOST}:${PORT} \
    --workers ${WORKERS} \
    --threads 2 \
    --access-logfile - \
    --error-logfile - \
    wsgi:app