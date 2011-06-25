#ifndef KEYBOARD_H
#define KEYBOARD_H

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
player_input player1_input = {FALSE, FALSE, FALSE, KEYBOARD};
player_input player2_input = {FALSE, FALSE, FALSE, KEYBOARD};



void irq_handler() NAKED;
void install_irq_handler(void);



#endif /* KEYBOARD_H */

