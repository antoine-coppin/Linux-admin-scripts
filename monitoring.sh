#!/bin/bash

# ===========================
# Monitor CPU, RAM et disque
# Alerte par email + log local
# ===========================

# Configuration
EMAIL="admin@example.com"         # destinataire
LOG_FILE="/var/log/monitor_resources.log"
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Seuils à définir
CPU_THRESHOLD=90      # %
RAM_THRESHOLD=90      # %
DISK_THRESHOLD=90     # %

# ===========================
# Vérification CPU (via mpstat)
# ===========================
# mpstat 1 1 -> mesure CPU pendant 1 seconde, 1 rapport
# $12 = %idle, donc utilisation = 100 - idle
CPU_USAGE=$(mpstat 1 1 | awk '/Average:/ {print 100 - $12}')
CPU_USAGE_INT=${CPU_USAGE%.*}    # Transforme le float en int

# ===========================
# Vérification RAM
# ===========================
MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
MEMORY_USAGE_INT=${MEMORY_USAGE%.*}    # Transforme le float en int

# ===========================
# Vérification Disque (/)
# ===========================
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_USAGE_INT=$DISK_USAGE    # Transforme le float en int

# ===========================
# Création du message
# ===========================
ALERT_MESSAGE=""

if [ "$CPU_USAGE_INT" -ge "$CPU_THRESHOLD" ]; then
    ALERT_MESSAGE+="CPU élevé : $CPU_USAGE_INT% (seuil $CPU_THRESHOLD%)\n"
fi

if [ "$MEMORY_USAGE_INT" -ge "$RAM_THRESHOLD" ]; then
    ALERT_MESSAGE+="RAM élevée : $MEMORY_USAGE_INT% (seuil $RAM_THRESHOLD%)\n"
fi

if [ "$DISK_USAGE_INT" -ge "$DISK_THRESHOLD" ]; then
    ALERT_MESSAGE+="Disque trop rempli : $DISK_USAGE_INT% (seuil $DISK_THRESHOLD%)\n"
fi

# ===========================
# Logging + Envoi du mail
# ===========================
if [ -n "$ALERT_MESSAGE" ]; then
    FULL_MESSAGE="[$DATE] Alerte sur $HOSTNAME\n\n$ALERT_MESSAGE"

    # Log local
    echo -e "$FULL_MESSAGE" >> "$LOG_FILE"

    # Envoi du mail
    echo -e "$FULL_MESSAGE" \
    | mail -s "Alerte Ressources - $HOSTNAME" "$EMAIL"
fi
