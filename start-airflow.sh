#!/bin/bash
#
# start-airflow.sh
# Version: 1.1.2
# Last Updated: 2025-08-24
#
# Description:
# Starts Apache Airflow in dev mode using Docker + WSL2.
# Includes stability fixes for DB/init/user race conditions.
#

# -----------------------
# Config & Color Constants
# -----------------------

AIRFLOW_CONTAINER="airflow-airflow-webserver-1"
INIT_CONTAINER="airflow-airflow-scheduler-1"
DOCKER_COMPOSE_FILE="docker-compose.yaml"
AIRFLOW_USER="admin"
AIRFLOW_PASSWORD="admin"
AIRFLOW_EMAIL="markholahan@pm.me"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

log()         { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}✔ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error()   { echo -e "${RED}✖ $1${NC}"; }

# -----------------------
# Flags
# -----------------------

SLOW_MODE=false
DEBUG_MODE=false

for arg in "$@"; do
  case $arg in
    --slow)  SLOW_MODE=true;  log_warn "Slow mode enabled — longer wait for Airflow UI." ;;
    --debug) DEBUG_MODE=true; log_warn "Debug mode enabled — full logs will be shown on failure." ;;
  esac
done

# -----------------------
# Helpers
# -----------------------

print_error_log() {
  echo -e "\n🪵 ${YELLOW}Showing Airflow webserver logs:${NC}"
  if $DEBUG_MODE; then
    docker logs "$AIRFLOW_CONTAINER" 2>&1 | tail -n 50
  else
    docker logs "$AIRFLOW_CONTAINER" 2>&1 | \
      grep -Ei "error|exception|traceback|failed|refused|unavailable|denied|not found|critical" | \
      tail -n 20
  fi
}

wait_for_ui() {
  log "Checking if Airflow UI is available …"
  MAX_ATTEMPTS=20
  $SLOW_MODE && MAX_ATTEMPTS=40

  for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    if curl --silent --fail http://localhost:8080/health; then
      log_success "Airflow UI is available!"
      return 0
    else
      log "Waiting for Airflow UI... ($i/$MAX_ATTEMPTS)"
      sleep 10
    fi
  done

  log_error "Airflow UI failed to start. Check Docker container logs."
  print_error_log
  return 1
}

wait_for_container_exit() {
  local container_name="$1"
  local max_retries=30
  local sleep_seconds=5

  log "Waiting for container '$container_name' to exit …"
  for ((i=1; i<=max_retries; i++)); do
    status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "missing")
    if [[ "$status" == "exited" ]]; then
      log_success "'$container_name' has exited."
      return 0
    elif [[ "$status" == "running" ]]; then
      log "Still running… ($i/$max_retries)"
    else
      log_warn "'$container_name' not found or already exited."
      return 0
    fi
    sleep $sleep_seconds
  done

  log_error "Container '$container_name' did not exit in time."
  return 1
}

# -----------------------
# Virtual Environment Setup
# -----------------------

log "Setting up Python virtual environment for testing..."

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  log_success "Virtual environment created."
fi

source .venv/bin/activate
log_success "Virtual environment activated."

if [ -f "requirements-dev.txt" ]; then
  pip install --quiet -r requirements-dev.txt
  log "Required Python packages installed from requirements-dev.txt."
else
  log_warn "requirements-dev.txt not found. Skipping pip install."
fi

log "You can now run test scripts like: python test_marketvol.py"

set -e

# -----------------------
# Docker + Airflow Setup
# -----------------------

log "Starting Docker containers …"
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d || {
  log_error "Failed to start Docker containers. Exiting."
  exit 1
}

log "Waiting for services to start …"
sleep 15

# wait_for_container_exit "$INIT_CONTAINER" -- seeing if skipping this works.

log "Checking if Airflow DB is initialized …"
db_status=$(docker exec "$INIT_CONTAINER" bash -c "airflow db check" 2>&1 || true)
if echo "$db_status" | grep -q "error\|not initialized\|unavailable"; then
  log_warn "Airflow DB not initialized. Initializing now …"
  docker exec "$INIT_CONTAINER" bash -c "airflow db init" || {
    log_error "Database initialization failed."
    print_error_log
    exit 1
  }
else
  log_success "Airflow DB already initialized."
fi

log "Checking if Airflow admin user exists …"
user_check=$(docker exec "$INIT_CONTAINER" bash -c "airflow users list | grep -i $AIRFLOW_USER" || true)
if [ -z "$user_check" ]; then
  log "Creating Airflow admin user …"
  for attempt in {1..5}; do
    docker exec "$INIT_CONTAINER" bash -c \
      "airflow users create --username $AIRFLOW_USER --firstname Mark --lastname Holahan --role Admin --email $AIRFLOW_EMAIL --password $AIRFLOW_PASSWORD" && break
    log_warn "Retrying user creation ($attempt/5) …"
    sleep 5
  done

  user_check=$(docker exec "$INIT_CONTAINER" bash -c "airflow users list | grep -i $AIRFLOW_USER" || true)
  if [ -z "$user_check" ]; then
    log_error "Failed to create admin user after retries."
    print_error_log
    exit 1
  else
    log_success "Admin user created successfully."
  fi
else
  log_success "Admin user already exists."
fi

log "Restarting webserver and scheduler …"
docker-compose restart airflow-webserver airflow-scheduler || {
  log_error "Restart failed."
  print_error_log
  exit 1
}

wait_for_ui
