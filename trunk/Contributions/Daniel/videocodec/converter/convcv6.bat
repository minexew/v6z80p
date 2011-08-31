@echo off
if %1!==! goto end
if %2!==! goto end
ffmpeg -y -i %1 -vcodec rawvideo -s 80x100 -pix_fmt bgr24 -r 20 -an temp.avi
ffmpeg -y -i %1 -vn temp.wav
::volume=$(sox temp.wav -n stat -v 2>&1)
sox temp.wav -D -c 1 -r 20480 temp.sb
cv6conv temp.avi temp.sb %2
del temp.avi
del temp.wav
del temp.sb
:end
