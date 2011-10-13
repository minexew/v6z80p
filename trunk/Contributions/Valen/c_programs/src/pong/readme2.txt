
System memory banks:
15 logic banks for v6z80p
(0 - 14)


Used system memory buffer:
This temporary buffer is used when loading sprites and tiles.
---------
sprites.h
#define BUF_FOR_LOADING_SPRITES_4KB             ....
background.c
#define BUF_FOR_LOADING_BACKGROUND_4KB          ....


There are 2 sytsem memory banks (32KB+32KB) used:
- one is main bank for code/data
- one for music player and MOD pattern data (MOD samples are in sound memory)


Note
--------
While developing Pong, my point was to: 
- develop as fast as possible
- develop a clean (well structured) C code,  using object-oriented tactic (OOP)
- optimize the C code a bit (certainly, there are a room for optimization)


Keyb IRQ note
-------------
Pong use its own irq handler and use its own code to handle keyboard irq and
thus pong can't use FLOS keyb functions.
However, at this time, will be much simpler to call FLOS keyb irq code (from pong irq handler),
via FLOS kjt call.
And thus we can use FLOS keyb functions.


Warning!
--------
SDCC doesnt set all globals vars to zero ! (this is violation of ANSI C rulez)
you must manualy set them, somewhere in C code.
Or perhaps you can add such init proc to CRT asm code.