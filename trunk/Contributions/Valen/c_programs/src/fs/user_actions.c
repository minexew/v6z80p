BOOL enter_pressed(void);
BOOL f4_pressed(void);
BOOL do_action_based_on_file_extension(const char* filename);

BOOL request_to_exit_and_execute_command_with_filename(const char* command, const char* filename);
BOOL extract_filename_from_buffer(const char* pFrom, char* pTo);
const char* GetFilenameOfSelectedItem(ListView* pLview);
BOOL IsSelectedItem_DIR(ListView* pLview);

/*struct {
    short prevSelectedIndex;
} user_actions;*/

BOOL enter_pressed(void)
{
    char *p;
    BOOL r;
    const char *filename = NULL;
//    char filename[FILENAME_LEN +1] = "";     // string  (filename with zero at end )

    char dirname[FILENAME_LEN +1] = "";

    p = ListView_GetSelectedItem(&lview);
/*
    if(!extract_filename_from_buffer(p, filename))
        return FALSE;
*/

    filename = GetFilenameOfSelectedItem(&lview);
    if(!filename) return FALSE;




    if(strstr(p, "[DIR]") != NULL) {
//        FLOS_SetCursorPos(25, 0);
//        FLOS_PrintString("++++++++++++++++++++"); 
//        FLOS_SetCursorPos(25, 0);
//        FLOS_PrintString(filename); 

        // check for ..   and   .  (go to parent dir)
        if(filename[0] == '.') {
            //pDirName = FLOS_GetDirName();
            //strcat(dirname, pDirName);

            r = FLOS_ParentDir();
            fill_ListView_by_entries_from_current_dir();

            //ListView_SetSelectedIndex(&lview, user_actions.prevSelectedIndex); // restore index of current selected list item
            //ListView_Update(&lview);

            return r;
        }

        // this is regular dir name, so call FLOS change dir
        //user_actions.prevSelectedIndex = ListView_GetSelectedIndex(&lview);     // save index of current selected list item
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
//word *pW = (word*) 0xF000;
    char *pFromEnd;
    word pFromLen;

        pFromEnd = strstr(pFrom, " ");
        if(pFromEnd == NULL)
            return FALSE;

        pFromLen = pFromEnd - pFrom;
        if(pFromLen > FILENAME_LEN)
            return FALSE;

//*pW++ = (word) pTo; *pW++ = (word) pFrom; *pW++ = (word) pFromLen;
        memset(pTo, 0, FILENAME_LEN +1);
        memmove(pTo, pFrom, pFromLen);         // here, memcpy dont work in SDCC 2.9.7 (compiler put args on stack in WRONG order)
//        memcpy ((void*)0x1, (void*)0x2, pFromLen);
//while(1);
        return TRUE;
}


//  In:   filename - ptr to str (e.g. "FILENAME.EXT")
BOOL do_action_based_on_file_extension(const char* filename)
{
    const char* pExt;
    const char* pAction;
    BOOL isExecuteCommand = FALSE;
    const char *command = "";

    const char* p = filename;           // just alias

    char full_command_str[80] = "";     // big enough string (hm..)

    pExt = strstr(p, ".") + 1;
    if(strstr(p, ".EXE") != NULL) {
        isExecuteCommand = TRUE;
        command = "";
    } else {
        if(pExt == NULL || strlen(pExt) == 0) return TRUE;
        pAction = get_user_action_based_on_ext(pExt);
        if(pAction == NULL) return TRUE;

        isExecuteCommand = TRUE;
        command = pAction;
    }

/*
    if(strstr(p, ".TXT") != NULL) {
        isExecuteCommand = TRUE;
        command = "TEXTEDIT ";
    }
*/


    // append spacebar to end of command
    strcat(full_command_str, command);
    strcat(full_command_str, " ");

    if(isExecuteCommand) {
        if(!request_to_exit_and_execute_command_with_filename(full_command_str, p))
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
    const char *p = GetFilenameOfSelectedItem(&lview);
    if(!p) return FALSE;


    // return, if selected entry is DIR
    if(IsSelectedItem_DIR(&lview))
        return TRUE;

    if(!request_to_exit_and_execute_command_with_filename("TEXTEDIT ", p))
        return FALSE;


    return TRUE;
}


BOOL IsSelectedItem_DIR(ListView* pLview)
{
    char *p = ListView_GetSelectedItem(pLview);
    // return true, if selected entry is DIR
    if(strstr(p, "[DIR]") != NULL)
        return TRUE;
    else
        return FALSE;

}


// This func extract filename only from 
// selected listview item.
// e.g. from "ECHO.EXE   $BB0" will be extracted "ECHO.EXE"
// TODO: Add columns functionality to list view. 
//       Thus, one column can  be used for filename and other for filesize.
const char* GetFilenameOfSelectedItem(ListView* pLview)
{
    // result filename will be placed in this string
    static char filename[FILENAME_LEN +1];                     // string  (filename with zero at end )

    char *p = ListView_GetSelectedItem(pLview);

    /*FLOS_SetCursorPos(1, 1);
    FLOS_PrintString("xx");     FLOS_PrintString(p);     FLOS_PrintString("xx");*/ 

    if(!extract_filename_from_buffer(p, filename))
        return NULL;

    return filename;
}


void print_box(byte x, byte y, byte w, byte h)
{
    byte i, j;
    //const char *p = "----------------------";
    for(i=0; i<h; i++) {
        FLOS_SetCursorPos(x, y+i); 
        if(i == 0)   { for(j=0; j<w; j++) FLOS_PrintString("-"); continue; }
        if(i == h-1) { for(j=0; j<w; j++) FLOS_PrintString("-"); continue; }
        FLOS_PrintString("+"); for(j=0; j<w-2; j++) FLOS_PrintString(" "); FLOS_PrintString("+");
                        
    }

}

BOOL delete_dir_entry(void)
{
    BOOL r = TRUE;
    byte asciicode, scancode;
    byte x, y;
    const char *p = GetFilenameOfSelectedItem(&lview);
    if(!p) return FALSE;

    if(strstr(p, "..") != NULL)
        return TRUE;


    x = 1; y = 1;
    print_box(x, y, 20, 4+2);
    FLOS_SetCursorPos(x+2, y+1);  FLOS_PrintString("Delete "); 
    FLOS_SetCursorPos(x+2, y+2);  FLOS_PrintString(p); 
    FLOS_SetCursorPos(x+2, y+3);
    FLOS_PrintString("Y/N ?"); 

    FLOS_WaitKeyPress(&asciicode, &scancode);
    if(scancode == SC_Y) {
        //FLOS_SetCursorPos(20, 1);  FLOS_PrintString("XXXXX"); 

        if(IsSelectedItem_DIR(&lview))
            r = FLOS_DeleteDir(p);
        else {
            r = FLOS_EraseFile(p);
        }
        fill_ListView_by_entries_from_current_dir();
    } else {
        // clear list view area, erase request box
        clear_area(lview.x, lview.y, lview.width, lview.height);     
    }

    // redraw listbox
    ListView_Update(&lview);

    return r;
}