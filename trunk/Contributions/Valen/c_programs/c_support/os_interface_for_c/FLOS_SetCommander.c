#include "include_all.h"

// pCmdLine - ptr to string up to 40 bytes
void FLOS_SetCommander(const char* pCmdLine)
{
    word *pWord;

    SET_WORD_IN_DATA_AREA(I_DATA, (word) pCmdLine);

    CALL_FLOS_CODE(KJT_SET_COMMANDER);


}

