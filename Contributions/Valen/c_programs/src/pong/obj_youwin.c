void GameObjYouWin_Init(GameObjYouWin* this, int x, int y)
{
    // init parent obj
    GameObj_Init((GameObj*)this);

    this->gobj.x = x;
    this->gobj.y = y;
    this->gobj.width  = 16*2;
    this->gobj.height = 16;

    this->state = NORMAL;
    this->angle = 0;
    this->lifeTime = 0;

    //
    //GameObj_InitCollideBox((GameObj*)this);

    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjYouWin_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjYouWin_Draw);

    GameObjYouWin_AllocateAnimObjects(this);

}




void GameObjYouWin_Move(GameObjYouWin* this)
{
    byte i;
    short x_center = this->gobj.x + SPR_YOUWIN_WIDTH*16/2;
    short y_center = this->gobj.y + SPR_YOUWIN_HEIGHT*16/2;
    byte angle = this->angle/256;   // get integer part of fixet point value
    char radius;

    radius = HW_SIN_MUL(angle, 75);

    for(i=0; i<NUM_EMERLADS; i++) {
        this->emerlads[i]->gobj.x = x_center + HW_SIN_MUL(angle, radius) - 20/2;
        this->emerlads[i]->gobj.y = y_center + HW_SIN_MUL(angle+0x100/4, radius) - 16/2;

        angle += (256/NUM_EMERLADS);
    }
    this->angle += (word)(1.5*256);

    if(/*this->lifeTime >= 5*50*/ player1_input.fire1 || player2_input.fire1)
        GameObjYouWin_SetState(this, DIE);

    this->lifeTime++;
}



void GameObjYouWin_Draw(GameObjYouWin* this)
{
    this;
}

void GameObjYouWin_AllocateAnimObjects(GameObjYouWin* this)
{
    GameObjAnim* obj;
    int x, y;
    byte i;


    x = this->gobj.x;
    y = this->gobj.y;
    obj = PoolGameObj_AllocateGameObjAnim();
    if(obj) {
        GameObjAnim_Init(obj, x,  y);
        obj->spr_count          = 6;
        obj->spr_height         = 8;
        obj->spr_def_start      = SPRITE_DEF_NUM_YOUWIN;
        obj->spr_def_pitch      = 8;
        //obj->isDisplayOneFrame  = TRUE;
        GameObjAnim_ShowOnlyFirstFrame(obj);

    }
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
}

void GameObjYouWin_SetState(GameObjYouWin* this, ObjState state)
{

    // if object already in that state, return
    if(state == this->state)
        return;
    this->state = state;

}


void helper_GameObjYouWin_StartAnimation(byte num_player)
{
    short x, y;

    x = ((SCREEN_WIDTH/2) - SPR_YOUWIN_WIDTH*16)/2;
    y = ((SCREEN_HEIGHT)  - SPR_YOUWIN_HEIGHT*16)/2;
    if(num_player == 1) {
        x = x + SCREEN_WIDTH/2;
        //y = y + SCREEN_HEIGHT/2;
    }

    if(YouWinAnim.gobj.in_use) return;
    // Init YouWin animation for winner player
    YouWinAnim.gobj.in_use = TRUE;
    GameObjYouWin_Init(&YouWinAnim, x, y);
    PoolGameObj_AddObjToActiveObjects(&YouWinAnim.gobj);

    //Sound_NewFx(2);
    // stop score blinking
    GameObjScore_SetState(&scoreA, NORMAL); scoreA.is_show = TRUE;
    GameObjScore_SetState(&scoreB, NORMAL); scoreB.is_show = TRUE;

    game.isSoundfxEnabled = FALSE;
    game.isMusicEnabled   = TRUE;
}
