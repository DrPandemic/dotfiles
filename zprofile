export PATH=$PATH"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/vendor_perl:/usr/bin/core_perl"

# export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

export BUNDLE_PATH=~/.gems
export GEM_HOME="$(gem env user_gemhome)"
export PATH="$PATH:$GEM_HOME/bin"

export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.nvm/versions/node/v9.5.0/bin" # Add NVM to PATH for scripting

export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/Projects/dotfiles/bin"
# For unity/omnisharp
export FrameworkPathOverride=/lib/mono/4.5

export ANDROID_HOME=/mnt/green/android
export ANDROID_SDK_ROOT=/mnt/green/android
export CHROME_EXECUTABLE=google-chrome-stable
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk"
export PATH=$JAVA_HOME/bin:$PATH

export PATH=$HOME/.cargo/bin:$PATH

# Python
export PATH=$HOME/.local/bin:$PATH

# Dart
export PATH="$PATH":"$HOME/.pub-cache/bin"

export QT_QPA_PLATFORMTHEME=qt5ct
#export QT_QPA_PLATFORM=xcb
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_ENABLE_HIGHDPI_SCALING=1
export QT_SCALE_FACTOR=1
export QT_FONT_DPI=96

export MOZ_ENABLE_WAYLAND=1
#
#export GDK_BACKEND=wayland,x11
export GDK_BACKEND=wayland
export GDK_SCALE=1.5
export GDK_DPI_SCALE=1.5
#export GDK_DPI_SCALE=0.5
#export XDG_CURRENT_DESKTOP=sway

# Draw menu in the right position
export _JAVA_AWT_WM_NONREPARENTING=1

# electron
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# sway
# export SWAYSOCK=$(find /run/user/$UID/ -name 'sway-ipc.*.sock' -print -quit)

export RUST_SRC_PATH=/home/parasithe/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library

export PATH=/home/parasithe/.cache/rebar3/bin:$PATH

export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
