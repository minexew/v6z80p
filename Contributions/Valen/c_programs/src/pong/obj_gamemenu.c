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
}

void GameObjGameMenu_Draw(GameObjGameMenu* this)
{
    this;
}

// -----------------------------------------
// temp quick func
//void foo_DisplayMenuText(void)
//{
//}

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
        obj->spr_def_start      = SPRITE_DEF_NUM_YOUWIN;
        obj->spr_def_pitch      = 1;
        GameObjAnim_ShowOnlyFirstFrame(obj);

    }
/*
    // emerlads
    for(i=0; i<NUM_EMERLADS; i++) {
        obj = PoolGameObj_AllocateGameObjAnim();
        if(obj) {
            GameObjAnim_Init(obj, x + i*32,  y);
            obj->spr_count          = 2;
            obj->spr_height         = 1;
            obj->spr_def_start      = SPRITE_DEF_NUM_EMERALD;
            obj->spr_def_pitch      = 7;
            //GameObjAnim_ShowOnlyFirstFrame(obj);
            obj->spr_anim_time      = 250;
            obj->spr_anim_frames    = 7;
            GameObjAnim_EnableAnimation(obj, TRUE);

            obj->spr_anim_def_offset = i * 256U;

            this->emerlads[i] = obj;
        }
    }
*/
}
