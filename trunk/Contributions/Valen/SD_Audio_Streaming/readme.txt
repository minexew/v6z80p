Wav streaming from SD card by Valen.

(Updated by Phil - automatically uses the file start block
but requires FLOS v620+)


streamed_file.asm        - StreamedFile related routines and data
streamed_file_sound.asm  - playing sound stream related routines and data
test_streaming.asm       - example of using StreamedFile


Example of using StreamedFile
------------------------------
This example use sound file as source for streaming.
Sound file "SND1.WAV" (or whatever) must be located in the same  dir as executable.
(25600Hz, mono, 8-bit signed)
Recommendation: filesize must be divided by 7E00 without remainder, or you may
hear some noise at the end of file (on last file block)



How StreamedFile lib works
---------------------------
You call 'init' routine and call 'build list' routine.
'Build list' reads all PQFS file blocks numbers for requested file and store them to buffer (list of file block numbers).
After that, each frame you want next sector of file (512 byte) to be readed in, you call compute_lba_address
(and read_mmc_sector)


Size of file for streaming, is limited only by buffer size for PQFS file blocks numbers.
For now, buffer located in dedicated system memory bank and address is $8000.
Thus max file size, for streaming, is (32K / 2) * $7E00  = 528,482,304 bytes
(2 bytes per file block number)

You can stream multiple files by using several instances of StreamedFile.
(I'm not tested this so far)


todo
----



--------
by Valen