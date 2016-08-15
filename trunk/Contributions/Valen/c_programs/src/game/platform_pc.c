#include <stdio.h>
#include <string.h>

#include <SDL/SDL.h>
#include <assert.h>


#include "debug_print.h"
#include "game.h"
#include "platform.h"


void ClearScreen(void);


SDL_Surface* screen;
SDL_Surface* screen_scaled;




void ClearScreen(void)
{
    
    SDL_Rect rect = {0,0, SCREEN_WIDTH, SCREEN_HEIGHT};
    SDL_FillRect(screen, &rect, 0);

}

void Platform_InitVideo(int screen_w, int screen_h)
{


    // Initialize SDL and the video subsystem
    
   if( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
        printf("SDL_Init falied. %s \n", SDL_GetError());
        exit(1);
    }


    // Set the video mode
    screen_scaled = SDL_SetVideoMode(screen_w * 2, screen_h * 2, 16, SDL_HWSURFACE | SDL_DOUBLEBUF/*|SDL_FULLSCREEN*/ );
    if(screen_scaled == NULL) {
        printf("SDL_SetVideoMode falied. %s \n", SDL_GetError());
        exit(1);
    }
    // create screen
    screen = SDL_CreateRGBSurface(SDL_SWSURFACE, screen_w, screen_h, 16,  0, 0, 0, 0);
    if(screen == NULL) {
        printf("CreateRGBSurface failed: %s\n", SDL_GetError());
        exit(1);
    }



}

void Platform_CleanupVideo(void)
{ 

    SDL_Quit();

} 


void Platform_OnGameLoopBegin(void)
{
    if (SDL_Flip(screen_scaled) != 0) {
        printf("Failed to swap the buffers: %s \n", SDL_GetError() );
    }   
    screen_scaled = SDL_GetVideoSurface();
        
        
   ClearScreen();
    
}



void Platform_OnGameLoopEnd(void)
{
    assert(screen);
    SDL_SoftStretch(screen, NULL, screen_scaled, NULL);             


    // Increment the frame counter 
    // frame++;
    float fps = game.frames / ( SDL_GetTicks() / 1000.f );

}


/*
void Platform_Draw_Bounced(BouncedObj *self)
{
    // sprDraw.x = self->x;      //256 + 16;
    // sprDraw.y = self->y;      //32;



    // Platform_Draw_Sprite();

}
*/

void Platform_Draw_MovingObj(MovingObj *self)
{
    int x = self->x;
    int y = self->y;
    sprite_t *spr = &self->sprite;

    int r = 255;
    int g = 255;
    int b = 255;

   
    if(!spr->rcSource.w && !spr->rcSource.h) {
       rectangleRGBA(screen,    self->x, self->y, 
                                self->x + 16, self->y + 16,
                     r, g, b,   255);
    } else   {
        SDL_Rect rcSrc, rcSprite;

        

        /* set sprite position */
        rcSprite.x = x;
        rcSprite.y = y;



        /* set animation frame */
        rcSrc.x = spr->rcSource.x;
        rcSrc.y = spr->rcSource.y;
        
        rcSrc.w = spr->rcSource.w;
        rcSrc.h = spr->rcSource.h;

        SDL_BlitSurface(spr->spriteSurface, &rcSrc, screen, &rcSprite);

    }

}



void Platform_Draw_Sprite(void)
{


}





void Sprite_SetSrcImageRect(sprite_t *self, int x, int y, int w, int h)
{
    
    self->rcSource.x = x;
    self->rcSource.y = y;
    
    self->rcSource.w = w;
    self->rcSource.h = h;


}

void Sprite_LoadFromImageFile(sprite_t *self, unsigned char* filename)
{
    self->spriteSurface = NULL;

    
    SDL_Surface *temp, *sprite;
    int colorkey;

    // printf("SDL_yoyo \n");

    /* load sprite */
    temp   = SDL_LoadBMP(filename);
    if(temp == NULL) {
        printf("SDL_LoadBMP falied. %s \n", SDL_GetError());
        exit(1);
    }
    // printf("SDL_yoyo  2\n");

    // SDL_DisplayFormat must be called after SDL_Init (or else SDL_DisplayFormat will crash!)
    sprite = SDL_DisplayFormat(temp);

    // printf("SDL_yoyo  3\n");
    assert(sprite);
    SDL_FreeSurface(temp);

    self->spriteSurface = sprite;

    // printf("SDL_yoyo  4\n");
    /* setup sprite colorkey and turn on RLE */
    colorkey = SDL_MapRGB(screen->format, 255, 0, 255);
    // printf("SDL_yoyo  5\n");
    SDL_SetColorKey(sprite, SDL_SRCCOLORKEY | SDL_RLEACCEL, colorkey);

    
}


// --------------- Input -----------------------------

#include <scan_codes.h>

int  keys_pressed[10];

// table to convert between  game key codes (platform independed) and SDL key symbols
unsigned int keyTable[] = {
    SC_ESC,         SDLK_ESCAPE,
    SC_ENTER,       SDLK_RETURN,
    SC_UP,          SDLK_UP, 
    SC_DOWN,        SDLK_DOWN,
    SC_LEFT,        SDLK_LEFT,
    SC_RIGHT,       SDLK_RIGHT,
                };


unsigned int ConvertGameKeyToSdlKey(unsigned int keycode)
{
    int i;
    int size = sizeof(keyTable)/sizeof(keyTable[0]);

    for(i = 0; i < size; i += 2) {    
        // printf("i = %i \n", i);
        if(keyTable[i] == keycode)
            return keyTable[i + 1];
    }

    printf("Warn: Game keycode %i not found.\n",  keycode);

    return 0;
}


BOOL Platform_IsPressed(unsigned char scancode)
{
    unsigned int keySym = ConvertGameKeyToSdlKey(scancode);
    int i;


    for(i = 0; i < sizeof(keys_pressed)/sizeof(keys_pressed[0]); i++)
    {
        
        if(keys_pressed[i] != 0)
            // check if a pressed key, is a key what we are looking for
            if(keys_pressed[i] == keySym) return TRUE;
    }
    
    return FALSE;
}


void Platform_InitInput(void)
{   
    memset(keys_pressed,0,sizeof(keys_pressed));
}

// http://www.barcodeman.com/altek/mule/scandoc.php
// http://www.win.tue.nl/~aeb/linux/kbd/scancodes-10.html
// Some info  http://www.libsdl.org/release/SDL-1.2.15/docs/html/guideinputkeyboard.html
BOOL Platform_HandleInput(void)
{
    int isExit = 0;
    
    SDL_Event event;
    int i = 0;
    int k = 0;
    int cur_sym = 0;
    // const int sym_len = sizeof(self->sym)/sizeof(int);
    // printf("aa %i \n", sym_len); exit(0);

    while (SDL_PollEvent(&event)) {
        switch (event.type) {
            case SDL_QUIT: {
                isExit = 1;
            }
            case SDL_KEYDOWN:
            case SDL_KEYUP: {
                SDL_KeyboardEvent *e = &event.key;
                
                cur_sym = event.key.keysym.sym;
                const int len2 = sizeof(keys_pressed)/sizeof(int);
                // printf("aa %i \n", len2); exit(0);
                if(event.type == SDL_KEYDOWN) {
                    // find free slot and put pressed key in this free slot                                
                    for (k = 0; k < len2; k++)
                        if(keys_pressed[k] == 0) {
                            keys_pressed[k] = cur_sym;
                            // printf("k = %i, sym = %i \n", k, cur_sym);
                            // printf("scancode = 0x%02X \n",  cur_sym);
                            
                            break;
                        }
                }
                if(event.type == SDL_KEYUP) {
                    // find slot, with the key and make finded slot a free slot
                    for (k = 0; k < len2; k++)
                        if(keys_pressed[k] == cur_sym) {
                            keys_pressed[k] = 0;
                            // printf("kk = %i, sym = %i \n", k, cur_sym);
                            break;
                        }
                }
                
                break;
            }
        }
    } //while


    return (isExit == 1) ? FALSE : TRUE;        
    // return TRUE;
    
}





