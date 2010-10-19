// This source file is always linked to user program.

#define V6Z80P_EXTERN                   // define this macro as nothing, to compile as library
#include <os_interface_for_c/i_flos.h>

// allocate memory for globals
#define I_FLOS_GLOBALS_EXTERN
#include "globals.c"

#include <string.h>





extern char* flos_cmdline;
extern char  flos_spawn_cmd[SPAWN_CMD_LINE_BUFFER_LEN];


void MarkFrameTime(ushort color)
{
   ushort* p = (ushort*) PALETTE;
   *p = color;

}


// ---------------------------------------------
byte FLOS_GetLastError(void) 
{
   return g_flos_lasterror;
}


// Stop execution of program and exit to FLOS immediately 
void FLOS_ExitToFLOS(void) 
{
    BEGINASM()
    xor  a        ; program exit code is 0 (no reboot)
    ld   l,a      
    jp   _exit
    ENDASM()
}



// Helpers --------------------------------------
void FLOS_PrintStringLFCR(const char* string)
{
    FLOS_PrintString(string);
    FLOS_PrintString(PS_LFCR);
}


// Get ptr to FLOS cmd line 
// The line is zero terminated.
char* FLOS_GetCmdLine(void)
{
    return flos_cmdline;
}


// Set spawn command line (which executed by FLOS at program exit)
BOOL FLOS_SetSpawnCmdLine(const char* line)
{
    if(strlen(line) >= SPAWN_CMD_LINE_BUFFER_LEN)
        return FALSE;

    flos_spawn_cmd[0] = 0;              // reset string len (in buffer) len to 0
    strcat(flos_spawn_cmd, line);
    return TRUE;
}