Firmware.exe - now obsolete

A small app used to ("clumsily") write data from a file to the EEPROM with 64KB granularity.

*********************************************************
* In preference, please use EEPROM to update the V6Z80P *
* If you cannot use EEPROM, use UPDATE for a more user  *
* friendly version of this util.                        *
*********************************************************

Usage:

Firmware.exe file.bin (start block)

If the start block is not specified it'll start writing from EEPROM block 0.


Requirements:

Runs under any version of OSCA / FLOS.

