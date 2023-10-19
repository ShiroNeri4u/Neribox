SKIPUNZIP=0

NERIBOXDIR="/data/adb/Neribox"
MODDIR="/data/adb/modules/Neribox"
CER_DIR="$NERIBOXDIR/sysroot/etc/certificate"
UPDATEDIR="$NERIBOXDIR/update-cache"

case $(su -v | awk -F : '{print $2}') in
    MAGISKSU)
    SU_TYPE=MagiskSU
    SU_VERSION=$(su -V)
    BUSYBOX_PATH=/data/adb/magisk/busybox
    ;;
    KernelSU)
    SU_TYPE=KernelSU
    SU_VERSION=$(su -V)
    BUSYBOX_PATH=/data/adb/ksu/bin/busybox
    ;;
esac

ui_print "- Root type:$SU_TYPE Version:$SU_VERSION"

mkdir -p $NERIBOXDIR/sysroot

function LANG () {
    local LANG=$(getprop | grep persist.sys.locale | grep -v persist.sys.localevar | $BUSYBOX_PATH awk '{print $2}')
    local LANG=${LANG:1:5}
    if [ -f $MODPATH/support-lang/$LANG.txt ];then
        source $MODPATH/support-lang/$LANG.txt
    else source $MODPATH/support-lang/en-US.txt
    fi
}

LANG

mkdir -p $UPDATEDIR & chmod 777 $UPDATEDIR

ui_print "- $TEXT_INSTALL_GETLINK"
$BUSYBOX wget --no-check-certificate -q "https://kazamataneri.tech/link.txt" -P $UPDATEDIR
source $UPDATEDIR/link.txt

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- $TEXT_SOC_ARCH$ARCH"
if [ "$ARCH" = "arm64-v8a" ];then
ui_print "- $TEXT_INSTALL_DOWNLOAD$TEXT_INSTALL_BINARY"
$BUSYBOX wget --no-check-certificate -q "$bin64_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
elif [ "$ARCH" = "armeabi-v7a" ];then
ui_print "- $TEXT_INSTALL_DOWNLOAD$TEXT_INSTALL_BINARY"
$BUSYBOX wget --no-check-certificate -q "$bin32_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
else
    ui_print "- $TEXT_INSTALL_NO_BINARY"
    exit
fi
if [ -f $UPDATEDIR/binary*.zip ];then
    ui_print "- $TEXT_INSTALL_EXTRACT$TEXT_INSTALL_BINARY"
    if [ -d $NERIBOXDIR/sysroot/bin ];then
        rm -rf $NERIBOXDIR/sysroot/bin
    fi
    if [ -d $NERIBOXDIR/sysroot/lib ];then
        rm -rf $NERIBOXDIR/sysroot/lib
    fi
    $BUSYBOX_PATH unzip -q -o $UPDATEDIR/binary*.zip -d $NERIBOXDIR/sysroot
fi

ui_print "- $TEXT_INSTALL_DOWNLOAD$TEXT_INSTALL_PROFILE"
$BUSYBOX wget --no-check-certificate -q "$etc_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
ui_print "- $TEXT_INSTALL_EXTRACT$TEXT_INSTALL_PROFILE"
    for x in $NERIBOXDIR/sysroot/etc/{Default.parm,lighttpd.conf,aria2c.conf};do
        rm -r $x
    done
$BUSYBOX_PATH unzip -q -o $UPDATEDIR/etc.zip -d $NERIBOXDIR/sysroot

ui_print "- $TEXT_INSTALL_DOWNLOAD$TEXT_INSTALL_ARIANG"
$BUSYBOX wget --no-check-certificate -q "$ariang_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
ui_print "- $TEXT_INSTALL_EXTRACT$TEXT_INSTALL_ARIANG"
if [ -d $NERIBOXDIR/sysroot/www ];then
    rm -rf $NERIBOXDIR/sysroot/www
fi
$BUSYBOX_PATH unzip -q -o $UPDATEDIR/AriaNg.zip -d $NERIBOXDIR/sysroot

set_perm_recursive $MODPATH/ 0 0 0755 0644
set_perm_recursive $NERIBOXDIR/sysroot 0 0 0755 0644
chmod 744 $NERIBOXDIR/sysroot/bin/*
chmod 777 $MODPATH/toolkit

CER_FILE="$(find $CER_DIR -type f -maxdepth 1)"
if [ -z "$(echo $CER_FILE| grep SERVER-PRIVATE.key | grep SERVER.pem | grep CA.crt)" ];then
    chmod 777 $MODPATH/toolkit
    $MODPATH/toolkit openssl -mkcer -install
    ui_print "- $TEXT_INSTALL_CERTIFICATE"
fi

CONFIG () {
if [ -n "$1" -a -z "$2" -a -z "$3" ];then
    cat $1
        elif [ -n "$1" -a -n "$2" -a -z "$3" ];then
            cat $1 | $BUSYBOX_PATH egrep "^$2=" | $BUSYBOX_PATH sed -n 's/.*=//g;$p'
        elif [ -n "$1" -a -n "$2" -a -n "$3" ];then
    $BUSYBOX_PATH sed -i "s|$2=.*|$2=$3|g" $1
fi
}

CONFIG_PATH="$NERIBOXDIR/config.ini"

for object in AOD DASHBOARD STATUSBAR ALIST_DAEMON ALIST_PORT ALIST_PASSWD ARIA2_DAEMON ARIA2_HTTPS ARIANG_WEBUI RCLONE_DAEMON MOUNTDIR CLOUDDIR FRPC_DAEMON FRPC_PARM TERMUX_REPO TRACKERLIST ROOT_MANAGER;do
eval $object=$(CONFIG $CONFIG_PATH $object)
done
[ -z "$AOD" ] && AOD=0
[ -z "$DASHBOARD" ] && DASHBOARD=true
[ -z "$STATUSBAR" ] && STATUSBAR="ALIST[VERSION,DAEMON,PORT,USER,PASSWORD] ARIA2[VERSION,DAEMON,PORT,WEBUI] RCLONE[VERSION,DAEMON,PID] FRPC[VERSION,DAEMON,PID]"
[ -z "$ALIST_DAEMON" ] && ALIST_DAEMON=false
[ -z "$ALIST_PORT" ] && ALIST_PORT="80|443"
[ -z "$ALIST_PASSWD" ] && ALIST_PASSWD="root"
[ -z "$ARIA2_DAEMON" ] && ARIA2_DAEMON=false
[ -z "$ARIA2_HTTPS" ] && ARIA2_HTTPS=false
[ -z "$ARIANG_WEBUI" ] && ARIANG_WEBUI=true
[ -z "$RCLONE_DAEMON" ] && RCLONE_DAEMON=false
[ -z "$MOUNTDIR" ] && MOUNTDIR=AList
[ -z "$CLOUDDIR" ] && CLOUDDIR=/
[ -z "$FRPC_DAEMON" ] && FRPC_DAEMON=false
[ -z "$FRPC_PARM" ] && FRPC_PARM=
[ -z "$TERMUX_REPO" ] && TERMUX_REPO=https://packages-cf.termux.dev
[ -z "$TRACKERLIST" ] && TRACKERLIST=https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all_ip.txt
[ -z "$ROOT_MANAGER" ] && ROOT_MANAGER="$(dumpsys window | grep mCurrentFocus | awk '{print $NF}' | awk -F / '{print $1}')"

echo "$TEXT_CONFIG_SCREEN
AOD=$AOD

$TEXT_CONFIG_DASHBOARD
DASHBOARD=$DASHBOARD

$TEXT_CONFIG_STATUSBAR
STATUSBAR=$STATUSBAR

$TEXT_CONFIG_DAEMON
ALIST_DAEMON=$ALIST_DAEMON

$TEXT_CONFIG_ALIST_PORT
ALIST_PORT=$ALIST_PORT

$TEXT_CONFIG_ALIST_PASSWD
ALIST_PASSWD=$ALIST_PASSWD

$TEXT_CONFIG_DAEMON
ARIA2_DAEMON=$ARIA2_DAEMON

$TEXT_CONFIG_ARIA2_HTTPS
ARIA2_HTTPS=$ARIA2_HTTPS

$TEXT_CONFIG_ARIANG_WEBUI
ARIANG_WEBUI=$ARIANG_WEBUI

$TEXT_CONFIG_DAEMON
RCLONE_DAEMON=$RCLONE_DAEMON

$TEXT_CONFIG_MOUNTDIR
MOUNTDIR=$MOUNTDIR

$TEXT_CONFIG_CLOUDDIR
CLOUDDIR=$CLOUDDIR

$TEXT_CONFIG_DAEMON
FRPC_DAEMON=$FRPC_DAEMON

$TEXT_CONFIG_FRPC_PARM
FRPC_PARM=$FRPC_PARM

$TEXT_CONFIG_TERMUX_REPO
TERMUX_REPO=$TERMUX_REPO

$TEXT_CONFIG_TRACKERLIST
TRACKERLIST=$TRACKERLIST

$TEXT_CONFIG_ROOT_MANAGER
ROOT_MANAGER=$ROOT_MANAGER
" > $CONFIG_PATH
ui_print "- $TEXT_INSTALL_CONFIG"
ui_print "- $TEXT_INSTALL_ROOT_MANAGER: $ROOT_MANAGER"

if [ -d $NERIBOXDIR/PID ];then
    for x in $NERIBOXDIR/PID/clean $NERIBOXDIR/PID/aod $NERIBOXDIR/PID/daemon $NERIBOXDIR/PID/dashboard;do
    kill -9 $(cat $x)
done
fi
cp -f $MODPATH/toolkit $MODDIR/toolkit
cp -f $MODPATH/service.sh $MODDIR/service.sh
/system/bin/sh $MODDIR/service.sh
ui_print "- $TEXT_INSTALL_NOT_REBOOT"