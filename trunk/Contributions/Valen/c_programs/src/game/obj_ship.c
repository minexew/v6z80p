#include <stdio.h>
#include <string.h>

#include <scan_codes.h>

#include "debug_print.h"
#include "game.h"
#include "platform.h"
#include "obj_ship.h"


#define MAX_SHIP_OBJECTS 1
ShipObj ship[MAX_SHIP_OBJECTS];

void DoShip(void)
{
    ShipObj *self;
    
    for(self = &ship[0]; self <  &ship[0] + MAX_SHIP_OBJECTS; self++) 
        if(self->isUsed) {
            // DEBUG_PRINT("self = %i \n", (unsigned int) self);
            DO_MOVING_BEHAVIOR();

            self->xvel = 0;
            self->yvel = 0;

            if( Platform_IsPressed(SC_UP) )   self->yvel = -1;
            if( Platform_IsPressed(SC_DOWN) ) self->yvel = 1;
            
            if( Platform_IsPressed(SC_LEFT) ) self->xvel = -1;
            if( Platform_IsPressed(SC_RIGHT) )self->xvel = 1;


            Platform_Draw_MovingObj((MovingObj*) self);
        }
    
}

void InitShip(void)
{
    ShipObj *self;
    int i;

    DEBUG_PRINT(( "mem = %ui %i \n", (int) ship, sizeof(ship) ));
    memset(ship, 0, sizeof(ship));
  
    i = 0;    
    for(self = &ship[0]; self <  &ship[0] + MAX_SHIP_OBJECTS; self++) {
        self->isUsed = 1;
        self->x = 10;       self->y = 10;
        self->xvel = 0;         self->yvel = 0;

        Sprite_LoadFromImageFile(&self->sprite, "free_sprites.bmp");
        Sprite_SetSrcImageRect(&self->sprite, 0,0, 39,26);

        i++;
    }
}