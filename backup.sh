#!/bin/bash

## Script variables initialization
PATH_SCRIPT=`dirname "$0"`
PATH_BACKUP="${PATH_SCRIPT}/backup"
source $PATH_SCRIPT/config.cfg
DATABASE_LIST=`echo "$DATABASE_LIST" | sed 's/;/ /g'`
SVN_PATH_LIST=`echo "$SVN_PATH_LIST" | sed 's/;/ /g'`
GIT_PATH_LIST=`echo "$GIT_PATH_LIST" | sed 's/;/ /g'`
REP_TO_SAVE_LIST=`echo "$REP_TO_SAVE_LIST" | sed 's/;/ /g'`
EXCEPT_EXTENSION=`echo "$EXCEPT_EXTENSION" | sed 's/;/ /g'`
DATE=`date +%Y-%m-%d-%H-%M`
HOSTNAME=`hostname`
## END Script variables initialization

# Creating a temporary directory
TMP=`mktemp -d`
# Defining an action in case of interruption of the script
# trap "rm -rf $TMP" EXIT
# Going to temporary directory
cd $TMP

echo "Script ran at : $DATE"

if [ ! "1${DATABASE_LIST}" = "1" ]
then
	for i in $DATABASE_LIST
	do
		echo -en "Sauvegarde SQL de \"$i\" : \t\t"
		mysqldump -u$DB_USER -p$DB_PASSWORD $i --add-drop-table -c > $i.sql
		gzip ./${DATE}-SQL-${i}.gz ./$i.sql
		echo -e "\t SUCCES"
	done
fi

if [ ! "1${SVN_PATH_LIST}" = "1" ]
then
	for i in $PATH_SVN_WITH_SPACE
	do
		NAME=`sed -n ${COMPTEUR}p $PATH_BACKUP/sortie`
		REV_MAX=`svn info --username $SVN_USER --password $SVN_PASSWORD http://127.0.0.1/svn/${NAME} | grep "^Revision: " | sed "s/Revision: //g"`
		let "REV_MIN=$REV_MAX-50"
		echo -en "Sauvegarde SVN de \"$NAME\" revisions $REV_MIN:$REV_MAX a `date` : \t"
		svnadmin -q -r$REV_MIN:$REV_MAX dump $i > ./$NAME.svndump
		if [ `find ./$NAME.svndump -size 0` ]
		then
			rm -f ./$NAME.svndump
			echo -e "\t ECHEC : le depot n'existe pas"
		else
			tar cfz ./${DATE}-SVN-${NAME}.tar.gz ./$NAME.svndump
			echo -e "\t SUCCES : le depot a ete sauvegarde"
		fi 
		let "COMPTEUR=$COMPTEUR+1"
	done
fi

if [ ! "1${GIT_PATH_LIST}" = "1" ]
COMPTEUR=1
then
	for i in $GIT_PATH_LIST
	do
		NAME=`basename $i`
		echo -en "Saving GIT repo \"$NAME\" : \t\t"
		# dumping GIT
		mkdir ./$NAME
		git clone --mirror $i ./$NAME
		tar czf ./${DATE}-GIT-${NAME}.tar.gz ./$NAME
		echo -e "\t SUCCES : repo \"$NAME\" saved"
		let "COMPTEUR=$COMPTEUR+1"
	done
fi

if [ ! "1${REP_TO_SAVE_LIST}" = "1" ]
COMPTEUR=1
then
        for i in $REP_TO_SAVE_LIST
        do
			echo -en "Saving REP \"$i\" : \t\t"
			NAME=`basename $i`
			# Going to parent of directory to save to obtain relative path
			cd $i && cd ..
			# Preparing command to add necessary excpetions
			COMMANDE="tar czpf compressed_rep.tar.gz $NAME"
			# Loop to add exceptions for tar
			COMPTEUR2=1
			for j in $EXCEPT_EXTENSION
			do
				COMMANDE="${COMMANDE} --exclude \"$j\""
				let "COMPTEUR2=$COMPTEUR2+1"
			done
			# END Loop to add exceptions for tar
			# Running compression
			eval $COMMANDE
			let "COMPTEUR=$COMPTEUR+1"
			mv compressed_rep.tar.gz $TMP/${DATE}-REP-${NAME}.tar.gz
			echo -e "\t SUCCES"
        done
fi

#Return to temporary directory
cd $TMP

echo "FTP Connection to Batman"
ftp -i -n $IP_SERVBACKUP $FTP_PORT << FIN
        quote USER $FTP_USER
        quote PASS $FTP_PASSWORD
        cd $FTP_REP
        mkdir $HOSTNAME
        cd $HOSTNAME
        mkdir $DATE
        cd $DATE
        binary
        mput ${DATE}*
        quit
FIN

echo -e "Transfer is complete\n"
echo -e "--------------------------------------\n\n"
