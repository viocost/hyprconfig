#!/bin/bash
#
# running system upgrade
sudo snapper -c root create  -u important=yes -c timeline  -d "System upgrade!" \
    --command "sudo pacman -Syu"
