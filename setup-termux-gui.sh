#!/data/data/com.termux/files/usr/bin/bash
R="$(printf '\033[1;31m')"                           
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"                                       
W="$(printf '\033[1;37m')"

function banner() {
clear
printf "\033[33m ########                                      #####           \033[0m\n"
printf "\033[33m    #   ###### #####  #    # #    # #    #    #     # #    # # \033[0m\n"
printf "\033[33m    #   #      #    # ##  ## #    #  #  #     #       #    # # \033[0m\n"
printf "\033[33m    #   #####  #    # # ## # #    #   ##      #  #### #    # # \033[0m\n"
printf "\033[33m    #   #      #####  #    # #    #   ##      #     # #    # #  \033[0m\n"
printf "\033[33m    #   #      #   #  #    # #    #  #  #     #     # #    # # \033[0m\n"
printf "\033[33m    #   ###### #    # #    #  ####  #    #     #####   ####  #  \033[0m\n"
printf "\033[32m code by @sabamdrif \033[0m\n"
echo
}

function questions() {
	banner
	echo "${R} [${W}-${R}]${G}Select Theme Style"${W}
	echo
	echo "${R} [${W}-${R}]${G}Check the styles section in the github page"${W}
	echo
	echo "${R} [${W}-${R}]${B}https://github.com/sabamdarif/termux-desktop/blob/main/styles.md"${W}
	echo
	read -p "${R} [${W}-${R}]${Y}Type the number of the theme style (Default 1): "${W} style_answer
	echo
	banner
	echo "${R} [${W}-${R}]${G}Select browser you want to install"${W}
	echo
	echo "${Y}1. firefox"${W}
	echo
	echo "${Y}2. chromium"${W}
	echo 
	echo "${Y}3. firefox & chromium (both)"${W}
	echo
	echo "${Y}4. Skip"${W}
	echo
	read -p "${Y}select an option (Default 1): "${W} browser_answer
	banner
    echo "${R} [${W}-${R}]${G}Select IDE you want to install"${W}
	echo
	echo "${Y}1. VS Code"${W}
	echo
	echo "${Y}2. Geany (lightweight IDE)"${W}
	echo
	echo "${Y}3. Vlc & Audacious (both)"${W}
	echo
	echo "${Y}4. Skip"${W}
	echo
	read -p "${Y}select an option (Default 1): "${W} ide_answer
    banner
    echo "${R} [${W}-${R}]${G}Select Media Player you want to install"${W}
	echo
	echo "${Y}1. Vlc"${W}
	echo
	echo "${Y}2. Audacious"${W}
	echo 
	echo "${Y}3. Vlc & Audacious (both)"${W}
	echo
	echo "${Y}4. Skip"${W}
	echo
	read -p "${Y}select an option (Default 1): "${W} player_answer
    banner
    echo "${R} [${W}-${R}]${G}Select Photo Editor"${W}
	echo
	echo "${Y}1. Gimp"${W}
	echo
	echo "${Y}2. Inkscape"${W}
	echo 
	echo "${Y}3. Gimp & Inkscape (both)"${W}
	echo
	echo "${Y}4. Skip"${W}
	echo
	read -p "${Y}select an option (Default 1): "${W} photo_editor_answer
    banner
    read -p "${R} [${W}-${R}]${Y}Do you want to install a graphical package manager [Synaptic] (y/n) "${W} synaptic_answer
	banner
	echo "${R} [${W}-${R}]${G} By Default it only add 4 - 5 wallpaper"${W}
	echo
    read -p "${R} [${W}-${R}]${Y}Do you want to add some more wallpaper (y/n) "${W} ext_wall_answer
    banner
	read -p "${R} [${W}-${R}]${Y}Do you want to install Wine ${C}[No Box86 /can run only arm64 based exe] ${Y} (y/n) "${W} wine_answer
    banner
    read -p "${R} [${W}-${R}]${Y}Do you want to Setting Up Zsh (y/n) "${W} zsh_answer
    banner
	read -p "${R} [${W}-${R}]${Y}Do you want to Setting Up termux-x11 (y/n) "${W} tx11_answer
}

function check_and_create_directory() {
    if [ ! -d "$HOME/$1" ]; then
        mkdir -p "$HOME/$1"
    fi
}

function check_and_delete() {
if [[ -e "$1" ]]; then
        rm -rf $1
    fi
}

function package_install_and_check() {
    if type -p "$1" &>/dev/null || [ -e "$PREFIX/bin/$1"* ] || [ -e "$PREFIX/bin/"*"$1" ]; then
    echo "${R} [${W}-${R}]${G} $1 is installed successfully${W}"
else
    echo "${R} [${W}-${R}]${G} Installing package: $1${W}"
    pkg install "$1"
fi

}

function update_sys() {
	banner
    echo "${R} [${W}-${R}]${G}Updating System...."${W}
	echo
    pkg update -y
    pkg upgrade -y
}

function install_required_pack() {
	banner
    echo "${R} [${W}-${R}]${Y} Installling required packages..."${W}
	echo
      packs=(wget pulseaudio x11-repo tur-repo)
        for pack_name in "${packs[@]}"; do
            package_install_and_check "$pack_name"
        done
        update_sys
}

function install_desktop() {
    banner
    echo "${R} [${W}-${R}]${G} Installing Xfce4 Desktop"${W}
	echo
	desk_packs=(xfce4 xfce4-goodies kvantum)
        for desk_pack_name in "${packs[@]}"; do
            package_install_and_check "$desk_pack_name"
        done
}

function setup_config() {
	banner
	echo "${R} [${W}-${R}]${G} Setting Up Theme..."${W}
	cd ~
	if [[ ${style_answer} =~ ^[1-9][0-9]*$ ]]; then
    wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/patch/${style_answer}_look/${style_answer}_look.sh && bash ${style_answer}_look.sh
	else
    wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/patch/1_basic_look/1_basic_look.sh && bash 1_basic_look.sh
	fi
	if [ "$ext_wall_answer" = "y" ]; then
	echo "${R} [${W}-${R}]${G} Setting Up Some Extra Wallpapers..."${W}
	echo
	wget https://archive.org/download/wallpaper-extra.tar/wallpaper-extra.tar.gz
	tar -zxvf wallpaper-extra.tar.gz
    rm wallpaper-extra.tar.gz
	fi
}

function setup_folder() {
	banner
	echo "${R} [${W}-${R}] ${G}Setting Up Storage..."${W}
	echo
	termux-setup-storage
	sleep 5
# 	cd $HOME
# directories=(Music Downloads Pictures Videos)
# for dir in "${directories[@]}"; do
#     check_and_create_directory "/sdcard/$dir"
#     ln -s "/sdcard/$dir" "$dir"
# done
}

function setup_vnc() {
    banner
    echo "${R} [${W}-${R}]${G} Setting Up Vnc..."${W}
    echo
    package_install_and_check "tigervnc"
    check_and_create_directory ".vnc"
    check_and_delete "$HOME/.vnc/xstartup"
    cat << EOF > "$HOME/.vnc/xstartup"
    startxfce4 &
EOF
    chmod +x "$HOME/.vnc/xstartup"
    check_and_delete "$PREFIX/bin/vncstart"
    cat <<EOF > "$PREFIX/bin/vncstart"
    vncserver -geometry 1920x1080
EOF
    chmod +x "$PREFIX/bin/vncstart"
    check_and_delete "$PREFIX/bin/vncstop"
    cat <<EOF > "$PREFIX/bin/vncstop"
if [ "\$1" = "-f" ]; then
    pkill Xtigervnc
else
    vncserver -kill :1
fi
rm -rf \$HOME/.vnc/localhost:*.pid
rm -rf \$PREFIX/tmp/.X1-lock
rm -rf \$PREFIX/tmp/.X11-unix/X1
EOF
    chmod +x "$PREFIX/bin/vncstop"
}

function gui() {
    if [ "$tx11_answer" = "y" ]; then
        banner
        echo "${R} [${W}-${R}]${G}Setting Up Termux:X11 "${W}
        echo
        package_install_and_check "termux-x11-nightly"
        check_and_delete "$PREFIX/bin/gui"
        cat << EOF > "$PREFIX/bin/gui"
#!/data/data/com.termux/files/usr/bin/bash

if [ "\$1" = "-start" ]; then
    vncstart
elif [ "\$1" = "-stop" ]; then
    vncstop
elif [ "\$1" = "-tx11" ]; then
    XDG_RUNTIME_DIR=\${TMPDIR} termux-x11 :1.0 &
    sleep 1
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null
    sleep 1
    DISPLAY=:1 dbus-launch --exit-with-session xfce4-session > /dev/null 2>&1 &
    sleep 2
    # process_id=\$(ps -aux | grep '[x]fce4-screensaver' | awk '{print \$2}')
    # kill "\$process_id" > /dev/null 2>&1
elif [ "\$1" = "-kill" ]; then
    termux_x11_pid=\$(pgrep -f "/system/bin/app_process / com.termux.x11.Loader :")
    xfce_pid=\$(pgrep -f "xfce4-session")
    if [ -n "\$termux_x11_pid" ] && [ -n "\$xfce_pid" ]; then
        vncstop -f
        kill -9 "\$termux_x11_pid" "\$xfce_pid"
    fi
    # pids=$(echo "\$info_output" | grep -o 'TERMUX_APP_PID=[0-9]\+' | awk -F= '{print}')
    # for pid in \$pids; do
    #    if [[ "\$pid" =~ ^[0-9]+$ ]]; then
    #        kill "\$pid" > /dev/null 2>&1
    #    fi
    # done
fi
EOF
        chmod +x "$PREFIX/bin/gui"
    fi
}


function browser_installer() {
	banner
	if [[ ${browser_answer} == "1" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Firefox..."${W}
	echo
		package_install_and_check "firefox"
	elif [[ ${browser_answer} == "2" ]]; then
    echo "${R} [${W}-${R}]${G} installing Chromium..."${W}
	echo
	package_install_and_check "chromium"
	elif [[ ${browser_answer} == "3" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Firefox..."${W}
	echo
	package_install_and_check "firefox"
    echo "${R} [${W}-${R}]${G} installing Chromium..."${W}
	echo
	package_install_and_check "chromium"
	elif [[ ${browser_answer} == "4" ]]; then
    echo "${R} [${W}-${R}]${G} Skipping Browser Installation..."${W}
	echo
	sleep 2
	else
    echo "${R} [${W}-${R}]${G} Installing Firefox..."${W}
	echo
	package_install_and_check "firefox"
	fi
}

function ide_installer() {
	banner
	if [[ ${ide_answer} == "1" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Vs Code(Code-Oss)..."${W}
	echo
    sleep 1
		package_install_and_check "code-oss"
	elif [[ ${ide_answer} == "2" ]]; then
    echo "${R} [${W}-${R}]${G} installing Geany..."${W}
	echo
		package_install_and_check "geany"
	elif [[ ${ide_answer} == "3" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Vs Code(Code-Oss)..."${W}
	echo
    sleep 1
		package_install_and_check "code-oss"
    echo "${R} [${W}-${R}]${G} installing Geany..."${W}
    echo
		package_install_and_check "geany"
	elif [[ ${ide_answer} == "4" ]]; then
    echo "${R} [${W}-${R}]${G} Skipping Ide Installation..."${W}
	echo
	sleep 2
	else
    echo "${R} [${W}-${R}]${Y} Installing Vs Code(Code-Oss)..."${W}
	echo
    sleep 1
		package_install_and_check "code-oss"
	fi
}

function media_player_installer() {
	banner
	if [[ ${player_answer} == "1" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Vlc..."${W}
	echo
		package_install_and_check "vlc-qt-static"
		package_install_and_check "vlc-qt"
	elif [[ ${player_answer} == "2" ]]; then
    echo "${R} [${W}-${R}]${G} installing Audacious..."${W}
	echo
		package_install_and_check "audacious"
	elif [[ ${player_answer} == "3" ]]; then
    echo "${R} [${W}-${R}]${G} Installing Vlc..."${W}
	echo
		package_install_and_check "vlc-qt-static/x11 vlc-qt/x11"
    echo "${R} [${W}-${R}]${G} installing Audacious..."${W}
	echo
		package_install_and_check "audacious"
	elif [[ ${player_answer} == "4" ]]; then
    echo "${R} [${W}-${R}]${G} Skipping Media Player Installation..."${W}
	echo
	sleep 2
	else
    echo "${R} [${W}-${R}]${G} Installing Vlc..."${W}
	echo
		package_install_and_check "vlc-qt-static"
		package_install_and_check "vlc-qt"
	fi
}

function photo_editor_installer() {
	banner
	if [[ ${photo_editor_answer} == "1" ]]; then
    echo "${R} [${W}-${R}]${G} Installing GIMP..."${W}
	echo
		package_install_and_check "gimp"
	elif [[ ${photo_editor_answer} == "2" ]]; then
    echo "${R} [${W}-${R}]${G} installing Inkscape..."${W}
	echo
		package_install_and_check "inkscape"
	elif [[ ${photo_editor_answer} == "3" ]]; then
    echo "${R} [${W}-${R}]${G} Installing GIMP..."${W}
	echo
		package_install_and_check "gimp"
    echo "${R} [${W}-${R}]${G} installing Inkscape..."${W}
	echo
		package_install_and_check "inkscape"
	elif [[ ${photo_editor_answer} == "4" ]]; then
    echo "${R} [${W}-${R}]${G} Skipping Photo Editor Installation..."${W}
	echo
	sleep 2
	else
    echo "${R} [${W}-${R}]${G} Installing GIMP..."${W}
	echo
		package_install_and_check "gimp"
	fi
}

function setup_synaptic() {
	banner
    if [ "$synaptic_answer" == "y" ]; then
	echo "${R} [${W}-${R}]${G}Installing Synaptic Graphical Package Manager..."${W}
	echo
		   package_install_and_check "synaptic"
else
    echo "${R} [${W}-${R}]${C}Canceling Synaptic Setup.."${W}
	echo
    sleep 1.5
fi
}

function setup_zsh() {
	banner
    if [ "$zsh_answer" == "y" ]; then
	echo "${R} [${W}-${R}]${G}Setting Up Zsh.."${W}
	echo
	package_install_and_check "zsh"
	wget https://raw.githubusercontent.com/sabamdarif/short-linux-scripts/main/install-zsh.sh && bash install-zsh.sh   
else
    echo "${R} [${W}-${R}]${C}Canceling Zsh Setup..."${W}
    sleep 1.5
fi
}

function setup_wine() {
	banner
    if [ "$wine_answer" == "y" ]; then
	echo "${R} [${W}-${R}]${G}Installing Wine..."${W}
	echo
		 package_install_and_check "wine-stable"
else
    echo "${R} [${W}-${R}]${C}Canceling Wine Setup..."${W}
    sleep 1.5
fi
}

function notes() {
	banner
	echo "${R} [${W}-${R}]${G}Installation Successfull..."${W}
	echo
	sleep 2
	echo "${R} [${W}-${R}]${C}See Uses Section in github to know how to use it"${W}
	echo "${R} [${W}-${R}]${C}URL:- ${B}https://github.com/sabamdarif/termux-desktop/blob/main/README.md#usage"${W}
}


questions
update_sys
install_required_pack
setup_folder
setup_zsh
install_desktop
browser_installer
ide_installer
media_player_installer
photo_editor_installer
setup_synaptic
setup_wine
setup_config
setup_vnc
gui
notes