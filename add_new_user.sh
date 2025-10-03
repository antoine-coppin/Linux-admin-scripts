#!/bin/bash

# Vérifie que le script est exécuté en tant root
if [ "$(id -u)" -ne 0 ]; then
    echo "Nécéssite d'être exécuté avec sudo"
    exit 1
fi

# Vérifie qu'un nom a bien été donné en argument
if [ -z "$1" ]; then
    echo "Merci d'indiquer un nom d'utilisateur"
    exit 1
fi

USER=$1
HOME=/home/$USER
ADMIN=false

if [ "$2" == "--admin" ]; then
    ADMIN=true
fi

echo "==> Création de l’utilisateur : $USER"

# Crée l'user avec home et shell bash
useradd -m -d "$HOME" -s /bin/bash "$USER"

# Force l’user à rentrer un mdp
passwd "$USER"
chage -d 0 "$USER"

# Création dossier ssh
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
chown "$USER:" "$HOME/.ssh"

# Ajoute une clé rsa_pub
if [ -f "./authorized_keys" ]; then
    mv ./authorized_keys "$HOME/.ssh/"
    chmod 600 "$HOME/.ssh/authorized_keys"
    chown "$USER" "$HOME/.ssh/authorized_keys"
    echo "Clé SSH ajoutée"
else
    echo "/!\ Aucune clé SSH trouvée. N'oubliez pas de l'ajouter dans $HOME/.ssh/authorized_keys /!\ "
fi

# Attribution ou non des droits sudo
if [ "$ADMIN" = true ]; then
    usermod -aG sudo "$USER"
    echo "Utilisateur $USER créé AVEC droits administrateur."
else
    echo "Utilisateur $USER créé SANS droits administrateur."
fi
