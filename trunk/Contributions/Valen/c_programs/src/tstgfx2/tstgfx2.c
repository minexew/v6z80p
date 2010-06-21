/*
   Basic blit example.
           
*/
#include "../../inc/kernal_jump_table.h"
#include "../../inc/v6z80p_types.h"
#include "../../inc/OSCA_hardware_equates.h"
#include "../../inc/macros.h "
#include "../../inc/macros_specific.h"
#include "../../inc/set_stack.h"

#include "../../inc/os_interface_for_c/i_flos.h"

#include "object_32x28.c"

#include <stdlib.h>
#include <string.h>

// Display Window sizes:
// Width  256 pixels
#define X_WINDOW_START                0xB
#define X_WINDOW_STOP                 0xB
// Height 200 lines
#define Y_WINDOW_START                0x5
#define Y_WINDOW_STOP                 0xA

#define DISPLAY_WIDTH                 256
#define MYOBJECT_WIDTH                32
#define MYOBJECT_HEIGHT               28

#define SOURCE_MODULO                 0
#define DEST_MODULO                   (DISPLAY_WIDTH-MYOBJECT_WIDTH)

word destAddr = 0;

void SetVideoMode(void)
{
    // select bitmap mode + chunky pixel mode (1 byte = 1 pixel)
    mm__vreg_vidctrl = BITMAP_MODE|CHUNKY_PIXEL_MODE;

    // Setup display window size:
    // use y window pos reg
    mm__vreg_rasthi = 0;
    mm__vreg_window = (Y_WINDOW_START<<4)|Y_WINDOW_STOP;
    // Switch to x window pos reg.
    mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;
    mm__vreg_window = (X_WINDOW_START<<4)|X_WINDOW_STOP;

    // initialize datafetch start address HW pointer
    mm__bitplane0a_loc__byte0 = 0;      // [7:0] bits
    mm__bitplane0a_loc__byte1 = 0;      // [15:8] 
    mm__bitplane0a_loc__byte2 = 0;      // [18:16] 

}

void FillVideoMem(void)
{
    byte i, totalVideoPages;
    byte colorIndex = 0;

    totalVideoPages = 16;      // clear 16 x 8KB video pages

    for(i=0; i<totalVideoPages; i++) {
        PAGE_IN_VIDEO_RAM();        
        SET_VIDEO_PAGE(i);
        memset((byte*)(VIDEO_BASE), colorIndex, 0x2000);        // fill 8KB video page
        PAGE_OUT_VIDEO_RAM();
    }
}


// put pixels data to VRAM at 0x10000
void PutMyObjectToVRAM(void)
{
    PAGE_IN_VIDEO_RAM();        
    SET_VIDEO_PAGE(8);
    memcpy((void*)(VIDEO_BASE), object_32x28_pixels, sizeof(object_32x28_pixels));        // copy pixels data 
    PAGE_OUT_VIDEO_RAM();

}


void DoBlit(void)
{
    mm__blit_src_loc = 0;
    mm__blit_src_msb = 1;
    mm__blit_src_mod = SOURCE_MODULO;

    mm__blit_dst_loc = destAddr;
    mm__blit_dst_msb = 0;
    mm__blit_dst_mod = DEST_MODULO;

    mm__blit_misc = BLITTER_MISC_ASCENDING_MODE;
    mm__blit_height = MYOBJECT_HEIGHT - 1;
    mm__blit_width = MYOBJECT_WIDTH - 1;

    BEGINASM()
    nop
    nop
    ENDASM()

    while(mm__vreg_read & BLITTER_LINEDRAW_BUSY);
}




void SetPalette(void)
{

    memcpy((void*) PALETTE, object_32x28_palette, sizeof(object_32x28_palette));
}

int main(void)
{

    BOOL done = FALSE;

    SetVideoMode();
    SetPalette();
    FillVideoMem();
    PutMyObjectToVRAM();

    while(!done) {
        FLOS_WaitVRT();
        DoBlit();
        destAddr++;

        if(io__sys_keyboard_data == 0x76)
            done = TRUE;
    }
    

    return REBOOT;
}


