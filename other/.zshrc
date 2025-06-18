# Turn off “no match” errors
setopt nonomatch

# Enable auto-cd
setopt AUTO_CD

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# Load Oh My Zsh libraries
zinit lucid light-mode for \
    OMZL::history.zsh \
    OMZL::completion.zsh \
    OMZL::key-bindings.zsh

# Fix for proot-distro library issues
if [[ -z "$PREFIX" && "$PREFIX" != *"/com.termux/"* ]]; then
    # Set LD_LIBRARY_PATH for proot environments if needed
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/lib"
    # Disable commands that might cause errors in proot
    function fix_proot_cmd() {
        if ! command -v $1 &> /dev/null; then
            alias $1="echo '$1 not available in this proot environment'"
        fi
    }
    # Fix commonly problematic commands
    fix_proot_cmd uname
    fix_proot_cmd sleep
    fix_proot_cmd mkdir
fi

# Ensure completion is properly initialized in Termux
if [[ -n "$PREFIX" && "$PREFIX" = *"/com.termux/"* ]]; then
  autoload -Uz compinit
  compinit
fi

# Load plugins with Turbo mode
zinit wait lucid for \
    zdharma-continuum/fast-syntax-highlighting \
    OMZP::colored-man-pages \
    OMZP::git

zinit wait lucid for \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

# zsh-fzf-history-search
zinit ice lucid wait
zinit light joshskidmore/zsh-fzf-history-search

# real-time, fish-style type-ahead completion
zinit light marlonrichert/zsh-autocomplete

# Make Tab and ShiftTab go to the menu
bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

# Make Tab and ShiftTab change the selection in the menu
bindkey -M menuselect              '^I'         menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete

export PATH="$HOME/.local/bin:$PATH"

