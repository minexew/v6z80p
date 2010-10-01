#include "include_all.h"

BOOL FLOS_ForceLoad(const byte* address, const byte bank)
{
    byte *pByte; word *pWord;
    byte result = FALSE;

//    *PTRTO_I_DATA(I_DATA,   word) = (word) address;
//    *PTRTO_I_DATA(I_DATA+2, byte) = (byte) bank;
    SET_WORD_IN_DATA_AREA(I_DATA,   (word) address);
    SET_BYTE_IN_DATA_AREA(I_DATA+2, (byte) bank);

    CALL_FLOS_CODE(KJT_FORCE_LOAD);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}
