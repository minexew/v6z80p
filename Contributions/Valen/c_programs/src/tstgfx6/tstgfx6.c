/*
    Basic timer example.
   
    V6Z80P have 8-bit timer.
    The timer has a resolution of 0.000016 seconds (IE: it runs at 62.5 KHz).
    Timer can generate intervals from 0,016 millisec to 4 millisec.
    (See docs for more info)
   
    If you want to time long intervals, you have to count shorter
    periods in your IRQ routine.

           
*/
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>

#include <os_interface_for_c/i_flos.h>

#include <base_lib/keyboard.h>
#include <base_lib/timer.h>
#include <base_lib/utils.h>

#include <stdlib.h>
#include <string.h>

// We use our own irq code for:
// - keyb (ESC - exit from program) and timer
#define APP_USE_OWN_KEYBOARD_IRQ
#define APP_USE_OWN_TIMER_IRQ
#include "../../src/inc/irq.c"




// prototype
void Application_Timer_IRQ_Handler(void);

#define OS_VERSION_REQ  0x571           // OS version req. to run this program

// let's set timer to 4 milliseconds
#define TIMER_MILLISEC_PERIOD   4                                       // possible values are [0,016...4] 
#define TIMER_HARDWARE_PERIOD   256-(TIMER_MILLISEC_PERIOD/0.016)       // calculate timer hardware period (8-bit value)





//  application flags for pressed keyboard keys
typedef struct {
    BOOL esc;
} player_input;
player_input myplayer_input = {FALSE};

// keyboard input map, provided by application
keyboard_input_map_t keyboard_input_map[] = {
                {SC_ESC, &myplayer_input.esc},
                {0xFF, NULL}           // terminator (end of input map)
};


char buffer[32];
word seconds = 0;

word GetSeconds()
{
    word tmp;
    
    // non-atomic operation (do with disabled interrupts)
    DI();
    tmp = seconds;
    EI();
    
    return tmp;
}

void DoMain(void)
{    
    FLOS_SetCursorPos(0, 0);
    FLOS_PrintString("Seconds: ");
    _uitoa(GetSeconds(), buffer, 10);
    FLOS_PrintStringLFCR(buffer);
    FLOS_PrintStringLFCR("Press ESC to reboot...");
    
}



// function provided by application for timer irq handler
void Application_Timer_IRQ_Handler(void)
{
    static word counter = 0;
    
    
    //word *palette = 0;    
    //*palette = counter;
    
    // if counter accumulated one second, zero counter
    if(counter == 1000 / TIMER_MILLISEC_PERIOD) {
        counter = 0;
        
        seconds++;
    }
        
        
    counter++;
}


// Timer ISR
void Timer_IRQ_Handler()
{
    // call application function, to do some useful work
    Application_Timer_IRQ_Handler();


    // clear timer interrupt flag
    BEGINASM()
    PUSH_ALL_REGS()

    ld a,#0x04
    out (SYS_CLEAR_IRQ_FLAGS),a ; clear timer interrupt flag

    POP_ALL_REGS()
    ENDASM()

}


BOOL Check_FLOS_Version(void) 
{
    if(!Utils_Check_FLOS_Version(OS_VERSION_REQ)) {
        FLOS_PrintString("FLOS v");
        _uitoa(OS_VERSION_REQ, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintStringLFCR("+ req. to run this program.");
        return FALSE;
    }
    return TRUE;
}


int main(void)
{    

    if(!Check_FLOS_Version()) 
        return NO_REBOOT;

    FLOS_ClearScreen();
   
    Timer_Init(TIMER_HARDWARE_PERIOD);
    Keyboard_Init(keyboard_input_map);        // init keyboard input
    install_irq_handler(IRQ_ENABLE_MASTER | IRQ_ENABLE_KEYBOARD | IRQ_ENABLE_TIMER);          // enable irq: master, keyboard, timer    
        
    
    while(!myplayer_input.esc) {
        FLOS_WaitVRT();
                     
        DoMain();
    }
    

    return REBOOT;
}
