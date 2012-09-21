#include <v6z80p_types.h>

//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>

#include "sound_fx.h"
#include "../disk_io.h"
#include <base_lib/resource.h>
#include "../low_memory_container.h"
#include "handle_resource_error.h"


byte bufModFileHeader[1084];


static byte btmp;
static word wtmp;

BOOL Sound_LoadSoundCode(void)
{
    if(!Resource_LoadFileToBuffer("SFXPROXY.BIN", 0, (byte*)SOUND_FX_CODE, SOUND_FX_CODE_MAX_SIZE, BANK_MUSIC_STUFF))
       return Handle_Resource_Error();
    else
        return TRUE;
}

BOOL Sound_LoadSounds(void)
{
    byte* sfx_samples_addr = (byte*)0x8000;
    byte sfx_samples_bank = 3;

    if(!Resource_LoadFileToBuffer("SFX.SAM", 0, sfx_samples_addr, 65536, sfx_samples_bank))
        return Handle_Resource_Error();
     else
         return TRUE;
    //return load_file_to_buffer("ONE.RAW", 0, sfx_samples_addr, 4132, sfx_samples_bank);

}


BOOL Sound_LoadFxDescriptors(void)
{
    if(!Resource_LoadFileToBuffer("ALL_FX.BIN", 0, (byte*)SOUND_FX_DESC, 464, BANK_MUSIC_STUFF))
        return Handle_Resource_Error();
     else
         return TRUE;
}


void Sound_InitFx()
{
    /*sound_fx__one.fx.priority_level = 0x80;
    sound_fx__one.fx.duration = 0x10;
    sound_fx__one.fx.volume = 0xff;
    sound_fx__one.fx.sample_location = 0x00;
    sound_fx__one.fx.sample_lenght = 4132/2;
    sound_fx__one.fx.sample_period = 2000;
    sound_fx__one.fx.sample_loop_loc = 0;
    sound_fx__one.fx.sample_loop_len = 2;
    sound_fx__one.cmd = 0xff;*/

    //*((word*)SOUND_FX__FXLIST)          = (word) &sound_fx__one.fx;
    //*((word*)(SOUND_FX__FXLIST + 2))    = (word) &sound_fx__one.fx;
    //Sound_AddFxDesc(0,  &sound_fx__one.fx);
    //Sound_AddFxDesc(1,  &sound_fx__one.fx);

    Sound_AddFxDesc(0, (SOUND_FX*) (SOUND_FX_DESC + 0x00) );
    Sound_AddFxDesc(1, (SOUND_FX*) (SOUND_FX_DESC + 0x20) );
    Sound_AddFxDesc(2, (SOUND_FX*) (SOUND_FX_DESC + 0x50) );
    Sound_AddFxDesc(3, (SOUND_FX*) (SOUND_FX_DESC + 0x70) );
    Sound_AddFxDesc(4, (SOUND_FX*) (SOUND_FX_DESC + 0x90) );

    Sound_AddFxDesc(5, (SOUND_FX*) (SOUND_FX_DESC + 0xc0) );
    Sound_AddFxDesc(6, (SOUND_FX*) (SOUND_FX_DESC + 0xe0) );
    Sound_AddFxDesc(7, (SOUND_FX*) (SOUND_FX_DESC + 0x100) );
    Sound_AddFxDesc(8, (SOUND_FX*) (SOUND_FX_DESC + 0x120) );
    Sound_AddFxDesc(9, (SOUND_FX*) (SOUND_FX_DESC + 0x140) );
    Sound_AddFxDesc(10, (SOUND_FX*) (SOUND_FX_DESC + 0x150) );
    Sound_AddFxDesc(11, (SOUND_FX*) (SOUND_FX_DESC + 0x170) );
    Sound_AddFxDesc(12, (SOUND_FX*) (SOUND_FX_DESC + 0x180) );
    Sound_AddFxDesc(13, (SOUND_FX*) (SOUND_FX_DESC + 0x190) );
    Sound_AddFxDesc(14, (SOUND_FX*) (SOUND_FX_DESC + 0x1a0) );
    Sound_AddFxDesc(15, (SOUND_FX*) (SOUND_FX_DESC + 0x1b0) );

}




byte Mod_FindHighestUsedPattern(const byte* pPatternData)
{
    byte i;
    byte pat = 0;
    for(i=0; i<128; i++)
        if(pPatternData[i] > pat)
            pat = pPatternData[i];

    return pat;
}



BOOL Mod_LoadMusicModule(const char* pFilename)
{
//    FLOS_FILE myFile;
//    BOOL r;
    dword fileLen;
    byte pat;
    word patLen;             // length of pattern data part of file
    dword sampleLen;         // length of sample  data part of file


//    r = diag__FLOS_FindFile(&myFile, pFilename);
//    if(!r) return FALSE;
//    fileLen = myFile.size;
    fileLen = Resource_GetFileSize(pFilename);
    if(fileLen == -1) return FALSE;
//    printf("MOD fs: %li", fileLen);

    // load 1084 bytes
    if(!Resource_LoadFileToBuffer(pFilename, 0, bufModFileHeader, 1084, 0))
        return Handle_Resource_Error();


    // find highest used pattern in order to locate
    // the address where samples start
    pat = Mod_FindHighestUsedPattern(bufModFileHeader + 952);
    patLen = 1084 + (pat+1)*4*256;
    sampleLen = fileLen - (dword)patLen;

    /*_uitoa(pat, buffer, 16);        FLOS_PrintString(buffer);  FLOS_PrintString(PS_LFCR);
    _uitoa(patLen, buffer, 16);     FLOS_PrintString(buffer);  FLOS_PrintString(PS_LFCR);
    _uitoa(sampleLen, buffer, 16);  FLOS_PrintString(buffer);  FLOS_PrintString(PS_LFCR);*/

    // load pattern data (to dedicated system memory bank)
    if(!Resource_LoadFileToBuffer(pFilename, 0, (byte*) SOUND_MOD_PATTERN_DATA, patLen, BANK_MUSIC_STUFF))
        return Handle_Resource_Error();

    // load sample data (to audio memory bank)
    if(!Resource_LoadFileToBuffer(pFilename, patLen, (byte*) 0x8000, sampleLen, BANK_MOD_SAMPLE1))
        return Handle_Resource_Error();

    return TRUE;
}



void MUSIC_Silence(void)
{
    Music_InitTracker();
    Music_UpdateSoundHardware();
}

void MUSIC_Init(void)
{
    Music_SetForceSampleBase(0x10000/2);
    Music_InitTracker();


}



