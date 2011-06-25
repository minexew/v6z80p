#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>


#include "obj_.h"
#include "math.h"


void GameObj_Init(GameObj* this)
{
    this->extra_field1 = 0;
}

void GameObj_InitCollideBox(GameObj* this)
{


    // setup collision bounding box vars (use 80% from object box size)
    this->col_width  = HW_MATH_MUL(0.8 * 16384, this->width);
    this->col_height = HW_MATH_MUL(0.8 * 16384, this->height);

    this->col_x_offset = (this->width - this->col_width) / 2;
    this->col_y_offset = (this->height - this->col_height) / 2;


    /*dbg[0] = this->width;
    dbg[1] = this->col_width;
    dbg[2] = this->height;
    dbg[3] = this->col_height;*/
}


BOOL GameObj_Collide(GameObj* this, GameObj* other)
{

    int left1, left2;
    int right1, right2;
    int top1, top2;
    int bottom1, bottom2;

    left1 = this->x + this->col_x_offset;
    left2 = other->x + other->col_x_offset;
    right1 = left1 + this->col_width;
    right2 = left2 + other->col_width;
    top1 = this->y + this->col_y_offset;
    top2 = other->y + this->col_y_offset;
    bottom1 = top1 + this->col_height;
    bottom2 = top2 + other->col_height;

    if (bottom1 < top2) return(FALSE);
    if (top1 > bottom2) return(FALSE);

    if (right1 < left2) return(FALSE);
    if (left1 > right2) return(FALSE);

    return(TRUE);

}
