/*
   Basic keyboard and sprites example.

   Keyboard cursor keys to move.
   ESC to exit.
           
*/
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>

#include <base_lib/sprites.h>
#include <base_lib/keyboard.h>


#include <stdlib.h>
#include <string.h>

#define APP_USE_OWN_KEYBOARD_IRQ
#include "../../src/inc/irq.c"


// Display Window sizes:
// Width  320 pixels
#define X_WINDOW_START                0x8
#define X_WINDOW_STOP                 0xC
// Height 200 lines
#define Y_WINDOW_START                0x5
#define Y_WINDOW_STOP                 0xA



//  application flags for pressed keyboard keys
typedef struct {
    BOOL up, down, left, right;
    BOOL fire1;
    BOOL esc;
} player_input;
player_input myplayer_input = {FALSE, FALSE, FALSE, FALSE, 
                               FALSE, FALSE};

// keyboard input map, provided by application
keyboard_input_map_t keyboard_input_map[] = {
                {SC_UP, &myplayer_input.up},     {SC_DOWN, &myplayer_input.down},
                {SC_LEFT, &myplayer_input.left}, {SC_RIGHT, &myplayer_input.right},
                {SC_X, &myplayer_input.fire1},
                {SC_ESC, &myplayer_input.esc},
                {0xFF, NULL}           // terminator (end of input map)
};

word screenX = 0, screenY = 0;
unsigned char Img1[16 * 16];            // test sprite image buffer (will be copied to sprite memory)

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

/*void FillVideoMem(void)
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
}*/

void PutObjectsToSpriteMemory(void)
{
    
    memset(Img1,100,sizeof(Img1));
    
    // copy data to sprite memory at 0
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(0);
    memset((byte*)SPRITE_BASE,0,0x1000);                               //  clear 4kb sprite ram
    memcpy((byte*)SPRITE_BASE, (byte*)Img1, sizeof(Img1));
    PAGE_OUT_SPRITE_RAM();
}


void DoMain(void)
{    
    sprite_regs_t r;
    
    // process user input 
    if(myplayer_input.up)   screenY -= 2;
    if(myplayer_input.down) screenY += 2;
    if(myplayer_input.left)  screenX -= 2;
    if(myplayer_input.right) screenX += 2;
    
    r.sprite_number            = 0;
    r.x                        = screenX;
    r.y                        = screenY;
    r.height                   = 1;                       // 16 pixels tall       (height in 16pixels chunks)
    r.sprite_definition_number = 0;
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
    PutObjectsToSpriteMemory();
    SetVideoMode();
    SetPalette();    
    //FillVideoMem();

    Keyboard_Init(keyboard_input_map);        // init keyboard input
    install_irq_handler(IRQ_ENABLE_MASTER | IRQ_ENABLE_KEYBOARD);          // enable irq: master, keyboard
    
    

    while(!myplayer_input.esc) {
        FLOS_WaitVRT();
        SpritesRegsBuffer_CopyToHardwareRegs();         // must be called right after FLOS_WaitVRT()
        
        SpritesRegsBuffer_Clear();                      // clear sprite regs shadow buffer
        DoMain();
    }
    

    return REBOOT;
}


