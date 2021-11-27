#! /bin/bash

#SOURCE=https://download.openstreetmap.fr/replication/planet/minute/
SOURCE=https://planet.openstreetmap.org/replication/minute/

SEQ=`wget -o /dev/null -O /dev/stdout $SOURCE/state.txt|grep sequenceNumber|cut -d '=' -f 2`

MM=$[$SEQ/1000000]
KK=$[$SEQ-$MM*1000000]
KK=$[$KK/1000]
UU=$[$SEQ-$MM*1000000-$KK*1000]
A=`printf %03d $MM`
B=`printf %03d $KK`
C=`printf %03d $UU`

echo $A/$B/$C

wget -o /dev/null -O /dev/stdout $SOURCE/$A/$B/$C.osc.gz|gunzip -c|python compute-changeset-data.py
