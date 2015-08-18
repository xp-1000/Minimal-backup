#!/bin/bash

PATH_BACKUP=""
SPACE_USED=`df -H | awk ' NR > 1 && NR < 3 {print $5}' | sed "s/%//"`
SPACE_MAX=74

while [ $SPACE_USED -gt $SPACE_MAX ]
do
	for i in `ls $PATH_BACKUP`
	do
		REP=`find $PATH_BACKUP/$i/* -type d | sort -t/ -k7n,7n | sed -n 1p`
		if [ `ls -A1 $PATH_BACKUP/$i | wc -l` != 1 ]
		then
			echo "Suppression de : $REP"
			rm -fR $REP
		else
			echo "Omission de : $REP"
		fi
	done
	SPACE_USED=`df -H | awk ' NR > 1 && NR < 3 {print $5}' | sed "s/%//"`
done

for i in `find $PATH_BACKUP -type d`
do
	if [ "x`find $i`" == "x$i" ]
	then
		echo "Suppression du dossier vide $i"
		rm -fR $i
	fi
done
