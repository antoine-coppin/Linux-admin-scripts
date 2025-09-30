#!/bin/bash
# ========================================
# Script de sauvegarde d'un répertoire
# Sauvegarde quotidienne (cron ou systemd) avec rotation sur X jours
# Envoi d'un mail en cas d'erreur
# ========================================

# Variables
SOURCE_DIR="/etc"  # Répertoire que l'on souhaite sauvegarder
CLEAN_DIR=`basename $SOURCE_DIR`  # Retire le / du répertoire
BACKUP_DIR="/var/backups/$CLEAN_DIR" # Emplacement sauvegarde
BACKUP_FILE="$BACKUP_DIR/$CLEAN_DIR-backup-$DATE.tar.gz" # fichier de sauvegarde
LOG_FILE="/var/log/$CLEAN_DIR-backup.log" # fichier de log
RETENTION_DAYS=7  # Nombre de jours où l'on garde la sauvegarde
EMAIL="admin@example.com" # mail de réception de l'alerte
HOSTNAME=$(hostname)
DATE=$(date +%Y-%m-%d)

# Fonction pour envoyer une alerte mail, à commenter en cas d'absence de configuration smtp
send_alert() {
    local MESSAGE="$1"
    echo -e "$MESSAGE" | mail -s "Échec sauvegarde $SOURCE_DIR - $HOSTNAME" "$EMAIL"
}

# Vérifie si le répertoire de sauvegarde existe
if [ ! -d "$BACKUP_DIR" ]; then
    # Crée le répertoire de backup ou log l'échec + envoi d'une alerte mail en cas d'erreur
    mkdir -p "$BACKUP_DIR" || { 
        ERR="[$(date '+%Y-%m-%d %H:%M:%S')] Impossible de créer $BACKUP_DIR"
        echo "$ERR" | tee -a "$LOG_FILE"
        send_alert "$ERR" # à commenter en cas d'absence de configuration smtp
        exit 1 # interruption du script en cas d'erreur
    }
fi

# Création de la sauvegarde
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Début sauvegarde de $SOURCE_DIR" | tee -a "$LOG_FILE"
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>>"$LOG_FILE"

# Si la création a fonctionné: log de la réussite, sinon log l'échec + envoi alerte mail
if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sauvegarde réussie : $BACKUP_FILE" | tee -a "$LOG_FILE"
else
    ERR="[$(date '+%Y-%m-%d %H:%M:%S')] Erreur lors de la sauvegarde de $SOURCE_DIR"
    echo "$ERR" | tee -a "$LOG_FILE"
    send_alert "$ERR"
    exit 1 # interruption du script en cas d'erreur
fi

# Rotation des sauvegardes
find "$BACKUP_DIR" -type f -name "$CLEAN_DIR-backup-*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \; 2>>"$LOG_FILE"

# Si la rotation a fonctionné: log de la réussite, sinon log l'échec + envoi alerte mail
if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotation OK : suppression des sauvegardes > $RETENTION_DAYS jours" | tee -a "$LOG_FILE"
else
    ERR="[$(date '+%Y-%m-%d %H:%M:%S')] Erreur lors de la rotation des sauvegardes"
    echo "$ERR" | tee -a "$LOG_FILE"
    send_alert "$ERR" # à commenter en cas d'absence de configuration smtp
    exit 1
fi
