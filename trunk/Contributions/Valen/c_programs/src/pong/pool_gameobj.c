// ---------- Pool of game objects ---------------------

#define POOL_OBJ__MAX_OBJECTS           32
// define, how many objects will be reserverd in "pool of game objects" (a number for each object type)
#define POOL_OBJ__TOTAL_GAME_OBJ_ANIM       15
#define POOL_OBJ__TOTAL_GAME_OBJ_ROCKET     2

typedef struct  {
  // pool of game objects
  GameObjAnim pool_GameObjAnim  [POOL_OBJ__TOTAL_GAME_OBJ_ANIM];
  GameObjAnim pool_GameObjRocket[POOL_OBJ__TOTAL_GAME_OBJ_ROCKET];


  GameObj* active_objects[POOL_OBJ__MAX_OBJECTS];

} PoolGameObj;
PoolGameObj pool_game_obj;

// prototypes
void PoolGameObj_Init(void);
GameObj*     PoolGameObj_AllocateGameObj(GameObj* pPool, word poolSize, byte objSize);
GameObjAnim* PoolGameObj_AllocateGameObjAnim();

BOOL PoolGameObj_AddObjToActiveObjects(GameObj* obj);
BOOL PoolGameObj_RemoveObjFromActiveObjects(GameObj* obj);
void PoolGameObj_ApplyFuncMoveToObjects();
void PoolGameObj_ApplyFuncDrawToObjects();


void PoolGameObj_Init(void)
{
    memset(&pool_game_obj, 0, sizeof(pool_game_obj));
}

// Allocation.
GameObjAnim* PoolGameObj_AllocateGameObjAnim(void)
{

    return (GameObjAnim*) PoolGameObj_AllocateGameObj((GameObj*)pool_game_obj.pool_GameObjAnim,
                                POOL_OBJ__TOTAL_GAME_OBJ_ANIM, sizeof(GameObjAnim));
}

GameObjRocket* PoolGameObj_AllocateGameObjRocket(void)
{
    return (GameObjRocket*) PoolGameObj_AllocateGameObj((GameObj*)pool_game_obj.pool_GameObjRocket,
                                POOL_OBJ__TOTAL_GAME_OBJ_ROCKET, sizeof(GameObjRocket));
}


// Dealocation.
// Remove object from active objects list
// and Returns object back to objects pool.
void PoolGameObj_FreeGameObj(GameObj* gameObj)
{
    PoolGameObj_RemoveObjFromActiveObjects(gameObj);
    gameObj->in_use = FALSE;
}


// ------
// Allocation of generic obj.
GameObj* PoolGameObj_AllocateGameObj(GameObj* pPool, word poolSize, byte objSize)
{
    word i;
    GameObj* gameObj;

    for(i=0; i<poolSize; i++) {
       gameObj = pPool;
       if(!gameObj->in_use) {
           gameObj->in_use = TRUE;
           PoolGameObj_AddObjToActiveObjects(gameObj);
           return gameObj;
       }
       pPool = (GameObj*) ( ((byte*)pPool) + objSize );     // move ptr to next obj in pool
   }
    return NULL;

}
// ----------

BOOL PoolGameObj_AddObjToActiveObjects(GameObj* obj)
{
    GameObj** p;

    for(p = pool_game_obj.active_objects;
        p < pool_game_obj.active_objects + (sizeof(pool_game_obj.active_objects) / sizeof(p));
        p++)
        if(*p == NULL) {
            *p = obj;
            return TRUE;
        }

    return FALSE;
}



BOOL PoolGameObj_RemoveObjFromActiveObjects(GameObj* obj)
{
    GameObj** p;

    for(p = pool_game_obj.active_objects;
        p < pool_game_obj.active_objects + (sizeof(pool_game_obj.active_objects) / sizeof(p));
        p++)
        if(*p == obj) {
            *p = NULL;
            return TRUE;
        }

    return FALSE;
}

#define APPLY_FUNC_TO_ACTIVE_OBJECTS(func)              \
    for(i=0; i<POOL_OBJ__MAX_OBJECTS; i++) {            \
        obj = pool_game_obj.active_objects[i];          \
        if( obj ) {                                     \
            (*(obj->func))(obj);                        \
        }                                               \
    }

void PoolGameObj_ApplyFuncMoveToObjects()
{

    word i;
    GameObj* obj;

    APPLY_FUNC_TO_ACTIVE_OBJECTS(pMoveFunc);
}

void PoolGameObj_ApplyFuncDrawToObjects()
{

    word i;
    GameObj* obj;

    APPLY_FUNC_TO_ACTIVE_OBJECTS(pDrawFunc);

}
