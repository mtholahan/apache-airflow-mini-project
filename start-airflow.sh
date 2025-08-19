#!/bin/bash

echo "📦 Setting up local virtual environment for Python testing..."

# Create venv if it doesn't exist
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "✅ Virtual environment created."
fi

# Activate venv
source .venv/bin/activate
echo "✅ Virtual environment activated."

# Install required packages from requirements-dev.txt
if [ -f "requirements-dev.txt" ]; then
    pip install --quiet -r requirements-dev.txt
    echo "📚 Required Python packages installed from requirements-dev.txt."
else
    echo "⚠️ requirements-dev.txt not found. Skipping pip install."
fi

# Reminder to the user
echo "🧪 You can now run test scripts like: python test_marketvol.py"

set -e

AIRFLOW_CONTAINER="airflow-airflow-webserver-1"
DOCKER_COMPOSE_FILE="docker-compose.yaml"
AIRFLOW_USER="admin"
AIRFLOW_PASSWORD="admin"
AIRFLOW_EMAIL="markholahan@pm.me"

print_error_log() {
  echo "\n🪵 Showing relevant Airflow webserver logs (errors only):"
  docker logs "$AIRFLOW_CONTAINER" 2>&1 | \
    grep -Ei "error|exception|traceback|failed|refused|unavailable|denied|not found|critical" | \
    tail -n 20
}

echo "🚀 Starting Docker containers …"
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d || {
  echo "❌ Failed to start Docker containers. Exiting."
  exit 1
}

# Wait for all services to be healthy
echo "⏳ Waiting for services to start …"
sleep 10

# Check if DB is initialized
echo "🔍 Checking if Airflow DB is initialized …"
db_status=$(docker exec "$AIRFLOW_CONTAINER" bash -c "airflow db check" 2>&1 || true)
if echo "$db_status" | grep -q "error\|not initialized\|unavailable"; then
  echo "⚠️  Airflow DB not initialized. Initializing now …"
  docker exec "$AIRFLOW_CONTAINER" bash -c "airflow db init" || {
    echo "❌ Database initialization failed."
    print_error_log
    exit 1
  }
else
  echo "✅ Airflow DB already initialized."
fi

# Check for Airflow admin user
echo "🔍 Checking if Airflow admin user exists …"
user_check=$(docker exec "$AIRFLOW_CONTAINER" bash -c "airflow users list | grep -i $AIRFLOW_USER" || true)
if [ -z "$user_check" ]; then
  echo "➕ Creating Airflow admin user …"
  docker exec "$AIRFLOW_CONTAINER" bash -c \
    "airflow users create --username $AIRFLOW_USER --firstname Mark --lastname Holahan --role Admin --email $AIRFLOW_EMAIL --password $AIRFLOW_PASSWORD" || {
    echo "❌ Failed to create admin user."
    print_error_log
    exit 1
  }
else
  echo "✅ Admin user already exists."
fi

# Restart webserver and scheduler to apply DB + user updates
echo "🔄 Restarting webserver and scheduler …"
docker-compose restart airflow-webserver airflow-scheduler || {
  echo "❌ Restart failed."
  print_error_log
  exit 1
}

# Wait for UI availability
echo "🌐 Checking if Airflow UI is available …"
for i in {1..10}; do
  if curl -s --head http://localhost:8080 | grep -q "200 OK"; then
    echo "✅ Airflow UI is available at: http://localhost:8080"
    echo "🎯 All systems should be up. You're good to go!"
    exit 0
  fi
  sleep 3
done

echo "❌ Airflow UI failed to start. Check Docker container logs for issues."
print_error_log
exit 1
