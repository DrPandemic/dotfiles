source ~/.zprofile

# User configuration
export TERM='screen-256color'

alias htop TERM=screen htop
alias x=startx
alias gclean='git branch --merged master | grep -v "\* master" | xargs -n 1 git branch -d'

export EDITOR='vim'
export CC=clang
export CXX=clang++

if [[ -z $TMUX ]]; then
  if [[ -n $XAUTHORITY ]] then
    tmux a || tmux
  fi
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
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
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

# Theme
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
