
void install_irq_handler(byte irq_enable_mask);



#if defined(SDCC) || defined(__SDCC)
void irq_handler() NAKED;
// This is main IRQ handler.
// It will route call to specific functions.
void irq_handler() NAKED
{
    BEGINASM()
    PUSH_ALL_REGS()

    

#ifdef APP_USE_OWN_KEYBOARD_IRQ
    in a,(SYS_IRQ_PS2_FLAGS)            ; Read irq status flags
    bit 0,a                           ; keyboard irq set?
    call nz,_Keyboard_IRQ_Handler       ; call keyboard irq routine if so
#endif

#ifdef APP_USE_OWN_MOUSE_IRQ
    in a,(SYS_IRQ_PS2_FLAGS)            ; Read irq status flags
    bit 1,a
    call nz,_Mouse_IRQ_Handler		; mouse IRQ?
#endif

#ifdef APP_USE_OWN_TIMER_IRQ
    in a,(SYS_IRQ_PS2_FLAGS)            ; Read irq status flags
    bit 2,a
    call nz,_Timer_IRQ_Handler          ; timer IRQ?
#endif

    // TODO: add video irq related code
;    bit 3,a
;    call nz,video_irq_code	; video IRQ?


    POP_ALL_REGS()
    ei
    reti
    ENDASM()

}
#endif


#ifdef __IAR_SYSTEMS_ICC__
interrupt void irq_handler(void);
interrupt void irq_handler(void)
{

#ifdef APP_USE_OWN_KEYBOARD_IRQ
    if(io__sys_irq_ps2_flags & 1)   // Read irq status flags. Keyboard irq set?
        Keyboard_IRQ_Handler();     // call keyboard irq routine if so
#endif


}
#endif


void install_irq_handler(byte irq_enable_mask)
{
    word *pW;
    DI();
    pW  = (word*)IRQ_VECTOR;
    *pW = (word)&irq_handler;
    io__sys_irq_enable = irq_enable_mask;
    EI();
}
