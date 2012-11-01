
--------------------------------------
Quick start guide for Alessandro's
Cycle Perfect Spectrums Emulators:
--------------------------------------


THESE EMULATORS ARE FOR V6Z80P+ v1.1 ONLY


1. Install the config .bin files from:
   
  FPGA_CFG\Alessand\V6plusv1.1\Spec_V2

  into 2 free slots the EEPROM using
  the FLOS command "EEPROM"


2. If you copied the contents of the
   main project's "SD_CARD" folder to
   the root of an SD card, skip this
   step.

   You need a folder called "Spectrum"
   in ROOT dir of a FAT16-formatted SD
   Card. In this folder you need:
 
  Essentials:
 
    zxspec48.rom
    zxspec128.rom

  Optional: if want to use Residos:

     resi48.nvr
     resi128.nvr
     residos.tap

  Optional: if you want to use esxdos:

     esxdos.nvr
  
   If you want to use esxDOS, you also
   need the following folders in the
   ROOT dir of the SD card:
 
    sys
    bin
   
   Which contain code and data for
   esxdos.

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

   EMU selects Residos or esxDOS
   depending on the state of a PCB
   jumper. When EXP_B is installed
   esxDOS mode is selected.


4. Emulator keys:

   F1 - standard 3.5MHz mode
   F2 - 7 MHz Turbo mode
   ESC - Reset
   SCROLL - NMI
   TAB - Start tape
   F11 - Scanline mode (VGA only)
   
   Kempston Joystick in Port 0


5. Residos info: You can navigate/
   load via the commands:

   %cd "dir"
   %snapload "filname.sna"

   %dir

   %tapein "filename.tap"
   LOAD ""


   esxDOS info: The easiest way to
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
