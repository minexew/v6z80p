#include <base_lib/debug_print.h>

static BOOL g_isPrintToSerial = 0;

void DebugPrint_Set_IsPrintToSerial(BOOL isPrintToSerial)
{
    g_isPrintToSerial = isPrintToSerial;
}


BOOL DebugPrint_Get_IsPrintToSerial(void)
{
    return g_isPrintToSerial;
}




