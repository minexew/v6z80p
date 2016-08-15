#ifndef _MY_TYPES_
#define _MY_TYPES_




#if defined(__GNUC__) || defined(__GNUC__)
#define PC
#endif


#if defined(SDCC) || defined(__SDCC)
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros_specific.h>
#include <macros.h>

#include <os_interface_for_c/i_flos.h>
#endif


// PC
#ifdef PC
#define BOOL 	unsigned char
#define FALSE 	0
#define TRUE 	1
#endif





typedef struct GfxRect
{
    unsigned int x, y;
    unsigned int w, h;
} GfxRect;


typedef struct GfxPoint
{
    unsigned int x;
    unsigned int y;
} GfxPoint;




#endif /* _MY_TYPES_ */