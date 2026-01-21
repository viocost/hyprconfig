#!/bin/env bash

curdir=$(pwd)

git clone git@gitlab.com:viocost/arch-fonts ~/arch-fonts

cd ~/arch-fonts

./install.sh

cd $curdir

rm -rf ~/arch-fonts
