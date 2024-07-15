#!/bin/sh

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

[ -f /etc/xprofile ] && source /etc/xprofile
[ -f ~/.xprofile ] && source ~/.xprofile
[ -f ~/.Xresources ] && xrdb -merge -I$HOME ~/.Xresources

numlockx &

exec cinnamon-session
#exec i3 # -V > /tmp/i3.log 2>&1
#export GDK_BACKEND=x11
#export XDG_SESSION_TYPE=x11
#export GDK_BACKEND=wayland
#exec gnome-session
