#include <v6z80p_types.h>
#include <os_interface_for_c/i_flos.h>


//#include <stdlib.h>
#include <string.h>

#include "v6assert.h"

void _v6assert(char *expr, const char *filename, unsigned int linenumber)
{
        linenumber; filename;

	FLOS_FlosDisplay();
	FLOS_PrintStringLFCR("Assert ");
	FLOS_PrintStringLFCR(expr);

//        io__sys_mem_select = 14 + 1;
        strcpy((char*)0xF000, expr);
//        io__sys_mem_select = PONG_BANK + 1;


//	FLOS_PrintStringLFCR("Assert(%s) failed at line %u in file %s.\n",
//		expr, linenumber, filename);
	while(1);
}
