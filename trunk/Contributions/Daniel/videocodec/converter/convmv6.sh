#!/bin/bash
if [ -z "$1" ]; then
  exit 1
fi
if [ -z "$2" ]; then
  exit 1
fi
conv=$(tempfile)
ffmpeg -y -i $1 -vcodec rawvideo -s 320x100 -pix_fmt bgr24 -r 20 -an $conv.avi
ffmpeg -y -i $1 -vn $conv.wav
volume=$(sox $conv.wav -n stat -v 2>&1)
sox -v $volume $conv.wav -D -c 1 -r 20480 $conv.sb
mv6conv $conv.avi $conv.sb $2
rm $conv.avi
rm $conv.wav
rm $conv.sb
rm $conv
