#include <v6z80p_types.h>

#include "math.h"


/*
BOOL Math_IsPointHitBox(int px, int py, int box_x, int box_y, int box_width, int box_height)
{
    if(px > box_x && px < box_x + box_width &&
        py > box_y && py < box_y + box_height)
        return TRUE;
    else
        return FALSE;
}
*/

// http://www.gamedev.net/reference/articles/article735.asp
BOOL Math_IsBoxHitBox(const RECT* p1, const RECT* p2)
{
    int left1, left2;
    int right1, right2;
    int top1, top2;
    int bottom1, bottom2;

    left1 = p1->x;
    left2 = p2->x;
    right1 = p1->x + p1->width;
    right2 = p2->x + p2->width;
    top1 = p1->y;
    top2 = p2->y;
    bottom1 = p1->y + p1->height;
    bottom2 = p2->y + p2->height;

    if (bottom1 < top2) return(FALSE);
    if (top1 > bottom2) return(FALSE);

    if (right1 < left2) return(FALSE);
    if (left1 > right2) return(FALSE);

    return(TRUE);


}

