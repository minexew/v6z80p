#ifndef OBJ_SCORE_H
#define OBJ_SCORE_H

#include "obj_.h"

// Game object: Score - store and display score of the player
typedef struct {
    GameObj gobj;   // <-- this must be a FIRST member of struct !! (to allow pointer cast to parent type)

    ObjState state;

    word score;
    char score_str[3];  // string representation of score       (3 chars)
    byte sprite_num;

    // blinking stuff
    byte off_time_counter;
    byte off_num_switches;
    BOOL is_show;

    byte sprite_num_RocketsIndicator;
    byte num_rockets;

} GameObjScore;



// public
void GameObjScore_Init(GameObjScore* this, int x, int y);
void GameObjScore_Move(GameObjScore* this);
void GameObjScore_Draw(GameObjScore* this);
void GameObjScore_UpdateScore(GameObjScore* this);
void GameObjScore_SetState(GameObjScore* this, ObjState state);
void GameObjScore_SetScore(GameObjScore* this, short score);
// private
void GameObjScore_draw_score(GameObjScore* this);

void GameObjScore_Draw_PlayerRocketsIndicator(GameObjScore* this);


// helpers
BOOL helper_GameObjScore_IsScoreBlinkedAtLeast(byte num);

#endif /* OBJ_SCORE_H */