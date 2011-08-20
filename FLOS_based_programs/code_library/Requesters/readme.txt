FLOS Load and Save Requesters for user programs - By Phil Ruston 2010
---------------------------------------------------------------------

Requires FLOS v562+ / Last update 8-3-2010

Purpose:
---------

Provides file requesters for user programs, allowing the entry of filenames, listing
of directories etc.   (There are versions that include the ability to initiate load
and saves serially.) NOTE: The requester code does not perform the actual load and
save operation, that is left to the user program.


How to add to a project:
-------------------------

The file requester routines utilise the window draw and support code.
The simplest way to include all the necessary source is to add:
 
-I %v6z80pdir%\FLOS_based_programs\code_library\requesters\inc
-I %v6z80pdir%\FLOS_based_programs\code_library\window_routines\inc

to your project's assemble.bat PASMO.EXE command line and then
put this line in your source:

include "file_requesters.asm" (or include "file_requesters_with_rs232.asm")

Alternatively, you can manually copy all of the source files to your projects
inc folder. You need:

"file_requesters.asm" (or "file_requesters_with_rs232.asm")
"window_draw_routines.asm"
"window_support_routines.asm"
"window_chars.bin"

You only need to add the line "include file_requesters.asm" to your own project's
source, as the code has includes for the rest of the required files itself.


Usage:
------

When your program wants to load a file
--------------------------------------

Set:

    HL : The location of a 0-terminated filename (or 0 if not supplied)
    B  : Desired x coordinate of the requester (in characters from left)
    C  : Desired y coordinate of the requester (in characters from top)

 ...then call "load_requester" which invokes the requester...

When control is returned to the host program, the following registers are set up:
 
   Zero Flag: If set, the requester operation encountered no errors. In this case:

              A =  $00 : Ready to load file from disk, IX:IY = Length of file. 
                         HL = Address of selected filename. 

   Zero Flag: Not set, in this case:
 
              A = $FF  User aborted file load - EG: Pressed Escape or Cancel

              A = $FE (Requester with RS232 button only) All OK - ready to load file serially:
                      IX will be pointing to the file header:
                      IX+$00 = Filename ASCII 
                      IX+$10 = Length of file (low word)
                      IX+$12 = Length of file (high word)
                 Note that serial loads accept the header of ANY file offered, it is
                 up to the user's program to examine the filename in the header (if it
                 cares what it is.)
       
              A = $xx : Any other value: A standard FLOS error code. If A = 0,
                        there was a disk hardware error during requester activity.
                        (This can be reported with the call "hw_error_requester")
                        Other errors (file system related) can be reported with
                        the call "file_error_requester" if required)
   
Disk-loads checks the requested file exists before leaving the requester (by calling
"kjt_find_file") if the filename does not exist, a window message is shown and
control goes back to the main load requester. Therefore the user program can use
"kjt_force_load" immediately (IE: without its own "kjt_find_file") if desired.

File system errors appart from "File Not Found" are not automatically reported.
If the program wishes to display a disk error message using the window routines,
just call "file_error_requester" with the error code in A. If you wish to report a
disk hardware error call "hw_error_requester". The hardware error requester
offers a "Remount drives?" button.


When your program wants to save a file, set..
--------------------------------------------

   HL : Location of the default filename (or 0 if not supplied)
   B  : X coordinate of requester (in chars)
   C  : Y coordinate of requester (in chars)

..then call "save_requester" which invokes the requester..

When control is passed back to the host program, the following registers are set..

   Zero Flag: If set, the requester operation encountered no errors. In this case:

              A =  $00 : Ready to save file from disk, HL = Address of selected filename. 

   Zero Flag: Not set, in this case:
 
  
              A = $FF : User aborted file save - EG: Pressed Escape or Cancel

              A = $FE : (Requesters with RS232 support only) all OK, ready to send file serially.
                        HL: address of selected filename

              A = $xx : Any other value: A standard FLOS error code. If A = 0,
                        there was a disk hardware error during requester activity.
                        (This can be reported with the call "hw_error_requester")
                        Other errors (file system related) can be reported with
                        the call "file_error_requester" if required)

The user program should then proceed to create and save the required data using
the usual kernal routines.  The save requester checks if a file already exists
before leaving the requester, if it does the option is given to overwrite it.
If the user agrees, the original file is deleted ready for the new file to
be written by the user program.

File system errors appart from "File Not Found" are not automatically reported.
If the program wishes to display a disk error message using the window routines,
just call "file_error_requester" with the error code in A. If you wish to report a
disk hardware error call "hw_error_requester". The hardware error requester
offers a "Remount drives?" button.

Notes:
------

The requester code expects a normal FLOS display, so if the host program uses a
custom display mode, the routine KJT_FLOS_DISPLAY should be called prior to
calling the requester.

The requester code copies user defined characters to the FLOS font (ASCII 128-159)
so user programs requiring their own characters here should restore them after
using the requesters.

Windows are drawn on top of anything on the display. If the original character
map is to be restored after a window is finished with, the user's program must
handle this.

