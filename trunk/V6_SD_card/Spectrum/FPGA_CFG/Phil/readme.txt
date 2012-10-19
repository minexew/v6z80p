------------------------------------
Quick Start Guide for Phil's Simple
Spectrum 128 / 48 Emulator
------------------------------------

This emulator is limited to loading
.sna files and is not cycle-accurate.


To install:
-----------

1. Install the emulator FPGA config
   .bin file from the folder "FPGA_CFG"
   to the EEPROM using the FLOS command
   "EEPROM.EXE". Make sure you select
   the correct config file for your
   version of V6 board. (PAL and NTSC
   versions of each board's config
   file are supplied: filenames
   ending in "p" are for PAL and
   those ending in "n" are NTSC.
   Both support VGA.)


2. If you copied the contents of
   the main project's "SD_CARD"
   folder to the root of an SD card
   skip this step.

   You need a "SPECTRUM" folder in 
   the root of a FAT 16-formatted SD
   card. Put the following files in
   this dir:

    ZXSPEC48.ROM
    ZXSPE128.ROM
    BOOTCODE.EXE

   You should also add any snapshot
   files you want to run.


3. Start the emulator by either:

   Using FLOS command "boot n"
   command where n is the slot
   containing the emu config

   or

   During the V6 boot sequence,
   tap the function key
   corresponding to the slot used
   by the emulator (F1-F7 supported)


4. Within the emulator:

  Browse snapshots with cursors
  and select a .sna file to load

  Press B to go to spectrum 128
  basic

  Press shift + V to force VGA to
  50Hz mode

  Adjust speed with F1-F9 (only
  applicable to the V6 V1.1 and
  V6+ v1.0 boards).

  Kempston joystick is emulated
  via Joy port 1.

  Press ESC to go back to the
  file menu.

  Press Shift and 1, 2 or 3 to
  restart the FPGA from another
  config slot

----------------------------------

 Please read the full readme.txt
 in the main project archive for
 fuller info:

 Alternative_Configs\Phil\
 Spectrum_Emulator\

-----------------------------------
