
Spectrum 128 / 48 Emulator for V6Z80P by Phil Ruston 2009-2011
--------------------------------------------------------------

This is an "approximate" ZX Spectrum emulator config - it makes
no attempt to be cycle-perfect, but there are speed adjust keys
for the versions of the V6Z80Ps which do not have a 14MHz oscillator
from which to derive a 3.5MHz CPU clock. It is also limited to
loading only .sna image files.

-------
Changes
-------

v x013 - Changed ROM code to better activate Spectrum 48 Snapshots
       - Modified "Read from $0067 = Real Spectrum" logic.
       - Added version ID to all configs
       - Bootcode standard across all versions.
       - Keyboard now initializes correctly.

---------------------------
How to install the emulator
---------------------------

1. Copy the folder "SPECTRUM" to the root of your FAT 16 SD card
   (can be same card used for FLOS etc) (Add more Snapshots to the
   "48snaps" and "128snaps" folders as desired).

2. Install the FPGA config .bin file from the folder "FPGA_CFG"
   to the EEPROM using FLOS command "EEPROM.EXE" (Make sure you select
   the correct file for your version of V6 board) PAL and NTSC versions of
   each board's config file are supplied: filenames ending in "p" are
   for PAL and those ending in "n" are NTSC. Both support VGA.

3. Start the emulator by:

   a) Choosing option 2 in the EEPROM tool
   b) Using FLOS command "boot n" command where n is the slot with the emu config
   c) (During boot) tapping the function key corresponding to the emu slot (F1-F7 supported)


-----------
Usage notes
-----------

In the menu:

* Browse snapshots with cursors and select a .sna file to load

* Press B to go to spectrum 128 basic

* Press shift + V to force VGA to 50Hz mode

* Press Shift and 1, 2 or 3 to restart the FPGA from another
  config slot

* The versions for the original V6 and V6+ v1.0 boards can only approximate the
  speed of a real Spectrum, press keys F1-F9 to adjust.

* Kempston joystick is emulated (Joy port 1).

* Press ESC to go back to the boot menu.


Known issues:
-------------

* Only the first 44 files/folders in each directory are shown.

* The odd snapshot does not start correctly (EG: Cauldron 2)


----
Tech
----

If you remove the bootcode.exe file, you can download one serially
when the error message flashes. This is useful for testing new
bootcode programs. (Serial comms currenty Untested on v1013)


