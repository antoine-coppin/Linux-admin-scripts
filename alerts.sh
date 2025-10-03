#!/bin/bash
# ==========================================
# Bibliothèque d'alertes générique
# Envoi par Mail, Mattermost (avec couleurs), Log local
# avec niveaux INFO / WARNING / ERROR
# Inclut le nom du script appelant
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
    local SCRIPT_NAME=$(basename "$0")  # nom du script appelant

    # Définition du label, emoji et couleur
    case "$LEVEL" in
        INFO)
            SUBJECT="ℹ️ [INFO][$SCRIPT_NAME][$HOSTNAME]"
            ICON=":information_source:"
            COLOR="#36a64f"
            ;;
        WARNING)
            SUBJECT="⚠️ [WARNING][$SCRIPT_NAME][$HOSTNAME]"
            ICON=":warning:"
            COLOR="#ffae42"
            ;;
        ERROR)
            SUBJECT="❌ [ERROR][$SCRIPT_NAME][$HOSTNAME]"
            ICON=":x:"
            COLOR="#ff0000"
            ;;
        *)
            SUBJECT="[ALERTE][$SCRIPT_NAME][$HOSTNAME]"
            ICON=":speech_balloon:"
            COLOR="#808080"
            ;;
    esac

    # Corps du message
    BODY="[$DATE] ($HOSTNAME) [$SCRIPT_NAME] [$LEVEL] $MESSAGE"

    # ---- LOG LOCAL ----
    echo "$BODY" >> "$ALERT_LOG"

    # ---- ENVOI MAIL ----
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$BODY" | mail -s "$SUBJECT" "$ALERT_EMAIL"
    fi

    # ---- ENVOI MATTERMOST ----
    if [ -n "$MATTERMOST_WEBHOOK" ]; then
        PAYLOAD=$(cat <<EOF
{
    "username": "AlertBot",
    "icon_emoji": "$ICON",
    "attachments": [
        {
            "color": "$COLOR",
            "text": "$BODY"
        }
    ]
}
EOF
)
        curl -s -o /dev/null -X POST \
            -H 'Content-Type: application/json' \
            -d "$PAYLOAD" \
            "$MATTERMOST_WEBHOOK"
    fi
}
