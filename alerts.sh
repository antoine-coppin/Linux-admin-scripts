#!/bin/bash
# ==========================================
# Bibliothèque d'alertes
# Envoi par Mail, Mattermost, Log local au choix
# avec niveaux INFO / WARNING / ERROR
# ==========================================

# ---- CONFIG ----
# Email (laisse vide si pas utilisé)
ALERT_EMAIL="admin@example.com"

# Webhook Mattermost (laisse vide si pas utilisé)
MATTERMOST_WEBHOOK="https://mattermost.example.com/hooks/abcdefgh1234567890"

# Fichier log local
ALERT_LOG="/var/log/alerts.log"

# ---- FONCTION GENERIQUE ----
send_alert() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local HOSTNAME=$(hostname)
    local DATE=$(date '+%Y-%m-%d %H:%M:%S')

    # Définition du label et des emojis
    case "$LEVEL" in
        INFO)
            SUBJECT="ℹ️ [INFO] $HOSTNAME"
            ICON=":information_source:"
            ;;
        WARNING)
            SUBJECT="⚠️ [WARNING] $HOSTNAME"
            ICON=":warning:"
            ;;
        ERROR)
            SUBJECT="❌ [ERROR] $HOSTNAME"
            ICON=":x:"
            ;;
        *)
            SUBJECT="[ALERTE] $HOSTNAME"
            ICON=":speech_balloon:"
            ;;
    esac

    # Corps du message
    BODY="[$DATE] ($HOSTNAME) [$LEVEL] $MESSAGE"

    # Le log local est renseigné dans tous les cas.
    # ---- LOG LOCAL ----
    echo "$BODY" >> "$ALERT_LOG"

    # Pour le mail et mattermost, on vérifie d'abord que la variable est bien remplie avant d'utiliser ce moyen.
    # ---- ENVOI MAIL ----
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$BODY" | mail -s "$SUBJECT" "$ALERT_EMAIL"
    fi

    # ---- ENVOI MATTERMOST ----
    if [ -n "$MATTERMOST_WEBHOOK" ]; then
        PAYLOAD=$(cat <<EOF
{
    "username": "sysbot",
    "icon_emoji": "$ICON",
    "text": "$BODY"
}
EOF
)
        curl -s -o /dev/null -X POST \
            -H 'Content-Type: application/json' \
            -d "$PAYLOAD" \
            "$MATTERMOST_WEBHOOK"
    fi
}
