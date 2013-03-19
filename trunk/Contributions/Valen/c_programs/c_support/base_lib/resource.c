#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <base_lib/resource.h>



#define INDEX_AREA_MAX_FILES    20
// --------------------------------------
// Resource functions can load files from filesystem or from a single file (with index header).
//



struct tag_disk_io {
    BOOL        useFilesystem;
    const char *pDataFilename;
    DWORD       entry_total_files_size;  //

    struct tag_datafile_entry  datafileBuffer[INDEX_AREA_MAX_FILES];  // buffer for data file index (maximum for some files)
} resource;


BOOL Resource_Init(BOOL useFilesystem, const char *pDataFilename)
{
   memset(&resource, 0, sizeof(resource));

   resource.useFilesystem = useFilesystem;  // TRUE - use filesystem, FALSE - use data file
   resource.pDataFilename = pDataFilename;


   if(!resource.useFilesystem) {
       // load index of data file to buffer
       resource.useFilesystem = TRUE;
       if(!Resource_LoadFileToBuffer(pDataFilename, 0, (BYTE*) resource.datafileBuffer,
                                     sizeof(resource.datafileBuffer), 0))
            return FALSE;
       resource.useFilesystem = FALSE;
   }

   return TRUE;
}

BOOL Resource_LoadFileToBuffer(const char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
{
    FLOS_FILE myFile;
    BOOL r;
//    WORD d;
//    BYTE bufff[32];
    struct tag_datafile_entry* entry = NULL;
    WORD  index_size;
    DWORD file_offset_in_bulk_file;

#ifdef DEBUG_LIB_BASELIB
    DEBUGPRINT("LoadFile: %s is_fs: i\n", pFilename, resource.useFilesystem);
    DEBUGPRINT("ofs: %lu, buf: %x, len: %lu \n", file_offset, buf, len);
#endif


    if(resource.useFilesystem) {
        // load file contents from regular file
        r = FLOS_FindFile(&myFile, pFilename);
        if(!r) {  return FALSE; }

        FLOS_SetLoadLength(len);
        FLOS_SetFilePointer(file_offset);

        r = FLOS_ForceLoad( buf, bank );
        if(!r) { return FALSE; }
        return TRUE;
    } else {
        // load file contents from single bulk file


        entry = Resource_FindEntryByFilename(pFilename);    // find an entry for the requested filename
        if(!entry)
            return FALSE;

        index_size = resource.datafileBuffer[0].length_of_file[0] +
                     resource.datafileBuffer[0].length_of_file[1] * 0x100;
        file_offset_in_bulk_file = (DWORD)index_size +  resource.entry_total_files_size + file_offset;

//        _itoa(, bufff, 10); //ShowDiskErrorAndStopProgramExecution("---: ", bufff);
#ifdef DEBUG_LIB_BASELIB        
        DEBUGPRINT("bulk_offs: %lu \n", file_offset_in_bulk_file);
#endif
        r = FLOS_FindFile(&myFile, resource.pDataFilename);
        if(!r) {  return FALSE; }

        FLOS_SetLoadLength(len);
        FLOS_SetFilePointer(file_offset_in_bulk_file);


        r = FLOS_ForceLoad( buf, bank );
        if(!r) { return FALSE; }
        return TRUE;



    }

}


DWORD Resource_GetFileSize(const char* pFilename)
{
    FLOS_FILE file;
    struct tag_datafile_entry* entry;

    if(resource.useFilesystem) {
        if(!FLOS_FindFile(&file, pFilename))
            return -1;
        else
            return file.size;
    } else {
        entry = Resource_FindEntryByFilename(pFilename);    // find an entry for the requested filename
        if(!entry)
            return -1;  // entry was not found
        return Resource_GetEntryFileSize(entry);
    }

}



DatafileEntry* Resource_FindEntryByFilename(const char* pFilename)
{
    struct tag_datafile_entry* entry;
    BYTE i;
    resource.entry_total_files_size = 0;

    for(i=1; i<INDEX_AREA_MAX_FILES; i++) { // start with entry 1 (skip entry 0)
        entry = &resource.datafileBuffer[i];

        if(strcmp(entry->file_name, pFilename) == 0)
            return entry;
        resource.entry_total_files_size += Resource_GetEntryFileSize(entry);    // accumulate size (of all prev files)
//        DEBUGPRINT("entry f.s.: %lu %s\n", Resource_GetEntryFileSize(entry), entry->file_name);
    }

    return NULL;
}


DWORD Resource_GetEntryFileSize(DatafileEntry* entry)
{
//    DEBUGPRINT("entry file size: %x %x %x \n", entry->length_of_file[0], entry->length_of_file[1], entry->length_of_file[2]);
    return (DWORD) entry->length_of_file[0] +
           (DWORD) entry->length_of_file[1] * 0x100UL +
           (DWORD) entry->length_of_file[2] * 0x10000UL;
}

BYTE* Resource_GetLastError(void)
{
    return "GENERAL ERROR!";
}
