#ifndef RESOURCE_H
#define RESOURCE_H


BOOL Resource_Init(BOOL useFilesystem, const char *pDataFilename);
BOOL  Resource_LoadFileToBuffer(const char *pFilename, dword file_offset, byte* buf, dword len, byte bank);
DWORD Resource_GetFileSize(const char* pFilename);
BYTE* Resource_GetLastError(void);

// private

// Phil's bulk file format (index area)
typedef struct tag_datafile_entry {
    BYTE       file_name[13];
    BYTE       length_of_file[3];   // l-o-f is 24 bit
} DatafileEntry;

DatafileEntry* Resource_FindEntryByFilename(const char* pFilename);
DWORD Resource_GetEntryFileSize(DatafileEntry *entry);



#endif /* RESOURCE_H */
