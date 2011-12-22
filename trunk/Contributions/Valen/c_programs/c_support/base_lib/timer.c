#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <base_lib/timer.h>


void Timer_Init(byte timer_hardware_period)
{   
     io__sys_timer = timer_hardware_period;

}

