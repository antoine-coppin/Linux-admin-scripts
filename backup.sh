#!/bin/bash
# ========================================
# Script de sauvegarde d'un répertoire
# rotation sur X jours
# Envoi d'alertes via alerts.sh (Mail/Mattermost/Log)
# ========================================

# Import de la librairie d’alertes
source /usr/local/lib/alerts.sh

# Variables
SOURCE_DIR="/etc"                           # Répertoire que l'on souhaite sauvegarder
CLEAN_DIR=$(basename "$SOURCE_DIR")         # Retire le / du répertoire
BACKUP_DIR="/var/backups/$CLEAN_DIR"        # Emplacement sauvegarde
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/${CLEAN_DIR}-backup-$DATE.tar.gz" # fichier de sauvegarde
LOG_FILE="/var/log/${CLEAN_DIR}-backup.log" # fichier de log
RETENTION_DAYS=7                            # Nombre de jours où l'on garde la sauvegarde

# Vérifie si le répertoire de sauvegarde existe
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" || { 
        ERR="Impossible de créer $BACKUP_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $ERR" | tee -a "$LOG_FILE"
        send_alert "ERROR" "$ERR"
        exit 1
    }
fi

# Création de la sauvegarde
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Début sauvegarde de $SOURCE_DIR" | tee -a "$LOG_FILE"
if tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>>"$LOG_FILE"; then
    MSG="Sauvegarde réussie : $BACKUP_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" | tee -a "$LOG_FILE"
    send_alert "INFO" "$MSG"
else
    ERR="Erreur lors de la sauvegarde de $SOURCE_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $ERR" | tee -a "$LOG_FILE"
    send_alert "ERROR" "$ERR"
    exit 1
fi

# Rotation des sauvegardes
if find "$BACKUP_DIR" -type f -name "${CLEAN_DIR}-backup-*.tar.gz" -mtime +$RETENTION_DAYS -print -delete >>"$LOG_FILE" 2>&1; then
    MSG="Rotation OK : suppression des sauvegardes de plus de $RETENTION_DAYS jours"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" | tee -a "$LOG_FILE"
    send_alert "INFO" "$MSG"
else
    ERR="Erreur lors de la rotation des sauvegardes"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $ERR" | tee -a "$LOG_FILE"
    send_alert "ERROR" "$ERR"
    exit 1
fi
