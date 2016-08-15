#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <os_interface_for_c/i_flos.h>

// #include <base_lib/mouse.h>


unsigned char program_isPrintToSerial = 0;




// This is default implementation ot putchar for v6z80p (FLOS).
// If you want you own code, instead of this default putchar func.
// When copy'n'paste putchar() func code to you program source code and change func code, as u wish.
int putchar(int arg)
{
    unsigned char c = arg;
    BYTE str[2];

    str[0] = str[1] = 0;
    str[0] = c;

    if(program_isPrintToSerial) {
        if(c == '\n')   { FLOS_SerialTxByte(0xA); FLOS_SerialTxByte(0xD); }
        else            FLOS_SerialTxByte(c);
    } else {
        if(c == '\n')   FLOS_PrintStringLFCR("");
        else            FLOS_PrintString(str);
    }


}