#ifndef SOUND_FX_H
#define SOUND_FX_H





// SOUND_FX_CODE - start of fx_player code in your program
#ifndef SOUND_FX_CODE
#error SOUND_FX_CODE must be defined!
#endif


// defines for inline asm
// (jump table offsets)
#define SOUND_FX__NEWFX     (SOUND_FX_CODE + 0)
#define SOUND_FX__PLAYFX    (SOUND_FX_CODE + 3)


#endif /* SOUND_FX_H */
