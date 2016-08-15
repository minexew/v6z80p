#ifndef OBJ_SHIP_H
#define OBJ_SHIP_H

#include "obj_moving.h"

typedef struct tagShipObj
{
    DECLARE_BASE_OBJ()          // <-- this two macros must be the very first, in struct declaration !!!
    DECLARE_MOVING_OBJ()

} ShipObj;


void DoShip(void);
void InitShip(void);



#endif /* OBJ_SHIP_H */