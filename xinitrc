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

#exec gnome-session
exec i3 -V > ~/.logs/i3.log 2>&1
