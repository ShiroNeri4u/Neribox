complete -F toolkit_complete_func toolkit

toolkit_complete_func () {
    local cur prev opts  
    COMPREPLY=()  
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="alist aria2 rclone frpc openssl trackerlist -h -help -v -version dashboard"
    case $prev in
    alist)
    opts="-start -stop -update -h -help -v -version"
    ;;
    aria2)
    opts="-start -stop -update -h -help -v -version"
    ;;
    rclone)
    opts="-mount -umount -update -REMOTE -MOUNTDIR -CLOUDDIR -h -help -v -version"
    ;;
    frpc)
    opts="-start -stop -update -h -help -v -version"
    ;;
    openssl)
    opts="-mkcer -install -h -help -v -version"
    ;;
    trackerlist)
    opts="-update -h -help"
    ;;
    esac
    if [[ ${cur} == * ]] ; then  
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )   
        return 0   
    fi
}