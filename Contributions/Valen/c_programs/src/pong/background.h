#ifndef BACKGROUND_H
#define BACKGROUND_H


#define BUF_FOR_LOADING_BACKGROUND_4KB     buffer4K

#define TILE_MAP_WIDTH_IN_BLOCKS           32       // 512/16
#define TILEMAPS_VIDEO_PAGE                (0x70000/0x2000)

#define VRAM_ADDR_STORE_FLOS                0x60000      // 0x60000 - 0x70000  area where FLOS font data is stored (will be restored, if disk error will occur)
#define VRAM_ADDR_FLOS_AREA                 0x10000

//BOOL Background_LoadTiles(const char* pFilename, dword vram_addr);
void TileMap_Fill(word tileNumber);

BOOL Background_LoadTiles(const char* pFilename, word vram_addr);
void TileMap_FillTileDefinition(word tileNumber, byte fillValue);
void TileMap_Clear(void);
void TileMap_Fill(word tileNumber);
void Background_InitTilemap(word firstTileDef);

void Game_StoreFLOSVIdeoRam(void);
void Game_RestoreFLOSVIdeoRam(void);

#endif /* BACKGROUND_H */
