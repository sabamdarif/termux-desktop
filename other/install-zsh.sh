#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[0m')"
C="$(printf '\033[1;36m')"

check_prefix() {
 case "$PREFIX" in
    *com.termux*)
        while true; do
            read -p "${R}[${W}-${R}]${G}Input username [Lowercase]: ${W}" user_name
            echo
            read -p "${R}[${W}-${R}]${Y}Do you want to continue with username ${C}$user_name ${Y}? (y/n) : "${W} choice
            choice="${choice:-y}"
            echo "${R}[${W}-${R}]${G}Continuing with answer: $choice"${W}
				sleep 0.3
            case $choice in
                [yY]* )
                    echo "${R}[${W}-${R}]${G}Continuing with username ${C}$user_name"${W}
                    break;;
                [nN]* )
                    echo "${G}Please provide username and password again."${W}
                    echo
                    ;;
                * )
                    echo "${R}Invalid input. Please enter 'y' or 'n'.${W}"
                    ;;
            esac
        done
        final_user_name="${user_name}@termux"
        ;;
    *)
        final_user_name="$(whoami)@${selected_distro}"
        ;;
esac
}

check_file() {
# Check if a file named "install.sh" exists in the current directory
if [ -e "install.sh" ]; then
  echo -e "${R}A file named install.sh already exists in the current directory.${W}"
  
  # Rename the existing file by adding a timestamp suffix
  renamed_file="install_$(date +"%Y%m%d%H%M%S").sh"
  mv "install.sh" "$renamed_file"
  sleep 1.2 
  echo -e "${G}The existing file has been renamed to ${C}$renamed_file${W}."
else
  echo -e "${Y}No file named install.sh found in the current directory.${W}"
fi
}

zsh_setup() {
	clear
	echo "${Y}please wait ......"${W}
	sleep 1.3
	cd ~
	check_file
	sleep 1.5
	wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh
	sed -i -e 's/exec zsh -l/#exec zsh -l/g' install.sh
	sed -i '/printf .*Do you want to change your default shell to zsh/,/read -r opt/c\opt="y"' "install.sh"
	bash install.sh
	rm install.sh
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
	sed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="kalistyle"/g' ~/.zshrc
	sed -i -e 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc
    echo "setopt nonomatch" >> ~/.zshrc
}

setup_theme() {
	cat << EOF > ~/.oh-my-zsh/themes/kalistyle.zsh-theme
	local return_code="%(?..%{\$fg[red]%}%? ↵%{\$reset_color%})"
local user="$final_user_name"  # Replace with your desired name

local user_host="%B%F{green}┌──(%F{reset}\$user%F{green})-%F{green}[%F{reset}%B%{\$fg[blue]%}%~%b%F{blue}%B%F{green}]%F{reset}"

local user_symbol='%B%F{green}%(!.#.└─≽)%F{reset}'

local current_dir="%B%{\$fg[blue]%}%~ %{\$reset_color%}"

local vcs_branch='\$(git_prompt_info)\$(hg_prompt_info)'
local rvm_ruby='\$(ruby_prompt_info)'
local venv_prompt='\$(virtualenv_prompt_info)'

ZSH_THEME_RVM_PROMPT_OPTIONS="i v g"

PROMPT="\${user_host}\${rvm_ruby}\${vcs_branch}\${venv_prompt}
%{\$fg[yellow]%}\${user_symbol}%{\$reset_color%} "
RPROMPT="%B\${return_code}%b"

ZSH_THEME_GIT_PROMPT_PREFIX="%{\$fg[yellow]%}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="› %{\$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{\$fg[green]%}●%{\$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{\$fg[yellow]%}"

ZSH_THEME_HG_PROMPT_PREFIX="\$ZSH_THEME_GIT_PROMPT_PREFIX"
ZSH_THEME_HG_PROMPT_SUFFIX="\$ZSH_THEME_GIT_PROMPT_SUFFIX"
ZSH_THEME_HG_PROMPT_DIRTY="\$ZSH_THEME_GIT_PROMPT_DIRTY"
ZSH_THEME_HG_PROMPT_CLEAN="\$ZSH_THEME_GIT_PROMPT_CLEAN"

ZSH_THEME_RUBY_PROMPT_PREFIX="%{\$fg[red]%}‹"
ZSH_THEME_RUBY_PROMPT_SUFFIX="› %{\$reset_color%}"

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{\$fg[lightblue]%}‹"
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="› %{\$reset_color%}"
ZSH_THEME_VIRTUALENV_PREFIX="\$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX"
ZSH_THEME_VIRTUALENV_SUFFIX="\$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX"
EOF
}

print_success() {
	clear
	rm install-zsh.sh
	echo -e "${G}ZSH SETUP SUCCESSFUL${W} ${C}Now Restart the Terminal${W}"
	echo -e "${C}Or Log Out And Log Back In Again${W}"
}

check_paramitter() {
  if [[ "$1" == "-u" ]]; then
    user_name="$2"
    if [[ "$HOME" == *termux* && -z "$user_name" ]]; then
      read -p "${G}Please enter your user name: ${W}" user_name
    fi
    final_user_name="${user_name}@termux"
    return
  fi

  check_prefix
}

check_paramitter "$@"
zsh_setup
setup_theme
print_success