#!/bin/bash

# NVIM
#sudo pacman -S neovim
curl -fLo ./ \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cd vim
vim="$(pwd)/"
vimrc="$(pwd)/init.vim"
ln -s $vim $HOME/.vim
ln -s $vim $HOME/.config/nvim
ln -s $vimrc $HOME/.vimrc
