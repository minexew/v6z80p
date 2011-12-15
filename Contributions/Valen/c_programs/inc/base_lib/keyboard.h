
typedef struct {
    byte  scancode;
    BOOL* pVar;
} keyboard_input_map_t;

void Keyboard_Init(keyboard_input_map_t* pMap);
byte Keyboard_GetLastPressedScancode(void);
void Keyboard_IRQ_Handler();

void Keyboard_Clear_IRQ_Flag(void);
