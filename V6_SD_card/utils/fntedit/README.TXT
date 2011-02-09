FNTEDIT.EXE - by Calogiuri Enzo Antonio

A simple 8x8 pixel 1bpp font editor for FLOS
--------------------------------------------

This util allow you to create a 128 or 256 characters 
bitmap font for use in the user's own programs.

Changes:
--------


Single character format - overview:
-----------------------------------

Each character is defined by 8 byte of data, and each byte
represents 8 pixel of font. In this way you can save system
memory because 128 characters require only 1KB of ram (and
256 characters only 2KB of ram).

Each character is stored according to this table:

        |bit 0|bit 1|bit 2|bit 3|bit 4|bit 5|bit 6|bit 7|
row 0___|     |     |     |     |     |     |     |     | = first byte
row 1___|     |     |     |     |     |     |     |     | = second byte
row 2___|     |     |     |     |     |     |     |     | = third byte
row 3___|     |     |     |     |     |     |     |     | = fourth byte
row 4___|     |     |     |     |     |     |     |     | = fifth byte
row 5___|     |     |     |     |     |     |     |     | = sixth byte
row 6___|     |     |     |     |     |     |     |     | = seventh byte
row 7___|     |     |     |     |     |     |     |     | = eighth byte

for example, the character "+" will be represented by:

        |bit 0|bit 1|bit 2|bit 3|bit 4|bit 5|bit 6|bit 7|
row 0___|  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  | = first byte
row 1___|  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  | = second byte
row 2___|  0  |  0  |  0  |  1  |  0  |  0  |  0  |  0  | = third byte
row 3___|  0  |  0  |  0  |  1  |  0  |  0  |  0  |  0  | = fourth byte
row 4___|  0  |  1  |  1  |  1  |  1  |  1  |  0  |  0  | = fifth byte
row 5___|  0  |  0  |  0  |  1  |  0  |  0  |  0  |  0  | = sixth byte
row 6___|  0  |  0  |  0  |  1  |  0  |  0  |  0  |  0  | = seventh byte
row 7___|  0  |  0  |  0  |  0  |  0  |  0  |  0  |  0  | = eighth byte

Therefore, the eight bytes necessary to represent the character
will be equal to:

first byte  (from bit 7 to bit 0) : "00000000" - decimal 0
second byte (from bit 7 to bit 0) : "00000000" - decimal 0
third byte  (from bit 7 to bit 0) : "00001000" - decimal 8
fourth byte (from bit 7 to bit 0) : "00001000" - decimal 8
fifth byte  (from bit 7 to bit 0) : "00111110" - decimal 62
sixth byte  (from bit 7 to bit 0) : "00001000" - decimal 8
eighth byte (from bit 7 to bit 0) : "00001000" - decimal 8
eighth byte (from bit 7 to bit 0) : "00000000" - decimal 0

In C can be represented as: unsigned char MyChar[8] = {0,0,8,8,62,8,8,0};
Naturally to draw single pixel of character you must convert decimal value in
8 bit binary value. For example MyChar[2] (value 8) must by converted into
value "00001000" and draw on screen starting from last bit to first bit. 
The folders "fntex1", "fntex2" and "fntex3" contain source code examples in
C showing how convert value and put on screen character and string.


Use of fntedit
--------------

To start editor you must type fntedit <FontName>. If <FontName> exists
then be loaded into ram and the program will display the main work screen.
If <FontName> not exist, displays the menu it allows a choice between a
128 or 256 characters font or quit to FLOS. 

    New font menu
    -------------
    
    If <FontName> not exist you must see menù with this options:
    
    CREATE 8X8, 128 CHARS FONT
    CREATE 8X8, 256 CHARS FONT
    QUIT TO FLOS
    
    With key UP and DOWN you can move the selector ("->") end confirm the
    choice by pressing ENTER key.
    
    Main working screen
    -------------------
    
    The main working screen of fntedit is 320x200@256 colors mode. The screen
    is arranged in this way: in the upper-left you have the 8x8 design grid
    where you can move with the keys UP, DOWN, LEFT and RIGHT and you can
    set/reset single block by pressing SPACE key. Design grid can be activated
    by pressing F1 key.
    To choose the font color you must press F2 key, and be activated the Select
    color panel (in the bottom-left of screen). To choose color you can use the
    keys UP, DOWN, LEFT and RIGHT. The color selected will be saved in the file.
    By pressing F3 and F4 key you can change the current character in use/edit.
    Characters are listed on the right part of screen.
    Pressing F5 you can enter in the main working menù.
    
    Main working menù
    ---------
    
    In the main working menù you must see this options:
    
    RETURN TO EDITOR
    SAVE ON FILE
    SAVE ON FILE AND EXIT TO FLOS
    EXPORT FONT AS C HEADER		(create a file named "FNTDEF.H")
    EXPORT FONT AS MEMORY DUMP		(create a file named "FNTDEF.BIN")
    EXPORT FONT IN FLOS FORMAT		(create a file named "FNTFLOS.FNT")
    RELOAD ORIGINAL FONT
    CLEAR ALL CHARACTERS
    QUIT TO FLOS
    
    With key UP and DOWN you can move the selector ("->") end confirm the
    choice by pressing ENTER key.
   
   
How to use font files in user program
-------------------------------------

There are three ways to use a font file. You can load the file created by fntedit,
use the C header file (but you must use SDCC compiler) or read the dump font file.

Font file created by fntedit has this structure:

    1) NumOfCaracters                       : 2 byte
    2) FontColorIndex                       : 1 byte
    3) Byte 1 first character               : 1 byte
    4) Byte 2 first character               : 1 byte
    5) Byte 3 first character               : 1 byte
    6) Byte 4 first character               : 1 byte
    7) Byte 5 first character               : 1 byte
    8) Byte 6 first character               : 1 byte
    9) Byte 7 first character               : 1 byte
    10) Byte 8 second character             : 1 byte
    11) Byte 1 second character             : 1 byte
    12) Byte 2 second character             : 1 byte
    13) Byte 3 second character             : 1 byte
    14) Byte 4 second character             : 1 byte
    15) Byte 5 second character             : 1 byte
    16) Byte 6 second character             : 1 byte
    17) Byte 7 second character             : 1 byte
    18) Byte 8 second character             : 1 byte
    ...
    ...
    ...
    ...
    nn) Byte 1 NumOfCaracters character     : 1 byte
    nn) Byte 2 NumOfCaracters character     : 1 byte
    nn) Byte 3 NumOfCaracters character     : 1 byte
    nn) Byte 4 NumOfCaracters character     : 1 byte
    nn) Byte 5 NumOfCaracters character     : 1 byte
    nn) Byte 6 NumOfCaracters character     : 1 byte
    nn) Byte 7 NumOfCaracters character     : 1 byte
    nn) Byte 8 NumOfCaracters character     : 1 byte
    

Dump file has this structure:

    1) Byte 1 first character               : 1 byte
    2) Byte 2 first character               : 1 byte
    3) Byte 3 first character               : 1 byte
    4) Byte 4 first character               : 1 byte
    5) Byte 5 first character               : 1 byte
    6) Byte 6 first character               : 1 byte
    7) Byte 7 first character               : 1 byte
    8) Byte 8 second character              : 1 byte
    9) Byte 1 second character              : 1 byte
    10) Byte 2 second character             : 1 byte
    11) Byte 3 second character             : 1 byte
    12) Byte 4 second character             : 1 byte
    13) Byte 5 second character             : 1 byte
    14) Byte 6 second character             : 1 byte
    15) Byte 7 second character             : 1 byte
    16) Byte 8 second character             : 1 byte
    ...
    ...
    ...
    ...
    
To load a dump file, you must know how many characters are in file.    
    
In the folder "fntex2", you can see an example that show how load a font file (C language).
Folder ""fntex1" show how use the C header file and "fntex3" how use dump font file.
    
