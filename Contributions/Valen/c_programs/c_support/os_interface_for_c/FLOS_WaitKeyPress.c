#include "include_all.h"

// Out: pASCII, pScancode will be used to store results
void FLOS_WaitKeyPress(byte* pASCII, byte* pScancode)
{

    CALL_FLOS_CODE(KJT_WAIT_KEY_PRESS);

    *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
    *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);

}
