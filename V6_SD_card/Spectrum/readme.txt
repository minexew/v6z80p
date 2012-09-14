
There are two main Spectrum Emulators for the V6Z80P:


1. Phil's Spectrum 48/128 "approximating" (IE: non-cycle-perfect) emulator for all
   models of the V6Z80P board. Please install the correct config file for your
   version of the V6Z80P (using eeprom.exe) from the FPGA_CFG/PHIL folder. 

   I.O. on this emulator is limited to the loading of .sna files such as those
   provided in the "software/48snaps" and "software/128snaps" folders. 
  
   This emulator requires the files "BOOTCODE.BIN", "ZXSPEC48.ROM" and "ZXSPE128.ROM"
   in the [ROOT]:Spectrum directory of the SD Card.

   You can launch this emulator with the FLOS command "BOOT [n]" (where [n] is the
   slot number where the config file was installed)

   For full documentation see the V6Z80P project folder:

   "Alternative_Configs/Phil/Spectrum_Emulator"





2. Alessandro's cycle-perfect Spectrum 48 / 128 emulator for the V6Z80P+ v1.1 only (it
   requires clocking features only available on this board). Install the
   latest version of the config files free slots with eeprom.exe and launch
   the emulator with the FLOS command EMU.EXE

   This emulator can load .tap files (with the normal Spectrum LOAD instruction)
   and also includes the ZXMMC+ expansion system, allowing programs like Residos
   to be installed (which can load and save files to the SD card etc).
   
   Additionally, the emulator is able to start from a previously saved RESIDOS.NVR file,
   which removes the need to manually install Residos each time. Use the relevent option
   of EMU.EXE to load a RESIDOS.NVR file - it should be in the [ROOT]:Spectrum directory
   of your SD Card).

   The emulator also requires the files "ZXSPEC48.ROM" and "ZXPSE128.ROM" in the
   "[ROOT]:Spectrum" directory of the SD CARD (this is loaded by the EMU.EXE command.)
        
   For full documentation see the V6Z80P project folder:

   "Alternative_Configs/Alessandro/Cycle_Exact_Spectrum_Emulator"


