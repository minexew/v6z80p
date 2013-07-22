//#include <stdlib.h>
#include <stdio.h>

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


void* pool_malloc(unsigned int size);
void  pool_free(void* p);
#define malloc pool_malloc
#define free   pool_free
#include "game.c"
#undef malloc
#undef free

#include "pool.c"


#ifdef SDCC
int main(void)
#else
int main(int argc, char *argv[])
#endif
{
    Startup *startup;
    
    ValenPatch_init_virt_tables();
    
    startup = Startup_New();
    Startup_Run(startup);
    
    return 0;
}


