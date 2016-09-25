# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

ZSH_THEME="agnoster"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH=$PATH"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/vendor_perl:/usr/bin/core_perl"

export TERM='screen-256color'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
source /usr/share/pvm/init-pvm.sh
alias htop TERM=screen htop
alias x=startx

eval "$(ntfy shell-integration)"

if [[ -z $TMUX ]]; then
  if [[ -n $XAUTHORITY ]] then
    tmux a || tmux
  fi
fi

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

function :q {
    exit
}
