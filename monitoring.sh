#!/bin/bash
# ========================================
# Monitor CPU, RAM et disque (robuste)
# - Fallback CPU si mpstat absent
# - Option --quiet pour ignorer les INFO
# - Alertes via alerts.sh
# ========================================

# Import des fonctions d'alerte
source /usr/local/lib/alerts.sh

# Seuils
CPU_THRESHOLD=90
RAM_THRESHOLD=90
DISK_THRESHOLD=90

# Mode quiet
QUIET=false
if [ "${1:-}" == "--quiet" ]; then
    QUIET=true
fi

# ===========================
# Vérification CPU
# ===========================
if command -v mpstat &>/dev/null; then
    CPU_USAGE_INT=$(LC_ALL=C mpstat 1 1 2>/dev/null \
      | awk 'NR>3 && NF>0 {idle=$NF} END { if(idle!="") printf("%.0f", 100 - idle); else print "" }')
else
    # fallback avec /proc/stat
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    TOTAL1=$((user+nice+system+idle+iowait+irq+softirq+steal))
    IDLE1=$idle
    sleep 1
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    TOTAL2=$((user+nice+system+idle+iowait+irq+softirq+steal))
    IDLE2=$idle
    DIFF_TOTAL=$((TOTAL2 - TOTAL1))
    DIFF_IDLE=$((IDLE2 - IDLE1))
    CPU_USAGE_INT=$(( (100 * (DIFF_TOTAL - DIFF_IDLE)) / DIFF_TOTAL ))
fi

if [ -z "$CPU_USAGE_INT" ]; then
    send_alert ERROR "Impossible de récupérer l'utilisation CPU"
    exit 1
fi

# ===========================
# Vérification RAM
# ===========================
MEMORY_USAGE_INT=$(LC_ALL=C free 2>/dev/null \
  | awk '/Mem/ { if($2>0) printf("%.0f", $3*100/$2) }')

if [ -z "$MEMORY_USAGE_INT" ]; then
    send_alert ERROR "Impossible de récupérer l'utilisation RAM"
    exit 1
fi

# ===========================
# Vérification Disque (/)
# ===========================
DISK_USAGE_INT=$(LC_ALL=C df -P / 2>/dev/null \
  | awk 'NR==2 {gsub("%","",$5); if($5 ~ /^[0-9]+(\.[0-9]+)?$/) printf("%.0f", $5); else print "" }')

if [ -z "$DISK_USAGE_INT" ]; then
    send_alert ERROR "Impossible de récupérer l'utilisation disque"
    exit 1
fi

# ===========================
# Création du message d'alerte
# ===========================
ALERT_MESSAGE=""

if [ "$CPU_USAGE_INT" -ge "$CPU_THRESHOLD" ]; then
    ALERT_MESSAGE+="CPU élevé : ${CPU_USAGE_INT}% (seuil ${CPU_THRESHOLD}%)\n"
fi

if [ "$MEMORY_USAGE_INT" -ge "$RAM_THRESHOLD" ]; then
    ALERT_MESSAGE+="RAM élevée : ${MEMORY_USAGE_INT}% (seuil ${RAM_THRESHOLD}%)\n"
fi

if [ "$DISK_USAGE_INT" -ge "$DISK_THRESHOLD" ]; then
    ALERT_MESSAGE+="Disque trop rempli : ${DISK_USAGE_INT}% (seuil ${DISK_THRESHOLD}%)\n"
fi

# ===========================
# Envoi d'alerte
# ===========================
if [ -n "$ALERT_MESSAGE" ]; then
    send_alert WARNING "$ALERT_MESSAGE"
else
    if [ "$QUIET" = false ]; then
        send_alert INFO "Ressources normales — CPU ${CPU_USAGE_INT}%, RAM ${MEMORY_USAGE_INT}%, DISK ${DISK_USAGE_INT}%"
    fi
fi
