@REM docker build -t openclaw-python:latest .
docker compose down
docker build --pull --no-cache -t openclaw-python:latest .
docker compose up -d
