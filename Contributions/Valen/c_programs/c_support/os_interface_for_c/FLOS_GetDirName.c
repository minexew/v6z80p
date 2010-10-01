#include "include_all.h"

// Return: pointer to name of current dir (NULL if was error)
// Note: copy returned string before carrying out any other disk operations
// as the pointer will be in the sector buffer which obviously changes
const char* FLOS_GetDirName(void)
{
    byte result;
    word w;

    CALL_FLOS_CODE(KJT_GET_DIR_NAME);

    result = *PTRTO_I_DATA(I_DATA,   byte);
    w      = *PTRTO_I_DATA(I_DATA+1, word);

    return (result ? (const char*)w : NULL);
}
