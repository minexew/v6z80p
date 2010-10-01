#include "include_all.h"

// Get OS version word and Hardware version word
void FLOS_GetVersion(word* os_version_word, word* hw_version_word)
{

    CALL_FLOS_CODE(KJT_GET_VERSION);

    *os_version_word = *PTRTO_I_DATA(I_DATA+0, word);
    *hw_version_word = *PTRTO_I_DATA(I_DATA+2, word);

}
