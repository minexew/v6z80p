#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>

#include <os_interface_for_c/i_flos.h>


#include <stdlib.h>
//#include <string.h>

#include "debug.h"
#include "pool_gameobj.h"
#include "keyboard.h"
#include "sprites.h"
#include "pool_gameobj.h"
#include "pool_sprites.h"
#include "pong.h"

// key "A" moves debug render to next gameobj in list of active game objects
void Debug_Move(void)
{

    if(keyboard.last_typed_scancode == SC_A) {
        keyboard.last_typed_scancode = 0;

        debug.offset_gameobj_for_debug_render++;
        if(debug.offset_gameobj_for_debug_render >= POOL_OBJ__MAX_OBJECTS)
            debug.offset_gameobj_for_debug_render = 0;
    }

}

// render debug info
/*SPRITE_DEF_NUM_DEBUG_POINT1*/
void Debug_Draw(void)
{
    word i;
    GameObj* obj;
    short x,y;
    static short counter = 0;
    static byte corner = 0;     // 0 = top left corner, 1 = right bottom corner of collision box

    if(counter & 0x80) {
        counter = 0;
        corner ^= 1;
    }
    counter++;

    // search in list, nearest gameobj pointer
    // (gameobj ptr must be not null and gameobj must be "in use")
    for(i=debug.offset_gameobj_for_debug_render; i<POOL_OBJ__MAX_OBJECTS; i++) {
        obj = PoolGameObj_GetListOfActiveObjects()[i];
        if( obj && obj->in_use) {
            x = obj->x + obj->col_x_offset;
            y = obj->y + obj->col_y_offset;
            if(corner == 1) {
                x +=  obj->col_width;
                y +=  obj->col_height;
            }
            // show debug point at the corner of collision box
            // BUG: when spr num 61
            set_sprite_regs(SPRITE_NUM_DEBUG_POINT1, x, y, 1,
                             SPRITE_DEF_NUM_DIGIT,
                           FALSE, FALSE);
            return;
        }
    }


}

BOOL Debug_CheckCurrentBank(void)
{
    char buf [8];
    byte b = io__sys_mem_select;

    // check if current logic bank is fine
    if((b-1) != PONG_BANK) {
        FLOS_PrintStringLFCR("ERR: Not good cur bank.");
        _ultoa(b, buf, 16);
        FLOS_PrintString("Cur hardware bank: $");
        FLOS_PrintStringLFCR(buf);
        buffer[0] = 'E'; buffer[1] = 'R';   // put  E R as "was error" marker
        return FALSE;
    }

    return TRUE;
}

/*
BOOL Debug_CheckGuardStr(void)
{
        if(strcmp(debug.guard_str, "GUARD") == 0) {
            return TRUE;
        }


    return FALSE;
}
*/
