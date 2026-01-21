#!/usr/bin/env bash

# esc to caps
setxkbmap -option caps:escape

# Keyboard layout
setxkbmap -layout us,ru,il
setxkbmap -option 'grp:alt_shift_toggle'

# Duplicate mod key in i3
xmodmap -e 'keycode 135 = Super_R' && xset -r 135
