
V6Z80P EEPROM TOOL V1.15 - Phil Ruston www.retroleum.co.uk 2008-10
------------------------------------------------------------------

*******************************************************************
*                                                                 *
*                         CAUTION!                                *
*                                                                 *
* Incorrect use of this app can prevent the V6Z80P from starting  * 
*                                                                 *
*  Worse, reconfiguring the FPGA with a third party design that   *
*  has incorrect signal assigments, contention (clashing outputs  *
*  etc) could possibly damage the components on the PCB.          *
*                                                                 *
*******************************************************************


The EEPROM TOOL program treats the SPI EEPROM memory as 64KB blocks
and/or 128KB "slots" (each slot consists of two blocks).


        .---------------. <-$00000
      / !    BLOCK 0    !
SLOT 0  !---------------! <-$10000
      \ !    BLOCK 1    !
        !---------------! <-$20000
      / !    BLOCK 2    !
SLOT 1  !---------------! <-$30000
      \ !    BLOCK 3    !
        !---------------! <-$40000
      / !    BLOCK 4    !
SLOT 2  !---------------! <-$50000
      \ !    BLOCK 5    !
        !---------------! <-$60000
      / !    BLOCK 6    !
SLOT 3  !---------------! <-$70000
      \ !    BLOCK 7    !
        !---------------!
        ! etc etc etc   !


Slot 0 is reserved for the OS / bootcode / user data. The other slots can
each take a spartan II XS2S150 FPGA config .bin file (or user data).


EEPROM TOOL Menu Options
-------------------------

1: Reprogram a slot.
--------------------

Simply follow the prompts to upload an FPGA config .bin file (as produced by
the Xilinx Webpack software) These files are 130012 bytes in length and can
be be downloaded with the serial link app from the PC or loaded from disk.
Writing to the currently Active Slot is not recommended. Flashing should
take less than 1 minute. Note: The ENTIRE 128KB slot is erased prior to
flashing and the filename is tagged onto the end of the config file when
written to the EEPROM.


2: Reconfigure the FPGA now.
----------------------------

Temporarily (until power off) changes the slot pointer and reprograms
(restarts) the FPGA.


3: Change active slot.
----------------------

The active slot is that which the FPGA configures from on power up. The value
is held in the config PIC's flash memory and this option updates that value.

When writing a slot with option [1] it is recommended that an inactive
slot is chosen, the config can then be tested with option [2] "Configure
FPGA now". If all is OK, the change can be made "permanent" later with Option [3]. 

Remember, if the Active Slot pointer is changed to point to a config which
provides no means of changing the slot back this may be a problem. See
"Emergency recovery" instructions at the end of this document.


4: Install OS to EEPROM
-----------------------

Writes a file to $00800 (to $EFFF max) in the EEPROM.


5: Uninstall OS from EEPROM
---------------------------

Deletes the signature of an OS file in EEPROM (writes $FF to $00800-$008FF)


6: Update the bootcode
----------------------

Writes a file to either $0F000 (primary bootcode in Block 0) or $1F000
(backup bootcode in Block 1) The bootcode should be 3520 bytes max.
BE VERY CAREFUL updating the bootcode! An incorrect file will prevent
OSCA from starting up.


7: Insert arbitary data into block
----------------------------------

This is used to store small files in blocks that are not being used for FPGA
config data. The new file must fit within the 64KB block. When you insert a file,
the existing data from the block is first read into a buffer, the new file
overwrites the locations in the buffer that it occupies, the block in the EEPROM
is erased and finally the entire block rewritten. This way, seperate files can
coexist in any one block. Programming a block should take less than 30 seconds.

===============================================================================


Emergency Recovery: If the Active Slot points to an invalid / undesired config.
-------------------------------------------------------------------------------

Option 1: 

  With the latest PIC firmware, it is possible to change the Active Slot
  manually. 

      * Power off.
      * Install jumper J2 only
      * Power on (yellow led flashes rapidly - JTAG mode). 
      * Remove jumper J2 again
      * The PIC will reset the active slot to 1 (indicated by 1 pulse of the red LED)
        The yellow led lights up for 4 seconds
        Afterwards, Slot 2 is set (2 flashes of red LED)
        Again there's a 4 second pause, finally slot 3 is set (3 flashes).
      * Power off as soon as the yellow LED comes on following the desired slot setting.
      * When you next power on, the active slot will point to slot 1, 2 or 3.
 
    (Of course, for the above to be useful you must actually have a working (OSCA)
    configuration file in slot 1-3).

  If the method described above doesn't work (due to old PIC firmware) then the PIC must
  be removed and reprogrammed with the appropriate .hex file (this resets the Active Slot
  to point to Slot 1).


Option 2:

   Remove the EEPROM  and reprogram it externally. If you reprogram the EEPROM  use the
   "default.bin" image file from the "development files/eeprom" folder as this holds the
   bootcode as well as configs for SLOT1 and SLOT2.  


Option 3:
   
    Use a JTAG cable, install J1 and J2 and upload an OSCA .bit file from the Xilinx webpack
    software. Assuming the bootcode on the EEPROM is OK, you can then download FLOS and use
    the EEPROM.EXE program.


===============================================================================


Update History:
---------------


v1.15 - "EEPROM Busy" timeout in EEPROM routine increased to 5 seconds.
      - If write / verify fails writing data to EEPROM blocks, the option is
        given to retry the write.

v1.14 - Added file requesters.

v1.13 - Reports Config PIC firmware (if 618+)

v1.12 - If PIC firmware is v617+, the EEPROM type and the current
        Active Slot will be reported.

v1.11 - Filenames are tagged onto FPGA config files. Once tagged
        configs have been written they will be identified by the
        EEPROM tool later.
      - FPGA config writes to slot 0 are now prohibited.
 
v1.10 - Can install/uninstall OS to EEPROM.
      - Bootcode update option added.
      - Protection for critical areas added.

v1.03 - Can load files from disk
