// #include "debug_print.h"
#include <stdio.h>
#include <string.h>

#ifndef PC
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <os_interface_for_c/i_flos.h>
#include <scan_codes.h>

#include <base_lib/keyboard.h>
#endif



#include "user_types.h"

#include "debug_print.h"
#include "platform.h"
#include "obj_bounced.h"
#include "obj_ship.h"
#define EXTERN_GAME
#include "game.h"


void GameInit(void);
void GameMain(void);






int main(int argc, char *argv[])
{
    
    
    
    DEBUG_PRINT(("GAME started...\n"));
    // DEBUG_PRINT(("argc %i \n", argc));
    
    
    GameInit();
    GameMain();    


#ifdef PC
    return 0;
#else
    return REBOOT;
#endif   
}


void GameMain(void)
{    
    game.isExitRequested = FALSE;
    game.frames = 0;


        while(!game.isExitRequested)
        {
          
            Platform_OnGameLoopBegin();
                        
            if(!Platform_HandleInput())
                game.isExitRequested = TRUE;            
            // ProcessInput();

            // move and draw phase
            DoBounced();
            DoShip();
                    
                                        
            Platform_OnGameLoopEnd();
            game.frames++;

        }
    
    Platform_CleanupVideo();
}

void GameInit(void)
{



    Platform_InitVideo(SCREEN_WIDTH ,SCREEN_HEIGHT);
    Platform_InitInput();

    // init objects (after init video)
    InitBounced();
    InitShip();
}