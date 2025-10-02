# Linux-admin-scripts
Ce dépôt git à pour objectif de rassembler des scripts bash qui permettent d'automatiser des actions d'aministration de serveurs Linux.</br>
Sauf exceptions, ces scripts nécessitent les droits administrateurs. ils doivent être éxécutés en tant que root (sudo ./nom_script.sh).
Plusieurs règles sont à respecter:
- Placer les scripts dans le répertoire /usr/local/sbin. Dans le cas contraire, il faudra adapter les scripts et modifier la variable PATH dans le bashrc (export PATH=$PATH:/chemin/du/repertoire).
- Créer les scripts en tant que root:
```bash
# Depuis le répertoire /usr/local/sbin
sudo vim nom_script.sh
  ```
  Puis on colle le code du script.
- Donner les droits d'éxécution à l'utilisateur root sur le script (toujours depuis /usr/local/sbin):
```bash
sudo chmod u+x nom_script.sh
```
- Exécuter les scripts en tant que root. Bonne pratique:
```
# Depuis le répertoire /usr/local/sbin
sudo ./nom_script.sh
```
- Un système d'alerte mail/mattermost/logs peut être mis en place grâce au script alerts.sh. Vous devez obligatoirement l'installer pour éviter des erreurs.
- Bien suivre les indications du README pour chaque script pour assurer la bonne éxécution de ces derniers.

La majorité des scripts ont vocation à être éxécutés plusieurs fois, la plupart du temps à intervalles réguliers. Pour cela, la création de cronjob est privilégiée:
  ```bash
  # on édite le crontab de l'utilisateur root (sudo) afin que les scripts soient exécutés en tant que root
  sudo crontab -e
  ```
  Se référer au man de cron pour la syntaxe, ci-dessous deux exemples:
  ```bash
  # la ligne ci dessous exécute le script monitoring.sh toutes les 30 minutes, tous les jours.
  30 * * * * /usr/local/sbin/monitoring.sh
  # la ligne ci dessous exécute le script backup.sh tous les jours à 2h du matin.
  0 2 * * * /usr/local/sbin/backup.sh
  ```
---
   
### alerts.sh

Ce script est en réalité une bibliothèque qui est appelée par d'autres scripts. Elle permet d'envoyer des informations sur le déroulement des scripts qui l'utilise, par mail et/ou sur un canal Mattermost et dans un fichier de log local. Bien sûr les alertes Mattermost via webhook nécéssitent la configuration de cette application dans votre infrastructure. Les alertes par mail nécéssite la configuration d'un serveur SMTP au sein de l'infrastructure ainsi que l'installation du paquet mailutils sur les serveurs.</br>
A la différence des autres, ce script doit obligatoirement être placé dans le répertoire /usr/local/lib/.</br>
Plusieurs variables sont à renseigner:
- ALERT_EMAIL: on indique l'adresse mail sur laquelle on souhaite recevoir l'alerte. Si vous ne voulez/pouvez pas utiliser ce système, laissez la variable vide (ALERT_EMAIL="")
- MATTERMOST_WEBHOOK: on indique l'url du webhook mattermost crée précédemment. Cela permettra d'afficher les alertes dans le canal choisi. Même principe que pour la variable précédente si on ne souhaite pas l'utiliser.
- ALERT_LOG: on indique le fichier de log où seront inscrites les alertes. Ce fichier doit être dans le répertoire /var/log/.

La fonction send_alert prévoit 3 niveaux d'alerte: INFO, WARNING et ERROR. Ces trois niveaux sont pris en compte dans les scripts qui utilisent cette fonction mais il est possible de modifier le niveau d'une erreur directement depuis le script concerné. Les émojis et icônes (ICON=":nom_icone:") sont personnalisables.</br>

Afin d'éviter que le fichier de log remplisse l'espace disponible, il est important de mettre en place une rotation via logrotate. Pour cela il faut créer un fichier dans /etc/logrotate.d/ qui porte le même nom que le fichier renseigné dans ALERT_LOG.</br>Dans l'exemple cela donnerai /etc/logrotate.d/alerts (NB: pas d'extension .log). Voici un exemple de configuration:
```bash
sudo vim /etc/logrotate.d/alerts
```
```bash
/var/log/alerts.log {
    daily                      # rotation quotidienne
    rotate 7                   # 7 fichiers sont conservés 
    compress                   # compresse les anciens logs en .gz
    delaycompress              # compresse à partir du deuxième jour, le fichier de la veille reste donc lisible/non-compressé
    missingok                  # ne génère pas d'erreur si le fichier n'existe pas
    notifempty                 # ne fait pas de rotation si le fichier est vide
    create 640 root adm       # crée le nouveau fichier en root:adm avec les droits ugo rw-r----- 
}
```
---
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

Ce script a pour but de monitorer l'usage des ressources CPU, RAM et le taux d'occupation du ou des disques du serveur. Il permet également d'envoyer une alerte par mail dans le cas ou un seuil a été dépassé et de garder une trace de l'usage des ressources dans un fichier de log local.</br>

Pour l'envoi de l'alerte mail, vérifier les [pré-requis](#pré-requis-alerte-mail)

Plusieurs variables sont à définir dans le script:
- EMAIL: ici on renseigne l'adresse mail vers laquelle on veut que l'alerte soit envoyée.
- LOG_FILE: Nom du fichier de log où sera inscrit le résultat du script. Ce fichier DOIT être dans le répertoire /var/log/. Ex: /var/log/usage_ressources.log
- Les seuils: Ici on vient définir en pourcentage les seuils d'utilisation à partir desquels on veut générer une alerte.
  - CPU_THRESHOLD: Seuil utilisation CPU. Une valeur de 80 générera une alerte à chaque éxécution du script ou l'utilisation CPU est supérieure ou égale à 80%.
  - RAM_THRESHOLD: Seuil consommation RAM. Même principe que pour l'utilisation CPU.
  - DISK_THRESHOLD: Seuil d'occupation du disque.

Les messages d'alertes sont personnalisables comme l'objet du mail envoyé qui se situe à la ligne 68 après 'mail -s' et avant "EMAIL".</br></br>

Afin d'éviter que le fichier de log remplisse l'espace disponible, il est important de mettre en place une rotation via logrotate. Pour cela il faut créer un fichier dans /etc/logrotate.d/ qui porte le même nom que notre fichier de log.</br>Dans l'exemple cela donnerai /etc/logrotate.d/usage_ressources (NB: pas d'extension .log). Voici un exemple de configuration:
```bash
/var/log/usage_ressources.log {
    daily                      # rotation quotidienne
    rotate 7                   # 7 fichiers sont conservés 
    compress                   # compresse les anciens logs en .gz
    delaycompress              # compresse à partir du deuxième jour, le fichier de la veille reste donc lisible/non-compressé
    missingok                  # ne génère pas d'erreur si le fichier n'existe pas
    notifempty                 # ne fait pas de rotation si le fichier est vide
    create 640 root adm       # crée le nouveau fichier en root:adm avec les droits ugo rw-r----- 
}
```

Pour une bonne utilisation du script, plusieures solutions sont possibles:
- création d'un cronjob pour exécuter le script à des horaires définis ou à des intervalles de temps spécifiques. Se référer au man de crontab. Ex:
```bash
sudo crontab -e
```
La ligne ci-dessous exécutera le script (placé dans /usr/local/sbin) tout les jours et toutes les 30 minutes.

```bash
30 * * * * /usr/local/sbin/monitoring.sh
```
- Utilisation d'un poller de supervision, c'est à dire une machine de l'infrastructure spécialement dédiée à la surveillance des autres machines et qui va exécuter le script via le réseau à des intervalles définis. Cette solution est adaptée aux grosses infrastructures.

## backup.sh

Ce script a pour but de créer une sauvegarde quotidienne d'un répertoire et d'effectuer une rotation. Il log localement le résultat des sauvegardes et des rotations et permet également d'envoyer une alerte mail en cas d'échec à l'une des étapes si les [pré-requis](pré-requis-alerte-mail) sont respectés.

Avant d'éxécuter le script:
- Créer le répertoire destiné à contenir les backups(NB: si vous le nommait différemment il faudra modifier la variable BACKUP_DIR):
  ```bash
  sudo mkdir /var/backups/
  ```
- Plusieurs variables doivent être renseignées:
  - SOURCE_DIR: C'est le répertoire que l'on souhaite sauvegarder, par exemple "/etc".
  - RETENTION_DAYS: C'est le nombre de jours pendant lesquels une sauvegarde doit être conservée, par exemple "7".
 
- Ajouter un cronjob (ou un service systemd):
  ```bash
  sudo crontab -e
  ```
  La ligne ci-dessous exécutera le script tous les jours à 02h du matin.

  ```bash
  0 2 * * * /usr/local/sbin/backup.sh
  ```


### Pré-requis alerte mail:
- Avoir un MTA (Mail Transfer Agent) configuré sur le serveur:
   - via Postfix ou équivalent si un serveur SMTP est déjà présent dans l'infrastructure.
   - via un client léger type msmtp.
- Installation du paquet mailutils.
