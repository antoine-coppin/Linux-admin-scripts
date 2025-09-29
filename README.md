# Linux-admin-scripts
Scripts Bash pour automatiser la configuration de serveurs Linux

## add_new_user.sh

Ce script a pour but d'ajouter un nouvel utilisateur à un serveur linux. Il doit être lancé par un administrateur sur le dit serveur en tant que root.
Pour ajouter la clé RSA public du nouvel utilisateur, il faut l'insérer dans un fichier authorized_keys qui doit se trouver dans le même répertoire que le script.
</br>Ex:
```bash
echo "ssh-rsa AAAAB3Nza... nouvel_utilisateur@pc" > authorized_keys
sudo ./add_new_user.sh nouvel_utilisateur
```
Ce script permet également de choisir de donner les droits administrateur au nouvel utilisateur. Pour cela il faut ajouter l'option "--admin"
</br>Ex:
```bash
#Création utilisateur "steeve" AVEC droits administrateur:
sudo ./add_new_user.sh steeve --admin

#Création utilisateur "steeve" SANS droits administrateur:
sudo ./add_new_user.sh steeve
```

## monitoring.sh

Pré-requis:
 - Avoir un Mail Transfer Agent configuré sur le serveur:
   - via Postfix ou équivalent si un serveur SMTP est déjà présent dans l'infrastructure.
   - via un client léger type msmtp.
- Installation des paquetq mailutils et sysstat.

Ce script a pour but de monitorer l'usage des ressources CPU, RAM et le taux d'occupation du ou des disques du serveur. Il permet également d'envoyer une alerte par mail dans le cas ou un seuil a été dépassé et aussi de garder une trace du dépassement dans un fichier de log.</br></br>

Plusieurs variables sont à définir dans le script:
- EMAIL: ici on renseigne l'adresse mail vers laquelle on veut que l'alerte soit envoyée.
- LOG_FILE: Nom du fichier qui gardera les traces des alertes. Ex: /var/log/alerte_monitoring.log
- Les seuils: Ici on vient définir en pourcentage les seuils d'utilisation à partir desquels on veut générer une alerte.
  - CPU_THRESHOLD: Seuil utilisation CPU. Une valeur de 80 générera une alerte à chaque éxécution du script ou l'utilisation CPU est supérieure ou égale à 80%.
  - RAM_THRESHOLD: Seuil consommation RAM. Même principe que pour l'utilisation CPU.
  - DISK_THRESHOLD: Seuil d'occupation du disque.

Les messages d'alertes sont personnalisables comme l'objet du mail envoyé qui se situe à la ligne 68 après 'mail -s' et avant "EMAIL".</br></br>
Pour une bonne utilisation du script, plusieurs solutions sont possibles:
- création d'un cronjob pour exécuter le script à des horaires définis ou à des intervalles de temps spécifiques. Se référer au man de crontab. Ex:
```bash
#La ligne ci-dessous exécutera le script (placé dans /usr/local/sbin) tout les jours et toutes les 30 minutes.
30 * * * * /usr/local/sbin/monitoring.sh
```
- Utilisation d'un poller de supervision, c'est à dire une machine de l'infrastructure spécialement dédiée à la surveillance des autres machines et qui va exécuter le script via le réseau à des intervalles définis. Cette solution est adaptée aux grosses infrastructures.

