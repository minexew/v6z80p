#include "../../inc/kernal_jump_table.h"
#include "../../inc/v6z80p_types.h"
#include "../../inc/OSCA_hardware_equates.h "

#include "../../inc/os_interface_for_c/i_flos.h"

#include <string.h>


#define SPAWN_CMD_LINE_BUFFER_LEN 40            // in bytes

byte  g_a1_byte_result;
byte  g_flos_lasterror;
byte  g_flos_hw_lasterror;

extern char* flos_cmdline;
extern char  flos_spawn_cmd[SPAWN_CMD_LINE_BUFFER_LEN];

/*
void WaitVRT(void) NAKED
{
	BEGINASM()
        push af


        nop
wvrtstart:
	ld a,(VREG_READ)		
	and #0x1
	jr z,wvrtstart
wvrtend:
        ld a,(VREG_READ)
	and #0x1
	jr nz,wvrtend

        pop af
        ret
        ENDASM()


}
*/

void MarkFrameTime(ushort color)
{
   ushort* p = (ushort*) PALETTE;
   *p = color;

}


// ---------------------------------------------


byte FLOS_GetLastError(void) 
{
   return g_flos_lasterror;
}

#define I_DATA          0x5080
#define I_CODE_BASE     0x5080 + 0x20

#define GET_I_ADDRESS(kjt)              (kjt - 0x1000 + I_CODE_BASE)
#define PTRTO_I_DATA(data, ptrtype)     ((ptrtype*) (data))
#define CALL_FLOS_CODE(kjt)             pFunc = (ptrVoidFunc) GET_I_ADDRESS(kjt);     \
                                        (*pFunc)();

//typedef void (*ptrVoidFunc)(void);
ptrVoidFunc pFunc;



// 
BOOL FLOS_MakeDir(const char* pDirName)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;

    CALL_FLOS_CODE(KJT_MAKE_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}

BOOL FLOS_ChangeDir(const char* pDirName)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;

    CALL_FLOS_CODE(KJT_CHANGE_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}

BOOL FLOS_ParentDir(void)
{
    byte result = FALSE;
    CALL_FLOS_CODE(KJT_PARENT_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}

// Seems root_dir does not return Z,  when call was ok
// So, no return value in this func
void FLOS_RootDir(void)
{
//    byte result = FALSE;
    CALL_FLOS_CODE(KJT_ROOT_DIR);

/*    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
*/
}

BOOL FLOS_DeleteDir(const char* pDirName)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;

    CALL_FLOS_CODE(KJT_DELETE_DIR);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result;
}


void FLOS_StoreDirPosition(void)
{
     CALL_FLOS_CODE(KJT_STORE_DIR_POSITION);
}

void FLOS_RestoreDirPosition(void)
{
     CALL_FLOS_CODE(KJT_RESTORE_DIR_POSITION);
}

dword FLOS_GetTotalSectors(void)
{
    CALL_FLOS_CODE(KJT_GET_TOTAL_SECTORS);

    return  *PTRTO_I_DATA(I_DATA, dword);
}


BOOL FLOS_FindFile(FLOS_FILE* const pFile, const char* pFileName)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA, word) = (word) pFileName;

    CALL_FLOS_CODE(KJT_FIND_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(result) {
       pFile->z80_address = *PTRTO_I_DATA(I_DATA+3, word);
//       pFile->first_block = *PTRTO_I_DATA(I_DATA+2, word);
       pFile->z80_bank    = *PTRTO_I_DATA(I_DATA+2, byte);
       pFile->size        = *PTRTO_I_DATA(I_DATA+5, dword);
//    
    } else {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}

void FLOS_SetLoadLength(const dword len)
{
    *PTRTO_I_DATA(I_DATA, dword) = (dword) len;

    CALL_FLOS_CODE(KJT_SET_LOAD_LENGTH);
}


void FLOS_SetFilePointer(const dword p)
{
    *PTRTO_I_DATA(I_DATA, dword) = (dword) p;

    CALL_FLOS_CODE(KJT_SET_FILE_POINTER);
}

BOOL FLOS_ForceLoad(const byte* address, const byte bank)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA,   word) = (word) address;
    *PTRTO_I_DATA(I_DATA+2, byte) = (byte) bank;

    CALL_FLOS_CODE(KJT_FORCE_LOAD);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}


// Note:
// args default_z80_address and default_z80_bank       
// are irrelevent on FAT16
//
// const word default_z80_address, const byte default_z80_bank
BOOL FLOS_CreateFile(const byte* pFilename)
{
    word default_z80_address = 0;
    byte default_z80_bank = 0;

    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA,   word) = (word) pFilename;
    *PTRTO_I_DATA(I_DATA+2, word) = (word) default_z80_address;
    *PTRTO_I_DATA(I_DATA+4, byte) = (byte) default_z80_bank;

    CALL_FLOS_CODE(KJT_CREATE_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}


BOOL FLOS_EraseFile(const byte* pFilename)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA,   word) = (word) pFilename;

    CALL_FLOS_CODE(KJT_ERASE_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}


// len = 24 bit length
BOOL FLOS_WriteBytesToFile(const byte* pFilename, byte* address, const byte bank, const dword len)
{
    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA,   word)  = (word) pFilename;
    *PTRTO_I_DATA(I_DATA+2, word)  = (word) address;
    *PTRTO_I_DATA(I_DATA+4, byte)  = bank;
    *PTRTO_I_DATA(I_DATA+5, dword) = len;

    CALL_FLOS_CODE(KJT_WRITE_BYTES_TO_FILE);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(!result) {
       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 

}

// ---------------

void FLOS_PrintString(const char* string)
{
    *PTRTO_I_DATA(I_DATA, word) = (word) string;

    CALL_FLOS_CODE(KJT_PRINT_STRING);

}

void FLOS_ClearScreen(void)
{
    CALL_FLOS_CODE(KJT_CLEAR_SCREEN);

}


void FLOS_FlosDisplay(void)
{
    CALL_FLOS_CODE(KJT_FLOS_DISPLAY);

}



void FLOS_WaitVRT(void)
{
    CALL_FLOS_CODE(KJT_WAIT_VRT);

}

void FLOS_SetPen(byte color)
{

    *PTRTO_I_DATA(I_DATA,   byte) = color;

    CALL_FLOS_CODE(KJT_SET_PEN);
}


BOOL FLOS_SetCursorPos(byte x, byte y)
{

    byte result = FALSE;
    *PTRTO_I_DATA(I_DATA,   byte) = (byte) x;
    *PTRTO_I_DATA(I_DATA+1, byte) = (byte) y;

    CALL_FLOS_CODE(KJT_SET_CURSOR_POSITION);

    result = *PTRTO_I_DATA(I_DATA, byte);

    return result; 
}

// -----

// Out: pASCII, pScancode will be used to store results
void FLOS_WaitKeyPress(byte* pASCII, byte* pScancode)
{

    CALL_FLOS_CODE(KJT_WAIT_KEY_PRESS);

    *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
    *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);

}

// Out: pASCII, pScancode will be used to store results
BOOL FLOS_GetKeyPress(byte* pASCII, byte* pScancode)
{

    CALL_FLOS_CODE(KJT_GET_KEY);

    *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
    *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);

    // if scancode is 0, return FALSE (no scancode in buffer)
    return (*pScancode == 0) ?  FALSE : TRUE;
}

// functions, to iterate through current dir entries  (FLOS v537+)

void FLOS_DirListFirstEntry(void)
{
    CALL_FLOS_CODE(KJT_DIR_LIST_FIRST_ENTRY);

}

// Return: FALSE - if hardware error
//         TRUE  - all ok
BOOL FLOS_DirListGetEntry(FLOS_DIR_ENTRY* pEntry)
{
    byte result = FALSE;

    CALL_FLOS_CODE(KJT_DIR_LIST_GET_ENTRY);

    result = *PTRTO_I_DATA(I_DATA, byte);
    if(result) {
       pEntry->pFilename = (const char*) ( *PTRTO_I_DATA(I_DATA+1, word) );
       pEntry->file_flag =                 *PTRTO_I_DATA(I_DATA+3, byte);
       pEntry->err_code  =                 *PTRTO_I_DATA(I_DATA+4, byte);
       pEntry->len       =                 *PTRTO_I_DATA(I_DATA+5, dword);
    } else {
//       g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
//       g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
    }

    return result; 
}


// Return: 0x24 - Reached end of directory
//         0    - all ok
byte FLOS_DirListNextEntry(void)
{
    byte result;

    CALL_FLOS_CODE(KJT_DIR_LIST_NEXT_ENTRY);

    result = *PTRTO_I_DATA(I_DATA, byte);

    return result; 
}

// Return: pointer to name of current dir (NULL if was error)
// Note: copy returned string before carrying out any other disk operations
// as the pointer will be in the sector buffer which obviously changes
const char* FLOS_GetDirName(void)
{
    byte result;
    word w;

    CALL_FLOS_CODE(KJT_GET_DIR_NAME);

    result = *PTRTO_I_DATA(I_DATA,   byte);
    w      = *PTRTO_I_DATA(I_DATA+1, word);

    return (result ? (const char*)w : NULL);
}

// Misc --------------------------------------

// Get OS version word and Hardware version word
void FLOS_GetVersion(word* os_version_word, word* hw_version_word)
{

    CALL_FLOS_CODE(KJT_GET_VERSION);

    *os_version_word = *PTRTO_I_DATA(I_DATA+0, word);
    *hw_version_word = *PTRTO_I_DATA(I_DATA+2, word);

}



// helpers --------------------------------------
void FLOS_PrintStringLFCR(const char* string)
{
    FLOS_PrintString(string);
    FLOS_PrintString(PS_LFCR);
}


// Get ptr to FLOS cmd line 
// The line is zero terminated.
char* FLOS_GetCmdLine(void)
{
    return flos_cmdline;
}


// Set spawn command line (which executed by FLOS at program exit)
BOOL FLOS_SetSpawnCmdLine(const char* line)
{
    if(strlen(line) >= SPAWN_CMD_LINE_BUFFER_LEN)
        return FALSE;

    flos_spawn_cmd[0] = 0;              // reset string len (in buffer) len to 0
    strcat(flos_spawn_cmd, line);
    return TRUE;
}