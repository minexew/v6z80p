#include "include_all.h"

// 
byte FLOS_ReadSysramFlat(const dword address)
{
    byte result = 0;
    dword *pDword;

    SET_DWORD_IN_DATA_AREA(I_DATA, (dword) address);

    CALL_FLOS_CODE(KJT_READ_SYSRAM_FLAT);
    result = *PTRTO_I_DATA(I_DATA,   byte);

    return result;
}
