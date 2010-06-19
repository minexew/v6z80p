// Game object: Ball
// gobj->x and gobj->y are coord of ball center point (not top left point)
typedef struct {
    GameObj gobj;

    int radius;
    int speedx;
    int speedy;

    ObjState state;

    // dying stuff
    byte max_dying_time;
    byte dying_time;

} GameObjBall;

// There is only one Ball object.
GameObjBall ball1;

