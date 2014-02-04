//#include <stdlib.h>
#include <stdio.h>
#include "debug_print.h"

#ifndef SDCC
#include <SDL/SDL.h>
#endif

#include "game.h"

#ifdef SDL_MAJOR_VERSION
//#include "resize/resize.h"        // this gives segment fault, when resizing surface
//#include "SDL_gfx/SDL_rotozoom.h"
#include <assert.h>

SDL_Surface* screen;
SDL_Surface* screen_scaled;

// for FPS counting
//Keep track of the frame count 
int frame = 0; 
//Timer used to calculate the frames per second 
//Timer fps;
#endif

#ifdef SDCC

#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>
#endif



struct {
	unsigned char isPrintToSerial;
} program;

void Program_Set_IsPrintToSerial(unsigned char val)
{
    program.isPrintToSerial = val;
}


#ifdef SDCC
extern void ValenPatch_init_virt_tables(void);
int main(void)
#else
int main(int argc, char *argv[])
#endif
{
    Startup *startup;
    
    DEBUG_PRINT("CIOTRY started...\n");
    ValenPatch_init_virt_tables();
    
    startup = Startup_New();    
    
//return 0;    //
    Startup_Run(startup);
    
    return 0;
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
