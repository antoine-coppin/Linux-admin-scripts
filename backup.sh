#!/bin/bash
# ========================================
# Script de sauvegarde d'un répertoire
# Sauvegarde quotidienne (cron ou systemd)
# avec rotation sur X jours
# Option --quiet : ignore les alertes INFO
# ========================================

# Import des fonctions d'alerte
source /usr/local/lib/alerts.sh

# Sécurisation du script
set -euo pipefail

# Variables
SOURCE_DIR="/etc"                          # Répertoire à sauvegarder
CLEAN_DIR=$(basename "$SOURCE_DIR")        # Nom sans /
BACKUP_DIR="/var/backups/$CLEAN_DIR"       # Emplacement sauvegarde
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/$CLEAN_DIR-backup-$DATE.tar.gz"
RETENTION_DAYS=7                           # Jours de conservation

# Mode quiet
QUIET=false
if [ "${1:-}" == "--quiet" ]; then
    QUIET=true
fi

# ===========================
# Vérification des dépendances
# ===========================
for cmd in tar find; do
    if ! command -v "$cmd" &>/dev/null; then
        send_alert ERROR "Commande manquante : $cmd"
        exit 1
    fi
done

# ===========================
# Création du répertoire
# ===========================
if [ ! -d "$BACKUP_DIR" ]; then
    if ! mkdir -p "$BACKUP_DIR"; then
        send_alert ERROR "Impossible de créer le répertoire $BACKUP_DIR"
        exit 1
    fi
    if [ "$QUIET" = false ]; then
        send_alert INFO "Répertoire de sauvegarde créé : $BACKUP_DIR"
    fi
fi

# ===========================
# Création de la sauvegarde
# ===========================
if tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null; then
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        if [ "$QUIET" = false ]; then
            send_alert INFO "Sauvegarde réussie : $BACKUP_FILE"
        fi
    else
        send_alert ERROR "Le fichier $BACKUP_FILE est vide ou introuvable après tar"
        exit 1
    fi
else
    send_alert ERROR "Erreur lors de la sauvegarde de $SOURCE_DIR"
    exit 1
fi

# ===========================
# Rotation des sauvegardes
# ===========================
if find "$BACKUP_DIR" -type f -name "$CLEAN_DIR-backup-*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \; 2>/dev/null; then
    if [ "$QUIET" = false ]; then
        send_alert INFO "Rotation effectuée : suppression des sauvegardes > $RETENTION_DAYS jours"
    fi
else
    send_alert WARNING "Rotation échouée dans $BACKUP_DIR (à vérifier)"
fi
