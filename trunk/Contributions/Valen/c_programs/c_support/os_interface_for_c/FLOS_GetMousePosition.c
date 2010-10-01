#include "include_all.h"

// FLOS v571+
// Return: FALSE - the mouse driver was not enabled
//         TRUE  - all ok
BOOL FLOS_GetMousePosition(MouseStatus* ms)
{
    byte result;
    CALL_FLOS_CODE(KJT_GET_MOUSE_POSITION);

    result      = *PTRTO_I_DATA(I_DATA+0, byte);
    ms->PosX    = *PTRTO_I_DATA(I_DATA+1, word);
    ms->PosY    = *PTRTO_I_DATA(I_DATA+3, word);
    ms->buttons = *PTRTO_I_DATA(I_DATA+5, byte);

    return result;
}
