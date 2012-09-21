/*
PONG v0.06

Valen 2009, 2010, 2011, 2012
-------------

TODO: Need fix for 60Hz video mode. Call the pong code always at 50Hz, in both 50Hz and 60Hz videomodes.

v0.04:
- initial version
- was developed with SDCC 2.9.7
v0.05:
- major code refactoring (one .h file for one .c file)
- adapted for SDCC 3.0.6 #6969
- adapted for FLOS598+ (FLOS now produce correct 1B (EOF) error code)
- added disk error diagnostic (Gracefully exits to FLOS:  restore FLOS display and font and print error.)
v0.06:
- load all pong files (resources) from one big bulk file (.DAT file)
*/


#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>                  // must be included only once, in main C program file

#include <os_interface_for_c/i_flos.h>


#include "v6assert.h"
#include "util.h"
#include "sprites.h"
#include "background.h"
#include "keyboard.h"
#include "joystick.h"
#include "disk_io.h"
#include "loading_icon.h"
#include "obj_.h"
#include "obj_anim.h"
#include "obj_score.h"
#include "obj_rocket.h"
#include "obj_bat.h"
#include "obj_ball.h"
#include "obj_youwin.h"
#include "obj_gamemenu.h"
#include "pool_gameobj.h"
#include "pool_sprites.h"
#include "ai.h"
#include <base_lib/resource.h>

#include "sound_fx/sound_fx.h"
#include "debug.h"
#include "low_memory_container.h"
#include "data_loader.h"
#include "handle_resource_error.h"

//#undef  EXTERN_PONG
#define EXTERN_PONG
#include "pong.h"





#include <stdlib.h>
#include <string.h>



// foo funcs
//typedef unsigned long  time_t;


//void setbkcolor();
//void setfillstyle (int color1,int color2);      // {a;b;}
//void fillellipse (int x,int y,int r1,int r2); // {a;b;c;d;}
//void bar (int x1,int y1,int x2,int y2); // {a;b;c;d;}
//void textcolor () {}
//void outtextxy (int a,int b,char* c) {a;b;c;}
//void setcolor (int a) {a;}

char inportb(int a) {return a;}
void delay(int a) {a;}


// there is a standard rand() func in SDCC library, but we (can) override this to use R register as random value
// (this will be a bit faster)
//int rand () { return GetR(); }



void Game_Initialize(void) // Initialize the game.
{
    memset(&YouWinAnim, 0, sizeof(YouWinAnim));

    //game.is_one_player_mode = FALSE;
    game.is_paused = game.is_user_pressed_pause = FALSE;
    game.is_debug_mode = FALSE;
    game.shadow_sprite_register_bank = 0;
    game.global_time = 0;

    debug.offset_gameobj_for_debug_render = 0;


    // init pool of game obj
    PoolGameObj_Init();
    // init pool of sprites
    PoolSprites_Init();

}

void Game_InitializeMenuGameObjects(void) // Initialize
{
    gameMenu.gobj.in_use = TRUE;
    GameObjGameMenu_Init(&gameMenu, 0, 0);
    PoolGameObj_AddObjToActiveObjects(&gameMenu.gobj);
}

void Game_InitializeLevelGameObjects(void) // Initialize
{
    // Init some game objects and add them to the game
    //Initialise Bat A
    batA.gobj.in_use = TRUE;
    GameObjBat_Init(&batA, GAME_FIELD_X_BORDER - BAT_WIDTH, 237/2);
    PoolGameObj_AddObjToActiveObjects(&batA.gobj);


    // Intialise Bat B
    batB.gobj.in_use = TRUE;
    GameObjBat_Init(&batB, SCREEN_WIDTH - GAME_FIELD_X_BORDER, 237/2);
    PoolGameObj_AddObjToActiveObjects(&batB.gobj);


    // Intialise Ball
    ball1.gobj.in_use = TRUE;
    GameObjBall_Init(&ball1);
    PoolGameObj_AddObjToActiveObjects(&ball1.gobj);

    // Intialise Score A
    scoreA.gobj.in_use = TRUE;
    GameObjScore_Init(&scoreA, (SCREEN_WIDTH/2)-16*4, 0);
    scoreA.sprite_num = SPRITE_NUM_SCORE_A_DIGIT;
    scoreA.sprite_num_RocketsIndicator = SPRITE_NUM_PLAYER_A_NUM_ROCKETS;
    PoolGameObj_AddObjToActiveObjects(&scoreA.gobj);
    GameObjScore_UpdateScore(&scoreA);

    // Intialise Score B
    scoreB.gobj.in_use = TRUE;
    GameObjScore_Init(&scoreB, (SCREEN_WIDTH/2)+16*2, 0);
    scoreB.sprite_num = SPRITE_NUM_SCORE_B_DIGIT;
    scoreB.sprite_num_RocketsIndicator = SPRITE_NUM_PLAYER_B_NUM_ROCKETS;
    PoolGameObj_AddObjToActiveObjects(&scoreB.gobj);
    GameObjScore_UpdateScore(&scoreB);

    //helper_GameObjYouWin_StartAnimation(0);

}

void Game_Movebat(char input)
{
  switch (input)
     {
       case 'A' :
                   GameObjBat_MoveUp(&batA);
                   break;

       case 'Z' :
                  GameObjBat_MoveDown(&batA);
                  break;
       case 'J' :
                     GameObjBat_MoveUp(&batB);
                  break;

        case 'M' :
                    GameObjBat_MoveDown(&batB);
                   break;
         }

}






void Game_HandlePlayerInput_Bat(void)
{
       if (player1_input.up)  Game_Movebat ('A');
       if (player1_input.down)  Game_Movebat ('Z');
       if (player1_input.fire1)  GameObjBat_Fire(&batA);
       if (player2_input.fire1)  GameObjBat_Fire(&batB);

       if(game.is_one_player_mode)
           ai_update();
       else {
           if (player2_input.up)  Game_Movebat ('J');
           if (player2_input.down)  Game_Movebat ('M');
       }
}

void Game_HandlePlayerInput_PauseMode(void)
{
    if(game.is_user_pressed_pause) {
        game.is_user_pressed_pause = FALSE;
        game.is_paused ^= 1;
    }

    if(/*keyboard.last_typed_scancode*/ Keyboard_GetLastTypedScanCode() == SC_D) {
        keyboard.last_typed_scancode = 0;
        game.is_debug_mode ^= 1;

        game.is_paused ^= 1;
    }
}



void Game_ReInit_Watcher(void)
{

    if(scoreA.score >= MAX_SCORE_FOR_LEVEL || scoreB.score >= MAX_SCORE_FOR_LEVEL) {
        if(YouWinAnim.gobj.in_use && YouWinAnim.state == DIE) {
            //Game_SetState(MENU);
            Game_RequestSetState(MENU);
            //Game_Initialize();
            //Game_InitializeLevelGameObjects();

        }
    } else {
        if(ball1.state == DIE
    //      && batA.state != DYING && batB.state != DYING
            && helper_GameObjScore_IsScoreBlinkedAtLeast(4)
          ) {
           Game_Initialize();
           Game_InitializeLevelGameObjects();
        }
    }

}


void Game_Play(void)
{
    while (!request_exit) // Check wether key press is ESC if so exit loop
    {
        FLOS_WaitVRT();
        //wait_y_window();
        Game_MarkFrameTime(0xf00);
        SET_LIVE_SPRITE_REGISTER_BANK(game.shadow_sprite_register_bank^1);
        clear_shadow_sprite_regs();



        Sound_PlayFx();

        Game_HandlePlayerInput_PauseMode();
        if(!game.is_paused)
            Joystick_GetInput();
        PoolSprites_FreeAllSprites();

        // move ---
        if(!game.is_paused && game.game_state == LEVEL) {
            Game_HandlePlayerInput_Bat();
        }

        if(!game.is_paused)
            PoolGameObj_ApplyFuncMoveToObjects();

        // menu move
        /*if(game.game_state == MENU)
            GameMenu_Move();*/

        // draw ---
        PoolGameObj_ApplyFuncDrawToObjects();
        if(game.is_paused && game.is_debug_mode) {
            Debug_Move();
            Debug_Draw();
        }

        // menu Draw
        /*if(game.game_state == MENU)
            GameMenu_Draw();*/

        Game_ReInit_Watcher();

        if(game.isMusicEnabled) {
            Music_PlayTracker();
            Music_UpdateSoundHardware();
        }


        if(game.isRequestSetState) {
            game.isRequestSetState = FALSE;
            if(!Game_SetState(game.new_state))
                return;
        }


        game.shadow_sprite_register_bank ^= 1;
        if(!game.is_paused)
            game.global_time++;
        Game_MarkFrameTime(0x000);

        if(Keyboard_GetLastPressedScancode() == SC_LSHIFT) {
            debug.isShowFrameTime ^= 1; keyboard.prev_pressed_scancode = 0;
        }


        /*if(!Debug_CheckGuardStr()) {
            //FLOS_PrintStringLFCR("ERR: GUARD");
            //return NO_REBOOT;
            Game_MarkFrameTime(0x0F0);
            BEGINASM();
            di
            halt
            ENDASM();
            //request_exit = TRUE;
        }*/


        if(!Debug_CheckCurrentBank()) {
            Game_MarkFrameTime(0x00F);
//            BEGINASM()
//        di
//        halt
//            ENDASM()
            //return NO_REBOOT;
        }



    }//while




}


void Game_InitLevelBegining(void)
{
    // Intialize score
    scoreA.score = scoreB.score = 0;
    scoreA.num_rockets = scoreB.num_rockets = 3;

//    GameObjScore_SetScore(&scoreA, 0);
}




int main (void)
{

    request_exit = FALSE;
    game.isRequestSetState = FALSE;
    loadingIcon.isLoaded = FALSE;
    game.isFLOSVideoMode = TRUE;
    debug.isShowFrameTime = FALSE;
    //strcpy(debug.guard_str, "GUARD");


    if(!Debug_CheckCurrentBank())
        return NO_REBOOT; 

    Game_StoreFLOSVIdeoRam();

    Resource_Init(FALSE, "PONG.DAT");
    initgraph();
    Game_SetReg_SprCtrl(SPRITE_ENABLE|DOUBLE_BUFFER_SPRITE_REGISTER_MODE);
    Game_SetState(STARTUP);


    if(!LoadingIcon_Load())
        return NO_REBOOT;



    if(!Game_LoadSinTable())
        return REBOOT;
    if(!Sound_LoadSoundCode())
        return REBOOT;


    if(!Sound_LoadSounds())
        return REBOOT;
    if(!Sound_LoadFxDescriptors())
        return REBOOT;
    Sound_InitFx();




    Keyboard_Init();
    install_irq_handler();

    if(!Game_SetState(MENU))
        ShowErrorAndStopProgramExecution("SetState ERR!"); //return NO_REBOOT;

    Game_Play (); // Game Engine


    Sys_ClearIRQFlags(CLEAR_IRQ_KEYBOARD);
    return REBOOT;
}

void Game_RequestSetState(GameState state)
{
    game.isRequestSetState = TRUE;
    game.new_state = state;

}

BOOL Game_LoadStateData(GameState state, GameState prev_state)
{    
    return DataLoader_LoadData(state, prev_state);
}

BOOL Game_SetState(GameState state)
{
    GameState prev_game_state;

    if(state == game.game_state)
        return TRUE;

    prev_game_state = game.game_state;
    game.game_state = state;

    if(state == LEVEL) {
        // disable matte mode
        Game_EnableMatteMode(FALSE);

        game.isMusicEnabled = FALSE;
        game.isSoundfxEnabled = TRUE;

        MUSIC_Silence();
        // load pal, spr, tiles
        if(!Game_LoadStateData(state, prev_game_state))
            return FALSE;


        //
        Game_InitLevelBegining();
        Game_Initialize();
        Game_InitializeLevelGameObjects();
    }
    if(state == MENU) {
        // enable matte mode
        Game_EnableMatteMode(TRUE);     //  Game_SetReg_SprCtrl(SPRITE_ENABLE|DOUBLE_BUFFER_SPRITE_REGISTER_MODE | MATTE_MODE_ENABLE);

        game.isMusicEnabled = TRUE;
        game.isSoundfxEnabled = FALSE;

        if(prev_game_state == CREDITS)
            Background_InitTilemap(0);
        if(prev_game_state == LEVEL)
            MUSIC_Silence();
        // load pal, spr, tiles
        if(!Game_LoadStateData(state, prev_game_state))
            return FALSE;

        //
        Game_Initialize();
        Game_InitializeMenuGameObjects();
    }

    if(state == CREDITS) {
        /*if(!Game_LoadStateData(state, prev_game_state))
            return FALSE;*/
        Background_InitTilemap(TILES_CREDITS_VRAM_ADDR/0x100);
    }

    if(state == STARTUP) {
        TileMap_Clear();
    }



    Keyboard_Init();
    Input_ClearPlayersInput();
    return TRUE;
}

// ---- TEXT VIDEO MODE
int cur_color;
/*
void fillellipse (int x,int y,int r1,int r2)
{   r1;r2;

    x = x/2;
    y = y/2;

    FLOS_SetCursorPos(x/8, y/8);
    (cur_color == 0) ?  FLOS_PrintString(" ") : FLOS_PrintString("X");
}

void bar (int x1,int y1,int x2,int y2)
{   x2;y2;

    x1 = x1/2;
    y1 = y1/2;

    FLOS_SetCursorPos(x1/8, y1/8);
    (cur_color == 0) ?  FLOS_PrintString(" ") : FLOS_PrintString("0");
}

*/
void setfillstyle (int color1,int color2)
{   color1;

    cur_color = color2;

//    myinline(TRUE);
//    myinline(FALSE);
}






BOOL Game_LoadSinTable(void)
{
    if(!Resource_LoadFileToBuffer("SINE_TAB.BIN", 0, (byte*)MULT_TABLE, 0x200, 0))
        return Handle_Resource_Error();
    return TRUE;
}

void Game_MarkFrameTime(ushort color)
{
    if(debug.isShowFrameTime)
        MarkFrameTime(color);
}
// ----

void Game_SetReg_SprCtrl(BYTE r)
{
    mm__vreg_sprctrl = r;
    // make a copy of reg value, for later use
    game.regsdata.mm__vreg_sprctrl = r;
}

BYTE Game_ReadReg_SprCtrl(void)
{
    // we cannot read video reg (they are write only),
    // but we have a copy of reg in memory
    return game.regsdata.mm__vreg_sprctrl;
}

// Input:
void Game_EnableMatteMode(BOOL isEnable)
{
    if(isEnable)
        Game_SetReg_SprCtrl(Game_ReadReg_SprCtrl() | MATTE_MODE_ENABLE);
    else
        Game_SetReg_SprCtrl(Game_ReadReg_SprCtrl() & (~MATTE_MODE_ENABLE));
}




// --------------
void putchar(char c)
{
    BYTE str[2];

    str[0] = str[1] = 0;
    str[0] = c;

    if(c == '\n')   FLOS_PrintStringLFCR("");
    else            FLOS_PrintString(str);
}
