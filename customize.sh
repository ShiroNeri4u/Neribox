SKIPUNZIP=0

MODDIR=/data/adb/modules/Neribox
CER_DIR=$MODPATH/etc/certificate
if [ -f /data/adb/magisk/busybox ];then
BUSYBOX_PATH=/data/adb/magisk/busybox
elif [ -f /data/adb/ksu/bin/busybox ];then
BUSYBOX_PATH=/data/adb/ksu/bin/busybox
fi

mkdir -p /data/adb/Neribox
chmod 777 /data/adb/Neribox

function LANG () {
    local LANG=$(getprop | grep persist.sys.locale | grep -v persist.sys.localevar | $BUSYBOX_PATH awk '{print $2}')
    local LANG=${LANG:1:5}
    if [ -f $MODPATH/support-lang/$LANG.txt ];then
        source $MODPATH/support-lang/$LANG.txt
    else source $MODPATH/support-lang/zh-CN.txt
    fi
}

LANG

mkdir -p $MODPATH/bin $MODPATH/lib $MODPATH/system/bin
ARCH=$(getprop ro.product.cpu.abi)
ui_print "- $TEXT_SOC_ARCH$ARCH"
if [ "$ARCH" = "arm64-v8a" ];then
mv $MODPATH/common/arm64/bin/* $MODPATH/bin
mv $MODPATH/common/arm64/lib/* $MODPATH/lib
elif [ "$ARCH" = "armeabi-v7a" ];then
mv $MODPATH/common/arm/bin/* $MODPATH/bin
mv $MODPATH/common/arm/lib/* $MODPATH/lib
else
ui_print "- 没有当前架构的二进制文件"
fi
rm -r $MODPATH/common

set_perm_recursive $MODPATH/ 0 0 0755 0644
chmod 755 $MODPATH/bin/*

if [ -d $MODDIR ];then
    ALIST_CONFIG_PATH=$MODDIR/etc/config.json
    JQ_PATH=$MODPATH/bin/jq
    DB_FILE_PATH="$($JQ_PATH '.database.db_file' $ALIST_CONFIG_PATH | $BUSYBOX_PATH sed 's/"//g' )"
    for i in ${DB_FILE_PATH} ${DB_FILE_PATH}-shm ${DB_FILE_PATH}-wal $MODDIR/etc/dht.dat $MODDIR/etc/dht6.dat $MODDIR/rclone.conf;do
        if [ -f $i ];then
        cp -rp $i $MODPATH/etc
        ui_print "- ${TEXT_BACKUP}${i}"
        fi
    done
    CER_FILE="$(find $MODDIR/etc/certificate -type f -maxdepth 1)"
    if [ -n "$CER_FILE" ];then
    for i in $CER_FILE ;do
        if [ -f $i ];then
        cp -rp $i $CER_DIR
        ui_print "- ${TEXT_BACKUP}${i}"
        fi
    done
    fi
    if [ -f /data/adb/Neribox/backup.list ];then
    EXTBACKUPFILE=$(cat /data/adb/Neribox/backup.list | $BUSYBOX_PATH egrep "^file=" | $BUSYBOX_PATH sed -n 's/.*=//g;$p')
    for i in $EXTBACKUPFILE;do
        if [ -f ${MODDIR}${i} ];then
        cp -rp ${MODDIR}${i} ${MODPATH}${i}
        ui_print "- ${TEXT_BACKUP}${MODDIR}${i}"
        fi
    done
    fi
fi

if [ -z "$(echo $CER_FILE| grep SERVER-PRIVATE.key | grep SERVER.pem | grep CA.crt)" ];then
    chmod 777 $MODPATH/toolkit
    $MODPATH/toolkit openssl -mkcer -install
    ui_print "- 生成并安装CA证书"
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

CONFIG_PATH="/data/adb/Neribox/config.ini"

for object in AOD DASHBOARD STATUSBAR ALIST_DAEMON ALIST_HTTPS ARIA2_DAEMON ARIANG_WEBUI RCLONE_DAEMON MOUNTDIR CLOUDDIR FRPC_DAEMON FRPC_PARM TERMUX_REPO TRACKERLIST ROOT_MANAGER;do
eval $object=$(CONFIG $CONFIG_PATH $object)
done
[ -z "$AOD" ] && AOD=0
[ -z "$DASHBOARD" ] && DASHBOARD=true
[ -z "$STATUSBAR" ] && STATUSBAR="ALIST[VERSION,DAEMON,PORT,USER,PASSWORD] ARIA2[VERSION,DAEMON,PORT,WEBUI] RCLONE[VERSION,DAEMON,PID] FRPC[VERSION,DAEMON,PID]"
[ -z "$ALIST_DAEMON" ] && ALIST_DAEMON=false
[ -z "$ALIST_HTTPS" ] && ALIST_PROXY=-1
[ -z "$ARIA2_DAEMON" ] && ARIA2_DAEMON=false
[ -z "$ARIANG_WEBUI" ] && ARIANG_WEBUI=true
[ -z "$RCLONE_DAEMON" ] && RCLONE_DAEMON=false
[ -z "$MOUNTDIR" ] && MOUNTDIR=AList
[ -z "$CLOUDDIR" ] && CLOUDDIR=/
[ -z "$FRPC_DAEMON" ] && FRPC_DAEMON=false
[ -z "$FRPC_PARM" ] && FRPC_PARM=
[ -z "$TERMUX_REPO" ] && TERMUX_REPO=https://packages-cf.termux.dev
[ -z "$TRACKERLIST" ] && TRACKERLIST=https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all_ip.txt
[ -z "$ROOT_MANAGER" ] && ROOT_MANAGER="$(dumpsys window | grep mCurrentFocus | awk '{print $3}' | awk -F / '{print $1}')"
#创建配置文件
echo "#true启用,false不启用
#息屏控制，多少秒后关闭进程，0禁用
AOD=$AOD

#仪表盘是否开启
DASHBOARD=$DASHBOARD

#仪表盘自义定样式
STATUSBAR=$STATUSBAR

#AList进程守护
ALIST_DAEMON=$ALIST_DAEMON

#AList默认https端口，-1为禁用，端口可为1-66535之间
ALIST_HTTPS=-1

#Aria2进程守护
ARIA2_DAEMON=$ARIA2_DAEMON

#AriaNG界面
ARIANG_WEBUI=$ARIANG_WEBUI

#rclone守护进程
RCLONE_DAEMON=$RCLONE_DAEMON

#默认本地挂载路径，不需要文件路径前缀
MOUNTDIR=$MOUNTDIR

#默认云端挂载路径，/为全部
CLOUDDIR=$CLOUDDIR

#frpc守护进程
FRPC_DAEMON=$FRPC_DAEMON

#frpc启动参数
FRPC_PARM=$FRPC_PARM

#Termux仓库
TERMUX_REPO=$TERMUX_REPO

#tracker服务器订阅链接
TRACKERLIST=$TRACKERLIST

#Root管理器包名
ROOT_MANAGER=$ROOT_MANAGER
" > $CONFIG_PATH
ui_print "- 已生成配置文件"
ui_print "- Root管理器包名$ROOT_MANAGER"
ui_print "- 若不对在配置文件中修改"