/*			- putchar.c -

    The ANSI C "putchar" for v6z80p and FLOS.


*/

#include <stdio.h>
#include <intrz80.h>
// #pragma language=extended

// #include <kernal_jump_table.h>
// #include <v6z80p_types.h>
// #include <OSCA_hardware_equates.h>
#include <os_interface_for_c/i_flos.h>




unsigned char program_isPrintToSerial = 0;
    

int putchar(int val)
{

    unsigned char str[2];
    unsigned char c;
    c = val;

    str[0] = str[1] = 0;
    str[0] = c;

    

    if(program_isPrintToSerial) {
        if(c == '\n')   { FLOS_SerialTxByte(0xA); FLOS_SerialTxByte(0xD); }
        else            FLOS_SerialTxByte(c);
    } else {
        // if(c == '\n')   FLOS_PrintStringLFCR("");
        // else            FLOS_PrintString(str);
    }

    return val;
}
