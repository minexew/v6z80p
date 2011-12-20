/*
   Basic sprites example.
           
*/
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>


#include <stdlib.h>
#include <string.h>

// Display Window sizes:
// Width  320 pixels
#define X_WINDOW_START                0x8
#define X_WINDOW_STOP                 0xC
// Height 200 lines
#define Y_WINDOW_START                0x5
#define Y_WINDOW_STOP                 0xA



#include <base_lib/sprites.h>


unsigned char Img1[16 * 16];
unsigned char Img2[16 * 16];

word screenX;

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

    // Enable sprites
    mm__vreg_sprctrl = SPRITE_ENABLE;

    // set display window params to sprite functions
    SpritesRegsBuffer_SetDisplayWindowParams(X_WINDOW_START, Y_WINDOW_START);
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



void PutObjectsToSpriteMemory(void)
{
    
    memset(Img1,100,16 * 16);
    memset(Img2,200,16 * 16);

    // copy data to sprite memory at 0
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(0);
    memset((byte*)SPRITE_BASE,0,0x1000);                               //  clear 4kb sprite ram
    memcpy((byte*)SPRITE_BASE, (byte*)Img1, 16 * 16);
    PAGE_OUT_SPRITE_RAM();

    // copy data to sprite memory at 0x1000
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(1);
    memset((byte*)SPRITE_BASE,0,0x1000);                               //   clear 4kb sprite ram
    memcpy((byte*)SPRITE_BASE, (byte*)Img2, 16 * 16);
    PAGE_OUT_SPRITE_RAM();

}


void DoMain(void)
{    
    sprite_regs_t r;
    
    r.sprite_number            = 0;
    r.x                        = screenX;
    r.y                        = 0;
    r.height                   = 1;                       // 16 pixels tall       (height in 16pixels chunks)
    r.sprite_definition_number = 0;
    r.x_flip                   = FALSE;      
    SpritesRegsBuffer_SetSpriteRegs(&r);

    r.sprite_number            = 1;
    r.x                        = screenX;
    r.y                        = 32;
    r.height                   = 1;                       // 16 pixels tall       (height in 16pixels chunks)
    r.sprite_definition_number = 16;
    r.x_flip                   = FALSE;      
    SpritesRegsBuffer_SetSpriteRegs(&r);

}




void SetPalette(void)
{
    word* Palette = (word*)PALETTE;
    Palette[0] = RGB2WORD(0,0,0);
    Palette[100] = RGB2WORD(255,128,255);
    Palette[200] = RGB2WORD(255,255,255);
    
}

int main(void)
{

    BOOL done = FALSE;
    screenX = 0;

    SetVideoMode();
    SetPalette();
    //FillVideoMem();
    PutObjectsToSpriteMemory();
    

    while(!done) {
        FLOS_WaitVRT();        
        SpritesRegsBuffer_CopyToHardwareRegs();        // must be called just right after FLOS_WaitVRT()

        SpritesRegsBuffer_Clear();                     // clear sprite regs shadow buffer
        DoMain();
        screenX++;

        if(io__sys_keyboard_data == 0x76)
            done = TRUE;
    }
    

    return REBOOT;
}


