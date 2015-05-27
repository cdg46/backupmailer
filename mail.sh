#!/bin/bash

# inclusion fichier de configuration
source $(dirname $0)/config.sh.dist

if [ -f $(dirname $0)/config.sh ]
then
  source $(dirname $0)/config.sh
fi


# c'est parti !!
while read userid homedir email last_login
do
  ERRORCOLL=0
  RAPPORTCOLL=`mktemp`
  fappend $RAPPORTCOLL "Bonjour,

Veuillez trouver un rapport de votre sauvegarde a distance sur les serveurs du CDG46."

  if [ -d $homedir ]
  then
    SIZE=`du -ah --block-size=G --max-depth=0 ${homedir} | cut -f1`

    if [ "$last_login" == "0000-00-00 00:00:00" ]
    then
      ERRORNEVERLOGGED=1
      fappend $NEVERLOGGED "  * ${userid}"
      fappend $RAPPORT "$(printf "%s %s %s %s _____-__-__ __:__\n" $userid "${col1:${#userid}}" $SIZE "${col2:${#SIZE}}")"
    else
      last_login=`date --date="$last_login" +%Y-%m-%d\ %H:%m`

      # comparaison de date
      LASTDATE=`date --date="$last_login" +%s`
      DIFF=$((LASTDATE-TODAY))
      DIFF=${DIFF#-}

      ## Est-ce que la derniere connexion remonte a plus d'une semaine ?
      if [ "$DIFF" -ge 604800 ]
      then
        ERRORCOLL=1
        ERRORTOOLD=1
        fappend $RAPPORTCOLL "/!\ cela fait plus d'une semaine qu'aucun fichier n'a ete depose sur le serveur"
        fappend $TOOLD "$(printf "%s %s $last_login\n" $userid "${col1:${#userid}}")"
      fi


      ## Envoi mail a la collectivite 
      fappend $RAPPORTCOLL "Vous utilisez actuellement $SIZE sur votre espace de sauvegarde en ligne.

Votre derniere sauvegarde sur ce serveur date du ${last_login}"

      fappend $RAPPORT "$(printf "%s %s %s %s $last_login\n" $userid "${col1:${#userid}}" $SIZE "${col2:${#SIZE}}")"
    fi
  else
    if [ "$userid" != "userid" ]; then
      ERRORCOLL=1
      ERRORNOHOMEDIR=1
      fappend $NOHOMEDIR "  * ${userid}"
      SIZE=N/A
      fappend $RAPPORT "$(printf "%s %s %s\n" $userid "${col1:${#userid}}" $SIZE)"
    fi
  fi

  # Envoi du rapport a la collectivite
  if [ ! -z "$1" ]
  then
    fappend $RAPPORTCOLL "\n--------------------------------------------------------------------------\nService de sauvegarde a distance du CDG4\n\n
email : sauvegarde@cdgfpt46.fr\ntel : 05 32 28 00 15"

    # Il y a un souci donc envoi specifique
    if [ ! -z "$ERRORCOL" ]
    then
      fappend $RAPPORTCOLL "\n#################################################\n#                                               #\n#  VEUILLEZ CONTACTER LE SERVICE DE SAUVEGARDE  #\n#                                               #\n#          PAR TELEPHONE OU PAR MAIL            #\n#                                               #\n#################################################\n"

      sendreport $email "[CDG46][Sauvegarde][Rapport hebdomadaire]" 1 $RAPPORTCOLL $sender
    else
      sendreport $email "[CDG46][Sauvegarde][Rapport hebdomadaire]" 3 $RAPPORTCOLL $sender
    fi
  fi
done < <(echo "SELECT userid, homedir, email, last_login FROM users ORDER BY userid ASC" | mysql $DB -u $DBUSER -p$DBPWD)

# Envoi des rapports aux admins
sendreport "$admin" "[CDG46][Sauvegarde][Etat du jour]" 3 $RAPPORT $sender

if [ ! -z "$ERRORNOHOMEDIR" ]
then
  sendreport $admin "[CDG46][Sauvegarde][Repertoire vide]" 1 $NOHOMEDIR $sender
fi

if [ ! -z "$ERRORTOOLD" ]
then
  sendreport $admin "[CDG46][Sauvegarde][Plus d'une semaine]" 1 $TOOLD $sender
fi

if [ ! -z "$ERRORNEVERLOGGED" ]
then
  sendreport $admin "[CDG46][Sauvegarde][Jamais connecte]" 1 $NEVERLOGGED $sender
fi
