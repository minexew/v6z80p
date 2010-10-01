#include "include_all.h"

// Out: pASCII, pScancode will be used to store results
BOOL FLOS_GetKeyPress(byte* pASCII, byte* pScancode)
{

    CALL_FLOS_CODE(KJT_GET_KEY);

    *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
    *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);

    // if scancode is 0, return FALSE (no scancode in buffer)
    return (*pScancode == 0) ?  FALSE : TRUE;
}
