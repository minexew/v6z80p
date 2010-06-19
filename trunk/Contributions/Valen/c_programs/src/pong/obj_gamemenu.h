// Game object: GameMenu

typedef struct {
    GameObj gobj;


} GameObjGameMenu;

GameObjGameMenu gameMenu;


void GameObjGameMenu_Init(GameObjGameMenu* this, int x, int y);
void GameObjGameMenu_Move(GameObjGameMenu* this);
void GameObjGameMenu_Draw(GameObjGameMenu* this);

