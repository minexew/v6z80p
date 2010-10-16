/*
Minimal example.
Print string "Hello, world" to FLOS output and exit.

-------------
*/

#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>


int main(void)
{

    FLOS_PrintString("Hello, world!");

    return NO_REBOOT;
}
