#include "include_all.h"

void FLOS_FileSectorList(FLOS_FILE_SECTOR_LIST* const pF, byte sectorOffset, word clusterNumber)
{
    byte *pByte; word *pWord;
    word w;

//    *PTRTO_I_DATA(I_DATA,   byte) = (byte) sectorOffset;
//    *PTRTO_I_DATA(I_DATA+1, word) = (word) clusterNumber;
    SET_BYTE_IN_DATA_AREA(I_DATA,   (byte) sectorOffset);
    SET_WORD_IN_DATA_AREA(I_DATA+1, (word) clusterNumber);

    CALL_FLOS_CODE(KJT_FILE_SECTOR_LIST);

    pF->sectorOffset      = *PTRTO_I_DATA(I_DATA+0, byte);

    w                     = *PTRTO_I_DATA(I_DATA+1, word);
    pF->ptrToSectorNumber = (dword*) w; 

    pF->clusterNumber     = *PTRTO_I_DATA(I_DATA+3, word);

}
