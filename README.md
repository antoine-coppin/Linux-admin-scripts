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
<a name="cron" />
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

Ce script est en réalité une bibliothèque qui est appelée par d'autres scripts. Elle permet d'envoyer des informations sur le déroulement des scripts qui l'utilise, par mail et/ou sur un canal Mattermost et dans un fichier de log local. Les scripts qui utilisent ce système d'alerte sont marqués dans ce fichier par le symbole :email:.

Bien sûr les alertes Mattermost via webhook nécéssitent la configuration de cette application dans votre infrastructure. Les alertes par mail nécéssite la configuration d'un serveur SMTP au sein de l'infrastructure ainsi que l'installation du paquet mailutils sur les serveurs.</br></br>
A la différence des autres, ce script doit obligatoirement être placé dans le répertoire /usr/local/lib/.</br>
Plusieurs variables sont à renseigner:
- ALERT_EMAIL: on indique l'adresse mail sur laquelle on souhaite recevoir l'alerte. Si vous ne voulez/pouvez pas utiliser ce système, laissez la variable vide (ALERT_EMAIL="")
- MATTERMOST_WEBHOOK: on indique l'url du webhook mattermost crée précédemment. Cela permettra d'afficher les alertes dans le canal choisi. Même principe que pour la variable précédente si on ne souhaite pas l'utiliser.
- ALERT_LOG: on indique le fichier de log où seront inscrites les alertes. Ce fichier doit être dans le répertoire /var/log/.

La fonction send_alert prévoit 3 niveaux d'alerte: INFO, WARNING et ERROR. Le niveau d'alerte associé est défini directement dans les scripts. Tous les scripts qui utilisent cette fonction permettent d'utiliser l'option "--quiet" qui permet de ne pas activer la fonction pour les alertes de niveau INFO, seuls les WARNING et ERROR génèrent une alerte.</br>Par eexemple:
```bash
# Alertes INFO/WARNING/ERROR activées
sudo /usr/local/sbin/update.sh
# Alertes WARNING/ERROR activées
sudo /usr/local/sbin/update.sh --quiet
```

Les émojis et icônes (ICON=":nom_icone:") sont personnalisables.</br>

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

Ce script permet d'ajouter un utilisateur sur un serveur.</br>

Avant d'exécuter le script, il faut insérer la clé RSA publique de l'utilisateur dans un fichier authorized_keys qui doit se trouver dans le même répertoire que le script.
</br>Ex:
```bash
cd /usr/local/sbin
echo "ssh-rsa AAAAB3Nza... nouvel_utilisateur@pc" > authorized_keys
sudo ./add_new_user.sh nouvel_utilisateur
```
Comme on le voit dans la commande précédente, il faut indiquer après le script le nom de l'utilisateur qu'on rajoute.</br>
On peut également choisir de donner les droits administrateur au nouvel utilisateur. Pour cela il faut ajouter l'option "--admin"
</br>Ex:
```bash
#Création utilisateur "steeve" AVEC droits administrateur:
sudo ./add_new_user.sh steeve --admin

#Création utilisateur "steeve" SANS droits administrateur:
sudo ./add_new_user.sh steeve
```
---
## monitoring.sh :email:

Ce script a pour but de monitorer l'usage des ressources CPU, RAM et le taux d'occupation du ou des disques du serveur.

Plusieurs variables sont à définir dans le script, il s'agit des seuils d'utilisation à partir desquels on veut générer une alerte:
  - CPU_THRESHOLD: Seuil utilisation CPU. Une valeur de 80 générera une alerte à chaque éxécution du script ou l'utilisation CPU est supérieure ou égale à 80%.
  - RAM_THRESHOLD: Seuil consommation RAM. Même principe que pour l'utilisation CPU.
  - DISK_THRESHOLD: Seuil d'occupation du disque.
---
## backup.sh :email:

Ce script a pour but de créer une sauvegarde d'un répertoire et d'effectuer une rotation.

Avant d'éxécuter le script:
- Créer le répertoire destiné à contenir les backups(NB: si vous le nommait différemment il faudra modifier la variable BACKUP_DIR):
  ```bash
  sudo mkdir /var/backups/
  ```
- Plusieurs variables doivent être renseignées:
  - SOURCE_DIR: C'est le répertoire que l'on souhaite sauvegarder, par exemple "/etc".
  - RETENTION_DAYS: C'est le nombre de jours pendant lesquels une sauvegarde doit être conservée, par exemple "7".
 
Pensez à créer un [cronjob](#cron) pour des sauvegardes quotidiennes.

---
## update.sh

Ce script permet d'effectuer automatiquement les mises à jours des paquets. Aucune variable n'est à renseigner, il génère une alerte WARNING si une action de votre part est nécessaire: redémarrage de l'ordinateur ou suppression de certains paquets obsolètes.
