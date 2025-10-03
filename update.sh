#!/bin/bash
# ========================================
# Script de mise à jour automatique
# Pour Debian/Ubuntu (apt)
# Avec gestion des alertes, mode --quiet
# et vérification du besoin de redémarrage
# ========================================

# Import des fonctions d'alerte
source /usr/local/lib/alerts.sh

# Sécurisation du script
set -euo pipefail

# Mode quiet
QUIET=false
if [ "${1:-}" == "--quiet" ]; then
    QUIET=true
fi

# ===========================
# Mise à jour des dépôts
# ===========================
if apt update -y >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then
        send_alert INFO "Mise à jour de la liste des paquets réussie"
    fi
else
    send_alert ERROR "Échec de la mise à jour de la liste des paquets"
    exit 1
fi

# ===========================
# Mise à niveau des paquets
# ===========================
if apt upgrade -y >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then
        send_alert INFO "Mise à niveau des paquets effectuée"
    fi
else
    send_alert ERROR "Échec de la mise à niveau des paquets"
    exit 1
fi

# ===========================
# Nettoyage des paquets obsolètes
# ===========================
if apt autoremove -y >/dev/null 2>&1 && apt autoclean -y >/dev/null 2>&1; then
    if [ "$QUIET" = false ]; then
        send_alert INFO "Nettoyage des paquets obsolètes effectué"
    fi
else
    send_alert WARNING "Nettoyage partiel des paquets obsolètes (vérification requise)"
fi

# ===========================
# Vérification du besoin de reboot
# ===========================
if [ -f /var/run/reboot-required ]; then
    send_alert WARNING "Un redémarrage est nécessaire après les mises à jour"
fi
