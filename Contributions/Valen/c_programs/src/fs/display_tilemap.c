// Display functions
// using tilemap 8x8 video mode.

// Playfield A - background of chars
// Playfield B - chars 8x8


// Display Window sizes:
// Width  368 pixels
#define X_WINDOW_START                0x7
#define X_WINDOW_STOP                 0xE
// Height 240 lines
#define Y_WINDOW_START                0x3
#define Y_WINDOW_STOP                 0xD


void Display_PrintChar(BYTE c);
void Display_InitFont(void);
BOOL Display_LoadFont(void);
void Display_CreateChunkyFont(BYTE fontColor, DWORD fontVideoAddress);
void Display_SetPalette(void);

struct {
    BYTE cursor_x;
    BYTE cursor_y;
    BYTE cursor_color;
} display;

BYTE fontBuffer[0x300];



// public functions -------------------
BOOL Display_InitVideoMode(void)
{
    // load font
    if(!Display_LoadFont()) {
        FLOS_PrintStringLFCR("Load font failed!");
        return FALSE;
    }
    MarkFrameTime(2);
    //mm__vreg_vidctrl = 4;
    Display_InitFont();
    //mm__vreg_vidctrl = 0;
    MarkFrameTime(0);

    // select tile mode, extended (2 bytes per tilenumber), 8x8, no "left wide border"
    VideoMode_InitTilemapMode(/*DUAL_PLAY_FIELD |*/ TILE_SIZE_8x8, EXTENDED_TILE_MAP_MODE);
    VideoMode_SetupDisplayWindowSize(X_WINDOW_START, X_WINDOW_STOP, Y_WINDOW_START, Y_WINDOW_STOP);

    display.cursor_x = display.cursor_y = 0;
    display.cursor_color = 7;


    TileMap_8x8_FillPlayfieldA(0, 0x800, 0);
    Display_SetPalette();

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

// Simulate FLOS font numbers.
// 0 - transparent (shows "paper" colour)
//			1 - black
//			2 - blue
//                      ...
void Display_SetPen(BYTE color)
{
    //if(color > 0) color--;
    display.cursor_color = color & 0x0F;
}

void Display_ClearScreen(void)
{
    //FLOS_ClearScreen();
}

// private functions -------------------


// Playfield A Buffer 0
void TileMap_PutTileToTilemap(BYTE x, BYTE y, WORD tileNumber)
{
    BYTE* pTilemap;

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);
    pTilemap = (byte*)(VIDEO_BASE + y*64 + x);
    *pTilemap         = (byte) tileNumber;         //LSB
    *(pTilemap+0x800) = (byte)(tileNumber >> 8); //MSB
    PAGE_OUT_VIDEO_RAM();
}


#define FONT_8x8_SIZE   (96*8*8)
void Display_InitFont(void)
{
    DWORD fontVideoAddress;
    BYTE colorIndex;

    // make 15 fonts
    fontVideoAddress = 0;
    for(colorIndex=1; colorIndex<16; colorIndex++) {
        Display_CreateChunkyFont(colorIndex, fontVideoAddress);
        fontVideoAddress += FONT_8x8_SIZE;
    }
}



// Create chunky font, from current FLOS bitmap font.
// Font 96 chars.
//
// fontVideoAddress - must be div by 8 without remainder
void Display_CreateChunkyFont(BYTE fontColor, DWORD fontVideoAddress)
{
    WORD i;
    BYTE b, j;
    WORD destChar, destCharY;
    BYTE mask;
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
            (b & mask) ? (*pDestFont = fontColor) : (*pDestFont = 0);

            mask = mask >> 1;
            pDestFont++;

        }
        if(++destChar == 96) {destChar = 0; destCharY++;}
    }

    PAGE_OUT_VIDEO_RAM();
}

void Display_PrintChar(BYTE c)
{
    WORD tileNumber;
    BYTE cursorColor;

    tileNumber = c - 0x20;              // ASCII code to tile number
    // correct tilenumber, according to current color
    cursorColor = (display.cursor_color > 0) ? display.cursor_color - 1 : display.cursor_color;
    tileNumber +=  cursorColor * 96;

//tileNumber += 15 * 96;

    TileMap_PutTileToTilemap(display.cursor_x, display.cursor_y, tileNumber);
}



BOOL Display_LoadFont(void)
{
    FLOS_StoreDirPosition();
    FLOS_RootDir();
    FLOS_ChangeDir("FONTS");
    if(!load_file_to_buffer(/*"ZXSPEC.FNT"*/"PHILFONT.FNT", 0, fontBuffer, 0x300, 0))
        return FALSE;
    FLOS_RestoreDirPosition();

    return TRUE;
}

//void Display_CloneChunkyFont(DWORD fontVideoAddress, BYTE fontColor, )
//{

//}

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

    Display_SetCursorPos(0, 26);
    Display_SetPen(0); Display_PrintString("ABCD1234");
    Display_SetPen(1); Display_PrintString("ABCD1234");
    Display_SetPen(2); Display_PrintString("ABCD1234");
    Display_SetPen(3); Display_PrintString("ABCD1234");
    Display_SetPen(4); Display_PrintString("ABCD1234");
    Display_SetPen(5); Display_PrintString("ABCD1234");
    Display_SetCursorPos(0, 27);
    Display_SetPen(6); Display_PrintString("ABCD1234");
    Display_SetPen(7); Display_PrintString("ABCD1234");


    Display_SetCursorPos(0, 28);
    Display_SetPen(8); Display_PrintString("ABCD1234");
    Display_SetPen(9); Display_PrintString("ABCD1234");
    Display_SetPen(10); Display_PrintString("ABCD1234");
    Display_SetPen(11); Display_PrintString("ABCD1234");
    Display_SetPen(12); Display_PrintString("ABCD1234");
    Display_SetPen(13); Display_PrintString("ABCD1234");
    Display_SetCursorPos(0, 29);
    Display_SetPen(14); Display_PrintString("ABCD1234");
    Display_SetPen(15); Display_PrintString("ABCD1234");

}
