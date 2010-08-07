
Spectrum 128 / 48 Emulator for V6Z80P by Phil Ruston 2009-2010
--------------------------------------------------------------

V0.10

--------------------------
Installing the FPGA config
--------------------------


1. Copy the folder "SPECTRUM" to the root of your FAT 16 SD card
   (same card used for FLOS etc) 

2. Put SD card in V6z80p and boot into FLOS.

3. Enter "CD SPECTRUM" and then "EEPROM" to load the eeprom tool.

4. Choose Option 1 "write config to slot".

5. When asked what slot, choose an an inactive Slot (EG: slot 3).

6. Choose "L" to load config file from disk.

7. Enter filename of the FPGA .bin file (the version ending in "p"
   is for PAL TVs and the version ending in "n" is for NTSC TVs.
   both versions support VGA 60Hz with 50Hz option)

8. Wait for file to write to EEPROM and complete verification.

9. Quit the EEPROM tool and restart (type G 0), on the boot
   screen tap F3 to  start the Spectrum 128 emulator.


-----------
Usage notes
-----------

* Browse snapshots with cursors and select a .sna file to load

* Press B to go to spectrum 128 basic

* Press shift + V to force VGA to 50Hz mode

* Press Shift and 1, 2 or 3 to restart the FPGA from another
  config slot

* In games, press f1-f12 to adjust the speed. Escape to return
  to menu.

* Only the first 44 files/folders in each directory are shown.


----
Tech
----

If you remove the bootcode.exe file, you can download one serially
when the error message flashes. This is useful for testing new
bootcode programs.


