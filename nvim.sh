#!/bin/bash

sudo pacman -S neovim

cd nvim
vim="$(pwd)/"
vimrc="$(pwd)/init.vim"
remote_vim=$HOME/.vim
remote_nvim=$HOME/.config/nvim
if [ ! -L $remote_vim ]; then
  ln -s $vim $remote_vim
fi
if [ ! -L $remote_nvim ]; then
  ln -s $vim $remote_nvim
fi
ln -s $vimrc $HOME/.vimrc

curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Run :PlugInstall inside nvim"
cd ..
