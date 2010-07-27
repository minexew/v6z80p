/*
   Test bitmap chunky pixel mode
           
*/
#include "../../inc/kernal_jump_table.h"
#include "../../inc/v6z80p_types.h"
#include "../../inc/OSCA_hardware_equates.h"
#include "../../inc/macros.h"
#include "../../inc/macros_specific.h"
#include "../../inc/set_stack.h"

#include "../../inc/os_interface_for_c/i_flos.h"

#include <stdlib.h>
#include <string.h>

// Display Window sizes:
// Width  320 pixels
#define X_WINDOW_START                0x8
#define X_WINDOW_STOP                 0xC
// Height 200 lines
#define Y_WINDOW_START                0x5
#define Y_WINDOW_STOP                 0xA



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

    totalVideoPages = 8;      // 64000B / 8KB = 7,8 (calculate how many video pages in 320*200 mode)

    for(i=0; i<totalVideoPages; i++) {
        PAGE_IN_VIDEO_RAM();        
        SET_VIDEO_PAGE(i);
        memset((byte*)(VIDEO_BASE), colorIndex, 0x2000);        // fill 8KB video page
        PAGE_OUT_VIDEO_RAM();
        colorIndex += 1;
    }
}




const word myPalette[] = {
                    RGB2WORD(0, 0, 0),
                    RGB2WORD(255, 255, 255),
                    RGB2WORD(255, 0, 0),
                    RGB2WORD(0, 255, 0),
                    RGB2WORD(0, 0, 255),
                    RGB2WORD(255, 255, 0),
                    RGB2WORD(0, 255, 255),
                    RGB2WORD(255, 0, 255) };

void SetPalette(void)
{

    memcpy((void*) PALETTE, myPalette, sizeof(myPalette));
}

int main(void)
{

    byte asciicode, scancode;

    SetVideoMode();
    SetPalette();
    FillVideoMem();

    FLOS_WaitKeyPress(&asciicode, &scancode);
    FLOS_FlosDisplay();

    return NO_REBOOT;
}