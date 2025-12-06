#! /bin/sh

# Place all folders that mean something in places that need them.

cp ./other/.zshrc ~/.zshrc
cp ./other/.oh-my-zsh ~/.oh-my-zsh -r 
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"



