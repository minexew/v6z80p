// Game object: Rocket
// The bat can fire a rocket,
// rocket can destroy the other bat.
typedef struct {
    GameObj gobj;

    GameObjAnim *animObj;
    GameObjAnim *animObj1;
    //GameObjAnim *animObj2;

    // Signed fixed point values.
    // Fixed format: 24.8
    long        my_x;
    // Fixed format: 8.8
    short       x_speed;         // speed, started from const value,
                                 // increased by speed_acc every one frame,
                                 // until it reach max speed value
    short       x_speed_acc;

    BOOL        isMovingToTheRight;




} GameObjRocket;





