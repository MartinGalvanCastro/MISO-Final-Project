#!/bin/bash
set -e

echo "Starting Inventory Service..."
echo "Running database migrations..."

# Run migrations
uv run alembic upgrade head

echo "Migrations completed successfully!"
echo "Starting FastAPI application..."

# Start the application
exec uv run uvicorn main:app --host 0.0.0.0 --port 8002