//#include <kernal_jump_table.h>
#include <v6z80p_types.h>

//#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
//#include <macros.h>
//#include <macros_specific.h>

//#include <os_interface_for_c/i_flos.h>

#include <stdlib.h>

#include "data_loader.h"
#include "background.h"
#include "sprites.h"
#include "sound_fx/sound_fx.h"
#include "util.h"
#include "loading_icon.h"
#include "pong.h"

static const LoadTilesDescription tilesMenu[] = {
    {TILES_MENU_FILENAME, 0}, {TILES_CREDITS_FILENAME, TILES_CREDITS_VRAM_ADDR/0x100},
    {NULL, 0}
};
static const LoadTilesDescription tilesLevel[] = {
    {TILES_LVL_FILENAME, 0}, {NULL, 0}
};
// srpites menu
static const LoadFileDescription spritesMenu[] = {
#ifdef UNFINISHED_CODE
    {SPRITES_FILENAME_MENUTXT, 0, 1},
#endif  // UNFINISHED_CODE
    {NULL, 0, 0}
};
// srpites level
static const LoadFileDescription spritesLevel[] = {
    {SPRITES_FILENAME, 0, 1}, {NULL, 0, 0}
};

static struct {
    GameState s;                    // to   which gamestate
    GameState prev_s;               // from which gamestate
    const LoadTilesDescription *tiles;
    const LoadFileDescription  *file;

    const char* pFilenameMusic;
    const char* pFilenamePalette;
} gameStateData[] = {
    { MENU, STARTUP, tilesMenu,  spritesMenu,  MUSIC_MENU_FILENAME, PALETTE_MENU_FILENAME },
    { MENU, LEVEL,   tilesMenu,  spritesMenu,  MUSIC_MENU_FILENAME, PALETTE_MENU_FILENAME },
    /*{ MENU, CREDITS, tilesMenu,  NULL,                PALETTE_MENU_FILENAME },*/

    { LEVEL, MENU,   tilesLevel, spritesLevel, MUSIC_YOUWIN_FILENAME, PALETTE_LVL_FILENAME },
    /*{CREDITS, MENU, {TILES_CREDITS_FILENAME, 0},  NULL,               PALETTE_MENU_FILENAME},*/

};

BOOL DataLoader_LoadData(GameState state, GameState prev_state)
{

    byte i;
    byte num;
    const char* pFilename;
    const LoadTilesDescription *pTilesDesc;
    const LoadFileDescription  *pFileDesc;

    num = sizeof(gameStateData)/sizeof(gameStateData[0]);
    for(i=0 ;i<num; i++)
        if(state == gameStateData[i].s && prev_state == gameStateData[i].prev_s)
            break;
    if(i == num) return TRUE;    // state was not found in struct, just return

    TileMap_Clear();
    LoadingIcon_Enable(TRUE);

    // load tiles
    pTilesDesc = gameStateData[i].tiles;
    while(pTilesDesc->pFilenameTiles != NULL) {
        if(!Background_LoadTiles(pTilesDesc->pFilenameTiles, pTilesDesc->vramAddrTiles))
            return FALSE;
        pTilesDesc++;
    }

    // load sprites
    pFileDesc = gameStateData[i].file;
    while(pFileDesc->pFilename != NULL && pFileDesc->typeOfFile == 1) {
        if(!Sprites_LoadSprites(pFileDesc->pFilename, pFileDesc->dw1))
            return FALSE;
        pFileDesc++;
    }


    // load music
    pFilename = gameStateData[i].pFilenameMusic;
    if(pFilename) {
        if(!Mod_LoadMusicModule(pFilename))
            return FALSE;
        MUSIC_Init();
    }

    LoadingIcon_Enable(FALSE);
    // load palette
    pFilename = gameStateData[i].pFilenamePalette;
    if(pFilename) {
        if(!Util_LoadPalette(pFilename))
            return FALSE;
    }
    Background_InitTilemap(0);

    return TRUE;
}
