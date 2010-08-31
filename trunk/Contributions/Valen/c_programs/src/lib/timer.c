void Timer_Init(byte timer_hardware_period)
{   
     io__sys_timer = timer_hardware_period;
}

// Timer ISR 
void Timer_IRQ_Handler()
{
    // call function provided by application, to do some useful work
    Application_Timer_IRQ_Handler();
    

    // clear timer interrupt flag
    BEGINASM()
    PUSH_ALL_REGS()

    ld a,#0x04
    out (SYS_CLEAR_IRQ_FLAGS),a ; clear timer interrupt flag

    POP_ALL_REGS()
    ENDASM()

}
