#ifndef BACKGROUND_H
#define BACKGROUND_H


#define BUF_FOR_LOADING_BACKGROUND_4KB     buffer4K

#define TILE_MAP_WIDTH_IN_BLOCKS           32       // 512/16
#define TILEMAPS_VIDEO_PAGE                (0x70000/0x2000)

//BOOL Background_LoadTiles(const char* pFilename, dword vram_addr);
void TileMap_Fill(word tileNumber);

BOOL Background_LoadTiles(const char* pFilename, word vram_addr);
void TileMap_FillTileDefinition(word tileNumber, byte fillValue);
void TileMap_Clear(void);
void TileMap_Fill(word tileNumber);
void Background_InitTilemap(word firstTileDef);



#endif /* BACKGROUND_H */
