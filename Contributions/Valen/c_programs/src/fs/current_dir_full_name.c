#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

#include <stdlib.h>
#include <string.h>

#include "display.h"
#include "current_dir_full_name.h"






BYTE currentDirFullName[SCREEN_WIDTH/8 - 1];        // string
BYTE* SetupCurrentDirFullName(void)
{
    const char* dir_name;
    WORD        dir_name_len;
    const char* dest     = currentDirFullName + sizeof(currentDirFullName) - 1;      // Last byte minus 1. Last byte, in currentDirFullName, must be zero.

    FLOS_StoreDirPosition();
    memset(currentDirFullName, 0, sizeof(currentDirFullName));

    do {
        dir_name     = FLOS_GetDirName();
        dir_name_len = strlen(dir_name);

        if(dest - dir_name_len - 1 >= currentDirFullName)   //  (reserve one byte for '/' char in dest)
            dest = dest - dir_name_len - 1;
        else break;

        memcpy(dest + 1, dir_name, dir_name_len);
        memcpy(dest,     "/", 1);

    } while(FLOS_ParentDir());


    FLOS_RestoreDirPosition();
    return dest;
}
