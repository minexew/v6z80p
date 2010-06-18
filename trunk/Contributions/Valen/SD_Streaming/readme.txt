Video and sound streaming from SD card by Valen.  (should work in 50Hz and 60Hz video modes)
requires HW v638+

(Updated by Phil - automatically uses the file start block
but requires FLOS v520+)



streamed_file.asm        - StreamedFile related routines and data 
streamed_file_sound.asm  - playing sound stream related routines and data
myvideo,asm              - playing video stream related routines and data
test_streaming.asm       - example of using StreamedFile (main file)


Example of using StreamedFile
==============================
This example use sound and video files as sources for streaming.


Sound stream (25600Hz, mono, 8-bit signed)
-------------------------------------------
One sectors are readed (from SD card) in each frame at 50Hz (even in 60Hz videomode).
So, the bandwidth is 50 * (512*1) = 25600 Bytes per second. 
Each sector (on SD card) contain uncompressed sound data.



Video stream (frame size is 64x64 pixels, 240 colors, byte per pixel)
--------------------------------------------------
Two sectors are readed (from SD card) in each frame at 50Hz (even in 60Hz videomode).
So, the bandwidth is 50 * (512*2) = 51200 Bytes per second.
Each frame (on SD card) contain 1 sector of palette data + 8 sectors of image data. All frame data is uncompressed.
Palette is using 256 - 16 = 240 colors. (first 16 colors of palette is reserved for future use)
Frame rate is 51200 / (9 * 512) = 11,111 FPS. (Each 9 readed sectors, the new frame is ready and displayed)
Video is zoomed to video window 128x128 (each pixel is doubled in line and each line is doubled).

Total
-----
3 sectors are readed in each frame from SD card. 
Total bandwidth is 50 * (512*3) = 76800 Bytes per second.
About 15-20% of frame time is left free.


Data files
-----------
SND1.BIN
VID1.BIN
Must be located in the same  dir as executable.
Recommendation: filesize should be divided by 7E00 without remainder, or you may:
- hear some noise
- see some garbage
at the end of file (on last file block)



How StreamedFile lib works
===========================
You call 'init' routine and call 'build list' routine.
'Build list' reads all PQFS file blocks numbers for requested file and store them to buffer (list of file block numbers).
After that, each frame you want next sector of file (512 byte) to be readed in, you call compute_lba_address
(and read_mmc_sector)


Size of file for streaming, is limited only by buffer size for PQFS file blocks numbers.
For now, buffer located in dedicated system memory bank and address is $8000.
Thus max file size, for streaming, is (32K / 2) * $7E00  = 528,482,304 bytes
(2 bytes per file block number)

You can stream multiple files by using several instances of StreamedFile.
(example is using two instances, first for video streaming and second for sound streaming)


known bugs
-----------
at the end of the stream, 
video and audio can lost sync a bit
(not really a bug, just need some more coding/thinking)

todo
----



