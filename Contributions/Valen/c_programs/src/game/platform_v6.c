#include <stdio.h>
#include <string.h>

#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros.h>
#include <os_interface_for_c/i_flos.h>
#include <scan_codes.h>

#include <base_lib/video_mode.h>
#include <base_lib/sprites.h>
#include <base_lib/keyboard.h>

#include "debug_print.h"
#include "game.h"
#include "platform.h"



// Start = 96 Stop = 480 (Window Width = 368 pixels with left wideborder Total:384 pixels)
#define X_WINDOW_START                0x6
#define X_WINDOW_STOP                 0xE
// 240 line display (masks last line of tiles)
#define Y_WINDOW_START                0x3
#define Y_WINDOW_STOP                 0xD


static void Platform_PutObjectsToSpriteMemory(void);
static void Platform_SetPalette(void);


#define APP_USE_OWN_KEYBOARD_IRQ
#include "../../src/inc/irq.c"      // include hardware interrupt handler code


BYTE freeHardwareSpriteNumber;
sprite_regs_t sprDraw;



//  application flags for pressed keyboard keys
typedef struct {
    BOOL up, down, left, right;
    BOOL fire1;
    BOOL esc;
} player_input;
player_input myplayer_input;
// keyboard input map, provided by application
keyboard_input_map_t keyboard_input_map[] = {
                {SC_UP, &myplayer_input.up},     {SC_DOWN, &myplayer_input.down},
                {SC_LEFT, &myplayer_input.left}, {SC_RIGHT, &myplayer_input.right},
                {SC_X, &myplayer_input.fire1},
                {SC_ESC, &myplayer_input.esc},
                {0xFF, NULL}           // terminator (end of input map)
};



void SetBorder(WORD color)
{
    WORD* Palette = (WORD*)PALETTE;
    Palette[0] = color;
}


void Platform_InitVideo(int screen_w, int screen_h)
{

    VideoMode_InitTilemapMode(WIDE_LEFT_BORDER /*|DUAL_PLAY_FIELD*/, EXTENDED_TILE_MAP_MODE);
    VideoMode_SetupDisplayWindowSize(X_WINDOW_START, X_WINDOW_STOP, Y_WINDOW_START, Y_WINDOW_STOP);


    // Enable sprites
    mm__vreg_sprctrl = SPRITE_ENABLE;

//     // Set display window params to sprite functions.
//     // +1 point to x for wideleft border (one X  window point = 16 pixels)
//     SpritesRegsBuffer_SetDisplayWindowParams(X_WINDOW_START + 1, Y_WINDOW_START);


//     //
       Platform_PutObjectsToSpriteMemory();
       Platform_SetPalette();

}


// #define mm__vreg_rasthi ( *((unsigned char*) 0x100)  )
// sfr mm__vreg_rasthi      = 0x1234;
void Platform_OnGameLoopBegin(void)
{
    
    FLOS_WaitVRT();
    SetBorder(0x0ff);
    SpritesRegsBuffer_CopyToHardwareRegs();         // must be called right after FLOS_WaitVRT()
    SpritesRegsBuffer_Clear();                      // clear sprite regs shadow buffer
    // now you can do main game code  
    freeHardwareSpriteNumber = 0;


    // mm__vreg_rasthi = 0;
    // byte = mm__vreg_rasthi;
    // byte = mm__vreg_rasthi;
    // SetBorder(byte);
}



void Platform_OnGameLoopEnd(void)
{
    // BYTE i;  BYTE *p;
    
    SetBorder(0);

    

    Keyboard_PrintDebug();
}



void Platform_Draw_Bounced(BouncedObj *self)
{
    sprDraw.x = self->x;      //256 + 16;
    sprDraw.y = self->y;      //32;
    sprDraw.height = 1;
    sprDraw.sprite_definition_number = 0;
    sprDraw.x_flip = 0;



    Platform_Draw_Sprite();

}

void Platform_Draw_MovingObj(MovingObj *self)
{
    sprDraw.x = self->x;      //256 + 16;
    sprDraw.y = self->y;      //32;
    sprDraw.height = 1;
    sprDraw.sprite_definition_number = 0;
    sprDraw.x_flip = 0;



    Platform_Draw_Sprite();

}



void Platform_Draw_Sprite(void)
{
    int x_p                 = sprDraw.x;      //256 + 16;
    int y_p                 = sprDraw.y;      //32;
    BYTE sprite_height_p    = sprDraw.height; 
    BYTE sprite_number_p    = freeHardwareSpriteNumber;
    WORD sprite_definition_p = sprDraw.sprite_definition_number; 
    BOOL sprite_x_flip_p    = sprDraw.x_flip;
    BYTE* spr_buf_p = 0;
    

    freeHardwareSpriteNumber++;         
    freeHardwareSpriteNumber &= 127;    
                                        
                                        
                                        
    x_p += X_WINDOW_START * 16;         
    x_p += 16;                          
    y_p += Y_WINDOW_START * 8 + 1;      
                                        
    spr_buf_p = &spritesRegsBuffer[sprite_number_p*4];                                  
    *spr_buf_p++ = (BYTE) x_p;                                                      
    *spr_buf_p++ = ((BYTE)sprite_height_p << 4)         |                           
                                        ((WORD) x_p                 >> 8 & 1)       |   
                                        ((WORD) y_p                 >> 8 & 1) << 1  |   
                                        ((WORD) sprite_definition_p >> 8 & 1) << 2  |   
                                        ((BYTE) sprite_x_flip_p          & 1) << 3      
                                                ;                                       
    *spr_buf_p++ = (BYTE) y_p;                                                      
    *spr_buf_p++ = (BYTE) sprite_definition_p;  
    

}

void Platform_PutObjectsToSpriteMemory(void)
{

  
    static unsigned char Img1[16 * 16];            //  sprite image buffer
    unsigned char color = 100;
    // first "corner" debug spr
    memset(Img1,0,sizeof(Img1));
    Img1[0 * 16] = color;            Img1[0] = color;
    Img1[1 * 16] = color;            Img1[1] = color;
    Img1[2 * 16] = color;            Img1[2] = color;
    Img1[3 * 16] = color;            Img1[3] = color;
    Img1[4 * 16] = color;            Img1[4] = color;
    Img1[5 * 16] = color;            Img1[5] = color;
    Img1[6 * 16] = color;            Img1[6] = color;
    Img1[7 * 16] = color;            Img1[7] = color;

                                                         

    // copy data to sprite memory at 0
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(0);
    memset((byte*)SPRITE_BASE,0,0x1000);                               //  clear 4kb sprite ram
    memcpy((byte*)SPRITE_BASE, (byte*)Img1, sizeof(Img1));
    PAGE_OUT_SPRITE_RAM();
   
}

void Platform_SetPalette(void)
{
    word* Palette = (word*)PALETTE;
    Palette[0] = RGB2WORD(0,0,0);
    Palette[100] = RGB2WORD(255,128,255);

}

// --------------- Input -----------------------------

BOOL Platform_IsPressed(BYTE scancode)
{
    return Keyboard_IsPressed(scancode);
}


void Platform_InitInput(void)
{
    memset(&myplayer_input, 0, sizeof(myplayer_input));   // set to FALSE input vars

    Keyboard_Init(keyboard_input_map);        // init keyboard input
    install_irq_handler(IRQ_ENABLE_MASTER | IRQ_ENABLE_KEYBOARD);     // enable irq: master, keyboard

}

BOOL Platform_HandleInput(void)
{
    // byte keyASCII = 0;  byte keyScancode = 0;

    // FLOS_GetKeyPress(&keyASCII, &keyScancode);
    // if(keyScancode == SC_ESC) return FALSE;

    if( Keyboard_IsPressed(SC_ESC) ) return FALSE;
    
    return TRUE;
    
}





