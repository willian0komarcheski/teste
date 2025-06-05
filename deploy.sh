
#!/bin/bash
set -euo pipefail

LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1 # Redirect stdout/stderr to file and console

echo "Deployment script started at $(date)"
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

if [ ! -f docker-compose.yml ]; then
    echo "Error: docker-compose.yml not found in $(pwd)"
    exit 1
fi

echo "Bringing down existing services..."
docker-compose down --remove-orphans || echo "No existing services or error during down."

echo "Building images and starting services..."
docker-compose up -d --build --remove-orphans

echo "Waiting for services with health checks (max wait 120s)..."
SERVICES_TO_CHECK=("db" "redis" "auth-api" "record-api")
ALL_HEALTHY=false
TIMEOUT=120
INTERVAL=5
MAX_ATTEMPTS=$((TIMEOUT / INTERVAL))

for i in $(seq 1 $MAX_ATTEMPTS); do
    echo "Checking health status (Attempt $i/$MAX_ATTEMPTS)..."
    HEALTHY_COUNT=0
    ALL_SERVICES_CHECKED_THIS_ROUND=true # Flag to track if all services could be checked

    for SERVICE in "${SERVICES_TO_CHECK[@]}"; do
        CONTAINER_ID=$(docker-compose ps -q "$SERVICE" 2>/dev/null || echo "")
        if [ -z "$CONTAINER_ID" ]; then
             echo "  - $SERVICE: Container not found or not running yet."
             ALL_SERVICES_CHECKED_THIS_ROUND=false # Mark that we couldn't check everything this round
             continue # Skip to next service in the inner loop
        fi

        # Ensure correct quoting for format string
        HEALTH_STATUS=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no health check{{end}}' "$CONTAINER_ID" 2>/dev/null || echo "error inspecting")

        case "$HEALTH_STATUS" in
            "healthy")
                echo "  - $SERVICE: Healthy"
                HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
                ;;
            "unhealthy")
                 echo "  - $SERVICE: Unhealthy. Check logs: docker-compose logs $SERVICE"
                 ALL_SERVICES_CHECKED_THIS_ROUND=false # Treat unhealthy as not fully ready
                 ;;
            "starting")
                 echo "  - $SERVICE: Starting (Waiting...)"
                 ALL_SERVICES_CHECKED_THIS_ROUND=false # Not ready yet
                 ;;
            "no health check")
                 echo "  - $SERVICE: No health check configured (Skipping check)"
                 HEALTHY_COUNT=$((HEALTHY_COUNT + 1)) # Assume ready
                 ;;
            *) # Includes "error inspecting" or any other status
                 echo "  - $SERVICE: Status '$HEALTH_STATUS' (Waiting...)"
                 ALL_SERVICES_CHECKED_THIS_ROUND=false # Not ready yet
                 ;;
        esac
    done

    # Check if all services *that have health checks* are healthy
    if [ "$HEALTHY_COUNT" -eq "${#SERVICES_TO_CHECK[@]}" ]; then
        ALL_HEALTHY=true
        echo "All checked services are healthy or do not have health checks."
        break # Exit the outer loop (attempts loop)
    fi

    # If not all healthy yet, wait before next check
    if [ $i -lt $MAX_ATTEMPTS ]; then
      echo "Waiting $INTERVAL seconds before next check..."
      sleep $INTERVAL
    else
      # If it's the last attempt and not all are healthy
      echo "Timeout reached."
    fi
done

# Final check after the loop
if [ "$ALL_HEALTHY" = false ]; then
    echo "Error: Not all services became healthy within $TIMEOUT seconds."
    echo "Final Status Check:"
    docker-compose ps
    echo "Check service logs using 'docker-compose logs <service_name>'"
    # Optionally bring down services on failure
    # echo "Bringing down services due to health check failure..."
    # docker-compose down
    exit 1
fi

echo "Deployment appears successful. Services are up and running."
echo "You can view logs using: docker-compose logs -f"
echo "Deployment script finished at $(date)"

exit 0

