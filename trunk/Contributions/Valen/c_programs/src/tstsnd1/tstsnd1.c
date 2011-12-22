/*
   Basic sound fx example.
   How to use fx_player to play sound fx.
           
*/
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>

#include <base_lib/file_operations.h>


#include <stdlib.h>
#include <string.h>




#include "fx_player/sound_fx.h"
#include "fx_player/sound_fx.c"




void DoMain(void)
{    
    byte key_ASCII, key_Scancode;
    byte sfxNumber = 0;
    
    Sound_PlayFx();
    
    FLOS_GetKeyPress(&key_ASCII, &key_Scancode);
    
    if(key_ASCII == (byte)'1') sfxNumber = 1;
    if(key_ASCII == (byte)'2') sfxNumber = 2;
    if(key_ASCII == (byte)'3') sfxNumber = 3;
    if(key_ASCII == (byte)'4') sfxNumber = 4;
    if(key_ASCII == (byte)'5') sfxNumber = 5;
    if(key_ASCII == (byte)'6') sfxNumber = 6;
    if(key_ASCII == (byte)'7') sfxNumber = 7;
    // fx_player first effect number is 1 (not 0)
    if(sfxNumber) 
        Sound_NewFx(sfxNumber);
    
}






int main(void)
{    
    BOOL done = FALSE;
    
    FLOS_PrintStringLFCR("Call FX player from C code.");
    FLOS_PrintStringLFCR("Use keys 1..7 to play sound FX.");
    
    FLOS_PrintStringLFCR("Loading samples...");
    if(!Sound_LoadSounds())
        return NO_REBOOT;
    FLOS_PrintStringLFCR("ok");

 

    while(!done) {
        FLOS_WaitVRT();
        DoMain();
        
        if(io__sys_keyboard_data == 0x76)
            done = TRUE;
    }
    

    return NO_REBOOT;
}


