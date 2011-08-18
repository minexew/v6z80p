default.bin is an EEPROM image file. It can be written to
EEPROM location $0 (block 0) with the FLOS app "firmware.exe", IE:

FIRMWARE default.bin 0

Note: This is a fairly ham-fisted approach, and only normally used to
update the OS/Bootcode/FPGA config in one go from very old versions.
Most the time it is best to use the more elegant app "EEPROM.EXE"
which just updates the specific areas on the EEPROM. 



Contents:
---------

[SLOT 0]

$00800-$047FF - FLOS v587
$0F000-$0FFFF - Bootcode 6.14 (primary)
$1F000-$1FFFF - Bootcode 6.14 (backup)

[SLOT 1]

$20000-$3FFFF - OSCA 669 (PAL)

[SLOT 2]

$40000-$5FFFF - OSCA 668 (NTSC)






