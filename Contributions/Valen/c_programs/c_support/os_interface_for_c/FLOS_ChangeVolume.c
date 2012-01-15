#include "include_all.h"

BOOL FLOS_ChangeVolume(BYTE volume)
{
    BYTE b1;
    BYTE *pByte;

    SET_BYTE_IN_DATA_AREA(I_DATA,   volume);
    CALL_FLOS_CODE(KJT_CHANGE_VOLUME);

    b1  = *PTRTO_I_DATA(I_DATA, byte);
    
    return (b1 ? TRUE : FALSE);
}
