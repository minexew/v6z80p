// ------------
#include <stdio.h>
#include <string.h>

#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <base_lib/keyboard.h>

#include <debug_print.h>

struct {
    BOOL is_looking_for_second_byte_of_scancode;
    byte last_typed_scancode;
    byte prev_pressed_scancode;
    
    keyboard_input_map_t* pMap;

    // array of pressed scancodes
    BYTE arrPressed[7];
    // is the event (key press or release) was recivied from keyboard
    BOOL isEvent;
} keyboard;


void Keyboard_HandleScanCode(BYTE scancode, BOOL isPressed);

void Keyboard_Init(keyboard_input_map_t* pMap)
{
    
    memset(&keyboard.arrPressed, 0, sizeof(keyboard.arrPressed));
    DI();
    keyboard.is_looking_for_second_byte_of_scancode = FALSE;
    keyboard.prev_pressed_scancode = 0;
    keyboard.pMap = pMap;

    keyboard.isEvent = FALSE;
    EI();
}

byte Keyboard_GetLastPressedScancode(void)
{
    return keyboard.prev_pressed_scancode;
}

// Common interrupt pitfal link lhttp://sdcc.sourceforge.net/doc/sdccman.html/node68.html
// This ISR changes next variables:
//  - set BOOL var, is atomic operation for z80
void Keyboard_IRQ_Handler(void)
{
    byte scancode;
    keyboard_input_map_t *table;


    scancode = io__sys_keyboard_data;
    if(scancode == 224 || scancode == 225) {
        Keyboard_Clear_IRQ_Flag();
        return;
    }

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

        // remove scancode from a array of pressed keys
        Keyboard_HandleScanCode(scancode, FALSE);
        // DEBUG_PRINT(("Rel %i \n, ",  (WORD)scancode));

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

    // add the scancode to array of pressed keys
    Keyboard_HandleScanCode(scancode, TRUE);
    // DEBUG_PRINT(("Press %i \n, ",  (WORD)scancode));

    Keyboard_Clear_IRQ_Flag();
}

// add (or remove) the scancode from pressed array
void Keyboard_HandleScanCode(BYTE scancode, BOOL isPressed)
{
    BYTE i;

    keyboard.isEvent = TRUE;

    if(isPressed) {
        // check if a scancode is already in arr (if so, just return)
        for(i = 0; i < sizeof(keyboard.arrPressed)/sizeof(keyboard.arrPressed[0]); i++)
            if(keyboard.arrPressed[i] == scancode)
                return;

        // add scancode to arr
        for(i = 0; i < sizeof(keyboard.arrPressed)/sizeof(keyboard.arrPressed[0]); i++)
            if(keyboard.arrPressed[i] == 0) {
                keyboard.arrPressed[i] = scancode;
                return;
            }
    } else {
        // remove scancode from arr
        for(i = 0; i < sizeof(keyboard.arrPressed)/sizeof(keyboard.arrPressed[0]); i++)
            if(keyboard.arrPressed[i] == scancode) {
                keyboard.arrPressed[i] = 0;
                return;
            }
    }
    

}

// clear keyboard interrupt flag
void Keyboard_Clear_IRQ_Flag(void)
{
    
    // BEGINASM()
    // push af

    // ld a,#0x01
    // out (SYS_CLEAR_IRQ_FLAGS),a ; clear keyboard interrupt flag

    // pop af
    // ENDASM()

    io__sys_clear_irq_flags = 0x01;
}

BOOL Keyboard_IsPressed(BYTE scancode)
{
    BYTE i;

    for(i = 0; i < sizeof(keyboard.arrPressed)/sizeof(keyboard.arrPressed[0]); i++)
        if(keyboard.arrPressed[i] == scancode)
            return TRUE; 

    return FALSE;
}


// We cant print debug info inside IRQ because it is too long time operation
// and we may loose some keyborad events.
void Keyboard_PrintDebug(void)
{
    BYTE i;

    // for(i = 0; i < sizeof(keyboard.arrPressed)/sizeof(keyboard.arrPressed[0]); i++) {
    //     DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[i]));
    // }

    if(keyboard.isEvent) {
        keyboard.isEvent = FALSE;

        DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[0]));
        DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[1]));
        DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[2]));
        DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[3]));
        DEBUG_PRINT(("%i, ",  (WORD)keyboard.arrPressed[4]));
        DEBUG_PRINT((" \n"));
    }

}

//
