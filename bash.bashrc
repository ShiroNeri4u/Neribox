LANG=en_US.UTF-8
SYMBOL="➜"; if [ $UID == 0 ]; then SYMBOL="#"; fi
PS1="\$(V="\$?" ;if [ \$V == 0 ]; then echo \[\e[1\;32m\]; else echo \[\e[1\;31m\]; fi)$SYMBOL \[\e[1;36m\]\W\[\e[m\] "
for i in /data/user/0/bin.mt.plus/files/term/usr/etc/bash_completion.d/*.sh; do
	if [ -r $i ]; then
		. $i
	fi
done
unset i