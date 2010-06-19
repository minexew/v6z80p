void GameObjBall_Init(GameObjBall* this);
void GameObjBall_SetState(GameObjBall* this, ObjState state);

void GameObjBall_Move(GameObjBall* this);
void GameObjBall_CheckCollision(GameObjBall* this);
void GameObjBall_Draw(GameObjBall* this);



void GameObjBall_Init(GameObjBall* this)
{

    // init parent obj
    GameObj_Init((GameObj*)this);

   GameObjBall_SetState(this, NORMAL);

   this->max_dying_time = 50;
   this->dying_time = 0;

   this->radius = 3;
   this->speedx = 2;
   srand((int) GetR()*256 + (~GetR()) ); // Seed rand a random number
   this->speedy = rand ()%1;// Sets speed from 0 to 2 depending upon remainder.
   if (rand() % 2 == 0)
     {
       this->speedx = - this->speedx; // Generate Random X direction.
       this->speedy = - this->speedy; // Generate Random Y direction.
      }

    this->gobj.x = 320/2;
    this->gobj.y = 250/2;

    this->gobj.pMoveFunc = &GameObjBall_Move;
    this->gobj.pDrawFunc = &GameObjBall_Draw;

    // we dont use collision box vars for this game obj (because we doing collision detection based on radius)
    // so, just zero them
    this->gobj.col_x_offset = this->gobj.col_y_offset = this->gobj.col_width = this->gobj.col_height = 0;
}

void GameObjBall_SetState(GameObjBall* this, ObjState state)
{
    if(state == this->state)
        return;
    this->state = state;

    if(state == DIE){
        if(scoreA.score >= MAX_SCORE_FOR_LEVEL) {
            GameObjBat_SetState(&batB, DYING);

        }
        if(scoreB.score >= MAX_SCORE_FOR_LEVEL) {
            GameObjBat_SetState(&batA, DYING);

        }

        GameObjScore_SetState(game.pScore_to_blink, BLINKING);
    }

    if(state == DYING) {
        Sound_NewFx(SOUND_FX_CRUNCH);
    }

}

void GameObjBall_Move(GameObjBall* this)
{
   if(this->state == DYING) {
       if(this->dying_time++ >= this->max_dying_time)
           GameObjBall_SetState(this, DIE);
   }



   // ------------------------------
   if(this->state != NORMAL)
       return;

   this->gobj.x += this->speedx;
   this->gobj.y += this->speedy;

   if ( this->gobj.y - this->radius < 0 ) {
       this->speedy = -this->speedy; // Reflect From Top
       Sound_NewFx(SOUND_FX_BOUNCE);
   }
   if ( this->gobj.y + this->radius > GAME_FIELD_MAX_SCREEN_Y ) {
       this->speedy = -this->speedy; // Reflect From Bottom
       Sound_NewFx(SOUND_FX_BOUNCE);
   }

   GameObjBall_CheckCollision(this);
}



void GameObjBall_CheckCollision(GameObjBall* this)
{
   if(this->state != NORMAL)
       return;

  if ( this->gobj.x - this->radius <= GAME_FIELD_X_BORDER)
     {
         if (this->gobj.y > batA.gobj.y && this->gobj.y < batA.gobj.y+batA.gobj.height && batA.state == NORMAL)
            {
               this->speedx = - this->speedx;
               this->speedy = rand () % 3;// Sets speed from depending upon remainder.
               if (rand() % 2 == 0) this->speedy = - this->speedy; // Generate Random Y direction.
               Sound_NewFx(SOUND_FX_BOUNCE);
             }
          else
             {
               GameObjBall_SetState(this, DYING);
               GameObjScore_SetScore(&scoreB, scoreB.score + 1);
               game.pScore_to_blink = &scoreB;
             }
          return;
      }

  if ( this->gobj.x +  this->radius > SCREEN_WIDTH - GAME_FIELD_X_BORDER)

      {
         if (this->gobj.y > batB.gobj.y && this->gobj.y < batB.gobj.y+batB.gobj.height && batB.state == NORMAL)
          {
            this->speedx = - this->speedx;
            this->speedy = rand ()%3;// Sets speed from depending upon remainder.
            if (rand() % 2 == 0) this->speedy = - this->speedy; // Generate Random Y direction.
            Sound_NewFx(SOUND_FX_BOUNCE);
           }
         else
          {
           GameObjBall_SetState(this, DYING);
           GameObjScore_SetScore(&scoreA, scoreA.score + 1);
           game.pScore_to_blink = &scoreA;
          }
           return;
       }
}


void GameObjBall_Draw(GameObjBall* this)
{
    DrawBall (this->gobj.x, this->gobj.y, this->radius, this->radius);
}
