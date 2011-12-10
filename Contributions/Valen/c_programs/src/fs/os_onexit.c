/*
  Execute command string at program exit.
  When program exited to FLOS, the string is executed as command string.

  Also would be nice to have FLOS call,
  to get the name of current dir.
  (e.g.
  get_dir_name
  )


*/


#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>

#include <os_interface_for_c/i_flos.h>


//#include <string.h>


#include "fs_walk.h"
//#include "display.h"
//#include "list_view.h"
//#include "config.h"
#include "os_onexit.h"


extern BOOL request_exit;
extern BOOL request_spawn_command;
extern char  flos_spawn_cmd[40];

void RequestToExitAndExecuteCommandString(const char* cmd)
{
        FLOS_ClearScreen();

        FLOS_SetSpawnCmdLine(cmd);
        FLOS_PrintStringLFCR(flos_spawn_cmd);

        request_exit = TRUE;
        request_spawn_command = TRUE;
}
