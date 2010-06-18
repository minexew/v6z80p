
V6Z80P EEPROM TOOL V1.14 - Phil Ruston www.retroleum.co.uk 2008-10
------------------------------------------------------------------

*******************************************************************
*                                                                 *
*                         CAUTION!                                *
*                                                                 *
* Incorrect use of this app can prevent the V6Z80P from starting  * 
*                                                                 *
*  Worse, reconfiguring the FPGA with a third party design that   *
*  has incorrect signal assigments, contention (clashing outputs  *
*  etc) could easily damage the components on the PCB!            *
*                                                                 *
*******************************************************************


The EEPROM TOOL program treats the SPI EEPROM memory as four 128KB
"slots" (each of which consists of two 64KB blocks). Slot 0 is
reserved for the OS / bootcode / userdata. Slots 1-3 can each take
a spartan II XS2S150 FPGA config .bin file (or arbitary data).


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
         ---------------

Slot 0 (Blocks 0 and 1) stores bootcode, OS and user code, slots
1-3 can each store an FPGA configuration file.


Option 1: Reprogram a slot.
---------------------------
Simply follow the prompts to upload the FPGA config .bin
file produced by the Xilinx Webpack software to the EEPROM.
These files are 130012 bytes in length and can be be downloaded
with the V6Z80P link app from the PC or loaded from disk.
Flashing a slot should take less than 1 minute. Note: The
ENTIRE 128KB slot is erased prior to flashing and the filename
is tagged onto the end of the config file when written to the EEPROM.


Option 2: Reconfigure the FPGA now.
-----------------------------------

Temporarily (until power off) changes the slot pointer and reprograms
(restarts) the FPGA.


Option 3: Change active slot.
-----------------------------

The active slot which the FPGA configures from on power on is held in the
config PIC's flash memory, this can be changed with the EEPROM tool.

It is recommended that a spare slot is written with the config file first,
this can then be tested with the "Configure FPGA now" option [2],
which changes the active slot only until the power is cycled. If all
is OK, the change can be made permanent later with Option [3]. Obviously,
if the new configuration is not OSCA compatible, you cannot then use this
EEPROM tool to make any more changes in which case you'll have to use
one of the manual slot reset methods:

 a. With the latest PIC firmware, it is possible to change the Active Slot
    manually if the system does not start - of course, for this to be useful
    you must actually have a working OSCA configurarion in one of the slots.

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
   
 b. Remove and reprogram the EEPROM or config PIC chips externally. (Note: The
    PIC holds the slot selection.) If you reprogram the EEPROM, you'll
    need to preserve $0-$1FFFF as this holds the bootcode (it can hold
    the OS too but that is easily replaced). It is probably best to erase
    the entire EEPROM and reprogram it with the default 512KB binary image
    supplied in the development folder. 
   
 c. Use the JTAG cable, install J1 and J2 and send OSCA from the Xilinx webpack
    software. Assuming the bootcode on the EEPROM is OK, you can then download
    FLOS and use the EEPROM.EXE program.


Option 4: Install OS to EEPROM
------------------------------

Writes a file to $00800 (to $EFFF max) in the EEPROM.


Option 5: Uninstall OS from EEPROM
-----------------------------------

Deletes the signature of an OS file in EEPROM (writes $FF to $00800-$008FF)


OPtion 6: Update the bootcode
-----------------------------

Writes a file to either $0F000 (primary bootcode in Block 0) or $1F000
(backup bootcode in Block 1) The bootcode should be 3520 bytes max.
BE VERY CAREFUL updating the bootcode! An incorrect file will prevent
OSCA from starting up.


Option 7: Insert arbitary data into block
-----------------------------------------

This is used to store small files in blocks that are not being
used for FPGA config data. The new file must fit within the 64KB
block. When you insert a file, the existing data from the
block is first read into a buffer, the new file overwrites the
locations in the buffer that it occupies, the block in the EEPROM
is erased and finally the entire block rewritten. This way, seperate
files can coexist in any one block. Programming a block should
take less than 30 seconds.

===============================================================================

Notes:

If a larger capacity 25x series EEPROM is installed and the config PIC firmware
is v617 or above (24-11-2009) the additional space will be detected and become
available.

===============================================================================


Update History:
---------------

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

v1.02 - Compatible with V5.1 modifications

