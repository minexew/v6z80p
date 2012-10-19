
The ROM code is included in the actual FPGA configuration file as a 512 byte BLOCK RAM located
at address $0. (Convert the binary file to text using the app provided and paste into the
OSCA development .ucf file in the appropriate location). 

The ROM initializes the hardware and downloads the boot code from the onboard EEPROM.
The bootcode is loaded to $200. 3520 bytes are requested from EEPROM location $0f000,
if that fails (timeout or CRC check), bootcode backup location $1f000 is tried. If both
locations fail the bootcode can be loaded serially (115200 baud). Serial load is forced
immediately if UP+RIGHT+FIRE are selected by joystick in port A. 

ROM code Revisions:
-------------------


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
