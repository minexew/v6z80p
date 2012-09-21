#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

#include <stdlib.h>
#include <string.h>


#include "util.h"
#include "pong.h"
#include "disk_io.h"
#include <base_lib/resource.h>
#include "handle_resource_error.h"


void DiagMessage(const char* pMsg, const char* pFilename)
{
    byte err;

    err = FLOS_GetLastError();

//    if(game.isFLOSVideoMode) {
        /*FLOS_FlosDisplay();
        game.isFLOSVideoMode = TRUE;*/

        FLOS_PrintString(pMsg);
        FLOS_PrintString("'");
        FLOS_PrintString(pFilename);
        FLOS_PrintString("'");

        FLOS_PrintString(" OS_err: $");
        _uitoa(err, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintString(PS_LFCR);
//    }



}

BOOL Util_LoadPalette(const char* pFilename)
{

    if(!Resource_LoadFileToBuffer(pFilename, 0, (byte*)0x0000, 0x200, 0))
        return Handle_Resource_Error();

    *((ushort*)PALETTE) = 0;
    return TRUE;

}


void Sys_ClearIRQFlags(byte flags)
{
    io__sys_clear_irq_flags = flags;
}


byte GetR(void)  __naked
{
    __asm;
    push af
    ld a,r
    ld l,a
    pop af
    ret
    __endasm;

}
