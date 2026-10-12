source ~/.zprofile

# User configuration
# export TERM='screen-256color'

alias htop TERM=screen htop
alias gclean='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d '
alias ping=prettyping
alias vim=nvim
alias xg=start-gnome

export OPENCODE_ENABLE_EXA=1
export EDITOR='vim'
export CC=clang
export CXX=clang++
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/google-creds.json
export DOCKER_ID_USER="drpandemic"

#export WLR_RENDERER=vulkan
#export WLR_RENDERER=gles2

if [[ -z $TMUX ]]; then
  if [[ -n $WAYLAND_DISPLAY ]] then
    if [[ -n $TERMINFO ]] then
      tmux a || tmux
    fi
  fi
fi

# Session launchers run on the systemd user bus, never a private one:
# gnome-keyring-daemon owns org.freedesktop.secrets on $XDG_RUNTIME_DIR/bus, so on a
# second bus that name is only activatable and never claimed — every secret-service
# lookup (gpg-agent's passphrase cache, hence every signed commit) waits out a 25s
# D-Bus timeout before falling back to a prompt.
function x {
  XDG_CURRENT_DESKTOP=sway DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" sway
}

function start-gnome {
  XDG_SESSION_TYPE=wayland DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" gnome-session
}

function waybar-wayland {
  GDK_BACKEND=wayland waybar
}

function :q() {
    exit
}

function pvm() {
  unset -f pvm
  source ~/Projects/pvm/init-pvm.sh
  pvm "$@"
}

function load_nvm {
  unset -f load_node
  unalias node
  unset -f load_npm
  unalias npm
  unset -f nvm
  # [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
  #source /usr/share/nvm/init-nvm.sh
}

function load_node {
  load_nvm
  node "$@"
}
alias node="load_node"

function load_npm {
  load_nvm
  npm "$@"
}
alias npm="load_npm"

function nvm {
  load_nvm
  nvm "$@"
}

function sed_regex() {
  rg -l "$1" | xargs sed -i -e "s/$1/$2/g"
}

function dev() {
  devcontainer exec --workspace-folder ./ "$@"
}

# Theme
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# Vi keybindings
bindkey -v
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# ZFZ
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# .net core
export PATH="$PATH:/home/parasithe/.dotnet/tools"

# zsh history
setopt HIST_IGNORE_SPACE

# Game HUD
#export MANGOHUD=1
export GPG_TTY=$(tty)
