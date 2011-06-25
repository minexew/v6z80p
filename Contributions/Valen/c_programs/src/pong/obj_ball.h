#ifndef OBJ_BALL_H
#define OBJ_BALL_H

#include "obj_.h"

// Game object: Ball
// gobj->x and gobj->y are coord of ball center point (not top left point)
typedef struct {
    GameObj gobj;

    int radius;
    int speedx;
    int speedy;

    ObjState state;

    // dying stuff
    byte max_dying_time;
    byte dying_time;

} GameObjBall;

// There is only one Ball object.
GameObjBall ball1;

void GameObjBall_Init(GameObjBall* this);
void GameObjBall_SetState(GameObjBall* this, ObjState state);

void GameObjBall_Move(GameObjBall* this);
void GameObjBall_CheckCollision(GameObjBall* this);
void GameObjBall_Draw(GameObjBall* this);



#endif /* OBJ_BALL_H */