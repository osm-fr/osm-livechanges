#! /bin/bash

USER=live

SOURCE=https://download.openstreetmap.fr/replication/planet/minute/
SOURCE2=https://planet.openstreetmap.org/replication/minute/

LOCK_FILE=/run/lock/$USER-crontab-backend

DELAY=10

exec 200>"$LOCK_FILE"
flock -n 200
RC=$?
if [ "$RC" != 0 ]; then
    echo "ERROR: Already running script. Try again after sometime"
    exit 1
fi

if [ -e /data/work/$USER/prev-seq ]; then
  PREV_SEQ="$(cat /data/work/$USER/prev-seq)"
else
  PREV_SEQ=0
fi
echo "DEBUG: PREV_SEQ $PREV_SEQ"

[ $(date +%S) -le 10 ] && echo "DEBUG: trop proche de la minute ronde. attente de quelques secondes" && sleep 12
echo "DEBUG: wget $SOURCE/state.txt"
SEQ=`wget -4 -o /dev/null -O /dev/stdout $SOURCE/state.txt|grep sequenceNumber|cut -d '=' -f 2`

if (( SEQ <= PREV_SEQ-DELAY )); then
  echo "WARNING: downloaded SEQ $SEQ <= PREV_SEQ $PREV_SEQ"
  echo "INFO: Switch to $SOURCE2"
  SEQ=`wget -4 -o /dev/null -O /dev/stdout $SOURCE2/state.txt|grep sequenceNumber|cut -d '=' -f 2`
fi
echo "DEBUG: downloaded SEQ $SEQ"

echo "INFO: PREV_SEQ $PREV_SEQ SEQ $SEQ"

MM=$[$SEQ/1000000]
KK=$[$SEQ-$MM*1000000]
KK=$[$KK/1000]
UU=$[$SEQ-$MM*1000000-$KK*1000]
A=`printf %03d $MM`
B=`printf %03d $KK`
C=`printf %03d $UU`

echo "DEBUG: $SEQ mean $A/$B/$C"

wget -4 -o /dev/null -O /dev/stdout $SOURCE/$A/$B/$C.osc.gz|gunzip -c|chronic python compute-changeset-data.py
return_code="${?}"
echo "DEBUG: return_code $return_code"

echo $SEQ > /data/work/$USER/prev-seq
exit $return_code
