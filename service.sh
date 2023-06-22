#!/system/bin/sh
#by @风又音理neri
#程序路径
if [ -f /data/adb/magisk/busybox ];then
BUSYBOX_PATH=/data/adb/magisk/busybox
elif [ -f /data/adb/ksu/bin/busybox ];then
BUSYBOX_PATH=/data/adb/ksu/bin/busybox
fi

MODDIR="$($BUSYBOX_PATH dirname "$(readlink -f "$0")")"
LIB_DIR="$MODDIR/lib"
ETC_DIR="$MODDIR/etc"
ARIA2_CONFIG_PATH="$MODDIR/etc/aria2c.conf"

NERIBOXDIR="/data/adb/Neribox"
CONFIG_PATH="$NERIBOXDIR/config.ini"

CONFIG () {
if [ -n "$1" -a -z "$2" -a -z "$3" ];then
    cat $1
        elif [ -n "$1" -a -n "$2" -a -z "$3" ];then
            cat $1 | $BUSYBOX_PATH egrep "^$2=" | $BUSYBOX_PATH sed -n 's/.*=//g;$p'
        elif [ -n "$1" -a -n "$2" -a -n "$3" ];then
    $BUSYBOX_PATH sed -i "s|$2=.*|$2=$3|g" $1
fi
}

ALIST_DAEMON () {
if [ "$(CONFIG $CONFIG_PATH ALIST_DAEMON)" = "true" ];then
    if [ -z "$ALIST_PID" ];then
        /system/bin/sh $MODDIR/toolkit alist --start
    fi
fi
}

ARIA2_DAEMON () {
if [ "$(CONFIG $CONFIG_PATH ARIA2_DAEMON)" = "true" ];then
    if [ -z "$ARIA2_PID" ];then
        /system/bin/sh $MODDIR/toolkit aria2 --start
    fi
fi
}

RCLONE_DAEMON () {
if [ "$(CONFIG $CONFIG_PATH RCLONE_DAEMON)" = "true" ];then
    if [ -z "$ALIST_PID" -a -n "$RCLONE_PID" ];then
        /system/bin/sh $MODDIR/toolkit rclone --umount
    elif [ -n "$ALIST_PID" -a -z "$RCLONE_PID" ];then
        /system/bin/sh $MODDIR/toolkit rclone --mount
    fi
fi
}

FRPC_DAEMON () {
if [ "$(CONFIG $CONFIG_PATH FRPC_DAEMON)" = "true" ];then
    if [ -z "$FRPC_PID" ];then
        /system/bin/sh $MODDIR/toolkit frpc --start
    fi
fi
}

KEEP_DAEMON () {
        local ALIST_PID="$($BUSYBOX_PATH ps | grep "$MODDIR/bin/alist server --data $ETC_DIR" | grep -v "grep" | $BUSYBOX_PATH awk '{print $1}')"
        local ARIA2_PID="$($BUSYBOX_PATH ps | grep "$MODDIR/bin/aria2c -m $LIBDIR --conf-path=$ARIA2_CONFIG_PATH -D" | grep -v "grep" | $BUSYBOX_PATH awk '{print $1}')"
        local RCLONE_PID="$($BUSYBOX_PATH ps | grep "$MODDIR/bin/rclone mount" | grep -v "grep" | $BUSYBOX_PATH awk '{print $1}')"
        local FRPC_PID="$($BUSYBOX_PATH ps | grep $MODDIR/bin/frpc | grep -v -e "grep" -e "-v" | $BUSYBOX_PATH awk '{print $1}')"
        ALIST_DAEMON
        ARIA2_DAEMON
        RCLONE_DAEMON
        FRPC_DAEMON
        sleep 3
}

PRO () {
while true;do
local STOPPED=false
    while [ "$(dumpsys deviceidle get screen)" = "false" ];do
        local AOD="$(CONFIG $CONFIG_PATH AOD)"
        if [ "$AOD" -gt "0" -a "$STOPPED"="false" ];then
            local AOD_COUNT=0
                while [ "$AOD" -gt "$AOD_COUNT" ];do
                sleep 1
                local AOD_COUNT=`$BUSYBOX_PATH expr $AOD_COUNT + 1`
                    if [ "$AOD_COUNT" -ge "$AOD" ];then
                    if [ "$(CONFIG $CONFIG_PATH ALIST_DAEMON)" = "false" ];then
                    /system/bin/sh $MODDIR/toolkit alist --stop
                    fi
                    if [ "$(CONFIG $CONFIG_PATH ARIA2_DAEMON)" = "false" ];then
                    /system/bin/sh $MODDIR/toolkit aria2 --stop
                    fi
                    if [ "$(CONFIG $CONFIG_PATH RCLONE_DAEMON)" = "false" ];then
                    /system/bin/sh $MODDIR/toolkit rclone --umount
                    fi
                    if [ "$(CONFIG $CONFIG_PATH FRPC_DAEMOM)" = "false" ];then
                    /system/bin/sh $MODDIR/toolkit frpc --stop
                    fi
                    local STOPPED=true
                    break
                    elif [ "$(dumpsys deviceidle get screen)" = "true" ];then
                    local STOPPED=false
                    break
                    fi
                done
        fi
        sleep 3
    done
    while [ "$(dumpsys deviceidle get screen)" = "true" ];do
        if [ "$(CONFIG $CONFIG_PATH DASHBOARD)" = "true" ];then
        /system/bin/sh $MODDIR/toolkit dashboard
        fi
    sleep 3
    done
done
}

KEEP_DAEMON &
PRO