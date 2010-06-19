#ifndef PONG_H
#define PONG_H

#define PONG_BANK                     0     // main PONG bank (Logical! Not physical.)

#define SCREEN_WIDTH                  368
#define SCREEN_HEIGHT                 240

#define BAT_WIDTH                     8
#define BAT_HEIGHT                    32

#define GAME_FIELD_MAX_SCREEN_Y       240
#define GAME_FIELD_X_BORDER           10
#define MAX_SCORE_FOR_LEVEL           10

#define RAND()                        rand()

// we use wide left border (no realy reason for using left border, just want to test it)
#define IS_WIDE_LEFT_BORDER

// ----------- filenames
#define MUSIC_MENU_FILENAME         "BALLDRE2.MOD"
#define MUSIC_YOUWIN_FILENAME       "MONDAY.MOD"

#define PALETTE_MENU_FILENAME       "MENU.PAL"
#define PALETTE_LVL_FILENAME        "B1.PAL"
#define TILES_MENU_FILENAME         "MENU.TIL"
#define TILES_LVL_FILENAME          "B1.TIL"

#define SPRITES_FILENAME            "PONG.SPR"

#define SPRITES_DISKETTE_FILENAME   "LOAD_ICO.SPR"
#define PALETTE_DISKETTE_FILENAME   "LOAD_ICO.PAL"

#define TILES_CREDITS_FILENAME      "CREDITS.TIL"

#define TILES_CREDITS_VRAM_ADDR     0x16000         // must be div by 0x1000 without reminder



typedef enum {
    LEVEL = 0,
    MENU,
    CREDITS,
    STARTUP,
} GameState;

typedef struct {
    GameState game_state;

    BOOL isRequestSetState;
    GameState new_state;

    BOOL is_one_player_mode;
    BOOL is_paused, is_user_pressed_pause;
    BOOL is_debug_mode;

    BOOL isSoundfxEnabled;
    BOOL isMusicEnabled;

    //BOOL isDisketteIconLoaded;
    BOOL isFLOSVideoMode;

    GameObjScore* pScore_to_blink;

    byte shadow_sprite_register_bank;
//    byte max_score_per_round;
    word global_time;       // frames counter - (50Hz)
} game_t;


typedef struct  {
    byte offset_gameobj_for_debug_render;

    BOOL isShowFrameTime;
} debug_t;


/*static inline void myinline(BOOL b)
{
    byte a = 0;
    game.is_one_player_mode = b;

}*/

void Game_InitLevelBegining(void);

void Game_Initialize(void);
void Game_InitializeLevelGameObjects(void);
void Game_InitializeMenuGameObjects(void);
void Game_RequestSetState(GameState state);
BOOL Game_SetState(GameState state);
void Game_Movebat(char input);
BOOL Game_LoadSinTable(void);

void Game_MarkFrameTime(ushort color);


#endif /* PONG_H */
