//

void DiagMessage(char* pMsg, const char* pFilename);

void DiagMessage(char* pMsg, const char* pFilename)
{
    byte err;

    err = FLOS_GetLastError();

    if(game.isFLOSVideoMode) {
        /*FLOS_FlosDisplay();
        game.isFLOSVideoMode = TRUE;*/

        FLOS_PrintString(pMsg);
        FLOS_PrintString(pFilename);

        FLOS_PrintString(" OS_err: $");
        _uitoa(err, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintString(PS_LFCR);
    }



}

BOOL Util_LoadPalette(const char* pFilename)
{

    if(!load_file_to_buffer(pFilename, 0, (byte*)0x0000, 0x200, 0))
        return FALSE;

    *((ushort*)PALETTE) = 0;
    return TRUE;

}


void Sys_ClearIRQFlags(byte flags)
{
    io__sys_clear_irq_flags = flags;
}


byte GetR(void)  __naked
{
    __asm;
    push af
    ld a,r
    ld l,a
    pop af
    ret
    __endasm;

}
