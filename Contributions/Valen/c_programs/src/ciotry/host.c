//#include <stdlib.h>
#include <stdio.h>
//#include <malloc.h>
#include "debug_print.h"

#ifndef SDCC
#include <SDL/SDL.h>
#endif

#include "game.h"



#ifdef SDCC

#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>

extern void _sdcc_heap_init (void);
#endif



struct {
	unsigned char isPrintToSerial;
} program;

void Program_Set_IsPrintToSerial(unsigned char val)
{
    program.isPrintToSerial = val;
}

//void* g_enginePtr;
Startup *startup;

extern void ValenPatch_init_virt_tables(void);

#ifdef SDCC
extern char _sdcc_heap_start;
extern char _sdcc_heap_end;

int main(void)
#else
int main(int argc, char *argv[])
#endif
{
#ifdef SDCC
    unsigned int heap_size = &_sdcc_heap_end - &_sdcc_heap_start;
#endif
    
    DEBUG_PRINT("CIOTRY started...\n");
    ValenPatch_init_virt_tables();
#ifdef SDCC
    _sdcc_heap_init();
    DEBUG_PRINT("SDCC heap size %i \n",heap_size);
#endif

    startup = Startup_New();    
        
//return 0;    //
    Startup_Run(startup);
    
    return 0;
}

void Host_ExitToOS(int code)
{
#ifdef SDCC
    FLOS_ExitToFLOS();
#else
    exit(1);
#endif
}

#ifdef SDCC
// -------------- 
// 
void putchar(char c)
{
    BYTE str[2];

    str[0] = str[1] = 0;
    str[0] = c;

    if(program.isPrintToSerial) {
        if(c == '\n')   { FLOS_SerialTxByte(0xA); FLOS_SerialTxByte(0xD); }
        else            FLOS_SerialTxByte(c);
    } else {
        if(c == '\n')   FLOS_PrintStringLFCR("");
        else            FLOS_PrintString(str);
    }


}
#endif
