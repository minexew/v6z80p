#include "include_all.h"

BOOL FLOS_ChangeDir(const char* pDirName)
{
    word *pWord;
    byte result = FALSE;

    SET_WORD_IN_DATA_AREA(I_DATA, (word) pDirName);

    CALL_FLOS_CODE(KJT_CHANGE_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}

