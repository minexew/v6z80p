#include "include_all.h"

// Return: FALSE - if hardware error
//         TRUE  - all ok
BOOL FLOS_DirListGetEntry(FLOS_DIR_ENTRY* pEntry)
{
    byte result = FALSE;

    CALL_FLOS_CODE(KJT_DIR_LIST_GET_ENTRY);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(result) {
       pEntry->pFilename = (const char*) ( *PTRTO_I_DATA(I_DATA+1, word) );
       pEntry->file_flag =                 *PTRTO_I_DATA(I_DATA+3, byte);
       pEntry->err_code  =                 *PTRTO_I_DATA(I_DATA+4, byte);
       pEntry->len       =                 *PTRTO_I_DATA(I_DATA+5, dword);
    } else {
//       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
//       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}
