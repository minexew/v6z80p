
There are two main Spectrum Emulators
for the V6Z80P:


1. Phil's Spectrum 48/128 "approximating"
   (IE: non-cycle-perfect) emulator for
   all models of the V6Z80P board. Please
   install the correct config file for your
   version of the V6Z80P (using eeprom.exe)
   from the FPGA_CFG\PHIL folder. 

   I.O. on this emulator is limited to the
   loading of .sna files such as those
   provided in the "software/48snaps" and
   "software/128snaps" folders. 
  
   Once installed in the EEPROM. you can
   launch this emulator with the FLOS
   command "BOOT [n]" (where [n] is
   the slot number where the config file
   was installed)

   For more info see the sub folder:

   FPGA_CFG\Phil\



2. Alessandro's cycle-perfect Spectrum 48/128
   emulators for the V6Z80P+ v1.1 only (as
   they require clocking features only
   available on this board). Please install
   (with the FLOS util "EEPROM") from the
   folder:

   FPGA_CFG\Alessand\V6plusv1.1\Spec_V2

   These emulators offer powerful features
   such as support for ResiDOS and esxDOS,
   ULA+ and Timex graphics modes etc. They
   can even load Spectrum software from tape.

   Once installed on the EEPROM these
   emulators are launched with the FLOS
   command "EMU"

   For more info see the sub folder:

   FPGA_CFG\Alessand\V6plusv1.1\Spec_V2\


