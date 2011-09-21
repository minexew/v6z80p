
There are now two main Spectrum Emulators for the V6Z80P:

1. Phil's Spectrum 48/128 "approximating" (IE: non-cycle-perfect) emulator for all
   models of the V6Z80P board. Please install the correct config file for your
   version of the V6Z80P (with eeprom.exe) from the FPGA_CFG/PHIL folder. 
   I.O. on this emulator is limited to the loading of .sna files. You can launch
   this emulator with the FLOS command "BOOT [slot]"


2. Alessandro's cycle-perfect Spectrum 48 emulator for the V6Z80P v1.1 only (it
   requires clocking features only available on this board). Please install the
   latest version to a free slot with eeprom.exe and the launch with the FLOS
   command GOSPEC.EXE. This emulator will load .tap files (with the normal
   spectrum LOAD instruction) and also includes the ZXMMC+ expansion system,
   allowing EG: Residos which can load and save files to the SD card.


