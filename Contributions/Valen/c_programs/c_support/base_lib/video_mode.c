#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <os_interface_for_c/i_flos.h>

#include <string.h>

#include "base_lib/video_mode.h"

// Setup display window size
void VideoMode_SetupDisplayWindowSize(byte window_x_start,  byte window_x_stop,
			              byte window_y_start,  byte window_y_stop)
{

    // use y window pos reg
    mm__vreg_rasthi = 0;
    mm__vreg_window = (window_y_start<<4)|window_y_stop;
    // Switch to x window pos reg.
    mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;
    mm__vreg_window = (window_x_start<<4)|window_x_stop;
}



// Set tilemap mode.
//
// For example:
// additionalBits_vidctrl can be: 
// WIDE_LEFT_BORDER, DUAL_PLAY_FIELD, TILE_SIZE_8x8, ...
// additionalBits_ext_vidctrl can be:
// EXTENDED_TILE_MAP_MODE, ...
void VideoMode_InitTilemapMode(byte additionalBits_vidctrl, byte additionalBits_ext_vidctrl)
{
    // select tile mode (OR'ed with additional bits)
    mm__vreg_vidctrl = TILE_MAP_MODE | additionalBits_vidctrl;

    // set extended bits of tile mode
    mm__vreg_ext_vidctrl = additionalBits_ext_vidctrl;



    // reset to zero , vertical scroll value (for both playfields)
    mm__vreg_yhws_bplcount = 0;         //pf A
    mm__vreg_yhws_bplcount = 0x80 | 0;  //pf B
    // reset to zero , horizontal scroll value (for both playfields)
    mm__vreg_xhws = 0;       //pf A and pf B

}


// Fill Playfield A 
// (Buffers 0 and 1)
//
// fillSize - max is 0x800
// playfieldNumber: 0 pf A, 1 pf B
void TileMap_8x8_FillPlayfield(BYTE playfieldNumber, WORD offset, WORD fillSize, WORD tileNumber)
{
    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE + playfieldNumber);
    memset((byte*)(VIDEO_BASE       + offset),   (byte)tileNumber,           fillSize); //LSB
    memset((byte*)(VIDEO_BASE+0x800 + offset),   (byte)(tileNumber >> 8),    fillSize); //MSB
    PAGE_OUT_VIDEO_RAM();
}
