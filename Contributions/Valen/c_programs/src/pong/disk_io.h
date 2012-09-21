#ifndef DISK_IO_H
#define DISK_IO_H

#include <os_interface_for_c/i_flos.h>


#define BEGIN_DISK_OPERATION()      DiskIO_BeginDiskOperation()
#define END_DISK_OPERATION(r)       DiskIO_EndDiskOperation(r)


BOOL diag__FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename);
BOOL diag__FLOS_ForceLoad(const byte* address, const byte bank);
void DiskIO_BeginDiskOperation(void);
void DiskIO_EndDiskOperation(BOOL isOperationOk);
void DiskIO_VisualizeDiskError(void);

BOOL ChunkLoader_Init(const char* pFilename, byte* buf, byte bank);
BOOL ChunkLoader_LoadChunk(void);
BOOL ChunkLoader_IsDone(void);

// private
void ShowDiskErrorAndStopProgramExecution(const char* strErr, const char* pFilename);
void ShowErrorAndStopProgramExecution(const char* strErr);

#endif /* DISK_IO_H */
