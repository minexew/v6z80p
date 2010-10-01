#include "include_all.h"

// Return: 0x24 - Reached end of directory
//         0    - all ok
byte FLOS_DirListNextEntry(void)
{
    byte result;

    CALL_FLOS_CODE(KJT_DIR_LIST_NEXT_ENTRY);

    result = *PTRTO_I_DATA(I_DATA, byte);

    return result; 
}
