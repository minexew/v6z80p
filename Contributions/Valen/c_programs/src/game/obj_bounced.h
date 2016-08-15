#ifndef OBJ_BOUNCED_H
#define OBJ_BOUNCED_H


#include "obj_moving.h"


typedef struct tagBouncedObj
{
    DECLARE_BASE_OBJ()          // <-- this two macros must be the very first, in struct declaration !!!
    DECLARE_MOVING_OBJ()

    int x1_bounce;
    int y1_bounce;
    
    int x2_bounce;
    int y2_bounce;

    
} BouncedObj;


void DoBounced(void);
void InitBounced(void);


// --------------------------------------------------------------------------------




#endif /* OBJ_BOUNCED_H */