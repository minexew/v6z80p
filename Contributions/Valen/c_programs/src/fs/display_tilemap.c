// Display functions
// using tilemap 8x8 video mode.

void Display_InitVideoMode(void)
{
    // select tile mode, extended (2 bytes per tilenumber), 8x8, no "left wide border"
    VideoMode_InitTilemapMode(DUAL_PLAY_FIELD | TILE_SIZE_8x8, EXTENDED_TILE_MAP_MODE);
}

void Display_SetCursorPos(BYTE x, BYTE y)
{
    FLOS_SetCursorPos(x, y);
}

void Display_PrintString(const char* str)
{
    FLOS_PrintString(str);
}

void Display_PrintStringLFCR(const char* str)
{
    FLOS_PrintStringLFCR(str);
}

void Display_SetPen(BYTE color)
{
    FLOS_SetPen(color);
}

void Display_ClearScreen(void)
{
    FLOS_ClearScreen();
}
