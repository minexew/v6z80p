#include "include_all.h"

void FLOS_PrintString(const char* string)
{
    word *pWord;

//    *PTRTO_I_DATA(I_DATA, word) = (word) string;
    SET_WORD_IN_DATA_AREA(I_DATA, (word) string);

    CALL_FLOS_CODE(KJT_PRINT_STRING);

}
