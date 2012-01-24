#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <base_lib/blit.h>

// TODO: change modulo from BYTE to WORD and setup bits in misc reg
void DoBlit(BLITTER_PARAMS *bp)
{
    // we need to use volatile temp vars to disable compiler optimization
    //
    volatile WORD w_tmp;
    volatile BYTE b_tmp;

    w_tmp = bp->src_addr << 3;      mm__blit_src_loc = w_tmp;
    b_tmp = bp->src_addr >> 13;     mm__blit_src_msb = b_tmp;
    mm__blit_src_mod = bp->src_mod;

    w_tmp = bp->dest_addr << 3;     mm__blit_dst_loc = w_tmp;
    b_tmp = bp->dest_addr >> 13;    mm__blit_dst_msb = b_tmp;
    mm__blit_dst_mod = bp->dest_mod;

    mm__blit_misc = bp->misc;
    mm__blit_height = bp->height;   // - 1;
    mm__blit_width  = bp->width;    //  - 1;

    BEGINASM();
    nop
    nop
    ENDASM();

    while(mm__vreg_read & BLITTER_LINEDRAW_BUSY);



}
