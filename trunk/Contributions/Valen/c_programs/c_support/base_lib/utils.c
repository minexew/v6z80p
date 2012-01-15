#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <os_interface_for_c/i_flos.h>

#include <string.h>
#include <stdlib.h>

#include "base_lib/utils.h"

BOOL Utils_Check_FLOS_Version(word req_version)
{
    word os_version_word, hw_version_word;

    FLOS_GetVersion(&os_version_word, &hw_version_word);
    if(os_version_word < req_version)
        return FALSE;


    return TRUE;
}



void DiagMessage(const char* pMsg, const char* pFilename)
{
    char buffer[32];
    byte err;
    err = FLOS_GetLastError();

    FLOS_PrintString(pMsg);
    FLOS_PrintString(pFilename);

    FLOS_PrintString(" OS_err: $");
    _uitoa(err, buffer, 16);
    FLOS_PrintString(buffer);
    FLOS_PrintString(PS_LFCR);
    
}

void PrintWORD(WORD w, BYTE radix)
{
    BYTE buffer[30];

    _uitoa(w, buffer, radix);
    FLOS_PrintString(buffer);
}
