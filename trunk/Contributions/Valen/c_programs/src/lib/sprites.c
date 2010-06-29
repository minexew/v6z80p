typedef struct {
    byte sprite_number;
    int x;
    int y;
    byte height;                        // height in 16 pixels chunks
    word sprite_definition_number;
    BOOL x_flip;    
} sprite_regs_t;



static inline void set_sprite_regs_hw(byte sprite_number, byte x, byte misc, byte y, byte sprite_definition_number)
{
    byte* p;

    p = (byte *) SPR_REGISTERS + (sprite_number*4);
    *p =  x;                            p++;
    *p =  misc;                         p++;
    *p =  y;                            p++;
    *p =  sprite_definition_number;

}


void set_sprite_regs(sprite_regs_t* r)
{
    byte reg_misc;
    int x, y;


    // convert X coord to hardware sprite coord
    x =  r->x + X_WINDOW_START*16;
    //x =  x + 16;  // + wide left border
    // convert Y coord to hardware sprite coord
    y =  r->y + Y_WINDOW_START*8 + 1;

    // build "misc" reg
    reg_misc = GET_WORD_9TH_BIT(x)                                  |
               GET_WORD_9TH_BIT(y) << 1                             |
               GET_WORD_9TH_BIT(r->sprite_definition_number) << 2      |
               ((r->x_flip&1) << 3)                                    |
               (r->height << 4)
               ;
    set_sprite_regs_hw(r->sprite_number, (byte)x, reg_misc, (byte)y, (byte)r->sprite_definition_number);

}

