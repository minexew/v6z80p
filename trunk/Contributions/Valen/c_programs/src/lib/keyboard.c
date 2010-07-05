// ------------

typedef struct {
    byte  scancode;
    BOOL* pVar;
} keyboard_input_map_t;

struct {
    BOOL is_looking_for_second_byte_of_scancode;
    byte last_typed_scancode;
    byte prev_pressed_scancode;
    
    keyboard_input_map_t* pMap;
} keyboard;




void Keyboard_Init(keyboard_input_map_t* pMap)
{
    DI();
    keyboard.is_looking_for_second_byte_of_scancode = FALSE;
    keyboard.prev_pressed_scancode = 0;
    keyboard.pMap = pMap;
    EI();
}

byte Keyboard_GetLastPressedScancode(void)
{
    return keyboard.prev_pressed_scancode;
}

// Common interrupt pitfal link lhttp://sdcc.sourceforge.net/doc/sdccman.html/node68.html
// This ISR changes next variables:
//  - set BOOL var, is atomic operation
void Keyboard_IRQ_Handler()
{
    byte scancode;
    keyboard_input_map_t *table;


    scancode = io__sys_keyboard_data;
    // release key logic ---------------------------
    if(scancode == 0xF0) {
        keyboard.is_looking_for_second_byte_of_scancode = TRUE;
        // next interrupt, will bring the second byte of scancode
        return;
    }

    if(keyboard.is_looking_for_second_byte_of_scancode) {
        keyboard.is_looking_for_second_byte_of_scancode = FALSE;

        table = keyboard.pMap;
        while(table->scancode != 0xFF) {        // loop 
            if(scancode == table->scancode)
                *(table->pVar) = FALSE;
            table++;
        }
        // if user typed (pressed and release) the same key, then remeber this key as "last typed key"
        if(scancode == keyboard.prev_pressed_scancode)
            keyboard.last_typed_scancode = scancode;

        return;
    }

    // press key logic ---------------------------
    table = keyboard.pMap;
    while(table->scancode != 0xFF) {            // loop
        if(scancode == table->scancode) {
            *(table->pVar) = TRUE;
            
        }
        table++;
        keyboard.prev_pressed_scancode = scancode;   // remember last pressed scancode
    }

}

//
