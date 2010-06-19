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

struct {
    BOOL is_looking_for_second_byte_of_scancode;
    byte last_typed_scancode;
    byte prev_pressed_scancode;
} keyboard;


typedef struct /*keyboard_input_map_tag*/ {
byte  scancode;
BOOL* pVar;
} keyboard_input_map_t;

keyboard_input_map_t keyboard_input_map[] = {
                {SC_A, &player1_input.up}, {SC_Z, &player1_input.down},
                {SC_J, &player2_input.up}, {SC_M, &player2_input.down},
                {SC_X, &player1_input.fire1}, {SC_COMMA, &player2_input.fire1},
                {SC_P, &game.is_user_pressed_pause},
};

void Input_ClearPlayersInput(void)
{
    player1_input.up = player1_input.down = player1_input.fire1 = FALSE;
    player2_input.up = player2_input.down = player2_input.fire1 = FALSE;
}

void Keyboard_Init(void)
{
    DI();
    keyboard.is_looking_for_second_byte_of_scancode = FALSE;
    keyboard.prev_pressed_scancode = 0;
    EI();
}

byte Keyboard_GetLastPressedScancode(void)
{
    return keyboard.prev_pressed_scancode;
}

void Keyboard_IRQ_Handler()
{
    byte scancode, i;
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

        table = keyboard_input_map;
        for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
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
    table = keyboard_input_map;
    for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
        if(scancode == table->scancode) {
            *(table->pVar) = TRUE;
            // Input auto switch.
            // player pressed a keyboard key, used to contol bat,
            // switch input type to "keyboard" for that player

            // is this player1?
            if(table->pVar == &player1_input.up || table->pVar == &player1_input.down ||
                                                    table->pVar == &player1_input.fire1)
                player1_input.input_type = KEYBOARD;
            // is this player2? (check only, if two players game mode)
            if(!game.is_one_player_mode)
                if(table->pVar == &player2_input.up || table->pVar == &player2_input.down ||
                                                    table->pVar == &player2_input.fire1)
                    player2_input.input_type = KEYBOARD;

        }
        table++;
        keyboard.prev_pressed_scancode = scancode;   // remember last pressed scancode
    }


    if(scancode == SC_ESC)
        request_exit = TRUE;



}

//
void irq_handler() NAKED
{
    BEGINASM()
    PUSH_ALL_REGS()

    in a,(SYS_IRQ_PS2_FLAGS)	; Read irq status flags
    bit 0,a			      ; keyboard irq set?
    call nz,_Keyboard_IRQ_Handler	; call keyboard irq routine if so

    ld a,#0x01
    out (SYS_CLEAR_IRQ_FLAGS),a	; clear keyboard interrupt flag

    POP_ALL_REGS()
    ei
    reti
    ENDASM()

}

void install_irq_handler(void)
{
    DI();
    *((word*)IRQ_VECTOR) = (word)&irq_handler;
    io__sys_irq_enable = 0x81;      // enable: master irq, keyb
    EI();
}
