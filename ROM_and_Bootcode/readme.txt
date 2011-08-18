
Bootcode - IMPORTANT: 
---------------------

After assembling the bootcode, remember to insert the correct CRC word
to the end of the file before writing it to the EEPROM. Use the PC-based util
"New_Bootcode_CRC.exe" in the apps subdirectory for this. (An incorrect
CRC word results in the display flashing magenta on power up).

The bootcode should be written to the EEPROM using the FLOS-based EEPROM.EXE
app, inserting the data into page 0, address $f000 (and page 1, address $f000
as a back up).


*************
* Revisions *
*************

Bootcode
--------

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




ROM code
--------

v6.16 (26/03/2011):

Sets audio panning register to original 0/2=left, 1/3=right format.


v6.15 (25/10/2010):

Clears new port "sys_vram_location", ensuring VRAM is placed at $2000 on reset.

v6.14 (20-07-2010):

This version became necessary mainly due to the V6Z80P+ having the
option of a soldered-on SMT EEPROM. As it would be difficult to program
the EEPROM prior to soldering, a means of writing the bootcode in situ
(without it already being available) was required. I decided the best
way was for the ROM code to allow serial download of the bootcode if
the EEPROM bootcode CRC checks failed. This way FLOS can boot allowing
access to the usual EEPROM.EXE tool for installing bootcode to the EEPROM.
This version of ROM code is used in OSCA 661 onwards.

ROM code no longer initializes all ports and registers, only blanks screen
and clears ports necessary for start up.

If the EEPROM bootcode is not available, the screen turns grey meaning
bootcode can then be sent via the serial link (115200 baud only). This
serial download can be forced (skipping the EEPROM bootcode checks) by
pressing Fire and holding UP+RIGHT on a joystick in port A on system
start up.

v6.12:

Port $20 is cleared on start-up so PAGE 0 of system RAM is located
at Z80 $0000-$7FFF

V6.11:

The ROM now loads the Bootcode to $200 - $FBF (using the "page out video
registers" bit in OSCA V652). It is read from EEPROM location $0f000
(and then $1f000 if that fails).

Various other changes connected to bootcode 6.11 (font location etc).

V6.05:

All video Registers $200-$27f (except $217 - blitwidth) are now cleared
on boot. This means the new modulo register (OSCA V645) is reset to zero.

V6.04:

$800 byte databurst requested for bootcode (for some reason I had
it set at $2000)

If databurst fails, the PIC comm clock is pulled low before the
1 second screen flash, ready for the next attempt (gives PIC
chance to resync at command wait)
