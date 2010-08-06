void irq_handler() NAKED;
void install_irq_handler(byte irq_enable_mask);

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

;    bit 2,a
;    call nz,timer_irq_code	; timer IRQ?
;    bit 3,a
;    call nz,video_irq_code	; video IRQ?


    POP_ALL_REGS()
    ei
    reti
    ENDASM()

}

void install_irq_handler(byte irq_enable_mask)
{
    DI();
    *((word*)IRQ_VECTOR) = (word)&irq_handler;
    io__sys_irq_enable = irq_enable_mask;
    EI();
}