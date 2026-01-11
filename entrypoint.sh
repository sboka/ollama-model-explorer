#!/bin/sh
set -e

# Resolve host.docker.internal to IP address
HOST_IP=$(getent hosts host.docker.internal | awk '{ print $1 }')

if [ -z "$HOST_IP" ]; then
    echo "ERROR: Cannot resolve host.docker.internal"
    exit 1
fi

echo "Host IP resolved: host.docker.internal -> $HOST_IP"

# Redirect localhost:11434 -> host.docker.internal:11434
# This happens at the kernel level - completely transparent
iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 11434 -j DNAT --to-destination ${HOST_IP}:11434
iptables -t nat -A POSTROUTING -p tcp -d ${HOST_IP} --dport 11434 -j MASQUERADE

echo "iptables: localhost:11434 -> ${HOST_IP}:11434"

# Start the application
echo "Starting Ollama Model Explorer on port ${PORT}..."
exec gunicorn \
    --bind ${HOST}:${PORT} \
    --workers ${WORKERS} \
    --threads 2 \
    --access-logfile - \
    --error-logfile - \
    wsgi:app