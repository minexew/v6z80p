#ifndef OBJ_BAT_H
#define OBJ_BAT_H

#include "obj_.h"
#include "obj_rocket.h"
#include "obj_score.h"

// Game object: Bat
// The bat can fire a rocket



typedef struct
{
    GameObj gobj;

    //int xcoordinate;
    //int new_ycoordinate;
    //int old_ycoordinate;

    ObjState state;
    // dying stuff
    byte max_dying_time;
    byte dying_time;

    // rocket firing stuff
    word rocket_creation_time;
    GameObjRocket* rocket;

    // associated score object
    GameObjScore* pScore;
} GameObjBat;



// public --------------------------------------
void GameObjBat_Init(GameObjBat* this, int x, int y);
void GameObjBat_SetState(GameObjBat* this, ObjState state);
void GameObjBat_Move(GameObjBat* this);
void GameObjBat_MoveUp(GameObjBat* this);
void GameObjBat_MoveDown(GameObjBat* this);
void GameObjBat_Draw(GameObjBat* this);
void GameObjBat_Fire(GameObjBat* this);
BOOL GameObjBat_IsCanFireWithRocket(GameObjBat* this);
// private --------------------------------------
void GameObjBat_state_handler(GameObjBat* this);


#endif /* OBJ_BAT_H */