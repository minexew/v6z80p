

typedef struct {
    byte sprite_number;                 // 127 total sprite numbers [0-126]
    int x;                              // x, y in local coordinate system
    int y;
    byte height;                        // height in 16 pixels chunks (0 - 240 pixels, 1 - 16pix, 2 - 32pix, etc...)
    word sprite_definition_number;
    BOOL x_flip;
} sprite_regs_t;




void SpritesRegsBuffer_SetDisplayWindowParams(WORD x_window_start, WORD y_window_start);
void SpritesRegsBuffer_SetSpriteRegs(sprite_regs_t* r);
void SpritesRegsBuffer_CopyToHardwareRegs(void);
void SpritesRegsBuffer_Clear(void);


