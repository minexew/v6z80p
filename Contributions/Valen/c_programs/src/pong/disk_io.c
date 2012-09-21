#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>

#include <stdio.h>

#include "disk_io.h"
#include "util.h"
#include "keyboard.h"
#include "background.h"     // for Game_RestoreFLOSVIdeoRam();
#include <base_lib/resource.h>
#include "handle_resource_error.h"

struct tag_disk_io{
    const char* pFilename;
} disk_io;




/*#define DI_HALT() \
    BEGINASM();   \
        di        \
        halt      \
    ENDASM();
*/



void ShowErrorAndStopProgramExecution(const char* strErr)
{
    ShowDiskErrorAndStopProgramExecution(strErr, NULL);
}

void ShowDiskErrorAndStopProgramExecution(const char* strErr, const char* pFilename)
{
//    BYTE asciicode, scancode;
    while(1);

    FLOS_FlosDisplay();
    Game_RestoreFLOSVIdeoRam();
    FLOS_ClearScreen();
    FLOS_PrintStringLFCR("FATAL PONG ERROR");

    if(pFilename) DiagMessage(strErr, pFilename);
    else          FLOS_PrintStringLFCR(strErr);
    FLOS_PrintStringLFCR("Exiting to FLOS...");     //               Press a key to reboot... ");

    deinstall_irq_handler();
//    FLOS_WaitKeyPress(&asciicode, &scancode);
//    5FLOS_SetSpawnCmdLine("dir");
//    flos_spawn_cmd[0] = 'D'; flos_spawn_cmd[1] = 'I';flos_spawn_cmd[2] = 'R';flos_spawn_cmd[3] = 0;
//    FLOS_ExitToFLOS_SpawnCmd();

    FLOS_ExitToFLOS();

    //DI_HALT();
//    BEGINASM();
//        jp 0
//    ENDASM();
}

// wrappers for FLOS funcs, with added diagnostic output
BOOL diag__FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename)
{
    BOOL r;

    BEGIN_DISK_OPERATION();
    disk_io.pFilename = pFilename;
    r = FLOS_FindFile(pFile, pFilename);
    if(!r)
        ShowDiskErrorAndStopProgramExecution("FindFile FAILED: ", pFilename);
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

    // quick fix for FLOS598+  Check for error code 1B and ignore it
    if(!r && FLOS_GetLastError() == 0x1B) {
        r = TRUE;
    }

    if(!r)
        ShowDiskErrorAndStopProgramExecution("ForceLoad FAILED: ", disk_io.pFilename);
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
    const char* pFilename;
    //FLOS_FILE file;


    byte* buf;           // 4KB buffer, where to load chunks
    byte bank;           // bank, to pass to FLOS ForceLoad()
    dword file_offset;   // current file offset (how many bytes was already readed)
    dword file_size;     // file size

} chunk_loader;

chunk_loader cl;        // global instance


BOOL ChunkLoader_Init(const char* pFilename, byte* buf, byte bank)
{
    cl.pFilename = pFilename;

    cl.buf       = buf;
    cl.bank      = bank;

    cl.file_offset = 0;
    cl.file_size   = Resource_GetFileSize(pFilename);
    if(cl.file_size == -1) {

        return FALSE;
    }
//    printf("FSize: %li", cl.file_size);

    return TRUE;
}

// load next chunk from disk to memory
BOOL ChunkLoader_LoadChunk(void)
{
    dword num_bytes = 0;


    (cl.file_offset+0x1000 <  cl.file_size) ?  (num_bytes = 0x1000) :  (num_bytes = cl.file_size - cl.file_offset);

//    FLOS_SetLoadLength(num_bytes);
//    if(!diag__FLOS_ForceLoad(cl.buf, cl.bank))
//        return FALSE;

    if(!Resource_LoadFileToBuffer(cl.pFilename, cl.file_offset, cl.buf, num_bytes, cl.bank))
        return Handle_Resource_Error();


    cl.file_offset  += num_bytes;

    return TRUE;

}

BOOL ChunkLoader_IsDone(void)
{
    return (cl.file_offset >= cl.file_size);
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


}


