# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="agnoster"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration
export PATH=$PATH"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/vendor_perl:/usr/bin/core_perl"
export TERM='screen-256color'
export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
alias htop TERM=screen htop
alias x=startx
alias gclean='git branch --merged master | grep -v "\* master" | xargs -n 1 git branch -d'

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
  source /usr/share/pvm/init-pvm.sh
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
