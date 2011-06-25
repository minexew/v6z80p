#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>

#include <stdlib.h>
#include <string.h>

#include "sprites.h"
#include "pong.h"
#include "obj_bat.h"
#include "obj_ball.h"
#include "disk_io.h"




void initgraph(void)
{
    // select tile mode/pfA:MapBufferSelect A
    mm__vreg_vidctrl = TILE_MAP_MODE|WIDE_LEFT_BORDER;       //|DUAL_PLAY_FIELD;

    // select extended tile mode
    mm__vreg_ext_vidctrl = EXTENDED_TILE_MAP_MODE;

    // use y window pos reg
    mm__vreg_rasthi = 0;

    mm__vreg_window = (Y_WINDOW_START<<4)|Y_WINDOW_STOP;
    // Switch to x window pos reg.
    mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;

    mm__vreg_window = (X_WINDOW_START<<4)|X_WINDOW_STOP;

    clear_sprite_regs();


    // reset to zero , vertical scroll value (for both playfields)
    mm__vreg_yhws_bplcount = 0;         //pf A
    mm__vreg_yhws_bplcount = 0x80 | 0;  //pf B
    // reset to zero , horizontal scroll value (for both playfields)
    mm__vreg_xhws = 0;       //pf A and pf B

    game.isFLOSVideoMode = FALSE;

}

/*
void Sprites_EnableSprites(BYTE flags1)
{
    // Enable sprites
    mm__vreg_sprctrl = flags1 | SPRITE_ENABLE|DOUBLE_BUFFER_SPRITE_REGISTER_MODE | MATTE_MODE_ENABLE;
}
*/


void clear_sprite_regs(void)
{
    byte* p;

    for(p = (byte*)SPR_REGISTERS; p < (byte*)(SPR_REGISTERS+0x200); p++)
        *p = 0;

}

// clears 64 sprite registers (shadow registers)
void clear_shadow_sprite_regs(void)
{
    byte* p;

    p = (byte*)(SPR_REGISTERS + game.shadow_sprite_register_bank*64*4);
    memset(p, 0, 0x100);

}

void DrawBat(int x1,int y1,int x2,int y2)
{
    byte num_bat;
    byte spr_height;
    word spr_def = 2;   /* sprite_definition_number*/
    BOOL x_flip;
    GameObjBat *p;
    x2;y2;



    // which bat to draw ? (left or right)
    if(x1<160) {
        num_bat = 0; x_flip = TRUE;  p = &batA;
    } else {
        num_bat = 1; x_flip = FALSE; p = &batB;
    }

/*
    if(p->state == DYING) {
        // put 32x32 BANG1 in place of Bat
        spr_height = 2;
        spr_def = SPRITE_DEF_NUM_BANG1 + ((p->dying_time/8)*2);

        set_sprite_regs(SPRITE_NUM_BANG1,   x1-4    ,  y1, spr_height, spr_def      , FALSE);
        set_sprite_regs(SPRITE_NUM_BANG1+1, x1-4 +16,  y1, spr_height, spr_def + 7*2, FALSE);
    }
*/

    // set sprite data
    if(p->state != NORMAL)
        y1 = SPRITE_Y_OFFSCREEN;

    spr_height = 2;
    set_sprite_regs(num_bat, x1-4,  y1, spr_height, spr_def, x_flip, FALSE);

}

void DrawBall(int x_center,int y_center)
{
    byte spr_height = 1;
    word spr_def = 0;   /* sprite_definition_number*/

    if(ball1.state == DYING)
        spr_def = SPRITE_DEF_NUM_DYING_BALL + (ball1.dying_time/8);

     // calc sprite coords
     x_center -= 8;
     y_center -= 8;
//    set sprite data
    if(ball1.state == DIE)
        y_center = SPRITE_Y_OFFSCREEN;

    set_sprite_regs(SPRITE_NUM_BALL, x_center,  y_center, spr_height, spr_def, FALSE, FALSE);

}




// set sprite regs to shadow sprite bank
/*static inline*/ void set_sprite_regs_hw(byte sprite_number, byte x, byte misc, byte y, byte sprite_definition_number)
{
    byte* p;


    if (game.shadow_sprite_register_bank == 0)
        p = (byte *) SPR_REGISTERS;
    else
        p = (byte *) (SPR_REGISTERS + 0x100);     // add offset of shadow sprite register bank

    p += ((sprite_number*4));
    *p =  x;                            p++;
    *p =  misc;                         p++;
    *p =  y;                            p++;
    *p =  sprite_definition_number;

}


void set_sprite_regs(byte sprite_number, int x, int y, byte height, word sprite_definition_number, BOOL x_flip, BOOL isEnableMatteMode)
{
    byte reg_misc = 0;


    // convert X coord to hardware sprite coord
    x =  x + X_WINDOW_START*16;
    x =  x + 16;  // + wide left border
    // convert Y coord to hardware sprite coord
    y =  y + Y_WINDOW_START*8 + 1;

    // build "misc" reg
    reg_misc = GET_WORD_9TH_BIT(x)                                  |
               GET_WORD_9TH_BIT(y) << 1                             |
               GET_WORD_9TH_BIT(sprite_definition_number) << 2      |
               ((x_flip&1) << 3)                                    |
               (height << 4)
               ;
    if(isEnableMatteMode) reg_misc |= 0x40;
    set_sprite_regs_hw(sprite_number,
                             (byte)x,
                             reg_misc,
                             (byte)y
                             ,(byte)sprite_definition_number);

}


// ------
typedef struct {
    // user params
    byte sprite_number;
    int x, y;
    byte height;
    byte sprite_definition_number;
    BOOL x_flip;

    // private
    byte reg_misc;

} SpriteReg;
SpriteReg spr_reg;

void set_sprite_regs_optimized(void)
{
    byte* p;

    // convert X coord to hardware sprite coord
    spr_reg.x += X_WINDOW_START*16;
    spr_reg.x +=  16;  // + wide left border
    // convert Y coord to hardware sprite coord
    spr_reg.y +=  Y_WINDOW_START*8 + 1;

    // TODO: add 9th bit of sprite definition
    spr_reg.reg_misc =
               GET_WORD_9TH_BIT(spr_reg.x)      |
               GET_WORD_9TH_BIT(spr_reg.y) << 1 |
               ((spr_reg.x_flip&1) << 3)        |
               (spr_reg.height << 4)
               ;
/*
    set_sprite_regs_hw(sprite_number,
                             (byte)x,
                             reg_misc,
                             (byte)y
                             ,sprite_definition_number);
*/
    // with respect to double buffering of sprite registers
    p = (byte*)(SPR_REGISTERS + (spr_reg.sprite_number*4)
                              + (game.shadow_sprite_register_bank*0x100U));       // add offset of shadow sprite register bank

    *p =  (byte) spr_reg.x;                     p++;
    *p =         spr_reg.reg_misc;              p++;
    *p =  (byte) spr_reg.y;                     p++;
    *p =         spr_reg.sprite_definition_number;

}

// ------

// destSpriteMem - destination linear address (0 - 128KB)  of sprite RAM
//                 (must be on 4KB bound, just to simplify function implementation)
BOOL Sprites_LoadSprites(const char *pFilename, DWORD destSpriteMem)
{

    byte sprite_page = destSpriteMem/0x1000;


    // load by 4KB chunks (using chunk loader)
    ChunkLoader_Init(pFilename, (byte*)BUF_FOR_LOADING_SPRITES_4KB, PONG_BANK);

    while(!ChunkLoader_IsDone()) {
        if(!ChunkLoader_LoadChunk())
            return FALSE;

        // copy from mem buf to sprite mem
        PAGE_IN_SPRITE_RAM();
        SET_SPRITE_PAGE(sprite_page);
        memcpy((byte*)SPRITE_BASE, (byte*)BUF_FOR_LOADING_SPRITES_4KB, 0x1000);
        PAGE_OUT_SPRITE_RAM();

        sprite_page++;
    }

    return TRUE;

}




void wait_y_window(void)
{
    byte b;

          /*b = mm__vreg_read;
          b = mm__vreg_read;
          b = mm__vreg_read;*/

          /*READ_REG(VREG_READ, b);
          READ_REG(VREG_READ, b);
          READ_REG(VREG_READ, b);*/

      do{
          b = mm__vreg_read;
      } while( (b&4) == 0 );
}
