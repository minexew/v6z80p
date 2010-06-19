
Logic banks:
15 banks for v6z80p
0 - 14

Buffers:
---------
sprites.h
#define BUF_FOR_LOADING_SPRITES_4KB             0xE000
background.c
#define BUF_FOR_LOADING_BACKGROUND_4KB          0xE000


Warning!
--------
SDCC doesnt set all globals to zero ! (this is violation of ANSI C rulez)
you must manualy set them 