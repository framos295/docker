#!/bin/bash

## habilitamos los alias
#sed 's/# alias/ alias/' ~/.bashrc
echo ' alias ls="ls $LS_OPTIONS"
 alias ll="ls $LS_OPTIONS -l"
 alias l="ls $LS_OPTIONS -lA" 
# Some more alias to avoid making mistakes:
 alias rm="rm -i"
 alias cp="cp -i"
 alias mv="mv -i"' >> ~/.bashrc

#Aplicamos cambios
source ~/.bashrc
