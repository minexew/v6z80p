#include "include_all.h"

// len = 24 bit length
BOOL FLOS_WriteBytesToFile(const byte* pFilename, byte* address, const byte bank, const dword len)
{
    byte *pByte; word *pWord; dword *pDword;
    byte result = FALSE;

//    *PTRTO_I_DATA(I_DATA,   word)  = (word) pFilename;
//    *PTRTO_I_DATA(I_DATA+2, word)  = (word) address;
//    *PTRTO_I_DATA(I_DATA+4, byte)  = bank;
//    *PTRTO_I_DATA(I_DATA+5, dword) = len;
    SET_WORD_IN_DATA_AREA (I_DATA,   (word)  pFilename);
    SET_WORD_IN_DATA_AREA (I_DATA+2, (word)  address);
    SET_BYTE_IN_DATA_AREA (I_DATA+4,         bank);
    SET_DWORD_IN_DATA_AREA(I_DATA+5,         len);

    CALL_FLOS_CODE(KJT_WRITE_BYTES_TO_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 

}
