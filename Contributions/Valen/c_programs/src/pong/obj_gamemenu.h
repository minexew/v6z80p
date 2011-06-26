#ifndef OBJ_GAMEMENU_H
#define OBJ_GAMEMENU_H

#include "obj_.h"

// Game object: GameMenu

typedef struct {
    GameObj gobj;


} GameObjGameMenu;

GameObjGameMenu gameMenu;


void GameObjGameMenu_Init(GameObjGameMenu* this, int x, int y);
void GameObjGameMenu_Move(GameObjGameMenu* this);
void GameObjGameMenu_Draw(GameObjGameMenu* this);


void GameObjGameMenu_AllocateAnimObjects(GameObjGameMenu* this);
void GameObjGameMenu_MoveAnimObjects(GameObjGameMenu* this);


#endif /* OBJ_GAMEMENU_H */