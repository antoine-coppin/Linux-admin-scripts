#!/bin/bash
# ========================================
# Script de sauvegarde d'un répertoire
# Utilise alerts.sh pour notifier
# ========================================

# Import de la librairie d’alertes
source /usr/local/lib/alerts.sh

# Variables
SOURCE_DIR="/etc"                           # Répertoire à sauvegarder
CLEAN_DIR=$(basename "$SOURCE_DIR")         # Retire le / du répertoire
BACKUP_DIR="/var/backups/$CLEAN_DIR"        # Emplacement sauvegarde
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/${CLEAN_DIR}-backup-$DATE.tar.gz"
RETENTION_DAYS=7                            # Nombre de jours à garder

# Vérifie si le répertoire de sauvegarde existe
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" || { 
        send_alert "ERROR" "Impossible de créer $BACKUP_DIR"
        exit 1
    }
fi

# Création de la sauvegarde
if tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null; then
    send_alert "INFO" "✅ Sauvegarde réussie : $BACKUP_FILE"
else
    send_alert "ERROR" "❌ Erreur lors de la sauvegarde de $SOURCE_DIR"
    exit 1
fi

# Rotation des sauvegardes
if find "$BACKUP_DIR" -type f -name "${CLEAN_DIR}-backup-*.tar.gz" -mtime +$RETENTION_DAYS -print -delete 2>/dev/null; then
    send_alert "INFO" "🧹 Rotation OK : suppression des sauvegardes de plus de $RETENTION_DAYS jours"
else
    send_alert "ERROR" "❌ Erreur lors de la rotation des sauvegardes"
    exit 1
fi
