#ifndef I_FLOS_H
#define I_FLOS_H


#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>

#include <stddef.h>


// FLOS exit codes
#define NO_REBOOT       0
#define REBOOT          0xff
#define SPAWN_COMMAND   0xfe

// PrintString control codes
#define PS_LF   "\x0a"    // line feed
#define PS_CR   "\x0d"    // carriage return
#define PS_LFCR "\x0b"    // LF+CR

// dir list err code
#define END_OF_DIR      0x24


#define I_DATA          0x5080
#define I_CODE_BASE     0x5080 + 0x20

#define GET_I_ADDRESS(kjt)              (kjt - 0x1000 + I_CODE_BASE)
#define PTRTO_I_DATA(data, ptrtype)     ((ptrtype*) (data))
#define CALL_FLOS_CODE(kjt)             pFunc = (ptrVoidFunc) GET_I_ADDRESS(kjt);     \
                                        (*pFunc)();

#define SET_DWORD_IN_DATA_AREA(dataAddr, dwordValue)     pDword = (dword*) (dataAddr);     \
                                                         *pDword = dwordValue;
#define SET_WORD_IN_DATA_AREA(dataAddr, wordValue)       pWord = (word*) (dataAddr);     \
                                                         *pWord = wordValue;
#define SET_BYTE_IN_DATA_AREA(dataAddr, byteValue)       pByte = (byte*) (dataAddr);     \
                                                         *pByte = byteValue;



#define SPAWN_CMD_LINE_BUFFER_LEN 40            // in bytes

#ifndef V6Z80P_EXTERN 
#define V6Z80P_EXTERN  extern
#endif




void MarkFrameTime(ushort color);


// ---------------------------------------------
typedef struct  { 
   word z80_address; 
   byte z80_bank;
//   word first_block;
   dword size;
   word firstCluster;
} FLOS_FILE;

typedef struct  { 
    const char* pFilename;      //      Location of null terminated filename string
    dword       len;            //      Length of file (if applicable)
    byte        file_flag;      //      File flag (1 = directory, 0 = file)
    byte        err_code;       //      Error code 0 = all OK. 0x24 = Reached end of directory.
} FLOS_DIR_ENTRY;

typedef struct  { 
    byte  sectorOffset;
    dword *ptrToSectorNumber;
    word  clusterNumber;
} FLOS_FILE_SECTOR_LIST;


typedef struct {
    byte buttons;
    word PosX, PosY; 
} MouseStatus;


// ----------------------------------------------------------------------
V6Z80P_EXTERN byte FLOS_GetLastError(void); 

V6Z80P_EXTERN BOOL FLOS_MakeDir(const char* pDirName);
V6Z80P_EXTERN BOOL FLOS_ChangeDir(const char* pDirName);
V6Z80P_EXTERN BOOL FLOS_ParentDir(void);
V6Z80P_EXTERN void FLOS_RootDir(void);
V6Z80P_EXTERN BOOL FLOS_DeleteDir(const char* pDirName);
V6Z80P_EXTERN void FLOS_StoreDirPosition(void);
V6Z80P_EXTERN void FLOS_RestoreDirPosition(void);

V6Z80P_EXTERN dword FLOS_GetTotalSectors(void);
V6Z80P_EXTERN BOOL FLOS_FindFile(FLOS_FILE* const pFile, const char* pFileName);
V6Z80P_EXTERN void FLOS_SetLoadLength(const dword len);
V6Z80P_EXTERN void FLOS_SetFilePointer(const dword p);
V6Z80P_EXTERN BOOL FLOS_ForceLoad(const byte* address, const byte bank);
V6Z80P_EXTERN BOOL FLOS_CreateFile(const byte* pFilename);
V6Z80P_EXTERN BOOL FLOS_EraseFile(const byte* pFilename);
V6Z80P_EXTERN BOOL FLOS_WriteBytesToFile(const byte* pFilename, byte* address, const byte bank, const dword len);

V6Z80P_EXTERN void FLOS_FileSectorList(FLOS_FILE_SECTOR_LIST* const pF, byte sectorOffset, word clusterNumber);
// ---------------

V6Z80P_EXTERN void FLOS_PrintString(const char* string);
V6Z80P_EXTERN void FLOS_ClearScreen(void);
V6Z80P_EXTERN void FLOS_FlosDisplay(void);
V6Z80P_EXTERN void FLOS_WaitVRT(void);
V6Z80P_EXTERN void FLOS_SetPen(byte color);
V6Z80P_EXTERN BOOL FLOS_SetCursorPos(byte x, byte y);

// ---------------
V6Z80P_EXTERN void FLOS_WaitKeyPress(byte* pASCII, byte* pScancode);
V6Z80P_EXTERN BOOL FLOS_GetKeyPress(byte* pASCII, byte* pScancode);

// ---------------
V6Z80P_EXTERN void FLOS_DirListFirstEntry(void);
V6Z80P_EXTERN BOOL FLOS_DirListGetEntry(FLOS_DIR_ENTRY* pEntry);
V6Z80P_EXTERN byte FLOS_DirListNextEntry(void);
V6Z80P_EXTERN const char* FLOS_GetDirName(void);

// Misc --------------------------------------
V6Z80P_EXTERN void FLOS_GetVersion(word* os_version_word, word* hw_version_word);

// Mouse --------------------------------------
V6Z80P_EXTERN BOOL FLOS_GetMousePosition(MouseStatus* ms);

// helpers --------------------------------------
V6Z80P_EXTERN void FLOS_PrintStringLFCR(const char* string);

V6Z80P_EXTERN char* FLOS_GetCmdLine(void);
V6Z80P_EXTERN BOOL FLOS_SetSpawnCmdLine(const char* line);

#endif /* I_FLOS_H */