// Display functions
// using FLOS output.

void Display_SetCursorPos(BYTE x, BYTE y);
void Display_PrintString(const char* str);
void Display_PrintStringLFCR(const char* str);
void Display_SetPen(BYTE color);
void Display_ClearScreen(void);

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
