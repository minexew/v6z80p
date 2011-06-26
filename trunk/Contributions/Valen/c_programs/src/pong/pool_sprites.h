#ifndef POOL_SPRITES_H
#define POOL_SPRITES_H


#ifndef EXTERN_POOL_SPRITES
    #define EXTERN_POOL_SPRITES extern
#endif


// ---------- Pool of sprite numbers (hardware sprite regs) ---------------------

// POOL_SPR__FIRST_SPRITE  must be defined in user code

#define POOL_SPR__MAX_SPRITES           35
#define POOL_SPR__LAST_SPRITE           (POOL_SPR__FIRST_SPRITE + POOL_SPR__MAX_SPRITES)


EXTERN_POOL_SPRITES byte allocatedSpriteNumbers[POOL_SPR__MAX_SPRITES];

void PoolSprites_Init(void);
byte PoolSprites_AllocateSpriteNumber(byte count);
void PoolSprites_FreeAllSprites(void);




#endif /* POOL_SPRITES_H */