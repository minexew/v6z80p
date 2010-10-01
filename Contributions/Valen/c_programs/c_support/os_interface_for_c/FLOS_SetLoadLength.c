#include "include_all.h"

void FLOS_SetLoadLength(const dword len)
{
    dword *pDword;

//    *PTRTO_I_DATA(I_DATA, dword) = (dword) len;
    SET_DWORD_IN_DATA_AREA(I_DATA, (dword) len);

    CALL_FLOS_CODE(KJT_SET_LOAD_LENGTH);
}
