#ifndef OBJ_GAMEMENU_H
#define OBJ_GAMEMENU_H

#include "obj_.h"
#include "obj_anim.h"

// Game object: GameMenu

typedef struct {
    GameObj gobj;

} GameObjGameMenu;




void GameObjGameMenu_Init(GameObjGameMenu* this, int x, int y);
void GameObjGameMenu_Move(GameObjGameMenu* this);
void GameObjGameMenu_Draw(GameObjGameMenu* this);



// *************************************
// Game object: GameMenuTxt

typedef struct {
    GameObj gobj;

    GameObjAnim* menuTxt;
    short        x_pos, y_pos;
    FIXED88      angle;
//    WORD         time_hold_position;
} GameObjMenuTxt;

void GameObjMenuTxt_Init(GameObjMenuTxt* this, int x, int y);
void GameObjMenuTxt_Move(GameObjMenuTxt* this);
void GameObjMenuTxt_Draw(GameObjMenuTxt* this);

void GameObjMenuTxt_AllocateAnimObjects(GameObjMenuTxt* this);
void GameObjMenuTxt_MoveAnimObjects(GameObjMenuTxt* this);


// *************************************
// Interpolator

#define MAX_IPOL_KEYS 10
typedef struct { WORD time;  short key; } IpolKey;
typedef struct {
// private
    IpolKey     key_array [MAX_IPOL_KEYS];
    BYTE        key_index;

} Ipol;



#endif /* OBJ_GAMEMENU_H */
