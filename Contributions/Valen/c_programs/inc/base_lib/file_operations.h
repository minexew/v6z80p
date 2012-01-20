#ifndef FILE_OPERATIONS_H
#define FILE_OPERATIONS_H

BOOL  FileOp_LoadFileToBuffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
DWORD FileOp_GetFileSize(char *pFilename);

BOOL FileOp_FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename);
BOOL FileOp_FLOS_ForceLoad(const byte* address, const byte bank);


#endif /* FILE_OPERATIONS_H */
