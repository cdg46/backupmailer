# Rapports de sauvegarde

## usages
Vous devez copier ```config.sh.dist``` en ```config.sh``` pour parametrer l'outil a votre environnement

### Envoi admin
```
$ ./path/backupmailer/mail.sh
```

### Envoi coll
```
$ ./path/backupmailer/mail.sh mail@collectivite.fr
```

### Automatisation
```
crontab -e

0 22 * * * /bin/bash /path/backupmailer/mail.sh # pour les admin
0 22 * * 1 /bin/bash /path/backupmailer/mail.sh users # pour les utilisateurs
```

### Customisation

Vous devez faire "matcher" ```/etc/hosts``` et sender de ```config.sh```
```
vi /etc/hosts
127.0.0.1 domain
```

```
vi config.sh
sender=email@domain
```
