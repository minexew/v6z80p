#include "include_all.h"

// Return: cluster pointed at by current directory
WORD FLOS_GetDirCluster(void)
{
    word w;

    CALL_FLOS_CODE(KJT_GET_DIR_CLUSTER);

    w      = *PTRTO_I_DATA(I_DATA, word);
    return w;
}
