#!/bin/bash

# Vérifie si le script est exécuté en root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en root."
    exit 1
fi

# Vérifie si un nom d’utilisateur a été passé en argument
if [ -z "$1" ]; then
    echo "Usage: $0 nom_utilisateur"
    exit 1
fi

USERNAME=$1
USER_HOME="/home/$USERNAME"

echo "➡️ Création de l’utilisateur : $USERNAME"

# Crée l’utilisateur avec un dossier personnel et shell bash
useradd -m -d "$USER_HOME" -s /bin/bash "$USERNAME"

# Force l’utilisateur à changer son mot de passe au premier login
passwd "$USERNAME"
chage -d 0 "$USERNAME"

# Crée un dossier .ssh sécurisé
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chown "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

# Ajoute une clé publique SSH si un fichier existe
if [ -f "./authorized_keys" ]; then
    cp ./authorized_keys "$USER_HOME/.ssh/"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown "$USERNAME:$USERNAME" "$USER_HOME/.ssh/authorized_keys"
    echo "🔑 Clé SSH ajoutée depuis authorized_keys"
else
    echo "⚠️ Aucune clé SSH trouvée. Vous pouvez en ajouter manuellement dans $USER_HOME/.ssh/authorized_keys"
fi

# Ajoute l’utilisateur au groupe sudo
usermod -aG sudo "$USERNAME"

echo "✅ Utilisateur $USERNAME créé avec succès."
echo "👉 Connexion : ssh $USERNAME@<IP_SERVEUR>"
