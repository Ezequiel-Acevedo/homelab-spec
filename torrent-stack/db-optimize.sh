#!/bin/sh

# Set paths to your compose file directory and database configuration directories
COMPOSE_DIR="$(pwd)"
RADARR_DB="./config/radarr/radarr.db"
SONARR_DB="./config/sonarr/sonarr.db"
PROWLARR_DB="./config/prowlarr/prowlarr.db"

echo "=== Starting Arr Stack Database Optimization ==="

# 1. Gracefully shut down the application containers to unlock the SQLite files
echo "Stopping containers to release database locks..."
docker compose down

# Function to execute raw SQLite internal optimizations
optimize_db() {
    DB_PATH=$1
    DB_NAME=$2

    if [ -f "$DB_PATH" ]; then
        echo "Optimizing $DB_NAME database..."
        
        # Reconstructs the entire database file, removing fragmentation and reclaiming space
        sqlite3 "$DB_PATH" "VACUUM;"
        
        # Gathers structural statistics about tables and indices for the query planner
        sqlite3 "$DB_PATH" "ANALYZE;"
        
        # Optimizes query execution integrity
        sqlite3 "$DB_PATH" "PRAGMA optimize;"
        
        echo "$DB_NAME optimization complete."
    else
        echo "Warning: Database not found at $DB_PATH"
    fi
}

# 2. Run optimizations against the databases
optimize_db "$RADARR_DB" "Radarr"
optimize_db "$SONARR_DB" "Sonarr"
optimize_db "$PROWLARR_DB" "Prowlarr"

# 3. Bring the stack back online
echo "Restarting containers..."
docker compose up -d

echo "=== Arr Stack Optimization Sequence Finished Successfully ==="
