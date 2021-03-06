#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

//#include <stdlib.h>
#include <string.h>

#include "loading_icon.h"
#include "sprites.h"
#include "pong.h"
#include "disk_io.h"
#include <base_lib/resource.h>
#include "handle_resource_error.h"


BOOL LoadingIcon_LoadSprites(void)
{
    const char *pFilename = SPRITES_DISKETTE_FILENAME;
    word size = 48*48;

    if(!Resource_LoadFileToBuffer(pFilename, 0, BUF_FOR_LOADING_SPRITES_4KB, size, PONG_BANK))
        return Handle_Resource_Error();

    // put to the end of sprite memory
    PAGE_IN_SPRITE_RAM();
    SET_SPRITE_PAGE(31);
    memcpy((byte*)(SPRITE_BASE+4096-size), BUF_FOR_LOADING_SPRITES_4KB, size);
    PAGE_OUT_SPRITE_RAM();

    loadingIcon.isLoaded = TRUE;
    return TRUE;
}

void LoadingIcon_Enable(BOOL isEnable)
{
    int x = SCREEN_WIDTH/2 - 48/2;
    int y = SCREEN_HEIGHT - 16*4;

    if(isEnable) {
        if(!loadingIcon.isLoaded)
            return;

        // make the shadow sprite bank and hardware live bank to be the same
        // (thus our writes will go to the live sprite bank)
        game.shadow_sprite_register_bank = 0;
        SET_LIVE_SPRITE_REGISTER_BANK(game.shadow_sprite_register_bank);

        clear_sprite_regs();
        // show diskette icon (3 sprites)
        set_sprite_regs(SPRITE_NUM_DISKETTE   , x,    y, 3, SPRITE_DEF_NUM_DISKETTE  , FALSE, FALSE);
        set_sprite_regs(SPRITE_NUM_DISKETTE+1 , x+16, y, 3, SPRITE_DEF_NUM_DISKETTE+3, FALSE, FALSE);
        set_sprite_regs(SPRITE_NUM_DISKETTE+2 , x+32, y, 3, SPRITE_DEF_NUM_DISKETTE+6, FALSE, FALSE);

        memcpy((byte*)PALETTE, (byte*)loadingIcon.palette, 0x200);
    } else {
        clear_sprite_regs();
    }



}


BOOL LoadingIcon_Load(void)
{
    if(!LoadingIcon_LoadSprites())
        return FALSE;
    // load palette of "loading icon"
    if(!Resource_LoadFileToBuffer(PALETTE_DISKETTE_FILENAME, 0, (byte*)loadingIcon.palette, 0x200, PONG_BANK))
        return Handle_Resource_Error();
    loadingIcon.palette[0] = 0;

    return TRUE;
}
