BOOL FileOp_LoadFileToBuffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
BOOL FileOp_FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename);
BOOL FileOp_FLOS_ForceLoad(const byte* address, const byte bank);
void DiagMessage(const char* pMsg, const char* pFilename);

