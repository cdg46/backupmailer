#!/bin/bash

if [ -f $(dirname $0)/config.sh ]
then
  source $(dirname $0)/config.sh
else
  source $(dirname $0)/config.sh.dist
fi

while read userid homedir email last_login
do
  ERRORCOLL=0
  RAPPORTCOLL=$BASE/backupreport_$userid
  echo "Bonjour,

Veuillez trouver un rapport de votre sauvegarde a distance sur les serveurs du CDG46.

" > $RAPPORTCOLL

  if [ -d $homedir ]
  then
    SIZE=`du -ah --block-size=G --max-depth=0 ${homedir} | cut -f1`

    if [ "$last_login" == "0000-00-00 00:00:00" ]
    then
      ERRORNEVERLOGGED=1
      echo "  * ${userid}" >> $NEVERLOGGED
      printf "%s %s %s %s _____-__-__ __:__\n" $userid "${col1:${#userid}}" $SIZE "${col2:${#SIZE}}" >> $RAPPORT
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
        echo "/!\ cela fait plus d'une semaine qu'aucun fichier n'a ete depose sur le serveur
" >> $RAPPORTCOLL
        printf "%s %s $last_login\n" $userid "${col1:${#userid}}"  >> $TOOLD
      fi


      ## Envoi mail a la collectivite 
      echo "vous utilisez actuellement $SIZE sur votre espace de sauvegarde en ligne.

Votre derniere sauvegarde sur ce serveur date du ${last_login}" >> $RAPPORTCOLL

      printf "%s %s %s %s $last_login\n" $userid "${col1:${#userid}}" $SIZE "${col2:${#SIZE}}" >> $RAPPORT
      
#${userid} : ${homedir} __ ${email}  ${last_login}"
    fi
  else
    if [ "$userid" != "userid" ]; then
      ERRORCOLL=1
      ERRORNOHOMEDIR=1
      echo "  * ${userid}" >> $NOHOMEDIR
      SIZE=N/A
      printf "%s %s %s\n" $userid "${col1:${#userid}}" $SIZE >> $RAPPORT
    fi
  fi

  # Envoi du rapport a la collectivite
  if [ ! -z "$1" ]
  then
    echo "
--------------------------------------------------------------------------
Service de sauvegarde a distance du CDG46

email : sauvegarde@cdgfpt46.fr
tel : 05 32 28 00 15" >> $RAPPORTCOLL

    # Il y a un souci donc envoi specifique
    if [ ! -z "$ERRORCOL" ]
    then
      echo "
#################################################
#                                               #
#  VEUILLEZ CONTACTER LE SERVICE DE SAUVEGARDE  #
#                                               #
#          PAR TELEPHONE OU PAR MAIL            #
#                                               #
#################################################
" >> $RAPPORTCOLL

      cat $RAPPORTCOLL | mail -S "X-Priority: 1" -S "Importance: high" -s "[CDG46][Sauvegarde][Rapport hebdomadaire]" $email
    else
      cat $RAPPORTCOLL | mail -s "[CDG46][Sauvegarde][Rapport hebdomadaire]" $email
    fi
  fi
done < <(echo "SELECT userid, homedir, email, last_login FROM users ORDER BY userid ASC" | mysql $DB -u $DBUSER -p$DBPWD)

cat $RAPPORT | mail -s "[CDG46][Sauvegarde][Etat du jour]" $admin

if [ ! -z "$ERRORNOHOMEDIR" ]
then
  cat $NOHOMEDIR | mail -S "X-Priority: 1" -S "Importance: high" -s "[CDG46][Sauvegarde][Repertoire vide]" $admin
fi
if [ ! -z "$ERRORTOOLD" ]
then
  cat $TOOLD | mail -S "X-Priority: 1" -S "Importance: high" -s "[CDG46][Sauvegarde][Plus d'une semaine]" $admin
fi
if [ ! -z "$ERRORNEVERLOGGED" ]
then
  cat $NEVERLOGGED | mail -S "X-Priority: 1" -S "Importance: high" -s "[CDG46][Sauvegarde][Jamais connecte]" $admin
fi
