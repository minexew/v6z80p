void ai_update(void);

void ai_update(void)
{

    // not use ai , if ball x coord is near left side of gamefield
    // (without this, near to impossible to win ai)
    //if(ball1.gobj.x < SCREEN_WIDTH/6)
    //   return;

    int rocketY = batA.rocket->gobj.y;
    int rocketX = batA.rocket->gobj.x;
    if(batA.rocket && batA.rocket->gobj.in_use &&
        rocketY > batB.gobj.y && rocketY < batB.gobj.y + batB.gobj.height &&
        rocketX > SCREEN_WIDTH/2) {
        // anti rocker manevr
        GameObjBat_MoveUp(&batB); return;
    }

    if(ball1.gobj.y <  batB.gobj.y + batB.gobj.height/2)
        GameObjBat_MoveUp(&batB);      //movebat ('J');
    if(ball1.gobj.y >  batB.gobj.y + batB.gobj.height/2)
        GameObjBat_MoveDown(&batB);      //movebat ('M');

    if(GameObjBat_IsCanFireWithRocket(&batB))
        if(ball1.speedx < 0 && ball1.speedy == 0 &&
             ball1.gobj.y > batB.gobj.y &&  ball1.gobj.y < batB.gobj.y + batB.gobj.height)     // /*(RAND() & 0x1F) == 0*/)
            GameObjBat_Fire(&batB);




}
