/*
   Basic keyboard and mouse example.

   Draw, using mouse. Left button - draw. Right button - change color.
   Keyboard cursor keys also move pen.
   ESC - exit.
           
*/
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

// Display Window sizes:
// Width  368 pixels
#define X_WINDOW_START                0x7
#define X_WINDOW_STOP                 0xE
// Height 240 lines
#define Y_WINDOW_START                0x3
#define Y_WINDOW_STOP                 0xD

#define OS_VERSION_REQ  0x571           // OS version req. to run this program

// we use our own irq code for keyb and mouse 
#define APP_USE_OWN_KEYBOARD_IRQ
#define APP_USE_OWN_MOUSE_IRQ


#include "../../src/lib/sprites.c"
#include "../../src/lib/keyboard.c"
#include "../../src/lib/mouse.c"
#include "../../src/lib/irq.c"

#include "../../src/lib/video_mode.c"
#include "../../src/lib/utils.c"

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

short screenX = 0, screenY = 0;
unsigned char Img1[16 * 16];            // test sprite image buffer (will be copied to sprite memory)

byte colorIndex = 0xFF;        // color being draw under cursor

char buffer[32];

void SetVideoMode(void)
{
    // select bitmap mode + chunky pixel mode (1 byte = 1 pixel)
    mm__vreg_vidctrl = BITMAP_MODE|CHUNKY_PIXEL_MODE;

    VideoMode_SetupDisplayWindowSize(X_WINDOW_START, X_WINDOW_STOP, Y_WINDOW_START, Y_WINDOW_STOP);

    // initialize datafetch start address HW pointer
    mm__bitplane0a_loc__byte0 = 0;      // [7:0] bits
    mm__bitplane0a_loc__byte1 = 0;      // [15:8] 
    mm__bitplane0a_loc__byte2 = 0;      // [18:16] 

//    mm__bitplane0a_loc__byte3 = 0;      // modulo

    // Enable sprites
    mm__vreg_sprctrl = SPRITE_ENABLE;
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
    
    memset(Img1,100,sizeof(Img1));
    
    // copy data to sprite memory at 0
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(0);
    memset((byte*)SPRITE_BASE,0,0x1000);                               //  clear 4kb sprite ram
    memcpy((byte*)SPRITE_BASE, (byte*)Img1, sizeof(Img1));
    PAGE_OUT_SPRITE_RAM();
}


// unoptimized
void PutPixel(word x, word y, byte color)
{
    dword videoAddr = y * 368UL + x;
    byte bank;
    byte *p;

    bank = videoAddr >> 13; // div by 8KB

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(bank);
    p = (byte*)(VIDEO_BASE + ((word)videoAddr & 0x1FFF));
    *p = color;
    PAGE_OUT_VIDEO_RAM();

}

void DoMain(void)
{    
    sprite_regs_t r;
    
    // process user input 
    // keyboard:
    if(myplayer_input.up)   screenY -= 2;
    if(myplayer_input.down) screenY += 2;
    if(myplayer_input.left)  screenX -= 2;
    if(myplayer_input.right) screenX += 2;

    // mouse:
    screenX += Mouse_GetOffsetX();
    // mouse uses positive displacement = upwards
    // motion so subtract value instead of adding
    screenY -= Mouse_GetOffsetY();
    Mouse_ClearOffsets();

    if(mouse.buttons & MOUSE_RIGHT_BUTTON_PRESSED) colorIndex++;


    // check bounds
    if(screenX < 0) screenX = 0; if(screenX > 368-1) screenX = 368-1;
    if(screenY < 0) screenY = 0; if(screenY > 240-1) screenY = 240-1;
    
    r.sprite_number            = 0;
    r.x                        = screenX;
    r.y                        = screenY;
    r.height                   = 1;                       // 16 pixels tall       (height in 16pixels chunks)
    r.sprite_definition_number = 0;
    r.x_flip                   = FALSE;      
    SpritesRegsBuffer_SetSpriteRegs(&r);

    if(mouse.buttons & MOUSE_LEFT_BUTTON_PRESSED)
        PutPixel(screenX, screenY, colorIndex);


}




void SetPalette(void)
{
    word* Palette = (word*)PALETTE;
    Palette[0] = RGB2WORD(0,0,0);
    Palette[100] = RGB2WORD(255,128,255);
    Palette[200] = RGB2WORD(255,255,255);
    
}


BOOL Check_FLOS_Version(void) 
{
    if(!Utils_Check_FLOS_Version(OS_VERSION_REQ)) {
        FLOS_PrintString("FLOS v");
        _uitoa(OS_VERSION_REQ, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintStringLFCR("+ req. to run this program.");
        return FALSE;
    }
    return TRUE;
}

BOOL IsMouseInitialized(void)
{
    MouseStatus ms;
    if(!FLOS_GetMousePosition(&ms)) {   // req FLOS v571+
        FLOS_PrintStringLFCR("ERROR:");
        FLOS_PrintStringLFCR("The mouse driver was not enabled.");
        FLOS_PrintStringLFCR("Attach the mouse and run MOUSE.EXE,");
        FLOS_PrintStringLFCR("before running this program.");
        return FALSE;
    }
    return TRUE;
}

int main(void)
{    

    if(!Check_FLOS_Version()) 
        return NO_REBOOT;

    if(!IsMouseInitialized())
        return NO_REBOOT;
    

    PutObjectsToSpriteMemory();
    SetVideoMode();
    SetPalette();    
    FillVideoMem();

    Keyboard_Init(keyboard_input_map);        // init keyboard input
    install_irq_handler(IRQ_ENABLE_MASTER | IRQ_ENABLE_KEYBOARD | IRQ_ENABLE_MOUSE);          // enable irq: master, keyboard, mouse
    
    
    SpritesRegsBuffer_Clear();          // clear, to not see garbage on first frame
    while(!myplayer_input.esc) {
        FLOS_WaitVRT();
        SpritesRegsBuffer_CopyToHardwareRegs();         // must be called right after FLOS_WaitVRT()
        
        SpritesRegsBuffer_Clear();                      // clear sprite regs shadow buffer
        DoMain();
    }
    

    return REBOOT;
}


