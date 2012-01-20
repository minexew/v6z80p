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
#include "base_lib/file_operations.h"



DWORD FileOp_GetFileSize(char *pFilename)
{
    FLOS_FILE myFile;

    if(!FileOp_FLOS_FindFile(&myFile, pFilename)) {
       return -1;
    }

    return myFile.size;
}

BOOL FileOp_LoadFileToBuffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
{
    FLOS_FILE myFile;
    BOOL r;

    r = FileOp_FLOS_FindFile(&myFile, pFilename);
    if(!r) {
       return FALSE;
    }


    FLOS_SetLoadLength(len);
    FLOS_SetFilePointer(file_offset);

    r = FileOp_FLOS_ForceLoad( buf, bank );
    if(!r) {       
       return FALSE;
    }

    return TRUE;
}


// wrappers for FLOS funcs, with added diagnostic output
BOOL FileOp_FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename)
{
    BOOL r;

    
    r = FLOS_FindFile(pFile, pFilename);
    
    if(!r) {
       DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}

BOOL FileOp_FLOS_ForceLoad(const byte* address, const byte bank)
{
    BOOL r;

    
    r = FLOS_ForceLoad(address, bank);
    
    if(!r) {
       DiagMessage("ForceLoad failed: ", "");
       return FALSE;
    }

    return TRUE;
}







