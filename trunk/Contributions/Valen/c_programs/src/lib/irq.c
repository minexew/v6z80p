void irq_handler() NAKED;
void install_irq_handler(byte irq_enable_mask);

void irq_handler() NAKED
{
    BEGINASM()
    PUSH_ALL_REGS()

    in a,(SYS_IRQ_PS2_FLAGS)            ; Read irq status flags
    bit 0,a                           ; keyboard irq set?
    call nz,_Keyboard_IRQ_Handler       ; call keyboard irq routine if so

    ld a,#0x01
    out (SYS_CLEAR_IRQ_FLAGS),a ; clear keyboard interrupt flag

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