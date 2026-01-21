#!/bin/bash

# i3 volume control script

newvol="pkill -RTMIN+10 i3blocks"
sample="paplay  ${HOME}/.config/i3/sound/pop1.wav"


case "$1" in
	"up") pactl set-sink-volume 0 +"$2"% ; $newvol ; $sample ;;
	"down") pactl set-sink-volume 0 -"$2"% ; $newvol ; $sample ;;
	"mute") pactl set-sink-mute 0 toggle   ; $newvol ; $sample ;;
esac
