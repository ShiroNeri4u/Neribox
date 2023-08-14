#!/system/bin/sh
MODDIR=${0%/*}
NERIBOXDIR="/data/adb/Neribox"
ln -sf $MODDIR/toolkit $MODDIR/system/bin
ln -sf $MODDIR/etc NERIBOXDIR/config.d