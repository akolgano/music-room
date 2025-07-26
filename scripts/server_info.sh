#!/bin/bash

echo "===== SERVER CHARACTERISTICS ====="

echo -e "\n Platform:"
echo "Dockerized app running on host VM"

echo -e "\n Host OS:"
lsb_release -d

echo -e "\n🐍 Python Version (Host):"
python3 --version

echo -e "\nDocker Version:"
docker --version

echo -e "\nDocker Compose Version:"
docker-compose --version


echo -e "\nDisk:"
df -h / | tail -1


echo -e "\n🌐 Network Interfaces:"
ip a | grep inet | grep -v 127.0.0.1


echo -e "\n Database:"
engine_line=$(awk '/ENGINE/ { print; exit }' core/settings.py 2>/dev/null)

if echo "$engine_line" | grep -q "postgresql"; then
    echo "PostgreSQL"
elif echo "$engine_line" | grep -q "sqlite3"; then
    echo "SQLite"
else
    echo "Database not identified in settings.py"
fi

if docker-compose ps | grep -q "gunicorn"; then
    echo "Gunicorn is running"
elif grep -iq "gunicorn" docker/entrypoint.sh 2>/dev/null; then
    echo "Gunicorn configured in Docker Compose"
else
    echo "Gunicorn not detected"
fi

echo -e "\nCPU Cores:"
nproc

echo -e "\nRAM Size:"
free -h | awk '/Mem:/ { print $2 }'


