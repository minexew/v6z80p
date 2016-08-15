#ifndef GAME_H
#define GAME_H


#ifndef EXTERN_GAME
    #define EXTERN_GAME extern
#endif


#define DO_MOVING_BEHAVIOR()    self->x += self->xvel;   \
                                self->y += self->yvel;   
                                
#include "user_types.h"


extern unsigned char spritesRegsBuffer[127*4];





typedef struct {

    
    BOOL            isExitRequested;
    unsigned long   frames;



} game_t;
EXTERN_GAME game_t game;



#define SCREEN_WIDTH    320
#define SCREEN_HEIGHT   240




#endif /* GAME_H */