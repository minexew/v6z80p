/*
  Execute command string at program exit.
  When program exited to FLOS, the string is executed as command string.

  Also would be nice to have FLOS call,
  to get the name of current dir.
  (e.g.
  get_dir_name
  )


*/


void RequestToExitAndExecuteCommandString(const char* cmd);



extern char  flos_spawn_cmd[40];
void RequestToExitAndExecuteCommandString(const char* cmd)
{
        FLOS_ClearScreen();

        FLOS_SetSpawnCmdLine(cmd);
        FLOS_PrintStringLFCR(flos_spawn_cmd);

        request_exit = TRUE;
        request_spawn_command = TRUE;
}