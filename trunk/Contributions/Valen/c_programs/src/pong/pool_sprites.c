#define EXTERN_POOL_SPRITES
#include "pool_sprites.h"


typedef struct  {

    byte spr_number_offset;
} PoolSprites;

PoolSprites pool_sprites;




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
