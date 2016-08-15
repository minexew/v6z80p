// My malloc() and my free() funcs.
// 
// All calls to malloc() and free() in file clcsrc.c wiil
// be re-targeted to my_malloc() and my_free()

// #include <stdlib.h>
// #include <stdio.h>
//#include <malloc.h>
// #include <debug_print.h>

// #if defined(SDCC) || defined(__SDCC)
// #include <kernal_jump_table.h>
// #include <v6z80p_types.h>
// #include <OSCA_hardware_equates.h>
// #include <macros_specific.h>
// #include <os_interface_for_c/i_flos.h>

// #endif


void* my_malloc(size_t i);

void my_free(void* memblock);

