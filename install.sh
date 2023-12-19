#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-
# coded by Glitch

function print_ew () {

    if [[ "$1" == "error" ]]; then
        s_text="\x1b[38;5;1m[ERROR]:";
        text="$2\n";
    elif [[ "$1" == "warn" ]]; then
        s_text="\x1b[38;5;220m[WARNING]:";
        text="$2\n";
    elif [[ "$1" == "question" ]]; then
        s_text="\x1b[38;5;128m[QUESTION]:";
        text="$2";
    elif [[ "$1" == "info" ]]; then
        s_text="\x1b[38;5;83m[Installer thread/INFO]:";
        text="$2\n";
    else
        s_text="\x1b[38;5;31m[$1]:";
        text="$2\n";
    fi

    current_time="$( date +"%k:%M:%S" )";

    printf "\x1b[38;5;214m[${current_time}] ${s_text}\x1b[0m \x1b[38;5;87m$text\x1b[0m";

}

if [[ "$(uname -o)" != "Android" ]]; then  # check termux
    print_ew "error" "this script is for Termux. " && exit 1;
fi

fn_install () {

    clear;

    directory=kali-fs;

    if [ -d "$directory" ]; then
        first=1
        print_ew "warn" "Skipping the download and the extraction"
    elif [ -z "$(command -v proot)" ]; then
        print_ew "error" "Please install proot." && exit 1;
    elif [ -z "$(command -v wget)" ]; then
        print_ew "error" "Please install wget." && exit 1;
    fi

    if [ "$first" != 1 ]; then
        if [ -f "kali-linux-arm64.tar.gz" ]; then
            echo "kali linux already downloaded";
        fi

        if [ ! -f "kali-linux-arm64.tar.gz" ]; then

            print_ew "info" "Downloading the kali rootfs, please wait 2 minute...";

            wget "https://maximus-sallam/kali-linux-arm64.tar.gz" --show-progress -O kali-linux-arm64.tar.gz;

            print_ew "info" "Download complete!";
        fi

        cur=`pwd`;

        mkdir -p $directory > /dev/null 2>&1;

        cd $directory;

        print_ew "info" "Decompressing the kali rootfs, please wait...";

        proot --link2symlink tar -zxf $cur/kali-linux-arm64.tar.gz --exclude='dev'||:;

        print_ew "info" "The kali rootfs have been successfully decompressed!";

        print_ew "info" "Fixing the resolv.conf, so that you have access to the internet";

        printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" >> etc/resolv.conf;

        stubs=();

        stubs+=('usr/bin/groups');

        for f in ${stubs[@]};do
            print_ew "info" "Writing stubs, please wait...";
            echo -e "#!/bin/sh\nexit" > "$f";
        done

        print_ew "info" "Successfully wrote stubs!";
        
        cd $cur;

    fi

    mkdir -p kali-binds;

    bin=start.sh;

    print_ew "info" "Creating the start script, please wait...";

    cat > $bin <<- EOM
#!/bin/bash
# -*- coding: utf-8 -*-

cd \$(dirname \$0);

## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD;
command="proot";

## uncomment following line if you are having FATAL: kernel too old message.
#command+=" -k 4.14.81";
command+=" --link2symlink";
command+=" -0";
command+=" -r $directory";

if [ -n "\$(ls -A kali-binds)" ]; then
    for f in kali-binds/* ;do
      . \$f;
    done
fi

command+=" -b /dev";
command+=" -b /proc";
command+=" -b /sys";
command+=" -b kali-fs/tmp:/dev/shm";
command+=" -b /data/data/com.termux";
command+=" -b /:/host-rootfs";
command+=" -b /sdcard";
command+=" -b /storage";
command+=" -b /mnt";
command+=" -w /root";
command+=" /usr/bin/env -i";
command+=" HOME=/root";
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games";
command+=" TERM=\$TERM";
command+=" LANG=C.UTF-8";
command+=" /bin/bash --login";
com="\$@";

if [ -z "\$1" ]; then
    exec \$command;
else
    \$command -c "\$com";
fi
EOM

    print_ew "info" "The start script has been successfully created!";

    print_ew "info" "Fixing shebang of start.sh, please wait...";
    
    termux-fix-shebang $bin > /dev/null 2>&1;
    
    print_ew "info" "Successfully fixed shebang of start.sh!";

    print_ew "info" "Making start.sh executable please wait...";

    chmod +x $bin > /dev/null 2>&1;

    print_ew "info" "Successfully made start.sh executable";

    print_ew "info" "Cleaning up please wait...";
    
    rm -rf .git 2>&1;
    
    print_ew "info" "Successfully cleaned up!";

    print_ew "info" "installation completed! Run => bash start.sh";

}

trap '' 2

    if [ "$1" == "-y" ]; then
        fn_install;
    elif [ "$1" == "" ]; then
        print_ew "question" "Do you want to install kali-in-termux? [Y/n] " && read cmd;
        if [ "$cmd" == "y" ]; then
            fn_install;
        elif [ "$cmd" == "Y" ]; then
            fn_install;
        else
            print_ew "error" "Installation aborted.";
        fi
    else
        print_ew "error" "Installation aborted.";
    fi
