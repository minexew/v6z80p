#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <os_interface_for_c/i_flos.h>

//#include <string.h>
//#include <stdlib.h>

#include "base_lib/utils.h"
#include "base_lib/disk_service.h"

FLOS_PROGRAM_PARAMS* prog_params;
FLOS_VOLUME_INFO*   volume_info;
WORD                original_cluster;
BYTE                original_volume;

void DiskService_GotoSourceDirAndVolume(void)
{
    FLOS_PrintStringLFCR("Executable file volume and cluster: ");
    PrintWORD(prog_params->volume,      16); FLOS_PrintString(" ");
    PrintWORD(prog_params->dir_cluster, 16); FLOS_PrintStringLFCR("");

    if(!FLOS_ChangeVolume(prog_params->volume)) {
        FLOS_PrintStringLFCR("FLOS_ChangeVolume FAILED!");
        FLOS_ExitToFLOS();
    }
    FLOS_SetDirCluster(prog_params->dir_cluster);
}

void DiskService_StoreCurrentDirAndVolume(void)
{
    prog_params = FLOS_GetProgramParams();
    volume_info = FLOS_GetVolumeInfo();

    original_cluster = FLOS_GetDirCluster();
    original_volume  = volume_info->current_volume;
}

void DiskService_RestoreCurrentDirAndVolume(void)
{
    FLOS_PrintStringLFCR("Original volume and cluster: ");
    //PrintWORD((WORD)volume_info->mount_list,        16); FLOS_PrintStringLFCR("");
    //PrintWORD(volume_info->number_volumes_mounted,  16); FLOS_PrintStringLFCR("");
    PrintWORD(original_volume,              16); FLOS_PrintString(" ");
    PrintWORD(original_cluster,             16); FLOS_PrintStringLFCR("");

    if(!FLOS_ChangeVolume(original_volume)) {
        FLOS_PrintStringLFCR("FLOS_ChangeVolume FAILED!");
        FLOS_ExitToFLOS();
    }
    FLOS_SetDirCluster(original_cluster);
}



