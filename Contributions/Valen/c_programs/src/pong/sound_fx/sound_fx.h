#ifndef SOUND_FX_H
#define SOUND_FX_H



// Sounds from Bounder
#define SOUND_FX_BONUS              2
#define SOUND_FX_BOUNCE             3
#define SOUND_FX_CRUNCH             4
#define SOUND_FX_FALL               5
#define SOUND_FX_LASER_SHOT         7
#define SOUND_FX_LASER_BOINGGG      9
#define SOUND_FX_POP_BANG           10
#define SOUND_FX_ROCKET             11
#define SOUND_FX_SPLASH             12
#define SOUND_FX_COLLECT_BONUS      14

typedef struct {
    byte priority_level;  //       - Priority level (0-255)
    byte duration;        //       - Time (in frames) that this effect is active (for priority system) (0-255)
    byte volume;          //       - Volume of sample (0-255)
    word sample_location; //       - Location of sample (word address in 128KB Sample RAM)
    word sample_lenght;   //       - Length of sample (in words)
    word sample_period;   //       - Period of sample
    word sample_loop_loc; //       - Loop location of sample (word address in 128KB Sample RAM)
    word sample_loop_len; //       - Loop length of sample (in words)
    // offset   $0d-$xxxx - First command byte (FX scripts can be as long as required)
} SOUND_FX;




// There is dedicated audio memory bank for sound stuff.
// (part of system memory)
// - sound fx desc
// - soundfx and MOD players
// - MOD pattern data
#define BANK_MUSIC_STUFF        1
// logic system memory bank (audio ram bank for MOD sample data)
// +2 is offset, because first 2 audio banks is used for soundfx samples
#define BANK_MOD_SAMPLE1        3+2

//
// Mamory map:
#define SOUND_FX_CODE           0x8000
#define SOUND_FX_CODE_MAX_SIZE  0x2000

#define SOUND_FX_DESC           (0x8000 + SOUND_FX_CODE_MAX_SIZE)
#define SOUND_MOD_PATTERN_DATA  (0x8000 + SOUND_FX_CODE_MAX_SIZE + 0x200)

// defines for inline asm
#define SOUND_FX__NEWFX     (SOUND_FX_CODE + 0x100 + 0)
#define SOUND_FX__PLAYFX    (SOUND_FX_CODE + 0x100 + 3)



#define MUSIC_INIT_TRACKER          (SOUND_FX_CODE + 0x100 + 3*2)
#define MUSIC_PLAY_TRACKER          (SOUND_FX_CODE + 0x100 + 3*3)
#define MUSIC_UPDATE_SOUND_HW       (SOUND_FX_CODE + 0x100 + 3*4)
#define MUSIC_SET_FORCE_SAMPLE_BASE (SOUND_FX_CODE + 0x100 + 3*5)

// list of pointers to sound effects
#define SOUND_FX__FXLIST    (SOUND_FX_CODE)

BOOL Sound_LoadSoundCode(void);
BOOL Sound_LoadSounds(void);
BOOL Sound_LoadFxDescriptors(void);
void Sound_InitFx();
byte Mod_FindHighestUsedPattern(const byte* pPatternData);
BOOL Mod_LoadMusicModule(const char* pFilename);
void MUSIC_Silence(void);
void MUSIC_Init(void);


#endif /* SOUND_FX_H */
























