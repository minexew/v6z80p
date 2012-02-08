/*
FS
---------
File system walk
Valen 2010, 2011, 2012

changelog


0.012
- added config file FS.CFG
- added ability to delete file and empty folder
0.013
- now works fine with FLOS v560+
- after startup, current dir (from where fs_walk was started) is browsed 
0.014
- adapted to SDCC 2.9.7 (and fixed some compiler warnings)
- name of project changed to "fs" (was "fs_walk")
0.015
- adapted to SDCC 3.0.6 (minor issue)
- use FLOS_SetCommander()
0.016
- adapted to FLOS597
0.017
- adapted to FLOS598
0.018
- startup time now is about 2 sec (was 4.5 sec)
  Font generation function is optimizied.
-------------
*/

#include <kernal_jump_table.h>
#include <v6z80p_types.h>
#include <OSCA_hardware_equates.h>
#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>
#include <set_stack.h>
#include <os_interface_for_c/i_flos.h>

#include "base_lib/disk_service.h"

#include <fs_walk/fs_walk.h>

#include <stdlib.h>
#include <string.h>


#include "display.h"
#include "config.h"
#include "list_view.h"
#include "user_actions.h"
#include "os_cmd.h"

#define EXTERN_FS_WALK
#include "fs_walk.h"


#include <base_lib/assert_v6.h>
#include <base_lib/utils.h>




#define OS_VERSION_REQ  0x597           // OS version req. to run this program
#define FLOS_START_ADDR 0x1000



void main_loop(void);

void PrintMessage(const char* str);
BOOL check_OS_version(void);
void clear_keyboard_buffer(void);
void DisplayHelpString(void);
void DisplayString(BYTE x, BYTE y, BYTE pen, const char* str);

BOOL request_exit = FALSE;              // exit program request flag
BOOL request_spawn_command = FALSE;     // spawn command request flag

FLOS_FILE myFile;
byte buffer[32+1];      // buffer for numbers to string conversion

byte buf[8];

ListView lview;


// ---- buffer for list of dir entries ----
byte bufCatalog[DIRBUF_LEN];        // main buffer




word numStrings;        // 




int main (void)
{

    tmp1 = bufCatalog;

    if(!check_OS_version()) {
        FLOS_PrintString("FLOS v");
        _uitoa(OS_VERSION_REQ, buffer, 16);
        FLOS_PrintString(buffer);
        FLOS_PrintStringLFCR("+ req. to run this program");
        return NO_REBOOT;
    }

    DiskService_StoreCurrentDirAndVolume();

//
    DiskService_GotoSourceDirAndVolume();

    FLOS_StoreDirPosition();
    if(!load_config_file()) {
        FLOS_PrintStringLFCR("Failed to load config file.");
        return NO_REBOOT;
    }
    FLOS_RestoreDirPosition();

    DiskService_RestoreCurrentDirAndVolume();
    //return NO_REBOOT;

    MarkFrameTime(0x00f);
    if(!Display_InitVideoMode())
        return NO_REBOOT;
    Display_ClearScreen();
    Display_SetPen(PEN_DEFAULT);
    //DisplayString(/*SCREEN_WIDTH/8/2*/ 0, SCREEN_HEIGHT/8/2, 2, "Generating fonts...");
    clear_keyboard_buffer();
    FLOS_SetCommander("FS.EXE");    // set FS as commander application

    // ---
    lview.width = 24; lview.height = 23;
    lview.x = 1;      lview.y = 1;
//    lview.width = 20; lview.height = 5;
//    lview.x = 1;      lview.y = 1;


    fill_ListView_by_entries_from_current_dir();
    DisplayHelpString();
    main_loop();

/*
    FLOS_PrintString(" Addr: $");
    _uitoa(numStrings, buffer, 16);
    FLOS_PrintStringLFCR(buffer);
*/
    FLOS_ClearScreen();
    FLOS_FlosDisplay();

    if(request_spawn_command)
        return SPAWN_COMMAND;

    FLOS_SetCommander("");
    return NO_REBOOT;
}



void fill_ListView_by_entries_from_current_dir(void)
{
    char* mybuf;

    Display_SetPen(PEN_DEFAULT);
    // clear list view area
    clear_area(lview.x, lview.y, lview.width, lview.height);
    // clear txt area ("xxxx entries")
    clear_area(lview.x, lview.y + lview.height, lview.width, 1);

    // reset string (buffer) len to zero
    tmp1[0] = 0;

    numStrings = do_dir();
    mybuf = tmp1;       

    lview.strArr = mybuf; 
    lview.numItems = numStrings;
    lview.selectedIndex = 0;
    ListView_Init(&lview);
    ListView_Update(&lview);

}

void main_loop(void)
{
    byte asciicode, scancode;
    word numitems, selectedIndex;
    byte step;

    Display_SetPen(PEN_DEFAULT);
    asciicode = scancode = 0;
    while(scancode != SC_ESC && !request_exit) {
        FLOS_WaitKeyPress(&asciicode, &scancode);
        if(scancode == SC_DOWN || scancode == SC_PGDOWN) {
            step = (scancode == SC_DOWN) ? 1 : 5;
            numitems      = ListView_GetNumItems(&lview);
            selectedIndex = ListView_GetSelectedIndex(&lview);

            if(selectedIndex + step < numitems) {
                ListView_SetSelectedIndex(&lview, selectedIndex+step);
            } else
                ListView_SetSelectedIndex(&lview, numitems-1);
            ListView_Update(&lview);
        }

        if(scancode == SC_UP || scancode == SC_PGUP) {
            step = (scancode == SC_UP) ? 1 : 5;
            numitems      = ListView_GetNumItems(&lview);
            selectedIndex = ListView_GetSelectedIndex(&lview);

            if(selectedIndex >= step ) {
                ListView_SetSelectedIndex(&lview, selectedIndex-step);
            } else 
                ListView_SetSelectedIndex(&lview, 0);
            ListView_Update(&lview);
        }


        if(scancode == SC_HOME) {
            ListView_SetSelectedIndex(&lview, 0);
            ListView_Update(&lview);
        }

        if(scancode == SC_END) {
            numitems = ListView_GetNumItems(&lview);
            ListView_SetSelectedIndex(&lview, numitems-1);
            ListView_Update(&lview);
        }

        if(scancode == SC_F4) {
            if(!f4_pressed())
                MarkFrameTime(0xf00);   // set pal zero color to red, if error
        }

        if(scancode == SC_F3) {
            if(!f3_pressed())
                MarkFrameTime(0xf00);   // set pal zero color to red, if error
        }
        if(scancode == SC_F1) {
            if(!f1_pressed())
                MarkFrameTime(0xf00);   // set pal zero color to red, if error
        }

        if(scancode == SC_F8) {
            if(!delete_dir_entry())
                MarkFrameTime(0xf00);   // set pal zero color to red, if error
        }



        if(scancode == SC_ENTER) {
            if(!enter_pressed())
                MarkFrameTime(0xf00);   // set pal zero color to red, if error
        }


    }


}



// In: top left corner of window
void clear_area(byte x, byte y, byte width, byte height)
{
    byte cur_x, cur_y;

    for(cur_y=y; cur_y<y+height; cur_y++) {
        for(cur_x=x; cur_x<x+width; cur_x++) {
            Display_SetCursorPos(cur_x, cur_y);
            Display_PrintString(" ");
        }
    }

}


BOOL check_OS_version(void)
{
    word os_version_word, hw_version_word;

    FLOS_GetVersion(&os_version_word, &hw_version_word);

//_uitoa(os_version_word, buffer, 16);
//FLOS_PrintString(buffer);

    if(os_version_word < OS_VERSION_REQ)
        return FALSE;

    return TRUE;
}

void clear_keyboard_buffer(void) {
    byte ASCII, Scancode;

    while( FLOS_GetKeyPress(&ASCII, &Scancode) );
        //FLOS_PrintString("~"); 
}

void DisplayHelpString(void) {
    BYTE c1 = 8,  c2 = 0x51;
    BYTE i;
    const static char* strHelp[] = {
        "1", "Help  ", "3", "View  ", "4", "Edit  ", "8", "Delete", "ESC", "Exit" };

    Display_SetCursorPos(0, SCREEN_HEIGHT/8 - 1);
    for( i=0; i<sizeof(strHelp) / sizeof(strHelp[0]) ; i+=2 ) {
        Display_SetPen(c1); Display_PrintString(strHelp[i]  );
        Display_SetPen(c2); Display_PrintString(strHelp[i+1]);
    }

}


// x and y - in chars (not pixels)
void DisplayString(BYTE x, BYTE y, BYTE pen, const char* str) {

    Display_SetCursorPos(x, y);
    Display_SetPen(pen); Display_PrintString(str);

}



