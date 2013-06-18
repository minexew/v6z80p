
--------------------------------------
Quick start guide for Alessandro's
Cycle Perfect Spectrums Emulators:
--------------------------------------

NOTES:
------

THiS EMULATOR IS FOR V6Z80P+ v1.1(b) ONLY

ResiDOS support has been removed from
version 2.3.0 onwards. esxDOS is now
the preferred alternative Spectrum OS.



1. Install the config .v6c files from:
   
  FPGA_CFG\Alessand\V6plusv1.1\Pentagon

  into a free slot the EEPROM using
  the FLOS command "EEPROM"


2. If you copied the contents of the
   main project's "SD_CARD" folder to
   the root of an SD card, skip this
   step.

   You need a folder called "Spectrum"
   in ROOT dir of a FAT16-formatted SD
   Card. In this folder you need these
   files:
 
    zxspec48.rom
    zxspec128.rom

   Optional: if you want to use esxdos:

    esxdos.nvr
  
    Plus these folders (and the files
    therein)
 
    SYS
    BIN


-------------------------------------
If not present, all of these files
can be found in the main project
archive in:

 Alternative_Configs\Alessandro\
 Cycle_Exact_Spectrum Emulator\
 V6Z80+ V1.1\
-------------------------------------    


3. Start the emulator in FLOS with the
   command "EMU". Chose an option from
   the menu. Upon first run you will
   be asked which slots contain the
   emulators (a list will be shown).
   Respond as appropriate.

   The jumper on "EXP_B" should be
   installed if esxDOS is required
   otherwise EMU will only show
   the most basic boot options.


4. Emulator keys:

   F1 - standard 3.5MHz mode
   F2 - 7 MHz Turbo mode
   ESC - Reset
   SCROLL - NMI
   TAB - Start tape
   F11 - Scanline mode (VGA only)
   
   Kempston Joystick in Port 0


5. esxDOS info: The easiest way to
   load software is by activating
   the NMI browser (press SCROLL)
   or you can navigate/load with:

   .cd dir

   .ls

   .snapload filename

   .tapein filename

   LOAD ""

 
------------------------------------

 Please see the full readme files
 in the main project archive for
 full details:

 Alternative_Configs\Alessandro\
 Cycle_Exact_Spectrum Emulator\
 V6Z80+ V1.1\

------------------------------------
