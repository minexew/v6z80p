
There are two main Spectrum Emulators
for the V6Z80P:


1.Phil's Spectrum 48/128 "approximate"
  (IE: non-cycle-perfect) emulator for
  all models of the V6Z80P board.
  Please install the correct config
  file for your version of the V6Z80P 
  (using eeprom.exe) from the folder:
  
   FPGA_CFG\PHIL 

  I.O. on this emulator is limited to
  the loading of .sna files such as
  those provided in the folders 
  
  SOFTWARE/48SNAPS
  SOFTWARE/128SNAPS
  
  Once installed in the EEPROM. you
  can launch this emulator with the
  FLOS command "BOOT [n]" (where [n]
  is the slot number where the config
  file was installed)

  For more info see the sub folder:

  FPGA_CFG\Phil\



2.Alessandro's cycle-perfect Spectrum
  48/128 emulators for V6Z80P+ v1.1 only
  (as  they require clocking features
  only available on this board). Please
  install the config .bin files (using
  the FLOS util "EEPROM") from:

  FPGA_CFG\Alessand\V6plusv1.1\Spec_V2

  and:
  
  FPGA_CFG\Alessand\v6plus1.1\Pentagon

  These emulators offer powerful
  features such as support for esxDOS,
  ULA+ and Timex graphics modes etc.
  They can even load Spectrum software
  from tape.

  Once installed on the EEPROM these
  emulators are launched with the FLOS
  command "EMU"

  More info is in the config subfolders

