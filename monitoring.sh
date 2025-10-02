#!/bin/bash
# ========================================
# Monitor CPU, RAM et disque
# Utilise alerts.sh pour notifier
# ========================================

# Import de la librairie d’alertes
source /usr/local/lib/alerts.sh

# Seuils à définir
CPU_THRESHOLD=90
RAM_THRESHOLD=90
DISK_THRESHOLD=90

# Vérification CPU
CPU_USAGE=$(mpstat 1 1 | awk '/Average:/ {print 100 - $12}')
CPU_USAGE_INT=${CPU_USAGE%.*}

# Vérification RAM
MEMORY_USAGE=$(free | awk '/Mem/ {print $3*100/$2}')
MEMORY_USAGE_INT=${MEMORY_USAGE%.*}

# Vérification Disque
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_USAGE_INT=$DISK_USAGE

# Création du message d’alerte
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

# Envoi de l’alerte
if [ -n "$ALERT_MESSAGE" ]; then
    send_alert "WARNING" "$ALERT_MESSAGE"
else
    send_alert "INFO" "✅ Ressources normales"
fi
