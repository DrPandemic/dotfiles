export PATH=$PATH"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/vendor_perl:/usr/bin/core_perl"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

export PATH="$PATH:$HOME/.gem/ruby/2.4.0/bin" # Add RVM to PATH for scripting

export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.nvm/versions/node/v8.2.1/bin" # Add NVM to PATH for scripting

export PATH="$PATH:$HOME/bin"
export PATH="$PATH:/opt/omnisharp-roslyn"
export PATH="$PATH:$HOME/bin/omnisharp-server/OmniSharp/bin/Debug"

export ANDROID_HOME=${HOME}/Android/Sdk
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk"
export PATH=$JAVA_HOME/bin:$PATH
