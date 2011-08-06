#ifndef SPRITES_H
#define SPRITES_H

// hardware sprite numbers -----------------------------
#define SPRITE_NUM_BALL                 3                               // 16x16
#define SPRITE_NUM_SCORE_A_DIGIT        4                               // 2 sprites by 16x16
#define SPRITE_NUM_SCORE_B_DIGIT        6                               // 2 sprites by 16x16
// player rockets indicator (max 3 rockets per player)
#define SPRITE_NUM_PLAYER_A_NUM_ROCKETS SPRITE_NUM_SCORE_B_DIGIT+2          // 3 sprites by 16x16
#define SPRITE_NUM_PLAYER_B_NUM_ROCKETS SPRITE_NUM_PLAYER_A_NUM_ROCKETS+3   // 3 sprites by 16x16
// define first spr number for a pool of sprites
#define POOL_SPR__FIRST_SPRITE          SPRITE_NUM_PLAYER_B_NUM_ROCKETS+3

// define some numbers for sprites which must be drawed at top of all other sprites
#define SPRITE_NUM_DEBUG_POINT1         POOL_SPR__LAST_SPRITE+1             // 1 sprite by 16x16


// diskette picture
#define SPRITE_NUM_DISKETTE             0                                   // 1 frame by 3x3



// sprite definition numbers -----------------------------
// 0 - ball sprite
#define SPRITE_DEF_NUM_DEBUG_POINT1     1
// 2,3 - bat sprites
#define SPRITE_DEF_NUM_DIGIT            4                                        // 10 digits (size 16x16)
#define SPRITE_DEF_NUM_DYING_BALL       SPRITE_DEF_NUM_DIGIT+10                  // 7 frames by 16x16
#define SPRITE_DEF_NUM_BANG1            SPRITE_DEF_NUM_DYING_BALL+7              // 7 frames by 32x32
// rocket
#define SPRITE_DEF_NUM_ROCKET_TAIL      SPRITE_DEF_NUM_BANG1+7*4            // 6 frames by 16x16
#define SPRITE_DEF_NUM_ROCKET_MIDDLE    SPRITE_DEF_NUM_ROCKET_TAIL+6        // 2 frames by 16x16
#define SPRITE_DEF_NUM_ROCKET_TOP       SPRITE_DEF_NUM_ROCKET_MIDDLE+2      // 1 frames by 16x16

#define SPRITE_DEF_NUM_ROCKET_VERTICAL  SPRITE_DEF_NUM_ROCKET_TOP+1         // 1 frame(s) by 1x1
#define SPRITE_DEF_NUM_EMERALD          SPRITE_DEF_NUM_ROCKET_VERTICAL+1    // 7 frame(s) by 2x1
#define SPRITE_DEF_NUM_YOUWIN           SPRITE_DEF_NUM_EMERALD+7*2*1        // 1 frame(s) by 6x8
// rocket (drawed by phil)
#define SPRITE_DEF_NUM_ROCKET_TOP1      SPRITE_DEF_NUM_YOUWIN+1*6*8         // 1 frame(s) by 1x1
#define SPRITE_DEF_NUM_ROCKET_TAIL1     SPRITE_DEF_NUM_ROCKET_TOP1+1*1*1    // 3 frame(s) by 1x1

// at the end of sprite memory
#define SPRITE_DEF_NUM_DISKETTE         (512-3*3)                           // 1 frame(s) by 3x3


#define SPRITE_Y_OFFSCREEN              256             // put sprite offscreen (specific value for Y sprite reg)

// Start = 96 Stop = 480 (Window Width = 368 pixels with left wideborder Total:384 pixels)
#define X_WINDOW_START                0x6
#define X_WINDOW_STOP                 0xE
// 240 line display (masks last line of tiles)
#define Y_WINDOW_START                0x3
#define Y_WINDOW_STOP                 0xD

#define BUF_FOR_LOADING_SPRITES_4KB          buffer4K

// bank is 0 or 1
#define SET_LIVE_SPRITE_REGISTER_BANK(b)     Game_SetReg_SprCtrl( Game_ReadReg_SprCtrl() & (~4) | ((b)<<2) );

// --
//#include <v6z80p_types.h>



void initgraph(void);
//void Sprites_EnableSprites(BYTE flags1);
void clear_sprite_regs(void);
void clear_shadow_sprite_regs(void);

void DrawBat(int x1,int y1,int x2,int y2);
void DrawBall(int x_center,int y_center);

void set_sprite_regs(byte sprite_number, int x, int y, byte height, word sprite_definition_number, BOOL x_flip, BOOL isEnableMatteMode);
void set_sprite_regs_hw(byte sprite_number, byte x, byte misc, byte y, byte sprite_definition_number);

BOOL Sprites_LoadSprites(const char *pFilename, DWORD destSpriteMem);



#endif /* SPRITES_H */
