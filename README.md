# Linux-admin-scripts
Scripts Bash pour automatiser la configuration de serveurs Linux

## add_new_user.sh

Ce script a pour but d'ajouter un nouvel utilisateur à un serveur linux. Il doit être lancé par un administrateur sur le dit serveur en tant que root.
Pour ajouter la clé RSA public du nouvel utilisateur, il faut l'insérer dans un fichier authorized_keys qui doit se trouver dans le même répertoire que le script.
Ex:
```bash
echo "ssh-rsa AAAAB3Nza... nouvel_utilisateur@pc" > authorized_keys
sudo ./add_new_user.sh nouvel_utilisateur
```
Ce script permet également de choisir de donner les droits administrateur au nouvel utilisateur. Pour cela il faut ajouter l'option "--admin"
Ex:
```bash
#Création utilisateur "steeve" AVEC droits administrateur:
sudo ./add_new_user.sh steeve --admin

#Création utilisateur "steeve" SANS droits administrateur:
sudo ./add_new_user.sh steeve
