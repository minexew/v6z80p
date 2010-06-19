// Game object: YouWin
// Display YouWin animation

#define SPR_YOUWIN_WIDTH    6
#define SPR_YOUWIN_HEIGHT   8

#define NUM_EMERLADS    7

typedef struct {
    GameObj gobj;

    ObjState state;

    GameObjAnim* emerlads[NUM_EMERLADS];
    FIXED88      angle;
    word         lifeTime;

} GameObjYouWin;


GameObjYouWin YouWinAnim;

void GameObjYouWin_Move(GameObjYouWin* this);
void GameObjYouWin_Draw(GameObjYouWin* this);
void GameObjYouWin_AllocateAnimObjects(GameObjYouWin* this);
void GameObjYouWin_SetState(GameObjYouWin* this, ObjState state);

void helper_GameObjYouWin_StartAnimation(byte num_player);
