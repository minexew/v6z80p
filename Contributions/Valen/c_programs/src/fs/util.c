//

void DiagMessage(char* pMsg, char* pFilename);
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


BOOL load_file_to_buffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
BOOL load_file_to_buffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
{
    FLOS_FILE myFile;
    BOOL r;

    r = FLOS_FindFile(&myFile, pFilename);
    if(!r) {
       DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }

    FLOS_SetLoadLength(len);
    FLOS_SetFilePointer(file_offset);

    r = FLOS_ForceLoad( buf, bank );
    if(!r) {
       DiagMessage("ForceLoad failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}
