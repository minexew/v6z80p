/* 
The x and y struct members are in local coordinate system.
(not hardware)
The origin (x=0,y=0) of this local coordinate system is in the top left
corner of your display window.
(I think, it's more easy to manipulate sprite coordinates in local coordinate system.)
*/

#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <string.h>

#include <base_lib/sprites.h>




struct {
    WORD x_window_start;
    WORD y_window_start;
} sprite_regs_buffer_data;

/*
static inline void set_sprite_regs_hw(byte sprite_number, byte x, byte misc, byte y, byte sprite_definition_number)
{
    byte* p;

    p = (byte *) SPR_REGISTERS + (sprite_number*4);
    *p =  x;                            p++;
    *p =  misc;                         p++;
    *p =  y;                            p++;
    *p =  sprite_definition_number;

}
*/

// buffer for sprite registers
byte spritesRegsBuffer[127*4];               // 127 sprites (4 bytes per sprite)

void SpritesRegsBuffer_SetDisplayWindowParams(WORD x_window_start, WORD y_window_start)
{

    sprite_regs_buffer_data.x_window_start = x_window_start;
    sprite_regs_buffer_data.y_window_start = y_window_start;
}

// Set sprite regs to system memory buffer.
// 
// The sprite register writes go to buffer in
// system memory (not directly to hardware sprite registers). 
// This will prevent any sprite flickering/tearing.
void SpritesRegsBuffer_SetSpriteRegs(sprite_regs_t* r)
{
    byte reg_misc;
    int x, y;
    byte* p;


    // convert X coord to hardware sprite coord
    x =  r->x + sprite_regs_buffer_data.x_window_start*16;
    //x =  x + 16;  // + wide left border
    // convert Y coord to hardware sprite coord
    y =  r->y + sprite_regs_buffer_data.y_window_start*8 + 1;

    // build "misc" reg
    reg_misc = GET_WORD_9TH_BIT(x)                                  |
               GET_WORD_9TH_BIT(y) << 1                             |
               GET_WORD_9TH_BIT(r->sprite_definition_number) << 2      |
               ((r->x_flip&1) << 3)                                    |
               (r->height << 4)
               ;
               
    //set_sprite_regs_hw(r->sprite_number, (byte)x, reg_misc, (byte)y, (byte)r->sprite_definition_number);
    p = spritesRegsBuffer + (r->sprite_number*4);
    *p++ =  (byte)x;
    *p++ =  reg_misc;
    *p++ =  (byte)y;
    *p   =  (byte)r->sprite_definition_number;

}

// Copy buffer to hardware sprite registers.
// (must be called right in the beginning of the frame, right after WaitVRT() )
void SpritesRegsBuffer_CopyToHardwareRegs(void)
{
    // this is a time critical operation, disable interrupts
    DI();
    memcpy((void*)SPR_REGISTERS, spritesRegsBuffer, sizeof(spritesRegsBuffer));
    EI();
}

void SpritesRegsBuffer_Clear(void)
{    
    memset(spritesRegsBuffer, 0, sizeof(spritesRegsBuffer));    
}
