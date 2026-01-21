#!/bin/bash

if [[ ! -f $1 ]]; then
	echo Supply input file
	exit 1
fi

ffmpeg -i $1 -vn -acodec pcm_s16le ${1}.wav
