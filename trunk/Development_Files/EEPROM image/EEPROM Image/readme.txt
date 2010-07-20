default.bin is an EEPROM image file. It can be written to
EEPROM location $0 (block 0) either with an external eeprom
burner or with the FLOS app "firmware.exe", IE:

FIRMWARE default.bin 0

Note: This is a pretty ham-fisted approach, most the time it is
best to use the more elegant app "EEPROM.EXE" which just updates
the specific areas on the EEPROM. 


Contents:
---------

[SLOT 0]

$00800-$047FF - FLOS 570F
$0F000-$0FFFF - Bootcode 6.12 (primary)
$1F000-$1FFFF - Bootcode 6.12 (backup)

[SLOT 1]

$20000-$3FFFF - OSCA 661 (PAL)

[SLOT 2]

$40000-$5FFFF - OSCA 661 (NTSC)






