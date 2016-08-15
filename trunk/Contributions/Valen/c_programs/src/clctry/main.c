#include <stdlib.h>
#include <stdio.h>
//#include <malloc.h>
// #include "debug_print.h"
#include "my_types.h"


#include "clcsrc.h"

#if defined(SDCC) || defined(__SDCC)
#include <set_stack.h>
extern void __sdcc_heap_init (void);
#endif








int main( 	int			theCount ,
			const char* theTokens[ ] )
{

	struct Engine* obj;

#if defined(SDCC) || defined(__SDCC)
    DEBUG_PRINT("__sdcc_heap_init() \n");
    __sdcc_heap_init ();
#endif  

	obj = Engine_alloc( );
	Engine_Init( obj);
	Engine_Run( obj);
	// free_object( obj );
	
    return 0;
	
}


void Host_ExitToOS(int code)
{
#ifdef __SDCC
    FLOS_PrintString("Host_ExitToOS() called, program terminated.");
    FLOS_ExitToFLOS();    
#endif

#ifdef PC    
    exit(1);
#endif    
}