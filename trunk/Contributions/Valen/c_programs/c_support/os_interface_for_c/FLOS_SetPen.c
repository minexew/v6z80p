#include "include_all.h"

void FLOS_SetPen(byte color)
{
    byte *pByte;

//    *PTRTO_I_DATA(I_DATA,   byte) = color;
    SET_BYTE_IN_DATA_AREA(I_DATA, (byte) color);

    CALL_FLOS_CODE(KJT_SET_PEN);
}
