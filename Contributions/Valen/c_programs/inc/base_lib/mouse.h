// mouse.buttons bits
#define MOUSE_LEFT_BUTTON_PRESSED       1
#define MOUSE_RIGHT_BUTTON_PRESSED      2
#define MOUSE_MIDDLE_BUTTON_PRESSED     4




BYTE Mouse_GetButtons(void);
short Mouse_GetX(void);
short Mouse_GetOffsetX();
short Mouse_GetOffsetY();
void Mouse_ClearOffsets(void);
void Mouse_IRQ_Handler();
