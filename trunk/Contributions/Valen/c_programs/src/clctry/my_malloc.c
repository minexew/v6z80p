// My malloc() and my free() funcs.
// 
// All calls to malloc() and free() in file clcsrc.c wiil
// be re-targeted to my_malloc() and my_free()

#include <stdlib.h>
#include <stdio.h>
//#include <malloc.h>
#include <debug_print.h>

#if defined(SDCC) || defined(__SDCC)
#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <macros_specific.h>
#include <os_interface_for_c/i_flos.h>

#endif

#undef malloc
#undef free 


extern void Host_ExitToOS(int code);


void* my_malloc(size_t i)
{
	void *pMem = NULL;
	
	pMem = malloc(i);
	if(!pMem) {
		DEBUG_PRINT("my_malloc() FAILED mem allocation. Size: %u, ptr: %u \n", i, (unsigned int) pMem);
		Host_ExitToOS(1);
	}
		
	DEBUG_PRINT("my_malloc() mem allocated. Size: %u, ptr: %u \n", i, (unsigned int) pMem);
		
	return pMem;
	
}
void my_free(void* memblock)
{
	return free(memblock);
}

