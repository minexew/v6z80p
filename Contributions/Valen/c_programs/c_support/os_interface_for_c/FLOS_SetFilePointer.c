#include "include_all.h"

void FLOS_SetFilePointer(const dword p)
{
    dword *pDword;

//    *PTRTO_I_DATA(I_DATA, dword) = (dword) p;
    SET_DWORD_IN_DATA_AREA(I_DATA, (dword) p);

    CALL_FLOS_CODE(KJT_SET_FILE_POINTER);
}
