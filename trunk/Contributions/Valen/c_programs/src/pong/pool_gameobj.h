#ifndef POOL_GAMEOBJ_H
#define POOL_GAMEOBJ_H

#include "obj_rocket.h"
//#include "pong.h"

// ---------- Pool of game objects ---------------------

#define POOL_OBJ__MAX_OBJECTS           32
// define, how many objects will be reserverd in "pool of game objects" (a number for each object type (class) )
#define POOL_OBJ__TOTAL_GAME_OBJ_ANIM       15
#define POOL_OBJ__TOTAL_GAME_OBJ_ROCKET     2

// prototypes
void           PoolGameObj_Init(void);


void         PoolGameObj_FreeGameObj(GameObj* gameObj);
GameObj*     PoolGameObj_AllocateGameObj(GameObj* pPool, word poolSize, byte objSize);
// allocation of game objects
GameObjAnim*   PoolGameObj_AllocateGameObjAnim();
GameObjRocket* PoolGameObj_AllocateGameObjRocket(void);

BOOL PoolGameObj_AddObjToActiveObjects(GameObj* obj);
BOOL PoolGameObj_RemoveObjFromActiveObjects(GameObj* obj);
void PoolGameObj_ApplyFuncMoveToObjects();
void PoolGameObj_ApplyFuncDrawToObjects();

GameObj** PoolGameObj_GetListOfActiveObjects(void);



#endif /* POOL_GAMEOBJ_H */
