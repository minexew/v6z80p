

BOOL load_file_to_buffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
{
    FLOS_FILE myFile;
    BOOL r;

    r = diag__FLOS_FindFile(&myFile, pFilename);
    if(!r) {
       //DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }

    FLOS_SetLoadLength(len);
    FLOS_SetFilePointer(file_offset);

    r = diag__FLOS_ForceLoad( buf, bank );
    if(!r) {
       //DiagMessage("ForceLoad failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}


// wrappers for FLOS funcs, with added diagnostic output
BOOL diag__FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename)
{
    BOOL r;

    BEGIN_DISK_OPERATION();
    r = FLOS_FindFile(pFile, pFilename);
    END_DISK_OPERATION(r);
    if(!r) {
       DiagMessage("FindFile failed: ", pFilename);
       return FALSE;
    }

    return TRUE;
}

BOOL diag__FLOS_ForceLoad(const byte* address, const byte bank)
{
    BOOL r;

    BEGIN_DISK_OPERATION();
    r = FLOS_ForceLoad(address, bank);
    END_DISK_OPERATION(r);
    if(!r) {
       DiagMessage("ForceLoad failed: ", "");
       return FALSE;
    }

    return TRUE;
}

// ------------ chunk loader --------------------
// loads file from disk by 4KB chunks
typedef struct {
    char* pFilename;
    FLOS_FILE file;

    byte* buf;           // 4KB buffer, where to load chunks
    byte bank;           // bank, to pass to FLOS ForceLoad()
    dword file_offset;   // current file offset (how many bytes was already readed)

} chunk_loader;

chunk_loader cl;        // global instance


void ChunkLoader_Init(char* pFilename, /*FLOS_FILE* file,*/ byte* buf, byte bank)
{
    cl.pFilename = pFilename;

    cl.buf       = buf;
    cl.bank      = bank;

    cl.file.size   = -1;        // set -1 as "first chunk load" marker
    cl.file_offset = 0;

}

// load next chunk from disk to memory
BOOL ChunkLoader_LoadChunk(void)
{
    dword num_bytes = 0;

    // if loading first chunk, do findfile
    if(cl.file.size == -1) {
        if(!diag__FLOS_FindFile(&cl.file, cl.pFilename))
            return FALSE;
    }


    (cl.file_offset+0x1000 <  cl.file.size) ?  (num_bytes = 0x1000) :  (num_bytes = cl.file.size - cl.file_offset);

    FLOS_SetLoadLength(num_bytes);
    if(!diag__FLOS_ForceLoad(cl.buf, cl.bank))
        return FALSE;

    cl.file_offset  += num_bytes;

    return TRUE;

}

BOOL ChunkLoader_IsDone(void)
{
    return (cl.file_offset >= cl.file.size);
}



void DiskIO_BeginDiskOperation(void)
{
    // disable interrupts, while disk operation is active
    // (disk operation may write to any memory bank)
    DI();
}

void DiskIO_EndDiskOperation(BOOL isOperationOk)
{


    if(!isOperationOk) {
        DiskIO_VisualizeDiskError();
    }

    EI();
}

void DiskIO_VisualizeDiskError(void)
{
    ushort* p = (ushort*) PALETTE;
    ushort color;
    byte i, t;
    word k;

    color = 0xf00;
    // flash some times, to indicate disk error
    for(t=0; t<6; t++) {
        *p = color;
        for(i=0; i<25;i++) {        // delay
            FLOS_WaitVRT();
            for(k=0; k<10000; k++);
        }
        color ^= 0xf00;
    }

    //FLOS_FlosDisplay();
}
