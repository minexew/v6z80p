#ifndef MATH_H
#define MATH_H


#include <OSCA_hardware_equates.h>
#include <macros.h>

typedef struct {
    int x, y;
    int width, height;
} RECT;


BOOL Math_IsBoxHitBox(const RECT* p1, const RECT* p2);

static inline word HW_MATH_MUL(word n1, word n2)
{
    word a;
    mm__mult_table = n1;
    mm__mult_index = 0;
    mm__mult_write = n2;

    a = mm__mult_read;
    mm__mult_table = 0;     // restore sin table first entry
    return a;
    //return mm__mult_read;
}

static inline word HW_SIN_MUL(byte angle, word n2)
{
    mm__mult_index = angle;
    mm__mult_write = n2;
    return mm__mult_read;
}



#endif /* MATH_H */