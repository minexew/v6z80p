#include <kernal_jump_table.h>
#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

//#include <os_interface_for_c/i_flos.h>

//#include <stdio.h>
#include <string.h>

#include <base_lib/resource.h>
#include "disk_io.h"
#include "handle_resource_error.h"

BOOL Handle_Resource_Error(void)
{
    static BYTE str[100];
    strcpy(str, "Datafile Err: ");
    strcat(str, Resource_GetLastError());

    ShowDiskErrorAndStopProgramExecution(str, NULL);

    return FALSE;
}
