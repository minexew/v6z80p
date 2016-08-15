#ifndef KEYBOARD_H
#define KEYBOARD_H

typedef struct {
    byte  scancode;
    BOOL* pVar;
} keyboard_input_map_t;

void Keyboard_Init(keyboard_input_map_t* pMap);
byte Keyboard_GetLastPressedScancode(void);
void Keyboard_IRQ_Handler(void);

void Keyboard_Clear_IRQ_Flag(void);
void Keyboard_PrintDebug(void);
BOOL Keyboard_IsPressed(BYTE scancode);

#endif /* KEYBOARD_H */