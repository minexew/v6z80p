
V6Z80P EEPROM TOOL V1.17 - Phil Ruston www.retroleum.co.uk 2008-10
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


8. Erase slot
-------------

Used to erase one of the 128KB eeprom slots. This option will give a warning
if slot 0 or the currently active slot is selected for erasure, but will allow
it.


===============================================================================
Emergency Recovery: If the Active Slot points to an invalid / undesired config.
===============================================================================

*** For the original V6Z80P Board ***
--------------------------------------

OPTION 1: With Config PIC firmware v616+ the Active Slot can be changed manually.
Assuming there is a working config in Slot 1, 2 or 3 and the problem is just that
the Active Slot selection is pointing at a bad config:

•Power off.

•Install jumper J2 only

•Power on (yellow led flashes rapidly - JTAG mode).

•Remove jumper J2 again

•The PIC will reset the active slot to 1 (indicated by 1 pulse of the red LED)
 The yellow led lights up for 4 seconds then Slot 2 is set (2 flashes of red LED),
 again there's a 4 second pause, finally slot 3 is set (3 flashes).

•Power off only when the yellow LED is lit following the desired slot setting.

•When you power on the active slot will correctly point to slot 1, 2 or 3.

OPTION 2: Remove and reprogram the EEPROM or config PIC externally. (Note: It is the PIC
chip that actually holds the slot selection - you will only need to reprogram the PIC if
you have old firmware that doesn't support the manual slot selection. If you do reprogram
the PIC, use the latest firmware .hex file so that you wont have to do so again.) If you
reprogram the EEPROM, use "default.bin" from the folder development_files/eeprom image as
this also contains the bootcode for SLOT 0.

OPTION 3: JTAG config. If none of the first 3 slots contain OSCA:

•Power off and connect a Xilinx JTAG cable to the V6Z80P.

•Install jumpers J1 and J2.

•Load the most recent OSCA project into Xilinx webpack ISE and send the OSCA config .bit
 file from the PC to the V6Z80P via JTAG.

•If the bootcode is intact in the EEPROM, the system will start as normal allowing you to load
 EEPROM.EXE via FLOS. If the bootcode checksum fails the screen will flash magenta, then grey.
 See "bootcode problems" below.

•Remove jumpers J1 and J2 next time you power off so that the system automatically configures
 from the EEPROM.



Recovery Instructions for the V6Z80P+ Board
-------------------------------------------

OPTION 1: Assuming there is a working config in Slot 1 - 7 and the problem is just that
the Active Slot selection is pointing at a bad config:


•Power off.

•Install jumper J2 only

•Power on (yellow led flashes rapidly).

•Remove jumper J2 again

•The yellow LED will flash once, pause about 5 seconds, then flash twice, pause 5 seconds,
 then flash three times and so on - the number of flashes represents the slot selection.
 During the pause following the slot selection you require, replace the jumper - the LED
 will then stay on permanently signifying that the slot has been set.

•Power off and remove Jumper J2.



OPTION 2: JTAG configuration. (If none of the first seven slots contain OSCA)

•Power off and connect a Xilinx JTAG cable to the V6Z80P.

•Install jumpers J1 and J2.

•Load the most recent OSCA project into Xilinx webpack ISE and send the OSCA config .bit
 file from the PC to the V6Z80P via JTAG.

•If the bootcode is intact in the EEPROM, the system will start as normal allowing you to
 load EEPROM.EXE via FLOS. If the bootcode checksum fails the screen will flash magenta,
 then grey. See "bootcode problems" below.

•Remove jumpers J1 and J2 next time you power off so that the system automatically
 configures from the EEPROM.



============================================================================================
Bootcode Problems:
============================================================================================

If the OSCA ROM cannot load a valid bootcode file from the EEPROM, the display
will flash magenta (bad CRC) or green (time out). If OSCA version 661 or above
is installed it is possible to send the bootcode file manually via the serial
link when the display turns grey.

It is possible to force serial transfer of the bootcode on power up by holding
UP+RIGHT+FIRE on a joystick in port A. (Note: The transfer must be at 115200 BAUD).
(Again, OSCA 661 or above must be installed).

==========================================================================================


Update History:
---------------

v1.17 - Fixed Success text after using "change slot" option.

v1.16 - Added "Erase Slot" option
        Added progress indication (replaced animated dots)
        Added confirmation to "Remove OS" option
        Fixed bug where invalid block figures were shown if > block 9

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
