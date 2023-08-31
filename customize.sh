SKIPUNZIP=0

NERIBOXDIR="/data/adb/Neribox"
MODDIR="/data/adb/modules/Neribox"
CER_DIR="$NERIBOXDIR/sysroot/etc/certificate"
UPDATEDIR="$NERIBOXDIR/update-cache"

if [ -f /data/adb/magisk/busybox ];then
BUSYBOX_PATH=/data/adb/magisk/busybox
elif [ -f /data/adb/ksu/bin/busybox ];then
BUSYBOX_PATH=/data/adb/ksu/bin/busybox
fi

mkdir -p $NERIBOXDIR

function LANG () {
    local LANG=$(getprop | grep persist.sys.locale | grep -v persist.sys.localevar | $BUSYBOX_PATH awk '{print $2}')
    local LANG=${LANG:1:5}
    if [ -f $MODPATH/support-lang/$LANG.txt ];then
        source $MODPATH/support-lang/$LANG.txt
    else source $MODPATH/support-lang/zh-CN.txt
    fi
}

LANG

mkdir -p $UPDATEDIR & chmod 777 $UPDATEDIR

ui_print "- 获取资源链接"
$BUSYBOX wget --no-check-certificate -q "https://kazamataneri.tech/link.txt" -P $UPDATEDIR
source $UPDATEDIR/link.txt

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- $TEXT_SOC_ARCH$ARCH"
if [ "$ARCH" = "arm64-v8a" ];then
ui_print "- 正在下载二进制文件"
$BUSYBOX wget --no-check-certificate -q "$bin64_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
elif [ "$ARCH" = "armeabi-v7a" ];then
ui_print "- 正在下载二进制文件"
$BUSYBOX wget --no-check-certificate -q "$bin32_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
else
    ui_print "- 没有当前架构的二进制文件"
    exit
fi
if [ -f $UPDATEDIR/binary*.zip ];then
    ui_print "- 正在释放二进制文件"
    unzip -q -o $UPDATEDIR/binary*.zip -d $NERIBOXDIR/sysroot
fi

ui_print "- 正在下载配置文件"
$BUSYBOX wget --no-check-certificate -q "$etc_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
ui_print "- 正在释放配置文件"
unzip -q -o $UPDATEDIR/etc.zip -d $NERIBOXDIR/sysroot

ui_print "- 正在下载AriaNg"
$BUSYBOX wget --no-check-certificate -q "$ariang_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
ui_print "- 正在释放AriaNg"
unzip -q -o $UPDATEDIR/AriaNg.zip -d $NERIBOXDIR/sysroot

set_perm_recursive $MODPATH/ 0 0 0755 0644
set_perm_recursive $NERIBOXDIR/sysroot 0 0 0755 0644
chmod 744 $NERIBOXDIR/sysroot/bin/*
chmod 777 $MODPATH/toolkit

CER_FILE="$(find $CER_DIR -type f -maxdepth 1)"
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

#AList启动端口，左边为http,右边为https，-1为禁用，端口可为0-66535之间
ALIST_PORT=$ALIST_PORT

#AList管理员密码（强制），仅对3.15.1版本以上生效
ALIST_PASSWD=$ALIST_PASSWD

#Aria2进程守护
ARIA2_DAEMON=$ARIA2_DAEMON

#Aria2是否启用https
ARIA2_HTTPS=$ARIA2_HTTPS

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

if [ -d /data/data/bin.mt.plus/files/term/usr/etc/bash_completion.d ];then
ui_print "- 检测到mt终端"
ui_print "- 下载补全扩展包"
$BUSYBOX wget --no-check-certificate -q "$bash_link" -P $UPDATEDIR --user-agent='pan.baidu.com'
ui_print "- 安装扩展包"
unzip -q -o $UPDATEDIR/MTbash.zip -d $UPDATEDIR
user_id="$(ls -l /data/data/bin.mt.plus/files/term/usr/etc | tail -n 1 | awk '{print $3}')"
rm -f /data/data/bin.mt.plus/files/term/usr/etc/bash_completion.d/toolkit_complete.sh
cp -f $UPDATEDIR/toolkit_complete.sh /data/data/bin.mt.plus/files/term/usr/etc/bash_completion.d/toolkit_complete.sh
chown $user_id:$user_id /data/data/bin.mt.plus/files/term/usr/etc/bash_completion.d/toolkit_complete.sh
chmod 700 /data/data/bin.mt.plus/files/term/usr/etc/bash_completion.d/toolkit_complete.sh
rm -f /data/data/bin.mt.plus/files/term/usr/etc/bash.bashrc
cp -f $UPDATEDIR/bash.bashrc /data/data/bin.mt.plus/files/term/usr/etc/bash.bashrc
chown $user_id:$user_id /data/data/bin.mt.plus/files/term/usr/etc/bash.bashrc
chmod 600 /data/data/bin.mt.plus/files/term/usr/etc/bash.bashrc
fi

if [ -d $NERIBOXDIR/PID ];then
    ui_print "- 启用非重启模式"
    for x in $NERIBOXDIR/PID/clean $NERIBOXDIR/PID/aod $NERIBOXDIR/PID/daemon $NERIBOXDIR/PID/dashboard;do
    kill -9 $(cat $x)
    cp $MODPATH/toolkit $MODDIR/toolkit
done
    /system/bin/sh $MODPATH/service.sh
fi