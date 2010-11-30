/*
TEST 3
Basic test of file I/O functions.

Can be compiled for V6Z80P and PC.
Run on both platforms and compare output listings.
If they are equ, then test is passed.
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
    #include <stdio_v6z80p.h>        // provide file I/O funcs (fopen, fread, ...)

    #define MY_PRINT(str)    FLOS_PrintString(str)
    #define MY_PRINT_CR(str) FLOS_PrintStringLFCR(str)



    const char *myFilename   = "TEST3.EXE";
    const char *myFilenameW  = "TEST3.TXT";


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
    #define fset_system_bank(b)
    #define NO_REBOOT 0


    char *myFilename =      "/home/valen/_1/test3.exe";
    char *myFilenameW =     "/home/valen/_1/test3.txt";


#endif

long GetFileSize(FILE *f);
WORD CalcCRC(BYTE *data, WORD size);
long CalcFileCRC_Slow(const char* filename);
long CalcFileCRC(const char* filename);

BOOL test0(void);
BOOL test1(void);
BOOL test2(void);
BOOL test3(void);


int main(void) {
    test0(); test1(); test2(); test3();
    return NO_REBOOT;
}



BOOL test0(void)
{
    WORD sum = 0;

    // init V6Z80P stdio lib
    init_stdio_v6z80p();
    // Set the logical system memory bank for use with fread and fwrite functions.
    // Info: How FLOS start program:
    // - set logic bank 0 (in area 0x8000-0xFFFF)
    // - load program and pass excution to entry point (0x5000)
    fset_system_bank(0);

    sum = CalcFileCRC(myFilename);
    sprintf(myTestString, "CRC: %x ", sum); MY_PRINT_CR(myTestString);
    return TRUE;
}



// read some parts of file and and calc simple CRC
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
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", myFilename); MY_PRINT_CR(myTestString); return TRUE;}

    sprintf(myTestString, "File size:%x", GetFileSize(f)); MY_PRINT_CR(myTestString);

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



BOOL test2(void)
{
    WORD sum = 0;

    sprintf(myTestString, "test2()"); MY_PRINT_CR(myTestString);
    sum = CalcFileCRC_Slow(myFilename);
    sprintf(myTestString, "CRC: %x ", sum); MY_PRINT_CR(myTestString);

    return TRUE;
}



BOOL test3(void)
{
    FILE *f;
    size_t r = 1;
    WORD sum = 0, i;

    sprintf(myTestString, "test3()"); MY_PRINT_CR(myTestString);
    f = fopen(myFilenameW, "wb");
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", myFilenameW); MY_PRINT_CR(myTestString); return TRUE;}

    // fill buffer with some bytes
    for(i=0; i<sizeof(myFileBuf); i++) {
        myFileBuf[i] = (BYTE) i;
//        sum += CalcCRC(myFileBuf, r);
//        sprintf(myTestString, "r: %x ", r); MY_PRINT_CR(myTestString);
    }
    r = fwrite(myFileBuf, 1, sizeof(myFileBuf), f);

//    sprintf(myTestString, "r: %x ", r); MY_PRINT_CR(myTestString);
    fclose(f);

    sum = CalcFileCRC(myFilenameW);
    sprintf(myTestString, "CRC: %x ", sum); MY_PRINT_CR(myTestString);
    return TRUE;
}
// --------------------------

// load file, byte by byte (slow on V6Z80P),  and calc simple CRC
long CalcFileCRC_Slow(const char* filename)
{
    FILE *f;
    size_t r = 1;
    WORD sum = 0;

    f = fopen(filename, "rb");
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", filename); MY_PRINT_CR(myTestString); return -1;}


//    sprintf(myTestString, "f: %x ", (DWORD)f); MY_PRINT(myTestString);


    while(!feof(f) && !ferror(f)) {
        r = fread(myFileBuf, 1, 1, f);
//        sprintf(myTestString, "readed: %x ", r); MY_PRINT(myTestString);
//        sprintf(myTestString, "EOF: %x ", feof(f)); MY_PRINT_CR(myTestString);

        sum += CalcCRC(myFileBuf, r);
//        sprintf(myTestString, "r: %x ", r); MY_PRINT_CR(myTestString);
    }

    sprintf(myTestString, "r: %x ", r); MY_PRINT_CR(myTestString);

    fclose(f);

    return sum;
}

// load file by 4KB chunks and calc simple CRC
long CalcFileCRC(const char* filename)   {
    FILE *f;
    size_t r = 1;
    WORD sum = 0;

    f = fopen(filename, "rb");
    if(!f) {sprintf(myTestString, "fopen failed. File:%s", filename); MY_PRINT_CR(myTestString); return -1;}

    while(!feof(f) && !ferror(f)) {
        r = fread(myFileBuf, 1, sizeof(myFileBuf), f);
        sprintf(myTestString, "readed: %x ", r);  MY_PRINT(myTestString);
        sprintf(myTestString, "EOF: %x ", feof(f));  MY_PRINT_CR(myTestString);

        sum += CalcCRC(myFileBuf, r);
    }

    fclose(f);
    return sum;
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

const char* intToBoolString(long v)
{
    return (v ? "TRUE" : "FALSE");
}
