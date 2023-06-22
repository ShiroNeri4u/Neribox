#!/system/bin/sh
# 请不要硬编码 /magisk/modname/... ; 请使用 $MODDIR/...
# 这将使你的脚本更加兼容，即使Magisk在未来改变了它的挂载点
MODDIR=${0%/*}
NERIBOXDIR="/data/adb/Neribox"
# 这个脚本将以 post-fs-data 模式执行(系统启动前执行)
# 更多信息请访问 Magisk 主题

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

# 删除pid文件保证AList重启能运行
if [ -f $MODDIR/bin/daemon/pid ];then
    rm $MODDIR/bin/daemon/pid
fi

# 清除升级缓存
if [ -d /data/adb/Neribox/update-cache ];then
    rm -r /data/adb/Neribox/update-cache
fi