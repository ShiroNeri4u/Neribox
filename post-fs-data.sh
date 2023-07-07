#!/system/bin/sh
MODDIR=${0%/*}
NERIBOXDIR="/data/adb/Neribox"
ln -sf $MODDIR/toolkit $MODDIR/system/bin

find $NERIBOXDIR -name '*.log' -size +10M > $NERIBOXDIR/TMP
while read LOG;do
    if [ -f $LOG ];then
        rm $LOG
    fi
done<$NERIBOXDIR/TMP
if [ -f $NERIBOXDIR/TMP ];then
    rm $NERIBOXDIR/TMP
fi

if [ -d /data/adb/Neribox/update-cache ];then
    rm -r /data/adb/Neribox/update-cache
fi