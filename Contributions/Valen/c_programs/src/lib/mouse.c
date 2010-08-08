// mouse.buttons bits
#define MOUSE_LEFT_BUTTON_PRESSED       1
#define MOUSE_RIGHT_BUTTON_PRESSED      2
#define MOUSE_MIDDLE_BUTTON_PRESSED     4


struct {
    byte buttons;
    short PosX, PosY; 
    short offsetX, offsetY;
    
} mouse;


short Mouse_GetX(void) {
    short v;
    DI();
    v = mouse.PosX; 
    EI();

    return v;
}

// read access for offsets
short Mouse_GetOffsetX()
{
    short v;
    DI();
    v = mouse.offsetX; 
    EI();

    return v;
}


short Mouse_GetOffsetY()
{
    short v;
    DI();
    v = mouse.offsetY; 
    EI();

    return v;
}

void Mouse_ClearOffsets(void) 
{
    DI();
    mouse.offsetX = mouse.offsetY = 0;
    EI();
}

// This ISR changes global variables.
// Non atomic operation:
// - mouse.PosX
void Mouse_IRQ_Handler()
{

    static byte mousePacketByteNumber = 0;
    static byte mousePacket[3];

    static short displacement;
    static byte b1;

    mousePacket[mousePacketByteNumber] = io__sys_mouse_data;
    mousePacketByteNumber++;
    if(mousePacketByteNumber == 3) {
        mousePacketByteNumber = 0;

	// update mouse registers, first the buttons
        mouse.buttons = mousePacket[0] & 7;

        // -------- update the pointer x position ----------
        // test 4 bit
        if(mousePacket[0] & 0x10) b1 = 0xFF; 
	else                      b1 = 0;
        displacement = mousePacket[1] + (b1<<8);
        mouse.PosX += displacement;
        mouse.offsetX = displacement;
        // check boundaries
        if(mouse.PosX < 0)   mouse.PosX = 0;
        if(mouse.PosX > 368) mouse.PosX = 368;

        // -------- update the pointer y position ----------
        // test 5 bit
        if(mousePacket[0] & 0x20) b1 = 0xFF; 
	else                      b1 = 0;
        displacement = mousePacket[2] + (b1<<8);
        mouse.PosY += displacement;
        mouse.offsetY = displacement;
        // check boundaries
        if(mouse.PosY < 0)   mouse.PosY = 0;
        if(mouse.PosY > 256) mouse.PosY = 256;


    }


// clear mouse interrupt flag
    BEGINASM()
    PUSH_ALL_REGS()

    ld a,#0x02
    out (SYS_CLEAR_IRQ_FLAGS),a ; clear mouse interrupt flag

    POP_ALL_REGS()
    ENDASM()

}
