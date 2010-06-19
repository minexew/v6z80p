// GameObjAnim -----------------------------------------
//



void GameObjAnim_Init(GameObjAnim* this, int x, int y/*, byte offset*/)
{
    this->gobj.x = x;
    this->gobj.y = y;
    //this->offset = offset;
    this->is_Xflip = FALSE;
    this->isLoopAnim = TRUE;
    //this->isDisplayOneFrame = FALSE;

    this->gobj.pMoveFunc = &GameObjAnim_Move;
    this->gobj.pDrawFunc = &GameObjAnim_Draw;

}


void GameObjAnim_Move(GameObjAnim* this)
{
//    this->gobj.x++; // do something
}

void GameObjAnim_Draw(GameObjAnim* this)
{
    byte i=0;
    word def;
    byte def_pitch = 0;

    if(!this->isAnimEnabled)
        return;
    Game_MarkFrameTime(0x0f0);
    //
//    set_sprite_regs(50+this->offset, this->gobj.x,  this->gobj.y, 3, 0, FALSE);

    if(this->spr_count != PoolSprites_AllocateSpriteNumber(this->spr_count))
        return;


    //if(this->spr_anim_time > this->spr_anim_frames) {
        // draw anim sprites
        for(i=0;i<this->spr_count;i++)  {
            def = ((this->spr_anim_def_offset/256U) * this->spr_height)  + def_pitch;
            set_sprite_regs(allocatedSpriteNumbers[i], this->gobj.x + i*16,  this->gobj.y,
                            this->spr_height,
                            this->spr_def_start + def,
                            /*FALSE*/this->is_Xflip);

/*
            spr_reg.sprite_number   = 50+i;
            spr_reg.x               = this->gobj.x + i*16;
            spr_reg.y               = this->gobj.y;
            spr_reg.height          = this->spr_height;
            spr_reg.sprite_definition_number = this->spr_def_start + def;
            spr_reg.x_flip          = FALSE;
            set_sprite_regs_optimized();
*/



            def_pitch += this->spr_def_pitch;
        }

        this->spr_anim_def_offset += this->spr_anim_def_step;
//        z->spr_anim_def_offset += z->spr_anim_def_step;
    //

    // loop animation frames

    if( (this->spr_anim_def_offset/256U) >= this->spr_anim_frames)
        if(this->isLoopAnim)
            GameObjAnim_init_animation(this);
        else
            GameObjAnim_Free(this);


    Game_MarkFrameTime(0xf00);
}

void GameObjAnim_EnableAnimation(GameObjAnim* this, BOOL isEnable)
{

    this->isAnimEnabled = isEnable;
    this->spr_anim_def_step = this->spr_anim_frames*256U / this->spr_anim_time;

    GameObjAnim_init_animation(this);
}

// private
void GameObjAnim_init_animation(GameObjAnim* this)
{

    //this->spr_anim_def_step   = 0;
    this->spr_anim_def_offset = 0 ;

}

// show only first frame of this anim obj (no animation)
void GameObjAnim_ShowOnlyFirstFrame(GameObjAnim* this)
{
    this->spr_anim_time      = 0;
    this->spr_anim_frames    = 0;
    GameObjAnim_EnableAnimation(this,TRUE);
}


void GameObjAnim_Free(GameObjAnim* this)
{
    PoolGameObj_FreeGameObj( (GameObj*)this );
}

/*
//---
// Game object: ScoreAnim - do score animation
// Blink few times a score of a winner.
// On last blink, we will show new score (incrased by 1)
typedef struct {
    GameObj gobj;   // <-- this must be a FIRST member of struct !! (to allow pointer cast to parent type)



} GameObjScoreAnim;


void GameObjScoreAnim_Init(GameObjScoreAnim* this, int x, int y)
{
    this->gobj.x = x;
    this->gobj.y = y;

    this->gobj.pMoveFunc = &GameObjAnim_Move;
    this->gobj.pDrawFunc = &GameObjAnim_Draw;

}
*/
