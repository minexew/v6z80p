#include "include_all.h"

void FLOS_SerialTxByte(BYTE byte_to_send)
{
    //BYTE b1;
    BYTE *pByte;

    SET_BYTE_IN_DATA_AREA(I_DATA,   byte_to_send);
    CALL_FLOS_CODE(KJT_SERIAL_TX_BYTE);

    //b1  = *PTRTO_I_DATA(I_DATA, byte);
    
    //return (b1 ? TRUE : FALSE);
}
