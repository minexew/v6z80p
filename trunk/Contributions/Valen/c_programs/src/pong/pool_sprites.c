// ---------- Pool of sprite numbers (hardware sprite regs) ---------------------

//#define POOL_SPR__FIRST_SPRITE          8
#define POOL_SPR__MAX_SPRITES           35
//45
#define POOL_SPR__LAST_SPRITE           (POOL_SPR__FIRST_SPRITE + POOL_SPR__MAX_SPRITES)


typedef struct  {

    byte spr_number_offset;
} PoolSprites;
PoolSprites pool_sprites;

byte PoolSprites_AllocateSpriteNumber(byte count);
void PoolSprites_FreeAllSprites(void);


byte   allocatedSpriteNumbers[POOL_SPR__MAX_SPRITES];


void PoolSprites_Init(void)
{
    memset(&pool_sprites, 0, sizeof(pool_sprites));
    PoolSprites_FreeAllSprites();

}


byte PoolSprites_AllocateSpriteNumber(byte count)
{
    byte i;
    byte* pNumBuffer = allocatedSpriteNumbers;


    for(i=0; i<count; i++) {
        if(pool_sprites.spr_number_offset >= POOL_SPR__LAST_SPRITE)
            return i;
        *(pNumBuffer+i) = pool_sprites.spr_number_offset;
        pool_sprites.spr_number_offset++;

    }


    return i;
}

void PoolSprites_FreeAllSprites(void)
{
    pool_sprites.spr_number_offset = POOL_SPR__FIRST_SPRITE;
}
