#include "include_all.h"

dword FLOS_GetTotalSectors(void)
{
    CALL_FLOS_CODE(KJT_GET_TOTAL_SECTORS);

    return  *PTRTO_I_DATA(I_DATA, dword);
}
