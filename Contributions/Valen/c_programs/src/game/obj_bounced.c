#include <stdio.h>
#include <string.h>

#include <scan_codes.h>

#include "debug_print.h"
#include "game.h"
#include "platform.h"
#include "obj_bounced.h"


#define MAX_BOUNCED_OBJECTS 20
BouncedObj obj1[MAX_BOUNCED_OBJECTS];

void DoBounced(void)
{
    BouncedObj *self;
    
    for(self = &obj1[0]; self <  &obj1[0] + MAX_BOUNCED_OBJECTS; self++) 
        if(self->isUsed) {
            // DEBUG_PRINT("self = %i \n", (unsigned int) self);
            DO_MOVING_BEHAVIOR();

            if( self->x  < self->x1_bounce || self->x > self->x2_bounce )
                self->xvel = -self->xvel;

            if( self->y  < self->y1_bounce || self->y > self->y2_bounce )
                self->yvel = -self->yvel;

            // Platform_Draw_Bounced(self);
            Platform_Draw_MovingObj((MovingObj*) self);
        }

    
}


void InitBounced(void)
{
    BouncedObj *self;
    int i;

    DEBUG_PRINT(( "mem = %ui %i \n", (int) obj1, sizeof(obj1) ));
    memset(obj1, 0, sizeof(obj1));
  
    i = 0;    
    for(self = &obj1[0]; self <  &obj1[0] + MAX_BOUNCED_OBJECTS; self++) {
        self->isUsed = 1;
        self->x = 10 * i;       self->y = 10 * i;
        self->xvel = 1;         self->yvel = 1;

        self->x1_bounce = 0; self->x2_bounce = 300;
        self->y1_bounce = 0; self->y2_bounce = 200;

        i++;
    }
}

// --------------------------------------------------------------------------------
