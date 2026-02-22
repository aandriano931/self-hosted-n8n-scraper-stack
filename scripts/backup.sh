#!/bin/bash

# --- Chargement de la configuration ---
# On cherche le fichier .env dans le même dossier que le script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found. Please copy .env.example to .env and fill it."
    exit 1
fi

# --- Vérification des prérequis ---
MANDATORY_VARS=(DB_NAME DB_USER RCLONE_REMOTE RCLONE_BUCKET)
for var in "${MANDATORY_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Variable $var is not set in .env"
        exit 1
    fi
done

# --- Variables de travail ---
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_${DB_NAME}_${TIMESTAMP}.sql.gz"
EXIT_CODE=0

echo "[$(date)] Starting backup of $DB_NAME to $RCLONE_REMOTE:$RCLONE_BUCKET..."

# --- Exécution ---
# Note : Le mot de passe doit être géré via ~/.pgpass pour plus de sécurité
pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip | rclone rcat "$BACKUP_RCLONE_REMOTE:$BACKUP_RCLONE_BUCKET/$BACKUP_NAME"

# On capture le code de sortie du pipe
EXIT_CODE=${PIPESTATUS[0]}

# --- Gestion du résultat ---
if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date)] Backup successful: $BACKUP_NAME"
else
    echo "[$(date)] Backup failed with exit code $EXIT_CODE"
    
    # Notification Discord si l'URL est fournie
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        PAYLOAD="{\"content\": \"⚠️ **[BACKUP FAILURE]** on \`$(hostname)\`\\nDatabase: \`$DB_NAME\`\\nStatus: Failed with exit code $EXIT_CODE\"}"
        curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK_URL" > /dev/null
    fi
    exit 1
fi