void GameObjBat_Init(GameObjBat* this, int x, int y)
{
    // init parent obj
    GameObj_Init((GameObj*)this);

    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjBat_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjBat_Draw);

    this->gobj.x = x;
    this->gobj.y = y;
    this->gobj.width  = BAT_WIDTH;
    this->gobj.height = BAT_HEIGHT;
    GameObj_InitCollideBox((GameObj*)this);

    this->state = NORMAL;
    this->max_dying_time = 250;
    this->dying_time = 0;
    this->rocket_creation_time = 0;
    this->rocket = NULL;

    this->pScore = (x < SCREEN_WIDTH/2) ? &scoreA : &scoreB;
}

void GameObjBat_SetState(GameObjBat* this, ObjState state)
{
   byte  i = 0;
   GameObjAnim *obj;
   word x;

    // if object already in that state, return
   if(state == this->state)
        return;
   this->state = state;

   if(this->state == DYING) {
       // helper_GameObjScore_UpdateScore();
       // add game obj
//       for(i=0; i<15; i++) {
           obj = PoolGameObj_AllocateGameObjAnim();
//           if(obj) GameObjAnim_Init(obj, this->xcoordinate+20+i*20, this->new_ycoordinate+20+i*20, i);
           //x = batA.xcoordinate - 4;
           //y = batA.old_ycoordinate;
           // add "bang" to game
           if(obj) {
               x = this->gobj.x;
               x > SCREEN_WIDTH/2 ? ( x -= 12) : (x -= 4);

               GameObjAnim_Init(obj, x/*(this->xcoordinate - 4)*/ /*+i*16*/, this->gobj.y /*+i*8*/);
               obj->spr_anim_time      = 50;   //-(i*10);
               obj->spr_anim_frames    = 7;
               obj->spr_count          = 2;
               obj->spr_height         = 2;
               obj->spr_def_start      = SPRITE_DEF_NUM_BANG1;
               obj->spr_def_pitch      = 7*2;
               obj->isLoopAnim         = FALSE;
               GameObjAnim_EnableAnimation(obj,TRUE);

           }

//       }//for i
         Sound_NewFx(SOUND_FX_SPLASH);
   }

}

void GameObjBat_Move(GameObjBat* this)
{
    GameObjBat_state_handler(this);
}

void GameObjBat_MoveUp(GameObjBat* this)
{

    if(this->state != NORMAL)
        return;


    if (this->gobj.y > 0) // Move only when bat is not touching the top so it doesnt jump out of screen.
    {
        //this->old_ycoordinate = this->new_ycoordinate;
        this->gobj.y --;
//        DrawBat (this->xcoordinate, this->new_ycoordinate,
//                 this->xcoordinate + this->width, this->new_ycoordinate + this->length);
    }

}


void GameObjBat_MoveDown(GameObjBat* this)
{

    if(this->state != NORMAL)
        return;

    if (this->gobj.y + this->gobj.height < GAME_FIELD_MAX_SCREEN_Y) // Make sure bat doesnot go below the screen.
    {
        //this->old_ycoordinate = this->new_ycoordinate;
        this->gobj.y ++;
//        DrawBat (this->xcoordinate, this->new_ycoordinate,
//                 this->xcoordinate + this->width, this->new_ycoordinate + this->length);
    }
}


void GameObjBat_Draw(GameObjBat* this)
{
    DrawBat (this->gobj.x, this->gobj.y,
             this->gobj.x + this->gobj.width, this->gobj.y + this->gobj.height);
}

//GameObjRocket rocket[2];    // static pool of rockets (GameObjRocket objects)
void GameObjBat_Fire(GameObjBat* this)
{
    GameObjRocket *new_obj;
    //BOOL isCanFire = FALSE;

    // bat can fire, only then in NORMAL mode
    if(this->state != NORMAL)
        return;
/*
    // maintain some delay
    if(this->rocket_creation_time + 150 > game.global_time)
        return;
    this->rocket_creation_time = game.global_time;
*/


    if(GameObjBat_IsCanFireWithRocket(this)) {
        // create and init the rocket object
        new_obj = PoolGameObj_AllocateGameObjRocket();
        if(new_obj){
            GameObjRocket_Init(new_obj, this->gobj.x, this->gobj.y);
            // set extra_field of allocated rocket obj to "this" pointer
            new_obj->gobj.extra_field1 = (word) this;
            // save ptr to rocket
            this->rocket = new_obj;
        }

        this->pScore->num_rockets--;
        Sound_NewFx(SOUND_FX_ROCKET);
        //debug.guard_str[0] = ' ';
    }


}




BOOL GameObjBat_IsCanFireWithRocket(GameObjBat* this)
{
    BOOL isCanFire = FALSE;

    if(!this->rocket) {
        isCanFire = TRUE;
    } else {
        // if rocket game obj is "in use" and was fired by this bat, then can't fire
        if(GameObj_GetInUse((GameObj*)this->rocket) && (GameObjBat*)this->rocket->gobj.extra_field1 == this)
            isCanFire = FALSE;
        else
            isCanFire = TRUE;
    }

    // is there are any rockets left in player ammun.
    if(this->pScore->num_rockets == 0)
        isCanFire = FALSE;


    return isCanFire;
}

void GameObjBat_state_handler(GameObjBat* this)
{
    if(this->state == DYING) {
        if(this->dying_time++ >= this->max_dying_time)
            GameObjBat_SetState(this, DIE);
    }


}
