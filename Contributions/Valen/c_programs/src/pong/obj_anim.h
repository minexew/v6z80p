// Game object: Animation - do sprite animation
typedef struct {
    GameObj gobj;   // <-- this must be a FIRST member of struct !! (to allow pointer cast to parent type)

//    byte offset;

// animation related
    byte    spr_anim_time;
    byte    spr_anim_frames;
    byte    spr_count;
    byte    spr_height;
    word    spr_def_start;
    byte    spr_def_pitch;
    BOOL    is_Xflip;

//    isDisplayOneFrame;     // display only one frame (no animation)

//    private
    FIXED88 spr_anim_def_step;
    FIXED88 spr_anim_def_offset;
    BOOL    isAnimEnabled;
    BOOL    isLoopAnim;

} GameObjAnim;


// prototypes
void GameObjAnim_Move(GameObjAnim* this);
void GameObjAnim_Draw(GameObjAnim* this);
// private
void GameObjAnim_init_animation(GameObjAnim* this);


void GameObjAnim_Free(GameObjAnim* this);
