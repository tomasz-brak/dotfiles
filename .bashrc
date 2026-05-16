#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export QSYS_ROOTDIR="/home/tomasz/.cache/yay/quartus-free/pkg/quartus-free-quartus/opt/intelFPGA/25.1/quartus/sopc_builder/bin"
