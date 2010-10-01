// Generic game object (parent for others game objects)
typedef enum {
    NORMAL = 0,
    DYING,
    DIE,

    // GameObjScore states
    BLINKING
} ObjState;

//typedef struct GameObj_tag *GAME_OBJ_PTR;

typedef struct GameObj_tag {
    BOOL in_use;        // is this object used or no? (allocated from objects pool or not?)

    int x, y;
    int width, height;
    // bounding box vars (used for collision detection)
    word col_width;
    word col_height;
    word col_x_offset, col_y_offset;

    word extra_field1;  // this var can be used by other objects to store some context info
                        //
    // virtual funcs, must be implemented in child objects
    void (*pMoveFunc)(struct GameObj_tag* this);
    void (*pDrawFunc)(struct GameObj_tag* this);

} GameObj;

//typedef struct GameObj_tag GameObj;


#define CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(func1)      (void ()(struct GameObj_tag*))   func1

void GameObj_SetPos(GameObj* this, int x, int y);
void GameObj_SetInUse(GameObj* this, BOOL inUse);
BOOL GameObj_GetInUse(GameObj* this);


// access funcs
void GameObj_SetPos(GameObj* this, int x, int y)
{
    this->x = x;
    this->y = y;
}


void GameObj_SetInUse(GameObj* this, BOOL inUse)
{
    this->in_use = inUse;
}

BOOL GameObj_GetInUse(GameObj* this)
{
    return this->in_use;
}


//word dbg[8];
//#define ppp ((byte volatile *) 0x1234)






