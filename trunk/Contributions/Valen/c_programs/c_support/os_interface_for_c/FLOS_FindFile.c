#include "include_all.h"

BOOL FLOS_FindFile(FLOS_FILE* const pFile, const char* pFileName)
{
    word *pWord;
    byte result = FALSE;

//    *PTRTO_I_DATA(I_DATA, word) = (word) pFileName;
    SET_WORD_IN_DATA_AREA(I_DATA, (word) pFileName);

    CALL_FLOS_CODE(KJT_FIND_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(result) {
       pFile->z80_address = *PTRTO_I_DATA(I_DATA+3, word);
//       pFile->first_block = *PTRTO_I_DATA(I_DATA+2, word);
       pFile->z80_bank    = *PTRTO_I_DATA(I_DATA+2, byte);
       pFile->size        = *PTRTO_I_DATA(I_DATA+5, dword);
       pFile->firstCluster= *PTRTO_I_DATA(I_DATA+9, word);

//    
    } else {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}
