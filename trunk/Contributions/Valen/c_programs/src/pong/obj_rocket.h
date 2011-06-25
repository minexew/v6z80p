#ifndef OBJ_ROCKET_H
#define OBJ_ROCKET_H

#include "obj_.h"
#include "obj_anim.h"

// Game object: Rocket
// The bat can fire a rocket,
// rocket can destroy the other bat.
typedef struct {
    GameObj gobj;

    GameObjAnim *animObj;
    GameObjAnim *animObj1;
    //GameObjAnim *animObj2;

    // Signed fixed point values.
    // Fixed format: 24.8
    long        my_x;
    // Fixed format: 8.8
    short       x_speed;         // speed, started from const value,
                                 // increased by speed_acc every one frame,
                                 // until it reach max speed value
    short       x_speed_acc;

    BOOL        isMovingToTheRight;




} GameObjRocket;



// GameObjRocket -----------------------------------------
//

// prototypes
void GameObjRocket_Init(GameObjRocket* this, int x, int y);
void GameObjRocket_Move(GameObjRocket* this);
void GameObjRocket_CheckCollision(GameObjRocket* this);
void GameObjRocket_Draw(GameObjRocket* this);
void GameObjRocket_Free(GameObjRocket* this);
// private
void GameObjRocket_AllocateAnimationObj(GameObjRocket* this);



#endif /* OBJ_ROCKET_H */