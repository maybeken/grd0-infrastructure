#!/bin/bash

# Migration tasks when transitioning to new version
docker exec nexterp-frontend-1 bench --site frontend migrate
# Manually clear cache to resolve issue in https://github.com/frappe/frappe_docker/issues/1353
docker exec nexterp-frontend-1 bench --site frontend clear-cache
docker exec nexterp-frontend-1 bench --site frontend clear-website-cache

# Run the following if cache is failed to clear
# docker compose down                                       # Shutdown application
# docker volume rm nexterp_redis-queue-data nexterp_logs    # Delete volume for redis queue and logs to clear cache
# docker compose up -d                                      # Start up application