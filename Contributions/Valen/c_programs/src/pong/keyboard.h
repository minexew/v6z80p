#ifndef KEYBOARD_H
#define KEYBOARD_H

#ifndef EXTERN_KEYBOARD
    #define EXTERN_KEYBOARD extern
#endif


#include <macros_specific.h>

typedef enum {
    KEYBOARD = 0,
    JOY
} InputType;

typedef struct {
    BOOL up, down;
    BOOL fire1;
    InputType input_type;
} player_input;

EXTERN_KEYBOARD player_input player1_input;// = {FALSE, FALSE, FALSE, KEYBOARD};
EXTERN_KEYBOARD player_input player2_input;// = {FALSE, FALSE, FALSE, KEYBOARD};


EXTERN_KEYBOARD struct {
    BOOL is_looking_for_second_byte_of_scancode;
    byte last_typed_scancode;
    byte prev_pressed_scancode;
} keyboard;



void Input_ClearPlayersInput(void);
void Keyboard_Init(void);
byte Keyboard_GetLastPressedScancode(void);
byte Keyboard_GetLastTypedScanCode(void);
//void Keyboard_IRQ_Handler();


void irq_handler() NAKED;
void install_irq_handler(void);
void deinstall_irq_handler(void);



#endif /* KEYBOARD_H */

