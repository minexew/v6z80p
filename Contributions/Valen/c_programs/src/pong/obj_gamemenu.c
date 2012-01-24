#include <v6z80p_types.h>
#include <scan_codes.h>
#include <OSCA_hardware_equates.h>

#include <string.h>

#include "obj_gamemenu.h"
#include "obj_anim.h"
#include "pool_gameobj.h"
#include "keyboard.h"
#include "math.h"
#include "pong.h"

#ifdef UNFINISHED_CODE
GameObjMenuTxt objMenuTxt[2];
#endif  // UNFINISHED_CODE

void GameObjGameMenu_Init(GameObjGameMenu* this, int x, int y)
{
    // init parent obj
    GameObj_Init((GameObj*)this);

    this->gobj.x = x;
    this->gobj.y = y;
    this->gobj.width  = 0;
    this->gobj.height = 0;


    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjGameMenu_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjGameMenu_Draw);

#ifdef UNFINISHED_CODE
    // init menu txt objects
    objMenuTxt[0].gobj.in_use = TRUE;
    GameObjMenuTxt_Init(&objMenuTxt[0], 100, 100);
    PoolGameObj_AddObjToActiveObjects(&objMenuTxt[0].gobj);
#endif  // UNFINISHED_CODE
}

void GameObjGameMenu_Move(GameObjGameMenu* this)
{
    BOOL isBeginLevel = FALSE;
    byte is_one_player_mode = FALSE;

    this;
    if (game.game_state == MENU) {
        if(player1_input.fire1) {
            player1_input.fire1 = FALSE;
            isBeginLevel       = TRUE;
            is_one_player_mode = TRUE;
        }
        if(player2_input.fire1) {
            player2_input.fire1 = FALSE;
            isBeginLevel       = TRUE;
            is_one_player_mode = FALSE;
        }
        // to CREDITS
        if(Keyboard_GetLastPressedScancode() == SC_1) {
            /*player1_input.up   = FALSE;*/
            Game_RequestSetState(CREDITS);
        }

        if(isBeginLevel) {
            Game_RequestSetState(LEVEL);
            game.is_one_player_mode = is_one_player_mode;

        }
    }


    if (game.game_state == CREDITS) {
        // to MENU
        // return back to menu, if any keyb key pressed (or one of joysticks fire pressed)
        if(Keyboard_GetLastPressedScancode() != 0 || player1_input.fire1 || player2_input.fire1) {
            Game_RequestSetState(MENU);
        }
    }

}

void GameObjGameMenu_Draw(GameObjGameMenu* this)
{
    this;
}

// -----------------------------------------


#ifdef UNFINISHED_CODE
// **************************
// display sprite 'PRESS FIRE TO START' and animate matte color



void GameObjMenuTxt_Init(GameObjMenuTxt* this, int x, int y)
{
    // init parent obj
    GameObj_Init((GameObj*)this);

    this->gobj.x = x;
    this->gobj.y = y;
    this->x_pos  = x;
    this->y_pos  = y;


    this->gobj.width  = 0;
    this->gobj.height = 0;

    this->angle = 0;

    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjMenuTxt_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjMenuTxt_Draw);

    GameObjMenuTxt_AllocateAnimObjects(this);
}

void GameObjMenuTxt_Move(GameObjMenuTxt* this)
{
    this;
    GameObjMenuTxt_MoveAnimObjects(this);
}

void GameObjMenuTxt_Draw(GameObjMenuTxt* this)
{
    this;
}

void GameObjMenuTxt_AllocateAnimObjects(GameObjMenuTxt* this)
{
    GameObjAnim* obj;
    int x = 0, y = 0;
    //byte i;
    this;


    //x = this->gobj.x;
    //y = this->gobj.y;
    obj = PoolGameObj_AllocateGameObjAnim();
    if(obj) {
        GameObjAnim_Init(obj, x,  y);
        obj->spr_count          = 6;
        obj->spr_height         = 2;
        obj->spr_def_start      = 0;
        obj->spr_def_pitch      = 2;
        GameObjAnim_ShowOnlyFirstFrame(obj);

    }

    this->menuTxt = obj;

/*
    ipol.Init();
    ipol.AddKeyInt(0,   0);
    ipol.AddKeyInt(100, 0xFFFF/2);
*/
}

void GameObjMenuTxt_MoveAnimObjects(GameObjMenuTxt* this)
{

    WORD* pColor;
    WORD* pColor1;
    WORD* pColor2;
    BYTE angle;
    this;


    GameObjAnim_EnableMatteMode(this->menuTxt, TRUE);

    angle = this->angle>>8;   // get integer part of 8.8 fixed point value
    this->menuTxt->gobj.y = this->y_pos + HW_SIN_MUL(angle, 120);
    this->menuTxt->gobj.x = this->x_pos;

//    if(counter_hold_position++ > time_hold_position)


    this->angle += (WORD)(1.5*256);
    if(this->angle > 0xFFFF/2) this->angle = 0;


    pColor  = (WORD*)(PALETTE + ((BYTE)game.global_time>>2) * 2);
    pColor1 = (WORD*)(PALETTE + 127*2);
    pColor2 = (WORD*)(PALETTE + 255*2);
    *pColor1 = *pColor;
    *pColor2 = *pColor;


}

// **************************

void Ipol_Init(Ipol* this)
{
    memset(this->key_array, 0, sizeof(this->key_array));
    this->key_index = 0;
}

void Ipol_AddKeyInt(Ipol* this, WORD time, short key)
{
    this->key_array[this->key_index].time = time;
    this->key_array[this->key_index].key  = key;
    this->key_index++;
}

void Ipol_Compute(Ipol* this)
{
    this;
}

#endif  // UNFINISHED_CODE
