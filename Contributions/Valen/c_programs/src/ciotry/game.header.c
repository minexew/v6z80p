/* Header begin */

#include "debug_print.h"
#include <stdio.h>

#ifdef SDCC
// includes for v6z80p paltform depended code
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

// Start = 96 Stop = 480 (Window Width = 368 pixels with left wideborder Total:384 pixels)
#define X_WINDOW_START                0x6
#define X_WINDOW_STOP                 0xE
// 240 line display (masks last line of tiles)
#define Y_WINDOW_START                0x3
#define Y_WINDOW_STOP                 0xD

#include <base_lib/sprites.h>
//#include <base_lib/keyboard.h>
//#include <base_lib/mouse.h>
#include <base_lib/video_mode.h>
//#include <base_lib/utils.h>

//extern Startup *startup;
#endif


//#include "pool.h"


// malloc --------------------
#include <malloc.h>

void* my_malloc(size_t i);
void my_free(void* memblock);
extern void Host_ExitToOS(int code);

#define malloc	my_malloc
#define free   	my_free







#ifndef SDCC
#include <SDL/SDL.h>
#include <SDL/SDL_gfxPrimitives.h>
#endif

#ifdef SDL_MAJOR_VERSION
#include <assert.h>

SDL_Surface* screen;
SDL_Surface* screen_scaled;

// for FPS counting
//Keep track of the frame count 
int frame = 0; 
//Timer used to calculate the frames per second 
//Timer fps;
#endif

/* Header end */

