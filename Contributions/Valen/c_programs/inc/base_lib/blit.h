


typedef struct  { 
    VIDEO_ADDR  src_addr, dest_addr;
    BYTE        src_mod, dest_mod;
    BYTE        width, height;
    BYTE        misc;
} BLITTER_PARAMS;

void DoBlit(BLITTER_PARAMS *bp);
