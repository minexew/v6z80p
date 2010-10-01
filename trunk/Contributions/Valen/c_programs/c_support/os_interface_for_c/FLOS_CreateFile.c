#include "include_all.h"

// Note:
// args default_z80_address and default_z80_bank       
// are irrelevent on FAT16
//
// const word default_z80_address, const byte default_z80_bank
BOOL FLOS_CreateFile(const byte* pFilename)
{
    byte *pByte; word *pWord;
    word default_z80_address = 0;
    byte default_z80_bank = 0;
    byte result = FALSE;

//    *PTRTO_I_DATA(I_DATA,   word) = (word) pFilename;
//    *PTRTO_I_DATA(I_DATA+2, word) = (word) default_z80_address;
//    *PTRTO_I_DATA(I_DATA+4, byte) = (byte) default_z80_bank;
    SET_WORD_IN_DATA_AREA(I_DATA,   (word) pFilename);
    SET_WORD_IN_DATA_AREA(I_DATA+2, (word) default_z80_address;);
    SET_BYTE_IN_DATA_AREA(I_DATA+4, (byte) default_z80_bank;);

    CALL_FLOS_CODE(KJT_CREATE_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}
