BOOL FileOp_LoadFileToBuffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
BOOL FileOp_FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename);
BOOL FileOp_FLOS_ForceLoad(const byte* address, const byte bank);
void DiagMessage(char* pMsg, char* pFilename);

BOOL FileOp_LoadFileToBuffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
{
    FLOS_FILE myFile;
    BOOL r;

    r = FileOp_FLOS_FindFile(&myFile, pFilename);
    if(!r) {
       return FALSE;
    }

    FLOS_SetLoadLength(len);
    FLOS_SetFilePointer(file_offset);

    r = FileOp_FLOS_ForceLoad( buf, bank );
    if(!r) {       
       return FALSE;
    }

    return TRUE;
}


// wrappers for FLOS funcs, with added diagnostic output
BOOL FileOp_FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename)
{
    BOOL r;

    
    r = FLOS_FindFile(pFile, pFilename);
    
    if(!r) {
       DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}

BOOL FileOp_FLOS_ForceLoad(const byte* address, const byte bank)
{
    BOOL r;

    
    r = FLOS_ForceLoad(address, bank);
    
    if(!r) {
       DiagMessage("ForceLoad failed: ", "");
       return FALSE;
    }

    return TRUE;
}





void DiagMessage(char* pMsg, char* pFilename)
{
    char buffer[32];
    byte err;
    err = FLOS_GetLastError();

    FLOS_PrintString(pMsg);
    FLOS_PrintString(pFilename);

    FLOS_PrintString(" OS_err: $");
    _uitoa(err, buffer, 16);
    FLOS_PrintString(buffer);
    FLOS_PrintString(PS_LFCR);
    
}
