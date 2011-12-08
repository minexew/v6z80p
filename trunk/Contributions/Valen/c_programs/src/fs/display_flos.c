// Display functions
// using FLOS output.

#include <v6z80p_types.h>
#include <os_interface_for_c/i_flos.h>

#include "display.h"

BOOL Display_InitVideoMode(void)
{
    return TRUE;
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
