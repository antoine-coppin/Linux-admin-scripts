#!/bin/bash
# ========================================
# Script de sauvegarde d'un répertoire
# Rotation sur X jours
# Vérification d’intégrité immédiate + sur Y jours
# ========================================

# Import des fonctions d'alerte
source /usr/local/lib/alerts.sh

# Variables
SOURCE_DIR="/etc"  # Répertoire à sauvegarder
CLEAN_DIR=$(basename "$SOURCE_DIR")
BACKUP_DIR="/var/backups/$CLEAN_DIR"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/$CLEAN_DIR-backup-$DATE.tar.gz"
RETENTION_DAYS=7 # Nombre de sauvegardes en mémoire
VERIFY_LAST=3    # Nombre de sauvegardes récentes à vérifier

# Vérifie si le répertoire de sauvegarde existe
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" || { 
        send_alert "ERROR" "Impossible de créer $BACKUP_DIR"
        exit 1
    }
fi

# ===========================
# Création de la sauvegarde
# ===========================
if tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null; then
    send_alert INFO "Sauvegarde réussie : $BACKUP_FILE"
else
    send_alert ERROR "Erreur lors de la création de la sauvegarde de $SOURCE_DIR"
    exit 1
fi

# ===========================
# Vérification immédiate d’intégrité
# ===========================
if tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
    send_alert INFO "Vérification OK : $BACKUP_FILE lisible"
else
    send_alert ERROR "Archive corrompue (supprimée) : $BACKUP_FILE"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# ===========================
# Vérification des N dernières archives
# ===========================
RECENT_FILES=$(ls -1t "$BACKUP_DIR"/$CLEAN_DIR-backup-*.tar.gz 2>/dev/null | head -n $VERIFY_LAST)

for FILE in $RECENT_FILES; do
    if tar -tzf "$FILE" >/dev/null 2>&1; then
        send_alert INFO "Archive OK : $FILE"
    else
        send_alert ERROR "Archive corrompue détectée : $FILE"
    fi
done

# ===========================
# Rotation des sauvegardes
# ===========================
if find "$BACKUP_DIR" -type f -name "$CLEAN_DIR-backup-*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;; then
    send_alert INFO "Rotation OK : sauvegardes > $RETENTION_DAYS jours supprimées"
else
    send_alert WARNING "Erreur lors de la rotation des sauvegardes"
fi
