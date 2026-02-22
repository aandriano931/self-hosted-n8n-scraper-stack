#!/bin/bash

# --- Chargement de la configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
    # On exporte les variables pour qu'elles soient disponibles pour les sous-processus (docker/rclone)
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "[$(date)] Configuration loaded from $ENV_FILE"
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# --- Vérification des prérequis ---
MANDATORY_VARS=(SCRAPE_DB_NAME POSTGRES_USER RCLONE_REMOTE RCLONE_BUCKET)
for var in "${MANDATORY_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Variable $var is not set in .env"
        exit 1
    fi
done

# --- Variables de travail ---
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_${SCRAPE_DB_NAME}_${TIMESTAMP}.sql.gz"
EXIT_CODE=0

echo "[$(date)] Starting backup of $SCRAPE_DB_NAME to $RCLONE_REMOTE:$RCLONE_BUCKET..."

# --- Exécution ---
# Note : Le mot de passe doit être géré via ~/.pgpass pour plus de sécurité
pg_dump -U "$POSTGRES_USER" "$SCRAPE_DB_NAME" | gzip | rclone rcat "$BACKUP_RCLONE_REMOTE:$BACKUP_RCLONE_BUCKET/$BACKUP_NAME"

# On capture le code de sortie du pipe
EXIT_CODE=${PIPESTATUS[0]}

# --- Gestion du résultat ---
if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date)] Backup successful: $BACKUP_NAME"
else
    echo "[$(date)] Backup failed with exit code $EXIT_CODE"
    
    # Notification Discord si l'URL est fournie
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        PAYLOAD="{\"content\": \"⚠️ **[BACKUP FAILURE]** on \`$(hostname)\`\\nDatabase: \`$SCRAPE_DB_NAME\`\\nStatus: Failed with exit code $EXIT_CODE\"}"
        curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK_URL" > /dev/null
    fi
    exit 1
fi