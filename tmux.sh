#!/bin/bash

sudo pacman -S tmux

cd tmux
git clone git@github.com:DrPandemic/tmux-powerline.git

tmuxfolder="$(pwd)/"
tmuxconf="$(pwd)/tmux.conf"
tmuxpowerline="$(pwd)/tmux-powerlinerc"
echo $HOME
ln -s $tmuxfolder $HOME/.config/tmux
ln -s $tmuxconf $HOME/.tmux.conf
ln -s $tmuxpowerline $HOME/.tmux-powerlinerc

cd ..
