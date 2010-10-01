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

