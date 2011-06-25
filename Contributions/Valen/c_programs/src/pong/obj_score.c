#include <v6z80p_types.h>

#include <stdlib.h>


#include "obj_score.h"
#include "obj_youwin.h"
#include "low_memory_container.h"
#include "sprites.h"
#include "pong.h"
#include "v6assert.h"


void GameObjScore_Init(GameObjScore* this, int x, int y)
{
    this->gobj.x = x;
    this->gobj.y = y;

    this->gobj.pMoveFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjScore_Move);
    this->gobj.pDrawFunc = CAST_GAME_OBJ_FUNC_PTR_TO_CORRECT_TYPE(&GameObjScore_Draw);

    this->state = NORMAL;

//    this->score = 0;
//    this->num_rockets = 3;

    this->is_show = TRUE;
    this->off_time_counter = this->off_num_switches = 0;


}

void GameObjScore_Move(GameObjScore* this)
{
    if(this->state == BLINKING) {
        if(this->off_time_counter > 25) {
            this->off_num_switches++;
            this->off_time_counter = 0;

            if(this->off_num_switches & 1)
                Sound_NewFx(SOUND_FX_LASER_SHOT);
        }
        this->off_time_counter++;

        this->is_show = this->off_num_switches & 1;
    }

    // check if its time to start youwin anim
    if(this->score >= MAX_SCORE_FOR_LEVEL &&
                    this->state == BLINKING && this->off_num_switches >= 8) {
        if(this == &scoreA)
            helper_GameObjYouWin_StartAnimation(0);
        else
            helper_GameObjYouWin_StartAnimation(1);

    }
}

void GameObjScore_Draw(GameObjScore* this)
{
    if(this->is_show) {
        GameObjScore_draw_score(this);
    }

    GameObjScore_Draw_PlayerRocketsIndicator(this);
}


// draw score sprites
// ASSERT: strlen(score_str) <= 2   (2 chars + zero byte)
void GameObjScore_draw_score(GameObjScore* this)
{
//word *pw;

    byte spr_height;
    byte spr1_def, spr2_def;
    char* p = this->score_str;
    int x = this->gobj.x; int y =  this->gobj.y;
    V6ASSERT(this->score <= MAX_SCORE_FOR_LEVEL);

//pw  = (word*)0xF000;
//*pw++ = 0x1234; *pw++ = this->score; *pw++ = (word)this->score_str; while(1);

    spr1_def = SPRITE_DEF_NUM_DIGIT + (p[0] - 0x30);
    if(p[1] != 0)
        spr2_def = SPRITE_DEF_NUM_DIGIT + (p[1] - 0x30);
    else
        spr2_def = 0xff;


//    set sprite data
    spr_height = 1;
    set_sprite_regs(this->sprite_num  , x,      y, spr_height, spr1_def, FALSE, FALSE);
/*
    if(spr2_def == 0xff)
        y = 256;        // put sprite off-screen
    set_sprite_regs(this->sprite_num+1, x+16,   y, spr_height, spr2_def, FALSE);
*/

    if(spr2_def != 0xff)
        set_sprite_regs(this->sprite_num+1, x+16,   y, spr_height, spr2_def, FALSE, FALSE);


}


// Convert score to string.
// (do conversion with (a bit) slow C library call)
void GameObjScore_UpdateScore(GameObjScore* this)
{
    // word to ASCII

    // uitoa worked fine in SDCC 2.9.0 but failed in 2.9.7 TODO: why?
    _ultoa(this->score, this->score_str, 10);

}

void GameObjScore_SetState(GameObjScore* this, ObjState state)
{

    // if object already in that state, return
    if(state == this->state)
        return;
    this->state = state;

    if(this->state == BLINKING) {
        // init blinking
        this->off_time_counter = this->off_num_switches = this->is_show = 0;
    }

}

void GameObjScore_SetScore(GameObjScore* this, short score)
{
    this->score = score;
    GameObjScore_UpdateScore(this);
}

/*
void helper_GameObjScore_UpdateScore(void)
{
    GameObjScore_UpdateScore(&scoreA);
    GameObjScore_UpdateScore(&scoreB);
}
*/

// Return TRUE, if one of the scores (scoreA or scoreB) is blinked at least num times.
BOOL helper_GameObjScore_IsScoreBlinkedAtLeast(byte num)
{
    return ((scoreA.state == BLINKING  && scoreA.off_num_switches >= num) ||
            (scoreB.state == BLINKING  && scoreB.off_num_switches >= num));
}

/*
void score_guard(void){
    if(score_game.score_B == 2)
        Bat_SetState(&batA, DYING);
}
*/


// ----
void GameObjScore_Draw_PlayerRocketsIndicator(GameObjScore* this)
{
//    set sprite data
    byte spr_height = 1;
    byte i;

    for(i=0; i<this->num_rockets; i++)
        set_sprite_regs(this->sprite_num_RocketsIndicator + i,
                        this->gobj.x + i*8, this->gobj.y + 16, spr_height,
                        SPRITE_DEF_NUM_ROCKET_VERTICAL, FALSE, FALSE);
}
