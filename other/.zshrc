#!/usr/bin/env zsh
# =============================================================================
# ZSH Configuration File (.zshrc)
# Based on:- https://github.com/zdharma-continuum/zinit-configs/tree/master/vladdoster
# =============================================================================
# -----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES & PATH
# -----------------------------------------------------------------------------
# Essential PATH exports
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Editor preferences
export EDITOR="nvim"
export VISUAL="nvim"

# Enable auto-cd
setopt AUTO_CD
# Turn off "no match" errors
setopt nonomatch

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS (moved after instant prompt to avoid console output)
# -----------------------------------------------------------------------------
function error() {
    print -P "%F{red}[ERROR]%f: %F{yellow}$1%f" && return 1
}

function info() {
    print -P "%F{blue}[INFO]%f: %F{cyan}$1%f"
}

# -----------------------------------------------------------------------------
# ZINIT CONFIGURATION
# -----------------------------------------------------------------------------
# Zinit directory structure - UPDATED TO MATCH DEFAULT PATH
typeset -gAH ZINIT
ZINIT[HOME_DIR]="$HOME/.local/share/zinit"
ZINIT[BIN_DIR]="$ZINIT[HOME_DIR]/zinit.git"
ZINIT[COMPLETIONS_DIR]="$ZINIT[HOME_DIR]/completions"
ZINIT[SNIPPETS_DIR]="$ZINIT[HOME_DIR]/snippets"
ZINIT[ZCOMPDUMP_PATH]="$ZINIT[HOME_DIR]/zcompdump"
ZINIT[PLUGINS_DIR]="$ZINIT[HOME_DIR]/plugins"
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

# Zinit variables
ZPFX="$ZINIT[HOME_DIR]/polaris"
ZI_FORK='vladdoster'
ZI_REPO='zdharma-continuum'
GH_RAW_URL='https://raw.githubusercontent.com'

# -----------------------------------------------------------------------------
# OH-MY-ZSH & PREZTO PLUGINS
# -----------------------------------------------------------------------------
# Load useful Oh My Zsh library functions and plugins
zi for is-snippet \
    OMZL::{clipboard,compfix,completion,git,grep,key-bindings}.zsh \
    OMZP::brew \
    PZT::modules/{history,rsync}

# Load completions for specific tools
zi as'completion' for \
    OMZP::{golang/_golang,pip/_pip,terraform/_terraform}

# -----------------------------------------------------------------------------
# CUSTOM COMPLETIONS
# -----------------------------------------------------------------------------
# Helper function to install completions from GitHub
install_completion() {
    zinit for as'completion' nocompile id-as"$1" is-snippet "$GH_RAW_URL/$2"
}

# -----------------------------------------------------------------------------
# ZINIT ANNEXES
# -----------------------------------------------------------------------------
# Load useful Zinit extensions
zi light-mode for \
    "$ZI_REPO"/zinit-annex-{bin-gem-node,binary-symlink,patch-dl,submods}

# Install additional command-line tools
zi as'command' light-mode for \
    pick'revolver' @molovo/revolver \
    pick'zunit' atclone'./build.zsh' @zunit-zsh/zunit

# -----------------------------------------------------------------------------
# PYTHON CONFIGURATION
# -----------------------------------------------------------------------------
# Custom pip completion function
function _pip_completion() {
    local words cword
    read -Ac words
    read -cn cword
    reply=(
        $(
            COMP_WORDS="$words[*]"
            COMP_CWORD=$((cword - 1))
            PIP_AUTO_COMPLETE=1 $words 2>/dev/null
        )
    )
}
compctl -K _pip_completion pip3

# -----------------------------------------------------------------------------
# ZSH ENHANCEMENT PLUGINS
# -----------------------------------------------------------------------------

# Enhanced completions - Additional completion definitions
zi light-mode for zsh-users/zsh-completions

# Auto-suggestions - Suggests commands as you type based on history
zi ice atload'_zsh_autosuggest_start' \
    atinit'
           ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
           bindkey "^_" autosuggest-execute
           bindkey "^ " autosuggest-accept'
zi light zsh-users/zsh-autosuggestions

# Fast syntax highlighting - Real-time command syntax validation
zi ice atclone'(){local f;cd -q →*;for f (*~*.zwc){zcompile -Uz -- ${f}};}' \
    atload'FAST_HIGHLIGHT[chroma-man]=' \
    atpull'%atclone' \
    compile'.*fast*~*.zwc' \
    nocompletions
zi light "$ZI_REPO"/fast-syntax-highlighting

# FZF history search - Fuzzy search through command history
zi light joshskidmore/zsh-fzf-history-search

# Zsh autocomplete - Real-time type-ahead autocompletion
zi ice atload'
        bindkey              "^I" menu-select
        bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi light marlonrichert/zsh-autocomplete

# -----------------------------------------------------------------------------
# FINALIZATION
# -----------------------------------------------------------------------------
# Initialize completions and replay cached completions
zi for atload'
    zicompinit; zicdreplay
    _zsh_highlight_bind_widgets
    _zsh_autosuggest_bind_widgets' \
    as'null' id-as'zinit/cleanup' lucid nocd wait \
    "$ZI_REPO"/null
