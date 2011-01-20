
Spectrum 128 / 48 Emulator for V6Z80P+ by Phil Ruston 2009-2011
--------------------------------------------------------------

v 1011 - 3.5MHz clock for more accurate Spectrum timing,

This version requires a V6Z80P+ V1.1 which has the 14MHz crystal
option onboard.

--------------------------
Installing the FPGA config
--------------------------


1. Copy the folder "SPECTRUM" to the root of your FAT 16 SD card
   (same card used for FLOS etc) 

2. Put SD card in V6z80p and boot into FLOS.

3. Enter "CD SPECTRUM" and then "EEPROM" to load the eeprom tool.

4. Choose Option 1 "write config to slot".

5. When asked what slot, choose an an inactive Slot

6. Choose "L" to load config file from disk.

7. Enter filename "SpecEmuP.bin" (for PAL) or "SpecEmuN.bin" (for NTSC)
   both versions support VGA 60Hz with 50Hz option

8. Wait for file to write to EEPROM and complete verification.

9. You can start the emulator from the EEPROM tool by choosing
   option 2, or use the boot.exe command from FLOS, or during
   boot by tapping the function key corresponding to the slot 
   it was installed in.


-----------
Usage notes
-----------

In the menu:

* Browse snapshots with cursors and select a .sna file to load

* Press B to go to spectrum 128 basic

* Press shift + V to force VGA to 50Hz mode

* Press Shift and 1, 2 or 3 to restart the FPGA from another
  config slot

* Only the first 44 files/folders in each directory are shown.


During Spectrum programs:

* Press ESC to go back to the boot menu.

* Kempston joystick is emulated (Joy port 1).

----
Tech
----

If you remove the bootcode.exe file, you can download one serially
when the error message flashes. This is useful for testing new
bootcode programs. (Untested on v1011)


