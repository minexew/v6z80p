
static byte btmp1;
static word wtmp1;



// first effect number is 1 (not 0)
void Sound_NewFx(byte fx_number)
{  
    btmp1 = fx_number;

    BEGINASM();
    PUSH_ALL_REGS();
    ld a,(#_btmp1)

    call SOUND_FX__NEWFX
    POP_ALL_REGS();
    ENDASM();
}


void Sound_PlayFx(void)
{
    BEGINASM();
    PUSH_ALL_REGS();

    call SOUND_FX__PLAYFX
    POP_ALL_REGS();
    ENDASM();
}

// To use this function, you should set stack (in your Makefile)  below 0x8000.
// 
BOOL Sound_LoadSounds(void)
{
    byte* sfx_samples_addr = (byte*)0x8000;
    byte sfx_samples_bank = 3;

    return FileOp_LoadFileToBuffer("MY_FX1.SAM", 0, sfx_samples_addr, 35684, sfx_samples_bank);
}
