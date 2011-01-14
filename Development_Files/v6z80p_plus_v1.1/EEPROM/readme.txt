
"default.bin" is an EEPROM image file. It can be written to the 
onboard EEPROM (location $0) with the FLOS app "firmware.exe", EG:

FIRMWARE default.bin 0

Note: This method of writing to the EEPROM is normally only used when 
first setting up a new PCB. Afterwards it is best to use the more elegant
app "EEPROM.EXE" which updates just specific locations of the EEPROM. 


Contents of "default.bin"
-------------------------

[SLOT 0]

$00800-$047FF - FLOS v582
$0F000-$0FFFF - Bootcode 6.13 (primary)
$1F000-$1FFFF - Bootcode 6.13 (backup)

[SLOT 1]

$20000-$3FFFF - OSCA v667 PAL for V6Z80P+V1.1 (PAL)






