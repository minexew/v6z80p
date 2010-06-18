fx_player.asm

How to use
----------

Create sounds using the FLOS program fxeditor.exe, save optimized
files. 

Include the source "fx_player.asm" from the inc dir and set up a
label called fx_data which points at the *.dat data in memory.
EG: add the the followinf lines to you program source:

	include "fx_player.asm"
fx_data	incbin  "my_fx1.dat"

The sample file (*.sam) needs be positioned into the start of the 
sample RAM (system RAM $20000-$3ffff).  If the file is small
it can also be incbin'd into the body of the user program and
located with an LDIR and use of the "sys_alt_write_page" port.
If it is large, then the user program can load it from disk
direct to sample RAM using the Kernal load routines.

The user program should call:

"new_fx" 

..With the new FX to play in A when a new effect needs to be
triggered. (Any important registers should be PUSH/POP'd around
the call by the user program.)

(The routine "silence_fx" can be called to clear all sound output.)

On each frame, call:

"play_fx" to update the registers.
