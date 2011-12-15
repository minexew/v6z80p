// ------------

#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <base_lib/keyboard.h>



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
//  - set BOOL var, is atomic operation for z80
void Keyboard_IRQ_Handler()
{
    byte scancode;
    keyboard_input_map_t *table;


    scancode = io__sys_keyboard_data;
    // release key logic ---------------------------
    if(scancode == 0xF0) {
        keyboard.is_looking_for_second_byte_of_scancode = TRUE;
        // next interrupt, will bring the second byte of scancode

        Keyboard_Clear_IRQ_Flag();
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

        Keyboard_Clear_IRQ_Flag();
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

    Keyboard_Clear_IRQ_Flag();
}


// clear keyboard interrupt flag
void Keyboard_Clear_IRQ_Flag(void)
{
    BEGINASM()
    push af

    ld a,#0x01
    out (SYS_CLEAR_IRQ_FLAGS),a ; clear keyboard interrupt flag

    pop af
    ENDASM()
}


//
