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

    GameObjGameMenu_AllocateAnimObjects(this);
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

    GameObjGameMenu_MoveAnimObjects(this);
}

void GameObjGameMenu_Draw(GameObjGameMenu* this)
{
    this;
}

// -----------------------------------------
// temp quick func
GameObjAnim* menuTxt1;
void GameObjGameMenu_AllocateAnimObjects(GameObjGameMenu* this)
{
    GameObjAnim* obj;
    int x = 100, y = 100;
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

    menuTxt1 = obj;

}

void GameObjGameMenu_MoveAnimObjects(GameObjGameMenu* this)
{

    WORD* pColor;
    WORD* pColor1;
    WORD* pColor2;
    this;
    //menuTxt1->gobj.y = 0;


    GameObjAnim_EnableMatteMode(menuTxt1, TRUE);

    pColor  = (WORD*)(PALETTE + ((BYTE)game.global_time>>2) * 2);
    pColor1 = (WORD*)(PALETTE + 127*2);
    pColor2 = (WORD*)(PALETTE + 255*2);
    *pColor1 = *pColor;
    *pColor2 = *pColor;


}
