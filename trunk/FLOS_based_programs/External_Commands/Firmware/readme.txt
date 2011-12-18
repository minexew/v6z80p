Firmware.exe

A small app used to ("clumsily") write data from a file to the EEPROM with 64KB granularity.

Usage:

Firmware.exe file.bin (start block)

If the start block is not specified it'll start writing from EEPROM block 0.

If possible, use EEPROM.EXE in preference as its safer and more elegant.


Requirements:

Runs under any version of OSCA / FLOS.

