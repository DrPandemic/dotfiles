#!/bin/bash

sudo pacman -S zsh
yaourt -S oh-my-zsh-git

zshrc="$(pwd)/zshrc"
ln -s $zshrc $HOME/.zshrc
