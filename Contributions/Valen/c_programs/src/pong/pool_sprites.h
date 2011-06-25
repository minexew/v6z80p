#ifndef POOL_SPRITES_H
#define POOL_SPRITES_H


#ifndef EXTERN_POOL_SPRITES
    #define EXTERN_POOL_SPRITES extern
#endif


// ---------- Pool of sprite numbers (hardware sprite regs) ---------------------

//#define POOL_SPR__FIRST_SPRITE          8
#define POOL_SPR__MAX_SPRITES           35
//45
#define POOL_SPR__LAST_SPRITE           (POOL_SPR__FIRST_SPRITE + POOL_SPR__MAX_SPRITES)


EXTERN_POOL_SPRITES byte allocatedSpriteNumbers[POOL_SPR__MAX_SPRITES];

byte PoolSprites_AllocateSpriteNumber(byte count);
void PoolSprites_FreeAllSprites(void);




#endif /* POOL_SPRITES_H */