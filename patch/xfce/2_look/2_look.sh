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

#########################################################################
############################### Shortcut Functions ######################
#########################################################################

function check_and_create_directory() {
    if [ ! -d "$HOME/$1" ]; then
        mkdir -p "$HOME/$1"
    fi
}

function check_backup() {
	if [[ -e "$HOME/$1" ]]; then
	mv $HOME/$1 $HOME/${1}-backup
	mkdir -p "$HOME/$1"
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

function get_file_name_number() {
    current_file=$(basename "$0")
    folder_name="${current_file%.sh}"
    theme_number=$(echo "$folder_name" | grep -oE '[1-9][0-9]*')
}

#########################################################################
############################### Theme Installer #########################
#########################################################################

function theme_installer() {
    banner
    echo "${R} [${W}-${R}]${G} Setting Up Theme: ${C} ${theme_number}"${W}
	echo
    sleep 3
    banner
    echo "${R} [${W}-${R}]${G} Setting Up Wallpapers..."${W}
	echo
	check_and_create_directory "/data/data/com.termux/files/usr/share/backgrounds/"
	cd $PREFIX/share/backgrounds/
	wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/patch/xfce/${folder_name}/wallpaper.tar.gz
	tar -zxvf wallpaper.tar.gz
    rm wallpaper.tar.gz
    banner
	echo "${R} [${W}-${R}]${G} Installing Icon Theme..."${W}
	echo
	pkg install fluent-icon-theme -y
	echo "${R} [${W}-${R}]${G} Installing Theme..."${W}
	echo
	check_and_create_directory ".themes"
	cd $HOME/.themes
	wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/patch/xfce/${folder_name}/theme.tar.gz
    tar -zxvf theme.tar.gz
    rm theme.tar.gz
	echo "${R} [${W}-${R}]${G} Making Additional Configuration..."${W}
	echo
	check_and_create_directory ".config"
	config_dirs=(autostart cairo-dock dconf gtk-3.0 menu ristretto rofi xfce4)
        for the_config_dir in "${config_dirs[@]}"; do
		check_backup ".config/$the_config_dir"
        done
    cd $HOME/.config/
    wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/patch/xfce/${folder_name}/config.tar.gz
    tar -zxvf config.tar.gz
    rm config.tar.gz
    ############## Remove Installer Script ############
    cd ~
    rm $current_file
}

#########################################################################
########################### Install Additional Packages #################
#########################################################################

function required_package_installler() {
    banner
    echo "${R} [${W}-${R}]${G} Installing Additional Packages For Your Theme..."${W}
	echo
    package_install_and_check "cairo-dock-core"
    package_install_and_check "vala-panel-appmenu"
}

get_file_name_number
required_package_installler
theme_installer