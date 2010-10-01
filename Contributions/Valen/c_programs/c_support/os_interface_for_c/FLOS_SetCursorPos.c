#include "include_all.h"

BOOL FLOS_SetCursorPos(byte x, byte y)
{
    byte *pByte;
    byte result = FALSE;

//    *PTRTO_I_DATA(I_DATA,   byte) = (byte) x;
//    *PTRTO_I_DATA(I_DATA+1, byte) = (byte) y;
    SET_BYTE_IN_DATA_AREA(I_DATA,   (byte) x);
    SET_BYTE_IN_DATA_AREA(I_DATA+1, (byte) y);

    CALL_FLOS_CODE(KJT_SET_CURSOR_POSITION);

    result = *PTRTO_I_DATA(I_DATA, byte);

    return result; 
}
