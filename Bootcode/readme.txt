
Bootcode
--------

The bootcode initializes the keyboard and loads an operating system file (*.OSF file)
from MMC/SD/SDHC card, EEPROM (location $00800+) or via serial download using the PC
Serial Link app.

Bootcode is 3518 bytes max of code/data (+ CRC word*). It is downloaded from the FPGA
config EEPROM (or serially if no bootcode exists) into RAM at $0200-$0FBF by the ROM
code in the FPGA then executed (if the CRC word in the last two bytes matches the 
contents of the file). $0FC0-$0FFF is reserved for the stack. Address range $200-$7FF
is system RAM when the ROM passes control to  this routine.

 * Updating the bootcode CRC checksum: It is necessary to manually set this word after
   assemling the bootcode. Use the PC App: "New_Bootcode_CRC.exe" in the apps
   subdirectory supplied (An incorrect CRC word results in the display flashing
   magenta on power up).


Updating the bootcode on the EEPROM
-----------------------------------

Use the FLOS tool EEPROM.EXE to update the bootcode on the EEPROM (which inserts
the data into page 0, address $f000 (and page 1, address $f000 as a back up).

Simply choose the "Update Bootcode" option. Send the file "bootcode.epr" Update
both the primary version of the bootcode first, reboot and if all OK then update 
he backup copy.

  If you have a really old versions of OSCA/FLOS, the latest version of "EEPROM.EXE"
  may not run. If this is the case you should use the command "FIRMWARE.EXE default.bin"
  to completely overwrite slots 0-2 with the a more recent bootcode and config data. (Obtain
  the "default.bin" file form the "development_files" subfolder relevant to your version
  of the V6Z80P. You can then update fully using EEPROM.EXE.


*************
* Revisions *
*************

6.16 (18-10-2012)

Minor mod to SD card driver for compatibility with the OSCA emulator (Not an issue
on real V6Z80P hardware).


6.15 (12-08-2012)

Added 100 uS delay after each databurst so that PIC is guaranteed enough time
to return to its "waiting for command" state. (Was previously sensitive
to crystal timing variations)

6.14 (18-08-2011)

Added SDHC support.

6.13 (31-07-2010)

Bug fix: Restored missing "jr nz" after find file which was causing loader
to try loading from card even when no .osf was present.

6.12 (20-07-2010) 

This update became necessary due to changes in ROM 6.14 (as used in OSCA
v661 onwards)

Bootcode is no longer dependant on routines in ROM (no longer uses RST
instructions)

Initializes system registers and ports, sets up and clears screen
(previously done by ROM)

Can now press F1-F7 to select configs (only F1-F3 previously)

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


