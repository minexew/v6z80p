/*
TEST 3
Basic test of file I/O functions.

*/

// ----------------------------------------------------------------------
char myFileBuf[4096];
char myTestString[128];


#ifdef SDCC
    #include <kernal_jump_table.h>
    #include <v6z80p_types.h>
    #include <OSCA_hardware_equates.h>
    #include <macros_specific.h>
    #include <macros.h>
    #include <set_stack.h>

    #include <os_interface_for_c/i_flos.h>

    #include <stdlib.h>

    // for use sprintf (this will add about 3KB of code)
    #include <stdio.h>
    #include <stdio_v6z80p.h>        // provide fopen, fread, ...

    #define MY_PRINT(str)    FLOS_PrintString(str)
    #define MY_PRINT_CR(str) FLOS_PrintStringLFCR(str)



    const char *myFilename        = "TEST1.EXE";


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
    #define NO_REBOOT 0


    char *myFilename =        "/home/valen/_1/test1.exe";


#endif

long GetFileSize(FILE *f);
WORD CalcCRC(BYTE *data, WORD size);
BOOL test0(void);
BOOL test1(void);


int main(void) {
    test0(); test1();
    return NO_REBOOT;
}



BOOL test0(void)
{
    FILE *f;
    size_t r = 1;
    WORD sum = 0;

    init_stdio_v6z80p();

    f = fopen(myFilename, "rb");
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", myFilename); MY_PRINT(myTestString); return TRUE;}


//    sprintf(myTestString, "f: %x ", (DWORD)f); MY_PRINT(myTestString);

    // load file by 4KB chunks and calc simple CRC
    while(!feof(f) && !ferror(f)) {
        r = fread(myFileBuf, 1, sizeof(myFileBuf), f);
        sprintf(myTestString, "readed: %x ", r);
        MY_PRINT(myTestString);
        sprintf(myTestString, "EOF: %x ", feof(f));
        MY_PRINT_CR(myTestString);

        sum += CalcCRC(myFileBuf, r);
    }


    sprintf(myTestString, "CRC: %x ", sum); MY_PRINT_CR(myTestString);
    fclose(f);

    return TRUE;
}


BOOL test1(void)
{
    FILE *f;
    //size_t r = 1;
    WORD sum = 0;
    DWORD arr[] = {SEEK_SET,0,100,      SEEK_SET,200,100,   SEEK_SET,300,100,
                   SEEK_CUR,0,100,      SEEK_CUR,200,100,   SEEK_CUR,300,100,
                   SEEK_END,-100,100,   SEEK_END,-200,100,  SEEK_END,-300,100,
                   -1};
    WORD i = 0;
    DWORD filePos,  bytesToRead, seekMode;

    sprintf(myTestString, "test1()"); MY_PRINT_CR(myTestString);

    f = fopen(myFilename, "rb");
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", myFilename); MY_PRINT(myTestString); return TRUE;}

    sprintf(myTestString, "File size:%x", GetFileSize(f)); MY_PRINT_CR(myTestString);
    // read some parts of file
    while(arr[i] != -1) {
        seekMode    = arr[i];
        filePos     = arr[i+1];
        bytesToRead = arr[i+2];

        fseek(f, filePos , seekMode);
        fread(myFileBuf, 1, bytesToRead, f);
        sum += CalcCRC(myFileBuf, bytesToRead);
        i += 3;

    }

    sprintf(myTestString, "CRC: %x ", sum); MY_PRINT_CR(myTestString);
    fclose(f);

    return TRUE;
}


// Simple cyclic sum (add all bytes)
WORD CalcCRC(BYTE *data, WORD size)
{
    WORD sum = 0, i;

    for(i=0; i<size; i++) {
        sum += data[i];
    }
    return sum;
}

long GetFileSize(FILE *f)
{
    long size;
    fseek(f, 0, SEEK_END); // seek to end of file
    size = ftell(f); // get current file pointer
    fseek(f, 0, SEEK_SET); // seek back to beginning of file

    return size;
}

