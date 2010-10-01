#include "include_all.h"

BOOL FLOS_ParentDir(void)
{
    byte result = FALSE;

    CALL_FLOS_CODE(KJT_PARENT_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}
