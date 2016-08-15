#ifndef DEBUG_PRINT_H
#define DEBUG_PRINT_H

#include <v6z80p_types.h>

#define DEBUGPRINT(...)     DebugPrint_Set_IsPrintToSerial(TRUE);   \
                            printf(__VA_ARGS__);                    \
                            DebugPrint_Set_IsPrintToSerial(FALSE);

void DebugPrint_Set_IsPrintToSerial(BOOL isPrintToSerial);
BOOL  DebugPrint_Get_IsPrintToSerial(void);



#endif /* DEBUG_PRINT_H */

