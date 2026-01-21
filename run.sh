#!/bin/bash

echo Running $1  ....

$1

while [ $? -ne 0 ]; do
    read -p "Command $1 didn't succeed. Try it again? Y/n:" yn
    case $yn in
        [Yy]* ) $1;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo RUN OK: $1 .
