

#define EXTERN
#include "low_memory_container.h"

// forward declaration
// (We define struct with dummy members,
// thus compiler can compile pointer to it.
// We dont use that struct in this file.)
//typedef struct { char foo; } GameObjScore;  // <-- dummy definition



#include "pong.h"

//extern game_t game;

//const char qqq[]="LOWMEMCODE";

// We add 1 to bank numbers, because we use logical bank numbers in C code,
// (When adding 1, we convert to hardware banks.)
//
#define SET_MUSIC_BANK              io__sys_mem_select = BANK_MUSIC_STUFF+1
// TODO: take pong bank from DEFINE
#define SET_PONG_MAIN_BANK          io__sys_mem_select = PONG_BANK + 1

//
#define SET_MUSIC_BANK_ASM          push af                         \
                                    ld a,#BANK_MUSIC_STUFF + #1     \
                                    out (#SYS_MEM_SELECT), a        \
                                    pop af

// TODO: take pong bank from DEFINE
#define SET_PONG_MAIN_BANK_ASM      push af                         \
                                    ld a,#PONG_BANK + #1                    \
                                    out (#SYS_MEM_SELECT), a        \
                                    pop af


// globals, used to get func params and make avail. for asm code
static byte btmp1;
static word wtmp1;


void Sound_NewFx(byte fx_number)
{
    if(!game.isSoundfxEnabled) return;
    btmp1 = fx_number;

    asmproxy__Sound_NewFx();
}

void asmproxy__Sound_NewFx(void)
{
    BEGINASM()
    PUSH_ALL_REGS()
    ld a,(#_btmp1)
    di
    SET_MUSIC_BANK_ASM

    call SOUND_FX__NEWFX
    SET_PONG_MAIN_BANK_ASM
    ei
    POP_ALL_REGS()
    ENDASM()
}

void Sound_PlayFx(void)
{
    if(!game.isSoundfxEnabled) return;

    DI();
    SET_MUSIC_BANK;
    BEGINASM();
    PUSH_ALL_REGS();

    call SOUND_FX__PLAYFX
    POP_ALL_REGS();
    ENDASM();
    SET_PONG_MAIN_BANK;
    EI();
}



// sound say "one" only one time
struct
{

    SOUND_FX fx;
    byte cmd;
} sound_fx__one = {
    {0x80, 0x10, 0xff,  0, 4132/2, 2000, 0, 2}, 0xff
};


void Sound_AddFxDesc(byte fx_number,  SOUND_FX* p)
{
    DI();
    SET_MUSIC_BANK;

    ((word*)SOUND_FX__FXLIST)[fx_number] = (word)p;
    SET_PONG_MAIN_BANK;
    EI();

}


// mod music player interface ---------------
void Music_InitTracker(void)
{
    BEGINASM();
    PUSH_ALL_REGS();
    di
    SET_MUSIC_BANK_ASM;

    call MUSIC_INIT_TRACKER
    SET_PONG_MAIN_BANK_ASM;
    ei
    POP_ALL_REGS();
    ENDASM();
}

void Music_PlayTracker(void)
{
    BEGINASM();
    PUSH_ALL_REGS();
    di
    SET_MUSIC_BANK_ASM;

    call MUSIC_PLAY_TRACKER
    SET_PONG_MAIN_BANK_ASM;
    ei
    POP_ALL_REGS();
    ENDASM();
}

void Music_UpdateSoundHardware(void)
{
    BEGINASM();
    PUSH_ALL_REGS();
    di
    SET_MUSIC_BANK_ASM;

    call MUSIC_UPDATE_SOUND_HW
    SET_PONG_MAIN_BANK_ASM;
    ei
    POP_ALL_REGS();
    ENDASM();

    // MUSIC_UPDATE_SOUND_HW trashes zero entry of mult table, we will restore that entry
    mm__mult_table = 0;     // restore sin table first entry
}

// base = word address in audio RAM
void Music_SetForceSampleBase(word base)
{
    wtmp1 = base;

    BEGINASM();
    PUSH_ALL_REGS();
    ld hl,(#_wtmp1)
    di
    SET_MUSIC_BANK_ASM;

    call MUSIC_SET_FORCE_SAMPLE_BASE
    SET_PONG_MAIN_BANK_ASM;
    ei
    POP_ALL_REGS();
    ENDASM();
}


