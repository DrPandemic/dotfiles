#!/bin/bash

sudo pacman -S tmux
git clone git@github.com:erikw/tmux-powerline.git

cd tmux

tmuxfolder="$(pwd)/"
tmuxconf="$(pwd)/tmux.conf"
tmuxpowerline="$(pwd)/tmux-powerlinerc"
ln -s $tmuxfolder $HOME/.config/tmux
ln -s $tmux $HOME/.tmux.conf
ln -s $tmuxpowerlinerc $HOME/.tmux-powerlinerc

cd ..
