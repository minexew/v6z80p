#ifndef DISK_IO_H
#define DISK_IO_H

#define BEGIN_DISK_OPERATION()      DiskIO_BeginDiskOperation()
#define END_DISK_OPERATION(r)       DiskIO_EndDiskOperation(r)

BOOL load_file_to_buffer(const char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
BOOL diag__FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename);
BOOL diag__FLOS_ForceLoad(const byte* address, const byte bank);
void DiskIO_BeginDiskOperation(void);
void DiskIO_EndDiskOperation(BOOL isOperationOk);
void DiskIO_VisualizeDiskError(void);

#endif /* DISK_IO_H */
