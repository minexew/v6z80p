#ifndef DISPLAY_H
#define DISPLAY_H

// define one of two possible video modes
//#define USE_FLOS_DISPALY
#define USE_TILEMAP_DISPALY

// Display window size, in pixels.
#define SCREEN_WIDTH                  368
#define SCREEN_HEIGHT                 240

// Display functions
BOOL Display_InitVideoMode(void);
void Display_SetCursorPos(BYTE x, BYTE y);
void Display_PrintString(const char* str);
void Display_PrintStringLFCR(const char* str);
void Display_SetPen(BYTE color);
void Display_ClearScreen(void);

#endif /* DISPLAY_H */
