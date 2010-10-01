/*
  In do_dir() we obtain list of current dir.

  We iterate through current dir entries, using FLOS functions
  FLOS_DirListFirstEntry()
  FLOS_DirListGetEntry()
  FLOS_DirListNextEntry()

*/

// --- Public -----------------------------------------
// init

// 
word do_dir(void);

// --- Internal ---------------------------------------
// init


// others funcs
word split_string_to_many_strings(void);


word do_dir(void)
{
    byte str[40+1];
    FLOS_DIR_ENTRY e;
    byte num_spaces, k;

    // iterate through current dir entries  (FLOS v537+)
    FLOS_DirListFirstEntry();
    while(1) {
        str[0] = 0;
        FLOS_DirListGetEntry(&e);
        if(e.err_code == END_OF_DIR) break;

        if( e.pFilename[0]=='.' && e.pFilename[1]==0 && e.file_flag == 1) {
            FLOS_DirListNextEntry();
            continue;
        }


        strcat(str, e.pFilename);
        // add align spaces (if req.)
        num_spaces = FILENAME_LEN - strlen(e.pFilename);
        for(k=0; k<num_spaces; k++) strcat(str, " ");


        if(e.file_flag == 1)
            strcat(str, "  [DIR]");
        else {
            strcat(str, "  $");
            // output lenght
            _ultoa(e.len, buffer, 16);
            strcat(str, buffer);
        }
        strcat(str, PS_LFCR);


        // check, if there a free space in dir buffer
        if( (strlen(tmp1) + 32) < DIRBUF_LEN )
            strcat(tmp1, str);
        else
            break;

        if(FLOS_DirListNextEntry() == END_OF_DIR) break;

    }

    return split_string_to_many_strings();
    
}






// Replace all LFCR codes to 0
word split_string_to_many_strings(void) {
    word i, len, num = 0;

    len = strlen(tmp1);
    for(i=0; i<len; i++) {
        if(tmp1[i] == 0x0b) {
            tmp1[i] = 0;                 // replace LFCR code to 0
            num++;
        }
    }

    return num;
}



void PrintMessage(const char* str)
{
    FLOS_PrintString(str);
    FLOS_PrintString(PS_LFCR);

}

