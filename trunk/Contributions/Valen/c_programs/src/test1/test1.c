/*
TEST v0.01
-------------
*/

#include "../../inc/kernal_jump_table.h"
#include "../../inc/v6z80p_types.h"
#include "../../inc/OSCA_hardware_equates.h"
#include "../../inc/macros_specific.h"
#include "../../inc/set_stack.h"

#include "../../inc/os_interface_for_c/i_flos.h"

#include <stdlib.h>

// for use sprintf (this will add about 3KB of code)
#include <stdio.h>             


#define OS_VERSION_REQ  0x575           // OS version req. to run this program


// prototypes
BOOL TestVersion(void);
BOOL test1(void);
BOOL test2(void);
BOOL test3(void);
BOOL test4(void);
BOOL test5(void);
BOOL test6(void);

void proccess_cmd_line(void);
void DiagMessage(char* pMsg, char* pFilename);
void PrintNum(dword n);
void WaitKeyPress(byte scancode);
BOOL PrintCurDirName(void);
word GetSP(void)  NAKED;

char *pFilename;
FLOS_FILE myFile;
char buffer[32+1];

byte buf[8];

byte mystring[60];


# define CALL_TEST(n)        if ( !test##n() ) {                \
                                 MarkFrameTime(0xf00);          \
                                 return 0;                      \
                             }


int main (void)
{

    MarkFrameTime(0x00f);
    FLOS_ClearScreen();

    proccess_cmd_line();

    if(!TestVersion()) {
        FLOS_PrintString("FLOS v");
        _uitoa(OS_VERSION_REQ, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintStringLFCR("+ req. to run this program");
        return NO_REBOOT;
    }


    CALL_TEST(1);
    CALL_TEST(2);
    CALL_TEST(3);
    CALL_TEST(4);
    CALL_TEST(5);
    CALL_TEST(6);


    FLOS_PrintStringLFCR("TEST OK");





    return NO_REBOOT;
}


void proccess_cmd_line(void)
{
    char* cmdline = NULL;

    cmdline = FLOS_GetCmdLine();
    // TODO: remove CRLF from end of filename
    pFilename =  (cmdline == NULL) ? "NOFILE" : cmdline;

/*
    FLOS_PrintString("CmdLine: ");
    if(cmdline != NULL)
        FLOS_PrintStringLFCR(cmdline);
    else
        FLOS_PrintStringLFCR("NO LINE");
*/


}

BOOL TestVersion(void)
{
    word os_version_word, hw_version_word;

    // print OS and HW version
    FLOS_GetVersion(&os_version_word, &hw_version_word);
    FLOS_PrintString("OS: ");
    PrintNum(os_version_word);
    FLOS_PrintString("   HW: ");
    PrintNum(hw_version_word);
    FLOS_PrintStringLFCR("");

    if(os_version_word < OS_VERSION_REQ)
        return FALSE;


    return TRUE;
}




BOOL test1(void)
{
    BOOL r;

    FLOS_FILE_SECTOR_LIST pF;
    byte sectorOffset;
    word clusterNumber;
    dword sectorNumber;


    r = FLOS_FindFile(&myFile, pFilename);
    if(!r) {
       DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }


    FLOS_PrintString("FindFile: ");
    FLOS_PrintString(pFilename);
    FLOS_PrintString(PS_LFCR);

    _ultoa(myFile.size, buffer, 16);
    FLOS_PrintString("Size: $");
    FLOS_PrintString(buffer);

    _ultoa(myFile.z80_address, buffer, 16);
    FLOS_PrintString(" Addr: $");
    FLOS_PrintString(buffer);

    _ultoa(myFile.z80_bank, buffer, 16);
    FLOS_PrintString(" Bank: $");
    FLOS_PrintString(buffer);
    FLOS_PrintString(PS_LFCR);

    sprintf(mystring, "Cluster: %i", myFile.firstCluster);
    FLOS_PrintStringLFCR(mystring);

    sectorOffset = 0; clusterNumber = myFile.firstCluster;
    FLOS_FileSectorList(&pF, sectorOffset, clusterNumber);

    sectorNumber =  *pF.ptrToSectorNumber;
    sprintf(mystring, "Cluster: %l", sectorNumber);
    FLOS_PrintStringLFCR(mystring);

    return TRUE;
}

// Note:
// FLOS or my issue ?
// if i do findfile and then forceload IT RESETS, but forceload must just return error: file len is zero (err = $7)
BOOL test2(void)
{
    BOOL r;
    byte i;
//    byte err;

    // print data at 0000
    FLOS_SetLoadLength(8);

    r = FLOS_ForceLoad( buf, 0 );
    if(!r) {
       DiagMessage("ForceLoad failed: ", pFilename);
       return FALSE;
    }

    FLOS_PrintString("Data at $0000: ");
    FLOS_PrintString(PS_LFCR);

    for(i=0; i<8; i++) {
       _itoa(buf[i], buffer, 16);
       FLOS_PrintString("  ");
       FLOS_PrintString(buffer);
    }

    FLOS_PrintString(PS_LFCR);

    // print data at 0010
    FLOS_SetFilePointer(0x10);
    FLOS_SetLoadLength(8);
    r = FLOS_ForceLoad( buf, 0 );
    if(!r) {
       DiagMessage("ForceLoad failed: ", pFilename);
       return FALSE;
    }
    FLOS_PrintString("Data at $0010: ");
    FLOS_PrintString(PS_LFCR);

    for(i=0; i<8; i++) {
       _itoa(buf[i], buffer, 16);
       FLOS_PrintString("  ");
       FLOS_PrintString(buffer);
    }
    FLOS_PrintString(PS_LFCR);


    return TRUE;
}

BOOL test3(void)
{
    BOOL r;
    dword blocks;
    byte* pFilename;

    blocks = FLOS_GetTotalSectors();

    FLOS_PrintString("Drive total sectors: $");
    _ultoa(blocks, buffer, 16);
    FLOS_PrintString(buffer);
    FLOS_PrintString(PS_LFCR);


    FLOS_PrintStringLFCR("Creating file... ");
    pFilename = "MYTEST.TMP";
    r = FLOS_CreateFile(pFilename);
    if(!r) {
       DiagMessage("CreateFile failed: ", pFilename);
       return FALSE;
    }


    // write bytes
    FLOS_PrintStringLFCR("Writing bytes to file...");
    r = FLOS_WriteBytesToFile(pFilename, (byte*) 0x1000, 0, 0x2000);
    if(!r) {
       DiagMessage("WriteBytesToFile failed: ", pFilename);
       return FALSE;
    }


    FLOS_PrintStringLFCR("Erasing file... ");
    r = FLOS_EraseFile(pFilename);
    if(!r) {
       DiagMessage("EraseFile failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}

BOOL test4(void)
{

    BOOL r;
    const char* pDirName = "TMPDIR";

    FLOS_PrintStringLFCR("Creating dir... ");
    r = FLOS_MakeDir(pDirName);
    if(!r) {
       DiagMessage("MakeDir failed: ", pDirName);
       return FALSE;
    }

    FLOS_PrintStringLFCR("Change dir... ");
    r = FLOS_ChangeDir(pDirName);
    if(!r) {
       DiagMessage("ChangeDir failed: ", pDirName);
       return FALSE;
    }


    if(!PrintCurDirName())
       return FALSE;


    FLOS_PrintStringLFCR("Parent dir... ");
    r = FLOS_ParentDir();
    if(!r) {
       DiagMessage("ParentDir failed: ", "");
       return FALSE;
    }


    FLOS_PrintStringLFCR("Deleting dir... ");
    r = FLOS_DeleteDir(pDirName);
    if(!r) {
       DiagMessage("DeleteDir failed: ", pDirName);
       return FALSE;
    }

    FLOS_PrintStringLFCR("ROOT dir... ");
    FLOS_RootDir();


    if(!PrintCurDirName())
       return FALSE;


    return TRUE;
}

BOOL PrintCurDirName(void)
{
    const char* p;

    FLOS_PrintString("Dirname: ");
    p = FLOS_GetDirName();
    if(!p) {
       DiagMessage("FLOS_GetDirName failed: ", "");
       return FALSE;
    }
    FLOS_PrintStringLFCR(p);

    return TRUE;

}

BOOL test5(void)
{
    BOOL r;
    byte asciicode, scancode;


    // test FLOS_WaitKeyPress
    FLOS_PrintStringLFCR("FLOS_WaitKeyPress... press any key");
    FLOS_WaitKeyPress(&asciicode, &scancode);
    FLOS_PrintString("scancode: $");
    _ultoa(scancode, buffer, 16);
    FLOS_PrintString(buffer);
    FLOS_PrintString(" ascii: $");
    _ultoa(asciicode, buffer, 16);
    FLOS_PrintStringLFCR(buffer);



    // test FLOS_SetCursorPos
    r = FLOS_SetCursorPos(10, 18);
    if(!r)
       return FALSE;
    FLOS_PrintStringLFCR("SetCursorPos... ");


    return TRUE;
}


BOOL test6(void)
{
    FLOS_DIR_ENTRY e;
//word sp;

    FLOS_PrintStringLFCR("Press ENTER key to DIR test...");
    // wait ENTER press
    WaitKeyPress(0x5A);

    FLOS_ClearScreen();

    FLOS_PrintStringLFCR("Dir list:");
    // iterate through current dir entries  (FLOS v537+)
    FLOS_DirListFirstEntry();
    while(1) {
        FLOS_DirListGetEntry(&e);
        if(e.err_code == END_OF_DIR) break;

        FLOS_PrintString(e.pFilename);

        if(e.file_flag == 1)
            FLOS_PrintStringLFCR("  (DIR)");
        else {
            FLOS_PrintString("  $");
            PrintNum(e.len);
            FLOS_PrintStringLFCR("");
        }

        if(FLOS_DirListNextEntry() == END_OF_DIR) break;

    }

//sp = GetSP();
//PrintNum(sp);

    return TRUE;
}

void DiagMessage(char* pMsg, char* pFilename)
{
    byte err;

    err = FLOS_GetLastError();

    FLOS_PrintString(pMsg);
    FLOS_PrintString(pFilename);

    FLOS_PrintString(" OS_err: $");
    _uitoa(err, buffer, 16);
    FLOS_PrintString(buffer);
    FLOS_PrintString(PS_LFCR);


}


void PrintNum(dword n)
{
    _ultoa(n, buffer, 16);
    FLOS_PrintString(buffer);

}

void WaitKeyPress(byte scancode)
{
    byte cur_asciicode = 0, cur_scancode = 0;

    while(cur_scancode != scancode) {
        FLOS_WaitKeyPress(&cur_asciicode, &cur_scancode);
    }
}

// my debug
// just get sp, to see if it is near good value (the value i setup in makefile)
word GetSP(void)  NAKED
{
    __asm;
    ld hl,#0
    add hl,sp
    ret
    __endasm;

}
