#!/bin/env bash
git config --global user.email "viocost@gmail.com"
git config --global user.name "Konstantin Y. Rybakov"

curdir=$(pwd)

# Prepare
if [[ ! -d ~/.ssh ]]; then
	mkdir ~/.ssh
fi

eval "$(ssh-agent -s)"

git clone -b master https://gitlab.com/viocost/wallpapers.git ~/wallpapers


cd ~/wallpapers

while [  -z "${STEG_FILE+set}" ]; do
	read -s -p "Enter file name without extension: " STEG_FILE
done

$curdir/run.sh "steghide extract -sf $STEG_FILE.jpg" &&
$curdir/run.sh "gpg dev_key.gpg" &&
mv dev_key ~/.ssh &&
chmod 600 ~/.ssh/dev_key &&
ssh-keygen -y -f ~/.ssh/dev_key > ~/.ssh/dev_key.pub &&
echo "Host *
    IdentityFile ~/.ssh/dev_key
    AddKeysToAgent yes
" > ~/.ssh/config &&

ssh-add ~/.ssh/dev_key &&
echo ssh key is written! || ( echo Something went wrong with extracting the key && exit 1 )

rm ~/wallpapers/dev_key.gpg

cd ~

git clone git@gitlab.com:viocost/secrets &&
cd secrets &&
./unpack.sh &&

cd raw

for i in $(ls -A); do
	ln -s $(pwd)/$i $(readlink -f ~/.local/)
done

cd $curdir
