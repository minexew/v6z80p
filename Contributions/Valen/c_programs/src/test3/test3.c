/*
TEST 3
Test file  i/o functions.
-------------
*/

// ----------------------------------------------------------------------
char myFileBuf[4096];
char myTestString[128];


#ifdef SDCC
    #include <kernal_jump_table.h>
    #include <v6z80p_types.h>
    #include <OSCA_hardware_equates.h>
    #include <macros_specific.h>
    #include <set_stack.h>

    #include <os_interface_for_c/i_flos.h>

    #include <stdlib.h>

    // for use sprintf (this will add about 3KB of code)
    #include <stdio.h>
    #include <stdio_v6z80p.h>        // provide fopen, fread, ...

    #define MY_PRINT(str)    FLOS_PrintString(str)
    #define MY_PRINT_CR(str) FLOS_PrintStringLFCR(str)
    const char *myFilename = "TEST1.EXE";

    BOOL test0(void);
    int main(void) { test0(); return NO_REBOOT;}
#else   // compiling for PC

    #include <stdio.h>
    #include <stdlib.h>
    //#include "~/_1/v6z80p_SVN/Contributions/Valen/c_programs/inc/v6z80p_types.h"
    typedef unsigned char  BYTE;
    typedef unsigned short WORD;
    typedef unsigned long  DWORD;
    typedef unsigned char  BOOL;

    #define FALSE   0
    #define TRUE    1

    #define MY_PRINT(str)    printf(str)
    #define MY_PRINT_CR(str) printf(str); printf("\n");
    #define init_stdio_v6z80p()

    char *myFilename = "/home/valen/_1/test1.exe";

    BOOL test0(void);
    int main(void) { test0(); return 0;}
#endif






BOOL test0(void)
{
    FILE *f;
    size_t r = 1;

    init_stdio_v6z80p();

    f = fopen(myFilename, "rb");
//    fclose(f);

   sprintf(myTestString, "f: %x ", (DWORD)f);
   MY_PRINT(myTestString);

    while(!feof(f)) {
        r = fread(myFileBuf, 1, sizeof(myFileBuf), f);
        sprintf(myTestString, "r: %x ", r);
        MY_PRINT(myTestString);
        sprintf(myTestString, "EOF: %x ", feof(f));
        MY_PRINT_CR(myTestString);
    }



    return TRUE;
}
// ---------------------------------------------------------
