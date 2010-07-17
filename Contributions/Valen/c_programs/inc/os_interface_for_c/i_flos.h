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




void MarkFrameTime(ushort color);


// ---------------------------------------------
typedef struct  { 
   word z80_address; 
   byte z80_bank;
//   word first_block;
   dword size;
} FLOS_FILE;

typedef struct  { 
    const char* pFilename;      //      Location of null terminated filename string
    dword       len;            //      Length of file (if applicable)
    byte        file_flag;      //      File flag (1 = directory, 0 = file)
    byte        err_code;       //      Error code 0 = all OK. 0x24 = Reached end of directory.
} FLOS_DIR_ENTRY;


byte FLOS_GetLastError(void); 


BOOL FLOS_MakeDir(const char* pDirName);
BOOL FLOS_ChangeDir(const char* pDirName);
BOOL FLOS_ParentDir(void);
void FLOS_RootDir(void);
BOOL FLOS_DeleteDir(const char* pDirName);
void FLOS_StoreDirPosition(void);
void FLOS_RestoreDirPosition(void);

dword FLOS_GetTotalSectors(void);
BOOL FLOS_FindFile(FLOS_FILE* const pFile, const char* pFileName);
void FLOS_SetLoadLength(const dword len);
void FLOS_SetFilePointer(const dword p);
BOOL FLOS_ForceLoad(const byte* address, const byte bank);
BOOL FLOS_CreateFile(const byte* pFilename);
BOOL FLOS_EraseFile(const byte* pFilename);
BOOL FLOS_WriteBytesToFile(const byte* pFilename, byte* address, const byte bank, const dword len);

// ---------------

void FLOS_PrintString(const char* string);
void FLOS_ClearScreen(void);
void FLOS_FlosDisplay(void);
void FLOS_WaitVRT(void);
void FLOS_SetPen(byte color);
BOOL FLOS_SetCursorPos(byte x, byte y);

// ---------------
void FLOS_WaitKeyPress(byte* pASCII, byte* pScancode);
BOOL FLOS_GetKeyPress(byte* pASCII, byte* pScancode);

// ---------------
void FLOS_DirListFirstEntry(void);
BOOL FLOS_DirListGetEntry(FLOS_DIR_ENTRY* pEntry);
byte FLOS_DirListNextEntry(void);
const char* FLOS_GetDirName(void);

// Misc --------------------------------------
void FLOS_GetVersion(word* os_version_word, word* hw_version_word);

// helpers --------------------------------------
void FLOS_PrintStringLFCR(const char* string);

char* FLOS_GetCmdLine(void);
BOOL FLOS_SetSpawnCmdLine(const char* line);