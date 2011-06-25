#ifndef POOL_GAMEOBJ_H
#define POOL_GAMEOBJ_H

#include "obj_rocket.h"

// ---------- Pool of game objects ---------------------

#define POOL_OBJ__MAX_OBJECTS           32
// define, how many objects will be reserverd in "pool of game objects" (a number for each object type)
#define POOL_OBJ__TOTAL_GAME_OBJ_ANIM       15
#define POOL_OBJ__TOTAL_GAME_OBJ_ROCKET     2

// prototypes
void           PoolGameObj_Init(void);
GameObjRocket* PoolGameObj_AllocateGameObjRocket(void);

void         PoolGameObj_FreeGameObj(GameObj* gameObj);
GameObj*     PoolGameObj_AllocateGameObj(GameObj* pPool, word poolSize, byte objSize);
GameObjAnim* PoolGameObj_AllocateGameObjAnim();

BOOL PoolGameObj_AddObjToActiveObjects(GameObj* obj);
BOOL PoolGameObj_RemoveObjFromActiveObjects(GameObj* obj);
void PoolGameObj_ApplyFuncMoveToObjects();
void PoolGameObj_ApplyFuncDrawToObjects();



#endif /* POOL_GAMEOBJ_H */
