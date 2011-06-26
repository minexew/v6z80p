#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <macros.h>


#include "joystick.h"
#include "keyboard.h"
#include "pong.h"



// Input:
// portNumber = 0 or 1
void Joystick_SelectJoystickPort(byte portNumber)
{
    io__sys_ps2_joy_control = portNumber & 1;
}

void Joystick_GetInput(void)
{
    //byte v;

    Joystick_CheckInputAutoSwith();

    if(player1_input.input_type == JOY)
        Joystick_GetInputForPlayer(0);

    if(Joystick_IsSecondJoyNeedToBeReaded())
        if(player2_input.input_type == JOY)
            Joystick_GetInputForPlayer(1);

}

// Read joystick bits from port and set player status.
// Input:
// playerNumber = 0 or 1
void Joystick_GetInputForPlayer(byte playerNumber)
{
    byte v;
    player_input* pPI;

    Joystick_SelectJoystickPort(playerNumber);
    v = io__sys_joy_com_flags;

    pPI = (playerNumber == 0) ? &player1_input : &player2_input;
    pPI->up    = (v & JOY_UP_MASK) ? TRUE : FALSE;
    pPI->down  = (v & JOY_DOWN_MASK) ? TRUE : FALSE;
    pPI->fire1 = (v & JOY_FIRE1_MASK) ? TRUE : FALSE;
}

// Input auto switch.
// if player move a joystick up or down,
// switch input type to "joystick" for that player
void Joystick_CheckInputAutoSwith(void)
{
    Joystick_CheckInputAutoSwithForPlayer(0);

    if(Joystick_IsSecondJoyNeedToBeReaded()) {
        Joystick_CheckInputAutoSwithForPlayer(1);
    }

}

void Joystick_CheckInputAutoSwithForPlayer(byte playerNumber)
{
    byte v;
    player_input* pPI;
    pPI = (playerNumber == 0) ? &player1_input : &player2_input;

    Joystick_SelectJoystickPort(playerNumber);
    v = io__sys_joy_com_flags;
    if(v & JOY_UP_MASK || v & JOY_DOWN_MASK || v & JOY_FIRE1_MASK)
        pPI->input_type = JOY;
}


BOOL Joystick_IsSecondJoyNeedToBeReaded(void)
{
    return (!game.is_one_player_mode || game.game_state == MENU || game.game_state == CREDITS);

}
