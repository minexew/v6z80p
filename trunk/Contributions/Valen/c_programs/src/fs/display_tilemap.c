// Display functions
// using tilemap 8x8 video mode.


#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>


#include <string.h>

#include "display.h"


#include <base_lib/video_mode.h>
#include <base_lib/assert_v6.h>
#include <base_lib/file_operations.h>

// Playfield A - background of chars
// Playfield B - chars 8x8


// Display Window size (hardware values):
// Width  368 pixels
#define X_WINDOW_START                0x7
#define X_WINDOW_STOP                 0xE
// Height 240 lines
#define Y_WINDOW_START                0x2
#define Y_WINDOW_STOP                 0xC

// Display window size, in pixels.
#define SCREEN_WIDTH                  368
#define SCREEN_HEIGHT                 240


void Display_PrintChar(BYTE c);
void Display_InitFont(void);
BOOL Display_LoadFont(void);
//void Display_CreateChunkyFont(BYTE fontColor, DWORD fontVideoAddress);
//void Display_SetNonZeroBytesToValue(BYTE value, WORD dataVideoAddress);
void Display_FillTile8x8(BYTE colorIndex, DWORD videoAddress);
void Display_SetPalette(void);
//void Display_CloneChunkyFont(DWORD srcFontVideoAddress, DWORD destFontVideoAddress, BYTE fontColor);


#define PF_A       0
#define PF_B       1

// Video memory map:
// 0000 - Tiles for 8x8 font. Total: 15 fonts, with different color indexes (1-15).
// then - Tiles for solid background. Total:  15 tiles, with different color indexes (1-15).

#define FIRST_BACKGROUND_TILE_NUMBER    ( (WORD)(FONT_8x8_SIZE*15UL / 64) )

struct {
    BYTE cursor_x;
    BYTE cursor_y;
    BYTE cursor_color, backgr_color;
} display;

BYTE fontBuffer[0x300];


#define DISABLE_NON_SPRITE_VIDEO        mm__vreg_vidctrl = 4;

// public functions -------------------
BOOL Display_InitVideoMode(void)
{
    // load font
    if(!Display_LoadFont()) {
        FLOS_PrintStringLFCR("Load font failed!");
        return FALSE;
    }
    MarkFrameTime(2);
    // disable hardware data fetching from video memory, because we want write to video memory at highest speed
    DISABLE_NON_SPRITE_VIDEO;
    Display_InitFont();
    MarkFrameTime(0);


    display.cursor_x = display.cursor_y = 0;
    display.cursor_color = 7;
    display.backgr_color = 2;


    TileMap_8x8_FillPlayfield(PF_A, 0, 0x800, 0);
    TileMap_8x8_FillPlayfield(PF_B, 0, 0x800, 0);
    Display_SetPalette();

    // select tile mode, extended (2 bytes per tilenumber), 8x8, no "left wide border"
    VideoMode_InitTilemapMode(DUAL_PLAY_FIELD | TILE_SIZE_8x8, EXTENDED_TILE_MAP_MODE);
    VideoMode_SetupDisplayWindowSize(X_WINDOW_START, X_WINDOW_STOP, Y_WINDOW_START, Y_WINDOW_STOP);

    return TRUE;
}

void Display_SetCursorPos(BYTE x, BYTE y)
{
    display.cursor_x = x;
    display.cursor_y = y;
}

void Display_PrintString(const char* str)
{

//    display.cursor_x = 0; display.cursor_y = 0; str = "        ABCD1234";

    while(*str) {
        Display_PrintChar(*str);
        display.cursor_x++;
        if(display.cursor_x >= SCREEN_WIDTH/8) display.cursor_x = 0;
        str++;
    }
}

void Display_PrintStringLFCR(const char* str)
{
    BYTE y = display.cursor_y;

    Display_PrintString(str);
    y++;
    display.cursor_y = y;
    display.cursor_x = 0;
}

// Simulate FLOS font numbers and colors.
/*
        0 - transparent (shows "paper" colour)
        1 - black
        2 - blue
        3 - red
        4 - magenta
        5 - green
        6 - cyan
        7 - yellow
        8 - white
        9 - dark grey
        a - mid grey
        b - light grey
        c - orange
        d - light blue
        e - light green
        f - brown
*/
void Display_SetPen(BYTE color)
{
    //if(color > 0) color--;
    display.cursor_color = color & 0x0F;
    display.backgr_color = (color & 0xF0) >> 4;
}

void Display_ClearScreen(void)
{
    //FLOS_ClearScreen();
}

// private functions -------------------


// Playfield A or B.  Buffer 0.
// playfieldNumber: 0 pf A, 1 pf B
void TileMap_PutTileToTilemap(BYTE playfieldNumber, BYTE x, BYTE y, WORD tileNumber)
{
    BYTE* pTilemap;

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE + playfieldNumber);  // video addr: 8KB - PF A, then 8KB PF_B
    pTilemap = (byte*)(VIDEO_BASE + y*64U + x);
    *pTilemap         = (byte) tileNumber;         //LSB
    *(pTilemap+0x800) = (byte)(tileNumber >> 8); //MSB
    PAGE_OUT_VIDEO_RAM();
}


#define FONT_8x8_SIZE   (96*8*8)
void Display_InitFont(void)
{
//    DWORD destVideoAddress;
//    BYTE colorIndex;

    // make 15 fonts, with color index 1 to 15
//    destVideoAddress = 0;
//    for(colorIndex=1; colorIndex<2; colorIndex++) {
//        Display_CreateChunkyFont(colorIndex, destVideoAddress);
//        destVideoAddress += FONT_8x8_SIZE;
//    }

//    Display_LoadChunkyFont();

    // Make 15 tiles, with color index 1 to 15 (will be used as background tiles)
    // Put in video memory right after fonts.
    //fontVideoAddress = 0;
//    for(colorIndex=1; colorIndex<16; colorIndex++) {
//        Display_FillTile8x8(colorIndex, destVideoAddress);
//        destVideoAddress += 8*8;
//    }
}



// Create chunky font, from FLOS bitmap font (1bit per pixel).
// Font 96 chars.
//
// fontVideoAddress - must be div by 8 without remainder
/*
void Display_CreateChunkyFont(BYTE fontColor, DWORD fontVideoAddress)
{
    BYTE b;
    WORD i;

    BYTE destChar, destCharY;
    BYTE mask, j;
    BYTE* pDestFont;

    //BYTE videoBank; WORD videoOffset;   // VRAM, destination for chunky font (byte per pixel)
    DWORD addressDestFont;

    ASSERT_V6( (fontVideoAddress & 7) == 0 );

    PAGE_IN_VIDEO_RAM();

    destChar = destCharY = 0;
    for(i=0; i<0x300; i++) {
        //SET_VIDEO_PAGE(15);         // VRAM $1E000 with FLOS bitmap font (bit per pixel)
        //b = *( (byte*)(VIDEO_BASE + 0x400 + i) );
        b = *(fontBuffer + i);
        // b - holds byte of font (8 dots)

        addressDestFont = fontVideoAddress + destChar*8*8 + destCharY*8;
        SET_VIDEO_PAGE(addressDestFont/0x2000);
        pDestFont = (BYTE*)(VIDEO_BASE + ((WORD)addressDestFont & 0x1FFF));

        mask = 0x80;
        for(j=0; j<8; j++) {
            ASSERT_V6( pDestFont < ((BYTE*)VIDEO_BASE + 0x2000) );
            *pDestFont = (b & mask) ? (fontColor) : (0);
            pDestFont++;

            mask = mask >> 1;
        }



        if(++destChar == 96) {destChar = 0; destCharY++;}
    }

    PAGE_OUT_VIDEO_RAM();
}
*/

// Load 15 fonts, 8x8 with colors 1-16.
//
//
// dataVideoAddress - in chunks of 64 bytes

/*
BOOL Display_LoadChunkyFont(void)
{
    DWORD i;
//    BYTE* p;

    FLOS_FILE myFile;
    BOOL r;

    r = FLOS_FindFile(&myFile, 'MYFONTS.BIN');
    if(!r) return FALSE;
    FLOS_SetLoadLength(0x2000);


    for(i=0; i<96UL*64*15 / 0x2000; i++) {
        SET_VIDEO_PAGE(i);

//        FLOS_SetFilePointer(0);
        r = FLOS_ForceLoad(0xA000, 0);

        PAGE_IN_VIDEO_RAM();
        memcpy(VIDEO_BASE, 0xA000, 0x2000);
        PAGE_OUT_VIDEO_RAM();
    }

    return TRUE;
}
*/




// Calc video page and video pointer from linear video address.
#define CALC_VIDEO_PAGE_NUMBER(dw)       (dw/0x2000)
#define CALC_PTR_TO_VIDEO_WINDOW(dw)     ( (BYTE*)(VIDEO_BASE + ((WORD)dw & 0x1FFF)) )
#define IS_PTR_WITHIN_VIDEO_WINDOW(p)    (p < ((BYTE*)VIDEO_BASE + 0x2000) )

// Fill tile. Size 8x8 pixels.
//
// videoAddress - must be div by 64 without remainder
void Display_FillTile8x8(BYTE colorIndex, DWORD videoAddress)
{
    BYTE* pDest;

    //
    ASSERT_V6( (videoAddress & 63) == 0);

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE( CALC_VIDEO_PAGE_NUMBER(videoAddress) );
    pDest = CALC_PTR_TO_VIDEO_WINDOW(videoAddress);
    ASSERT_V6( IS_PTR_WITHIN_VIDEO_WINDOW(pDest + 64 - 1) );

    memset(pDest, colorIndex, 8*8);
    PAGE_OUT_VIDEO_RAM();
}


void Display_PrintChar(BYTE c)
{
    WORD tileNumber;
    BYTE color;

    // char tile ---
    tileNumber = c - 0x20;              // ASCII code to tile number
    // correct tilenumber, according to current color
    color = (display.cursor_color > 0) ? display.cursor_color - 1 : display.cursor_color;
    tileNumber +=  color * 96;
    ASSERT_V6(display.cursor_x < SCREEN_WIDTH/8); ASSERT_V6(display.cursor_y < SCREEN_HEIGHT/8); ASSERT_V6(tileNumber < 2048);
    TileMap_PutTileToTilemap(PF_B, display.cursor_x, display.cursor_y, tileNumber);

    // background tile ---
    // correct tilenumber, according to current color
    color = (display.backgr_color > 0) ? display.backgr_color - 1 : display.backgr_color;
    tileNumber =  FIRST_BACKGROUND_TILE_NUMBER + color;
    TileMap_PutTileToTilemap(PF_A, display.cursor_x, display.cursor_y, tileNumber);
}



BOOL Display_LoadFont(void)
{
    FLOS_StoreDirPosition();
    FLOS_RootDir();
    FLOS_ChangeDir("FONTS");
    if(!/*load_file_to_buffer*/FileOp_LoadFileToBuffer("PHILFONT.FNT", 0, fontBuffer, 0x300, 0))
        return FALSE;
    FLOS_RestoreDirPosition();

    return TRUE;
}

/*
void Display_CloneChunkyFont(DWORD srcFontVideoAddress, DWORD destFontVideoAddress, BYTE fontColor)
{

    BYTE* pFont = 0;
    BYTE bytePixel;
    WORD i;

    PAGE_IN_VIDEO_RAM();
    for(i=0; i<FONT_8x8_SIZE; i++) {
        // get pixel
//        SET_VIDEO_PAGE(srcFontVideoAddress/0x2000);
//        pFont = (BYTE*)(VIDEO_BASE + ((WORD)srcFontVideoAddress & 0x1FFF));
        bytePixel = *pFont;

        // put pixel
        SET_VIDEO_PAGE(destFontVideoAddress/0x2000);
        pFont = (BYTE*)(VIDEO_BASE + ((WORD)destFontVideoAddress & 0x1FFF));
        *pFont = (bytePixel == 0) ? 0 : fontColor ;
        // advance linear video addresses
        srcFontVideoAddress++; destFontVideoAddress++;
    }
    PAGE_OUT_VIDEO_RAM();

}
*/

// 16 primary colors
const WORD myPalette[] = {
                    /*RGB2WORD(0, 0, 0),
                    RGB2WORD(0, 128, 0),
                    RGB2WORD(255, 255, 255),
                    RGB2WORD(128, 128, 128),
                    RGB2WORD(255, 0, 0),
                    RGB2WORD(128, 0, 0),
                    RGB2WORD(0, 255, 0),
                    RGB2WORD(0, 128, 0),

                    RGB2WORD(0, 0, 255),
                    RGB2WORD(0, 0, 128),
                    RGB2WORD(255, 255, 0),
                    RGB2WORD(128, 128, 0),
                    RGB2WORD(0, 255, 255),
                    RGB2WORD(0, 128, 128),
                    RGB2WORD(255, 0, 255),
                    RGB2WORD(128, 0, 128) */

                    0x000,      // index 0
    // FLOS pen_colours
                    0x000,0x00f,0xf00,0xf0f,0x0f0,0x0ff,0xff0,0xfff,
                    0x555,0x999,0xccc,0xf71,0x07f,0xdf8,0x840

                };

void Display_SetPalette(void)
{

    memcpy((void*) PALETTE, myPalette, sizeof(myPalette));

    /*Display_SetCursorPos(0, 26);
    Display_SetPen(0x30); Display_PrintString("ABCD1234");
    Display_SetPen(0x31); Display_PrintString("ABCD1234");
    Display_SetPen(0x32); Display_PrintString("ABCD1234");
    Display_SetPen(0x33); Display_PrintString("ABCD1234");
    Display_SetPen(0x34); Display_PrintString("ABCD1234");
    Display_SetCursorPos(0, 27);
    Display_SetPen(0x35); Display_PrintString("ABCD1234");
    Display_SetPen(0x36); Display_PrintString("ABCD1234");
    Display_SetPen(0x37); Display_PrintString("ABCD1234");


    Display_SetCursorPos(0, 28);
    Display_SetPen(8);  Display_PrintString("ABCD1234");
    Display_SetPen(9);  Display_PrintString("ABCD1234");
    Display_SetPen(10); Display_PrintString("ABCD1234");
    Display_SetPen(11); Display_PrintString("ABCD1234");
    Display_SetPen(12); Display_PrintString("ABCD1234"); 
    Display_SetCursorPos(0, 29);
    Display_SetPen(13); Display_PrintString("ABCD1234");
    Display_SetPen(14); Display_PrintString("ABCD1234");
    Display_SetPen(15); Display_PrintString("ABCD1234");
    */
}
