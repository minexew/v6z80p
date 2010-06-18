

BOOL enter_pressed(void);
BOOL f4_pressed(void);
BOOL do_action_based_on_file_extension(const char* filename);

BOOL request_to_exit_and_execute_command_with_filename(const char* command, const char* filename);
BOOL extract_filename_from_buffer(const char* pFrom, char* pTo);


BOOL enter_pressed(void)
{
    char *p;
    BOOL r;

    char filename[FILENAME_LEN +1];     // string  (filename with zero at end )

    p = ListView_GetSelectedItem(&lview);


    if(!extract_filename_from_buffer(p, filename))
        return FALSE;

    if(strstr(p, "[DIR]") != NULL) {
//        FLOS_SetCursorPos(25, 0);
//        FLOS_PrintString("++++++++++++++++++++"); 
//        FLOS_SetCursorPos(25, 0);
//        FLOS_PrintString(filename); 

        // check for ..   and   .  (go to parent dir)
        if(filename[0] == '.') {
            r = FLOS_ParentDir();
            fill_ListView_by_entries_from_current_dir();
            return r;
        }

        // this is regular dir name, so call FLOS change dir
        r = FLOS_ChangeDir(filename);
        fill_ListView_by_entries_from_current_dir();
        return r;
        
    }

    if(!do_action_based_on_file_extension(filename))
        return FALSE;

    return TRUE;
}

BOOL extract_filename_from_buffer(const char* pFrom, char* pTo)
{
    char *pFromEnd;
    byte pFromLen;

        pFromEnd = strstr(pFrom, " ");
        if(pFromEnd == NULL)
            return FALSE;

        pFromLen = pFromEnd - pFrom;
        if(pFromLen > FILENAME_LEN)
            return FALSE;

        memset(pTo, 0, FILENAME_LEN +1);
        memcpy(pTo, pFrom, pFromLen);

        return TRUE;
}


//  In:   filename - ptr to str (e.g. "FILENAME.EXT")
BOOL do_action_based_on_file_extension(const char* filename)
{
    BOOL isExecuteCommand = FALSE;
    char *command = "";

    const char* p = filename;           // just alias

//    byte maxlen = 

    if(strstr(p, ".EXE") != NULL) {
        isExecuteCommand = TRUE;
        command = "";
    }
    if(strstr(p, ".TXT") != NULL) {
        isExecuteCommand = TRUE;
        command = "TEXTEDIT ";
    }
    if(strstr(p, ".FNT") != NULL) {
        isExecuteCommand = TRUE;
        command = "CHFNT ";
    }
    if(strstr(p, ".WAV") != NULL) {
        isExecuteCommand = TRUE;
        command = "PLAYWAV ";
    }
    if(strstr(p, ".BMP") != NULL) {
        isExecuteCommand = TRUE;
        command = "SHOWBMP ";
    }
    if(strstr(p, ".MOD") != NULL) {
        isExecuteCommand = TRUE;
        command = "MODPLAY ";
    }
    if(strstr(p, ".PT3") != NULL) {
        isExecuteCommand = TRUE;
        command = "PT3PLAY ";
    }



    if(isExecuteCommand) {
        if(!request_to_exit_and_execute_command_with_filename(command, p))
            return FALSE;
    }

    return TRUE;
}


// In: command  - ptr to str (e.g. "MODPLAY")
//     filename - ptr to str (e.g. "FILENAME.EXT")
BOOL request_to_exit_and_execute_command_with_filename(const char* command, const char* filename)
{
    char cmd[32] = "";

    if(strlen(filename) > FILENAME_LEN)
        return FALSE;


    strcat(cmd, command);
    strcat(cmd, filename);
    RequestToExitAndExecuteCommandString(cmd);

    return TRUE;
}


BOOL f4_pressed(void)
{
    char filename[FILENAME_LEN +1];                     // string  (filename with zero at end )
    char *p = ListView_GetSelectedItem(&lview);


    if(!extract_filename_from_buffer(p, filename))
        return FALSE;

    // return, if selected entry is DIR
    if(strstr(p, "[DIR]") != NULL)
        return TRUE;

    if(!request_to_exit_and_execute_command_with_filename("TEXTEDIT ", filename))
        return FALSE;


    return TRUE;
}


