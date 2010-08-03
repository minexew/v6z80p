Updating bootcode on the EEPROM
-------------------------------

If your OSCA/FLOS system is relatively up to date, simply load the latest
version of EEPROM.EXE and choose the "Update Bootcode" option. Send the
file "bcodexxx.epr" (where xxx is the release number). Update both the
primary and backup versions of the bootcode.


If you have old versions of OSCA/FLOS, the latest version of the program
"EEPROM.EXE" may not work. If this the case you can either use the command
"FIRMWARE.EXE" to completely overwrite slots 0-2 with the latest bootcode
and config data, or use the original version of EEPROM.EXE supplied the "old"
subdirectory of this folder.


**********************
* Bootcode Revisions *
**********************


6.13 (31-07-2010)

Bug fix: Restored missing "jr nz" after find file which was causing loader
to try loading from card even when no .osf was present.


6.12 (20-07-2010) 

This version of the bootcode is ESSENTIAL for OSCA 661 onwards. (Previous
(recent) versions of OSCA will still work with bootcode 6.12)

This update became necessary due to changes in ROM 6.14 (as used in OSCA
v661 onwards) 

Bootcode is no longer dependant on routines in ROM (no longer uses RST
instructions)

Initializes system registers and ports, sets up and clears screen
(previously done by ROM)

User can now press F1-F7 to select configs (only F1-F3 previously)

Removed PQFS support code





V6.11 (27-08-2009)

The OS is now loaded from disk as a normal file, not directly from
reserved sectors. This has removed the need for the INSTALL.EXE
application. Both FAT16 and PQFS formats are supported. The bootcode
loads the first file called "*.OSF" (* being anything) from the
root directory. The OS now needs the 16 byte Z80P*OS* header
attached - this is also required for serially downloaded code
(although the contents are ignored in this case).

The bootcode font is copied to Video RAM.


V6.03:

On boot, pressing F1, F2 or F3 reconfigures the FPGA to slot 1, 2 or 3.
(Not permanent - Reverts back to default slot next power cycle).

Serial port speed no longer set automatically (FPGA sets it 115200
by default in OSCA 619+). An option is provided to manually set
BAUD on boot with Function keys F11 (slow) and F12 (fast)


