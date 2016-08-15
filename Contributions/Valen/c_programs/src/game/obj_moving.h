#ifndef OBJ_MOVING_H
#define OBJ_MOVING_H


#define DECLARE_MOVING_OBJ()            \
                            int x;      \
                            int y;      \
                                        \
                            int xvel;   \
                            int yvel;   \
                            sprite_t  sprite;  

#define DECLARE_BASE_OBJ()                        \
                            unsigned char isUsed;


typedef struct tagMovingObj
{
    DECLARE_BASE_OBJ()          // <-- this two macros must be the very first, in struct declaration !!!
    DECLARE_MOVING_OBJ()
    
} MovingObj;


#endif /* OBJ_MOVING_H */