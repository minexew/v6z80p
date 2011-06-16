
System memory banks:
15 logic banks for v6z80p
(0 - 14)

Used system memory buffer:
---------
sprites.h
#define BUF_FOR_LOADING_SPRITES_4KB             0xXXXX
background.c
#define BUF_FOR_LOADING_BACKGROUND_4KB          0xXXXX


There are 2 sytsem memory banks (32KB+32KB) used:
- one is main bank for code/data
- one for music player and MOD pattern data


Note
--------
While developing Pong, my point was to: 
- develop as fast as possible
- develop a clean (well structured) C code,  using object-oriented tactic
- optimize the C code a bit (certainly, there are a room for optimization)


Warning!
--------
SDCC doesnt set all globals vars to zero ! (this is violation of ANSI C rulez)
you must manualy set them, somewhere in C code.