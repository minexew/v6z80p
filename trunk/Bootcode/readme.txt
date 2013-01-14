
Bootcode
--------

The bootcode initializes the keyboard and loads an operating system file (*.OSF file)
from MMC/SD/SDHC card, EEPROM (location $00800+) or via serial download using the PC
Serial Link app.

Bootcode is 3518 bytes max of code/data (+ CRC word*). It is downloaded from the FPGA
config EEPROM (or serially if no bootcode exists) into RAM at $0200-$0FBF by the ROM
code in the FPGA, then executed (if the CRC word in the last two bytes matches the 
contents of the file). $0FC0-$0FFF is reserved for the stack. Address range $200-$7FF
is system RAM when the ROM passes control to  this routine.

 * Updating the bootcode CRC checksum: It is necessary to manually set this word after
   assemling the bootcode. Use the PC App: "Bootcode_CRC_maker.exe" in the apps
   subdirectory supplied (An incorrect CRC word results in the display flashing
   magenta on power up).


Updating the bootcode on the EEPROM
-----------------------------------

Use the FLOS tool EEPROM.EXE to update the bootcode on the EEPROM (which inserts
the data into page 0, address $f000 (and page 1, address $f000 as a back up).

Simply choose the "Update Bootcode" option. Send the file "bootcode.epr" Update
both the primary version of the bootcode first, reboot and if all OK then update 
the backup copy.

  If you have a really old versions of OSCA/FLOS, the latest version of "EEPROM.EXE"
  may not run. If this is the case you should use the command "FIRMWARE.EXE default.bin"
  to completely overwrite slots 0-2 with the a more recent bootcode and config data. (Obtain
  the "default.bin" file form the "development_files" subfolder relevant to your version
  of the V6Z80P. You can then update fully using EEPROM.EXE.



*************
* Revisions *
*************

Current version:
----------------

6.18 (2-1-2012)

* Uses standard keyboard init code from code library (required for OSCA v675 but compatible
  with previous versions). Will not hang on Keyboard init in any circumstances.



Previous versions:
------------------

6.17 (15-11-2012)

* Gives the option of not resetting the keyboard on boot if a file in the root dir
  called SYSTEM.CFG contains the line "RESETKB=0" 

* shows only 3 digits of OSCA version (for OSCA 674+)

* Passes bootcode version to OS in HL

* Boot device and available device codes changed (not previously used) and passed to OS
  in BC (A = 1 to signify valid, previously A=0)


6.16 (18-10-2012)

Minor mod to SD card driver for compatibility with the OSCA emulator (Not an issue
on real V6Z80P hardware).


6.15 (12-08-2012)

Added 100 uS delay after each databurst so that PIC is guaranteed enough time
to return to its "waiting for command" state. (Was previously sensitive
to crystal timing variations)

6.14 (18-08-2011)

Added SDHC support.
