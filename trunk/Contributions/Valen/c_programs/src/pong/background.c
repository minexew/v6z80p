#define BUF_FOR_LOADING_BACKGROUND_4KB     0xF000

#define TILE_MAP_WIDTH_IN_BLOCKS           32       // 512/16
#define TILEMAPS_VIDEO_PAGE                (0x70000/0x2000)

//BOOL Background_LoadTiles(const char* pFilename, dword vram_addr);
void TileMap_Fill(word tileNumber);




// In: vram_addr = in 100h chunks
BOOL Background_LoadTiles(const char* pFilename, word vram_addr)
{
    byte video_page = vram_addr/0x20;
    word video_offset = (vram_addr&0x1F) * 0x100;
    if(video_offset!=0 && video_offset!=0x1000) return FALSE;


    // load by 4KB chunks (using chunk loader)
    //video_offset = 0x1000;
    ChunkLoader_Init(pFilename,/*&myFile,*/ (byte*)BUF_FOR_LOADING_BACKGROUND_4KB, 0);

    while(!ChunkLoader_IsDone()) {
        if(!ChunkLoader_LoadChunk())
            return FALSE;

        // copy from mem buf to video mem
        PAGE_IN_VIDEO_RAM();
        SET_VIDEO_PAGE(video_page);
        memcpy((byte*)(VIDEO_BASE + video_offset), (byte*)BUF_FOR_LOADING_BACKGROUND_4KB, 0x1000);
        PAGE_OUT_VIDEO_RAM();


        video_offset += 0x1000;
        if(video_offset >= 0x2000) {
            video_offset = 0;
            video_page++;
        }
    }

    return TRUE;
}

void TileMap_FillTileDefinition(word tileNumber, byte fillValue)
{
    // The formula is: videopage = TileNumber*0x100/0x2000
    byte video_page   = tileNumber/0x20;
    word video_offset = (tileNumber&0x1F) * 0x100;

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(video_page);
    memset((byte*)(VIDEO_BASE) + video_offset, fillValue, 0x100); //fill tile def
    PAGE_OUT_VIDEO_RAM();
}

// clear tile map
void TileMap_Clear(void)
{

    /*PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);
    memset((byte*)(VIDEO_BASE), 0, 0x1000);
    PAGE_OUT_VIDEO_RAM();*/

    TileMap_FillTileDefinition(2047, 0);
    TileMap_Fill(2047);

}


// Fill Playfield A Buffer 0
void TileMap_Fill(word tileNumber)
{
    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);
    memset((byte*)(VIDEO_BASE),         (byte)tileNumber,           0x200); //LSB
    memset((byte*)(VIDEO_BASE+0x800),   (byte)(tileNumber >> 8),    0x200); //MSB
    PAGE_OUT_VIDEO_RAM();
}


// Init tilemap to show screen.
// firstTileDef = first tile def
void Background_InitTilemap(word firstTileDef)
{
    byte x, y;
    word tile_num;
    byte* p;

    PAGE_IN_VIDEO_RAM();
    SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);

    for(y=0; y<240/16; y++)
        for(x=0; x<368/16; x++) {
            tile_num = firstTileDef + (y*(368/16)) + x;
            p = (byte*)(VIDEO_BASE + (y*TILE_MAP_WIDTH_IN_BLOCKS) + x);
#ifdef IS_WIDE_LEFT_BORDER
            p++;
#endif
            *p         = tile_num & 0xFF;
            *(p+0x800) = tile_num >> 8;
        }

    PAGE_OUT_VIDEO_RAM();
}
