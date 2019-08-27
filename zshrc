source ~/.zprofile

# User configuration
# export TERM='screen-256color'

alias htop TERM=screen htop
alias x=startx
alias gclean='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d '
alias pint=prettyping

export EDITOR='vim'
export CC=clang
export CXX=clang++
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/google-creds.json
export DOCKER_ID_USER="drpandemic"

if [[ -z $TMUX ]]; then
  #if [[ -n $XAUTHORITY ]] then
    tmux a || tmux
  #fi
fi

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
  source /usr/share/nvm/init-nvm.sh
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

# Theme
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# OPAM configuration
. /home/parasithe/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# ZFZ
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

