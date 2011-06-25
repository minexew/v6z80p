#include <v6z80p_types.h>

#include "obj_rocket.h"
#include "obj_anim.h"
#include "obj_bat.h"
#include "pool_gameobj.h"
#include "sprites.h"
#include "pong.h"



void GameObjRocket_Init(GameObjRocket* this, int x, int y)
{
    // init parent obj
    GameObj_Init((GameObj*)this);

    this->gobj.x = x;
    this->gobj.y = y;
    this->gobj.width  = 16*2;
    this->gobj.height = 16;

    this->my_x = (dword)x << 8;
    //
    GameObj_InitCollideBox((GameObj*)this);

    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjRocket_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjRocket_Draw);


    if(x < SCREEN_WIDTH/2) {
        this->x_speed = 2 << 8;
        this->x_speed_acc = 0x0010;
        this->isMovingToTheRight = TRUE;
    }
    else {
        this->x_speed = -2 << 8;
        this->x_speed_acc = -0x0010;
        this->isMovingToTheRight = FALSE;
    }

    // rocket is moved (fired) to enemy bat
    GameObjRocket_AllocateAnimationObj(this);
}


void GameObjRocket_Move(GameObjRocket* /*restrict*/ this)
{
    char xo, xo1;   //, xo2;
    int cur_x, /*cur_y,*/ width;
    char speed;


    // move rocket obj
    this->my_x += this->x_speed;
    this->gobj.x = ((dword)this->my_x >> 8);

    // acellerate speed
    speed = ((word)this->x_speed >> 8);
    if( (speed > 0 && speed < 4) || (speed < 0 && speed > -4) )
        this->x_speed += this->x_speed_acc;

    // move own anim objects
    if(this->isMovingToTheRight){
        xo = 0; xo1 = 16*1;     //xo2 = 16*2;
    } else {
        xo = 16*1; xo1 = 0;     //xo2 = 0;
    }
    GameObj_SetPos(&this->animObj->gobj,  this->gobj.x + xo,   this->gobj.y);
    GameObj_SetPos(&this->animObj1->gobj, this->gobj.x + xo1,  this->gobj.y);
    //GameObj_SetPos(this->animObj2, this->gobj.x + xo2,  this->gobj.y);

    cur_x = this->gobj.x;
    width = this->gobj.width;
    // if rocket goes offscren, delete rocket
    if(cur_x > SCREEN_WIDTH || cur_x + width < 0){
        GameObjRocket_Free(this);
    }

    GameObjRocket_CheckCollision(this);
}




void GameObjRocket_CheckCollision(GameObjRocket* this)
{
    //static RECT r1, r2;             // globals, just for speed
    GameObjBat*    pBatCandidateForKill;
    GameObj* gameObj;

    gameObj = &this->gobj;
    /*r1.x      = gameObj->x + gameObj->col_x_offset;
    r1.y      = gameObj->y + gameObj->col_y_offset;
    r1.width  = gameObj->col_width;
    r1.height = gameObj->col_height;*/

    if(this->isMovingToTheRight)
    {
        pBatCandidateForKill = &batB;
    } else {
        pBatCandidateForKill = &batA;
    }
    // check collision with candidate for kill
    /*r2.x      = pBatCandidateForKill->gobj.x;
    r2.y      = pBatCandidateForKill->gobj.y;
    r2.width  = pBatCandidateForKill->gobj.width;
    r2.height = pBatCandidateForKill->gobj.height;*/

    if(pBatCandidateForKill->state == NORMAL) {
        /*if(Math_IsBoxHitBox(&r1, &r2) )
            GameObjBat_SetState(pBatCandidateForKill, DYING);*/

        if(GameObj_Collide((GameObj*)this, (GameObj*)pBatCandidateForKill))
            GameObjBat_SetState(pBatCandidateForKill, DYING);
    }

    /*dbg[0] = r1.x;
    dbg[1] = r1.y;
    dbg[2] = r1.width;
    dbg[3] = r1.height;

    dbg[4] = r2.x;
    dbg[5] = r2.y;
    dbg[6] = r2.width;
    dbg[7] = r2.height;*/
}

void GameObjRocket_Draw(GameObjRocket* this)
{
        this;

}


// this global struct is related to GameObjRocket_AllocateAnimationObj() func
typedef struct {
    //BOOL    isAnimationEnable;
    byte    spr_anim_time;
    byte    spr_anim_frames;
    byte    spr_count;
    byte    spr_height;
    word    spr_def_start;
    byte    spr_def_pitch;
    } OwnAnimObjConst;
OwnAnimObjConst const g_ownAnimObjConst[] = {
       {/*TRUE,*/  12, 3, 1, 1, SPRITE_DEF_NUM_ROCKET_TAIL1,   0},
       {/*FALSE,*/ 50, 1, 1, 1, SPRITE_DEF_NUM_ROCKET_TOP1, 0},
//       {/*FALSE,*/ 50, 1, 1, 1, SPRITE_DEF_NUM_ROCKET_TOP, 0}
                       };
// allocate animation objects, which will visually represent rocket game object
void GameObjRocket_AllocateAnimationObj(GameObjRocket* this)
{
    GameObjAnim *obj;
    GameObjAnim **p;
    OwnAnimObjConst* pConst;
    byte i;

    struct {
        GameObjAnim** ptr;
    } ownAnimObj[] = { {&this->animObj}, {&this->animObj1}, /*{&this->animObj2}*/
                     };

    pConst = g_ownAnimObjConst;
    for(i=0; i<sizeof(ownAnimObj)/sizeof(ownAnimObj[0]); i++) {
        obj = PoolGameObj_AllocateGameObjAnim();
        p = ownAnimObj[i].ptr;
        *p = obj;

       // init "rocket" animation
       if(obj) {
           GameObjAnim_Init(obj, 0, SPRITE_Y_OFFSCREEN);         // initialy put offscreen
           obj->spr_anim_time      = pConst->spr_anim_time;
           obj->spr_anim_frames    = pConst->spr_anim_frames;
           obj->spr_count          = pConst->spr_count;
           obj->spr_height         = pConst->spr_height;
           obj->spr_def_start      = pConst->spr_def_start;
           obj->spr_def_pitch      = pConst->spr_def_pitch;
           GameObjAnim_EnableAnimation(obj,TRUE);
            // if this rocket is flying from left to right, then X flip anim objects
            if(this->isMovingToTheRight){
                obj->is_Xflip = TRUE;
            }
        }

        pConst++;
    }//for


}

void GameObjRocket_Free(GameObjRocket* this)
{
    // free visual objects (which was created previosly by this object)
    PoolGameObj_FreeGameObj( (GameObj*)this->animObj );
    PoolGameObj_FreeGameObj( (GameObj*)this->animObj1 );
    //PoolGameObj_FreeGameObjAnim( (GameObj*)this->animObj2 );
    // free this object
    PoolGameObj_FreeGameObj( (GameObj*)this );
}
