#ifndef PLATFORM_V6_H
#define PLATFORM_V6_H

#ifdef PC
#include <SDL/SDL.h>
typedef struct {
    SDL_Surface     *spriteSurface;     // SDL sprite surf
    SDL_Rect        rcSource;
} sprite_t;
#endif


#include "obj_moving.h"


void Platform_InitVideo(int screen_w, int screen_h);
void Platform_CleanupVideo(void);

void Platform_OnGameLoopBegin(void);
void Platform_OnGameLoopEnd(void);
BOOL Platform_HandleInput(void);

void Platform_InitInput(void);
BOOL Platform_IsPressed(unsigned char scancode);



// void Platform_Draw_Bounced(BouncedObj *self);
void Platform_Draw_MovingObj(MovingObj *self);
void Platform_Draw_Sprite(void);



void Sprite_LoadFromImageFile(sprite_t *self, unsigned char* filename);
void Sprite_SetSrcImageRect(sprite_t *self, int x, int y, int w, int h);


#endif /* PLATFORM_V6_H */