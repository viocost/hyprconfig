#!/bin/sh

sudo ip link set down wlp2s0
if [[ -z $1  ]]; then
    sudo ip link set up wlp2s0
fi
sudo wifi-menu wlp2s0
