
This version of the Configuration PIC code has the default Active Slot
set to Slot 1.

In no slot is bootable, the EEPROM will either need to be removed and
reprogrammed externally with the 512KB default EEPROM image (see
relevent folder) or the V6Z80P can be started in OSCA mode using a
JTAG download cable and software (EG: Xilinx Impact) and the .bit
version of the OSCA configuration file.


Revisions
---------

v618 - Added command to read PIC firmware version

v617 - Added commands to read back Active Slot and EEPROM ID byte.

v616 - In config firmware 610, The OSCA system was not starting up reliably
       when configured from the JTAG connector (bootcode databurst timing out).
       This seemed to be because the PIC was wasting time still flashing the
       status LED (as it does in JTAG mode) after FPGA DONE had gone HIGH. The
       Z80 CPU would therefore already have started and issued the databurst command
       but the PIC would've missed it (or caught some of it,  messing things up).
       (I would've thought subsequent databurst requests would have suceeded
       but in practice they VERY rarely did..) 

v615 - In 615, the PIC samples FPGA DONE whilst in the LED flash pause loop,
       and exits if it is high for a while. (Curiously, this resampling
       seemed necessary to stop the PIC exiting the "flash LED" loop the
       instant a JTAG file started to download. The FPGA's DONE line is not
       supposed to go high until the FPGA is fully configured, and from a test
       (albeit only via a multimeter) it appeared to stay low until then.
       Bit mad, that. Oh well, it works now that's all that matters..)

       Also, there is a now an emergency active slot reset mechanism:
       To access, power off. Install jumper J2 only and power on (yellow
       led flashes rapidly). Now remove the jumper J2, the PIC resets
       the active slot to 1 (indicated by 1 pulse of the red LED),
       the yellow led lights for 4 seconds, then Slot 2 is set (2
       flashes of red led), finally slot 3 is set (3 flashes). Power
       off only when the yellow LED is lit following the desired
       slot setting.

