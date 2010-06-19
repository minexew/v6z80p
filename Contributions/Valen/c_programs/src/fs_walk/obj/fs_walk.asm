;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Tue Jun 08 18:26:07 2010
;--------------------------------------------------------
	.module fs_walk
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _delete_dir_entry
	.globl _print_box
	.globl _load_config_file
	.globl _init_config_file_parser
	.globl _get_user_action_based_on_ext
	.globl _iterate_trough_extensions
	.globl _replace_new_lines_with_zero_bytes
	.globl _lview
	.globl _config
	.globl _config_file_buffer
	.globl _numStrings
	.globl _tmp1
	.globl _buf
	.globl _buffer
	.globl _myFile
	.globl _request_spawn_command
	.globl _request_exit
	.globl _own_sp
	.globl _DiagMessage
	.globl _load_file_to_buffer
	.globl _RequestToExitAndExecuteCommandString
	.globl _do_dir
	.globl _split_string_to_many_strings
	.globl _PrintMessage
	.globl _ListView_Update
	.globl _ListView_GetNumItems
	.globl _ListView_GetSelectedIndex
	.globl _ListView_SetSelectedIndex
	.globl _ListView_Init
	.globl _ListView_GetItem
	.globl _ListView_GetSelectedItem
	.globl _ListView_check_visible_part
	.globl _ListView_get_item_by_index
	.globl _ListView_update_own_textfield
	.globl _add_user_action_based_on_ext
	.globl _enter_pressed
	.globl _extract_filename_from_buffer
	.globl _do_action_based_on_file_extension
	.globl _request_to_exit_and_execute_command_with_filename
	.globl _f4_pressed
	.globl _IsSelectedItem_DIR
	.globl _GetFilenameOfSelectedItem
	.globl _fill_ListView_by_entries_from_current_dir
	.globl _main_loop
	.globl _clear_area
	.globl _check_OS_version
	.globl _clear_keyboard_buffer
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
_request_exit::
	.ds 1
_request_spawn_command::
	.ds 1
_myFile::
	.ds 7
_buffer::
	.ds 33
_buf::
	.ds 8
_tmp1::
	.ds 2
_numStrings::
	.ds 2
_config_file_buffer::
	.ds 1024
_config::
	.ds 260
_lview::
	.ds 14
_GetFilenameOfSelectedItem_filename_1_1:
	.ds 13
;--------------------------------------------------------
; overlayable items in  ram 
;--------------------------------------------------------
	.area _OVERLAY
;--------------------------------------------------------
; external initialized ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;fs_walk.c:44: BOOL request_exit = FALSE;              // exit program request flag
	ld	iy,#_request_exit
	ld	0 (iy),#0x00
;fs_walk.c:45: BOOL request_spawn_command = FALSE;     // spawn command request flag
	ld	iy,#_request_spawn_command
	ld	0 (iy),#0x00
;fs_walk.c:54: byte* tmp1 = (byte*) 0x8800;
	ld	iy,#_tmp1
	ld	0 (iy),#0x00
	ld	iy,#_tmp1
	ld	1 (iy),#0x88
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;util.c:4: void DiagMessage(char* pMsg, char* pFilename)
;	---------------------------------
; Function DiagMessage
; ---------------------------------
_DiagMessage_start::
_DiagMessage:
	push	ix
	ld	ix,#0
	add	ix,sp
;util.c:8: err = FLOS_GetLastError();
	call	_FLOS_GetLastError
	ld	c,l
;util.c:10: FLOS_PrintString(pMsg);
	push	bc
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:11: FLOS_PrintString(pFilename);
	push	bc
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:13: FLOS_PrintString(" OS_err: $");
	push	bc
	ld	hl,#__str_0
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:14: _uitoa(err, buffer, 16);
	ld	b,#0x00
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	bc
	call	__uitoa
	pop	af
	pop	af
	inc	sp
;util.c:15: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;util.c:16: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_1
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	ix
	ret
_DiagMessage_end::
_own_sp:
	.dw #0xFFFF
__str_0:
	.ascii " OS_err: $"
	.db 0x00
__str_1:
	.db 0x0B
	.db 0x00
;util.c:23: BOOL load_file_to_buffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
;	---------------------------------
; Function load_file_to_buffer
; ---------------------------------
_load_file_to_buffer_start::
_load_file_to_buffer:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-7
	add	hl,sp
	ld	sp,hl
;util.c:28: r = FLOS_FindFile(&myFile, pFilename);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	push	bc
	call	_FLOS_FindFile
	pop	af
	pop	af
;util.c:29: if(!r) {
	xor	a,a
	or	a,l
	jr	NZ,00102$
;util.c:30: DiagMessage("FindFile failed: ", pFilename);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	ld	hl,#__str_2
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;util.c:31: return FALSE;
	ld	l,#0x00
	jp	00105$
00102$:
;util.c:34: FLOS_SetLoadLength(len);
	ld	l,14 (ix)
	ld	h,15 (ix)
	push	hl
	ld	l,12 (ix)
	ld	h,13 (ix)
	push	hl
	call	_FLOS_SetLoadLength
	pop	af
	pop	af
;util.c:35: FLOS_SetFilePointer(file_offset);
	ld	l,8 (ix)
	ld	h,9 (ix)
	push	hl
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_FLOS_SetFilePointer
	pop	af
	pop	af
;util.c:37: r = FLOS_ForceLoad( buf, bank );
	ld	a,16 (ix)
	push	af
	inc	sp
	ld	l,10 (ix)
	ld	h,11 (ix)
	push	hl
	call	_FLOS_ForceLoad
	pop	af
	inc	sp
	ld	b,l
	ld	c,b
;util.c:38: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00104$
;util.c:39: DiagMessage("ForceLoad failed: ", pFilename);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	ld	hl,#__str_3
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;util.c:40: return FALSE;
	ld	l,#0x00
	jr	00105$
00104$:
;util.c:43: return TRUE;
	ld	l,#0x01
00105$:
	ld	sp,ix
	pop	ix
	ret
_load_file_to_buffer_end::
__str_2:
	.ascii "FindFile failed: "
	.db 0x00
__str_3:
	.ascii "ForceLoad failed: "
	.db 0x00
;os_onexit.c:20: void RequestToExitAndExecuteCommandString(const char* cmd)
;	---------------------------------
; Function RequestToExitAndExecuteCommandString
; ---------------------------------
_RequestToExitAndExecuteCommandString_start::
_RequestToExitAndExecuteCommandString:
	push	ix
	ld	ix,#0
	add	ix,sp
;os_onexit.c:22: FLOS_ClearScreen();
	call	_FLOS_ClearScreen
;os_onexit.c:24: FLOS_SetSpawnCmdLine(cmd);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_SetSpawnCmdLine
	pop	af
;os_onexit.c:25: FLOS_PrintStringLFCR(flos_spawn_cmd);
	ld	hl,#_flos_spawn_cmd
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;os_onexit.c:27: request_exit = TRUE;
	ld	hl,#_request_exit + 0
	ld	(hl), #0x01
;os_onexit.c:28: request_spawn_command = TRUE;
	ld	hl,#_request_spawn_command + 0
	ld	(hl), #0x01
	pop	ix
	ret
_RequestToExitAndExecuteCommandString_end::
;os_cmd.c:25: word do_dir(void)
;	---------------------------------
; Function do_dir
; ---------------------------------
_do_dir_start::
_do_dir:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-59
	add	hl,sp
	ld	sp,hl
;os_cmd.c:32: FLOS_DirListFirstEntry();
	call	_FLOS_DirListFirstEntry
;os_cmd.c:33: while(1) {
	ld	hl,#0x000A
	add	hl,sp
	ld	-57 (ix),l
	ld	-56 (ix),h
	ld	hl,#0x000A
	add	hl,sp
	ex	de,hl
	ld	hl,#0x0006
	add	hl,de
	ld	-51 (ix),l
	ld	-50 (ix),h
	ld	hl,#0x0007
	add	hl,de
	ld	-59 (ix),l
	ld	-58 (ix),h
	ld	a,-51 (ix)
	ld	-53 (ix),a
	ld	a,-50 (ix)
	ld	-52 (ix),a
00116$:
;os_cmd.c:34: str[0] = 0;
	ld	hl,#0x0012
	add	hl,sp
	ld	-55 (ix),l
	ld	-54 (ix),h
	ld	(hl),#0x00
;os_cmd.c:35: FLOS_DirListGetEntry(&e);
	ld	hl,#0x000A
	add	hl,sp
	push	hl
	call	_FLOS_DirListGetEntry
	pop	af
;os_cmd.c:36: if(e.err_code == END_OF_DIR) break;
	ld	l,-59 (ix)
	ld	h,-58 (ix)
	ld	a,(hl)
	sub	a,#0x24
	jp	Z,00117$
;os_cmd.c:38: if( e.pFilename[0]=='.' && e.pFilename[1]==0 && e.file_flag == 1) {
	ld	l,-57 (ix)
	ld	h,-56 (ix)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,(bc)
	sub	a,#0x2E
	jr	NZ,00104$
	inc	bc
	ld	a,(bc)
	or	a,a
	jr	NZ,00104$
	ld	l,-51 (ix)
	ld	h,-50 (ix)
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00104$
;os_cmd.c:39: FLOS_DirListNextEntry();
	call	_FLOS_DirListNextEntry
;os_cmd.c:40: continue;
	jr	00116$
00104$:
;os_cmd.c:44: strcat(str, e.pFilename);
	ld	hl,#0x000A
	add	hl,sp
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
;os_cmd.c:46: num_spaces = FILENAME_LEN - strlen(e.pFilename);
	ld	hl,#0x000A
	add	hl,sp
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	call	_strlen
	pop	af
	ld	c,l
	ld	a,#0x0C
	sub	a,c
	ld	c,a
;os_cmd.c:47: for(k=0; k<num_spaces; k++) strcat(str, " ");
	ld	b,#0x00
00118$:
	ld	a,b
	sub	a,c
	jr	NC,00121$
	push	bc
	ld	hl,#__str_4
	push	hl
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
	pop	bc
	inc	b
	jr	00118$
00121$:
;os_cmd.c:50: if(e.file_flag == 1)
	ld	l,-53 (ix)
	ld	h,-52 (ix)
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00108$
;os_cmd.c:51: strcat(str, "  [DIR]");
	ld	hl,#__str_5
	push	hl
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
	jr	00109$
00108$:
;os_cmd.c:53: strcat(str, "  $");
	ld	hl,#__str_6
	push	hl
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
;os_cmd.c:55: _ultoa(e.len, buffer, 16);
	ld	hl,#0x000A
	add	hl,sp
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;os_cmd.c:56: strcat(str, buffer);
	ld	hl,#0x0012
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#_buffer
	push	hl
	push	bc
	call	_strcat
	pop	af
	pop	af
00109$:
;os_cmd.c:58: strcat(str, PS_LFCR);
	ld	hl,#__str_7
	push	hl
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
;os_cmd.c:62: if( (strlen(tmp1) + 32) < DIRBUF_LEN )
	ld	bc,(_tmp1)
	push	bc
	call	_strlen
	pop	af
	ld	b,h
	ld	c,l
	ld	hl,#0x0020
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,c
	sub	a,#0x00
	ld	a,b
	sbc	a,#0x08
	jp	P,00117$
;os_cmd.c:63: strcat(tmp1, str);
	ld	bc,(_tmp1)
	ld	l,-55 (ix)
	ld	h,-54 (ix)
	push	hl
	push	bc
	call	_strcat
	pop	af
	pop	af
;os_cmd.c:67: if(FLOS_DirListNextEntry() == END_OF_DIR) break;
	call	_FLOS_DirListNextEntry
	ld	a,l
	sub	a,#0x24
	jp	NZ,00116$
00117$:
;os_cmd.c:71: return split_string_to_many_strings();
	call	_split_string_to_many_strings
	ld	sp,ix
	pop	ix
	ret
_do_dir_end::
__str_4:
	.ascii " "
	.db 0x00
__str_5:
	.ascii "  [DIR]"
	.db 0x00
__str_6:
	.ascii "  $"
	.db 0x00
__str_7:
	.db 0x0B
	.db 0x00
;os_cmd.c:81: word split_string_to_many_strings(void) {
;	---------------------------------
; Function split_string_to_many_strings
; ---------------------------------
_split_string_to_many_strings_start::
_split_string_to_many_strings:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-6
	add	hl,sp
	ld	sp,hl
;os_cmd.c:84: len = strlen(tmp1);
	ld	bc,(_tmp1)
	push	bc
	call	_strlen
	pop	af
	ld	b,h
	ld	-4 (ix),l
	ld	-3 (ix),b
;os_cmd.c:85: for(i=0; i<len; i++) {
	ld	-6 (ix),#0x00
	ld	-5 (ix),#0x00
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
00103$:
	ld	a,-2 (ix)
	sub	a,-4 (ix)
	ld	a,-1 (ix)
	sbc	a,-3 (ix)
	jr	NC,00106$
;os_cmd.c:86: if(tmp1[i] == 0x0b) {
	ld	a,(#_tmp1+0)
	add	a,-2 (ix)
	ld	e,a
	ld	a,(#_tmp1+1)
	adc	a,-1 (ix)
	ld	d,a
	ld	a,(de)
	sub	a,#0x0B
	jr	NZ,00105$
;os_cmd.c:87: tmp1[i] = 0;                 // replace LFCR code to 0
	ld	a,#0x00
	ld	(de),a
;os_cmd.c:88: num++;
	inc	-6 (ix)
	jr	NZ,00115$
	inc	-5 (ix)
00115$:
00105$:
;os_cmd.c:85: for(i=0; i<len; i++) {
	inc	-2 (ix)
	jr	NZ,00116$
	inc	-1 (ix)
00116$:
	jr	00103$
00106$:
;os_cmd.c:92: return num;
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	sp,ix
	pop	ix
	ret
_split_string_to_many_strings_end::
;os_cmd.c:97: void PrintMessage(const char* str)
;	---------------------------------
; Function PrintMessage
; ---------------------------------
_PrintMessage_start::
_PrintMessage:
	push	ix
	ld	ix,#0
	add	ix,sp
;os_cmd.c:99: FLOS_PrintString(str);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
;os_cmd.c:100: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_8
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	ix
	ret
_PrintMessage_end::
__str_8:
	.db 0x0B
	.db 0x00
;list_view.c:38: void ListView_Update(ListView* this) {
;	---------------------------------
; Function ListView_Update
; ---------------------------------
_ListView_Update_start::
_ListView_Update:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-27
	add	hl,sp
	ld	sp,hl
;list_view.c:41: byte x = this->x, y = this->y;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0006
	add	hl,bc
	ld	a,(hl)
	ld	-4 (ix),a
	ld	hl,#0x0007
	add	hl,bc
	ld	a,(hl)
	ld	-5 (ix),a
;list_view.c:42: byte width = this->width, height = this->height;
	ld	hl,#0x0008
	add	hl,bc
	ld	a,(hl)
	ld	-6 (ix),a
	ld	hl,#0x0009
	add	hl,bc
	ld	a,(hl)
	ld	-7 (ix),a
;list_view.c:46: ListView_check_visible_part(this);
	push	bc
	call	_ListView_check_visible_part
	pop	af
;list_view.c:47: p = this->firstVisibleStr;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x000C
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-9 (ix),e
	ld	-8 (ix),d
;list_view.c:50: i=this->firstVisibleIndex;
	ld	hl,#0x000A
	add	hl,bc
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-2 (ix),e
	ld	-1 (ix),d
;list_view.c:51: while( i < (this->firstVisibleIndex+height) &&  i < this->numItems ) {
	ld	hl,#0x0002
	add	hl,bc
	ld	-14 (ix),l
	ld	-13 (ix),h
	ld	a,-4 (ix)
	add	a,-6 (ix)
	dec	a
	ld	-22 (ix),a
	ld	hl,#0x0004
	add	hl,bc
	ld	-16 (ix),l
	ld	-15 (ix),h
	ld	a,-4 (ix)
	inc	a
	ld	-23 (ix),a
	ld	hl,#0x0008
	add	hl,bc
	ld	-18 (ix),l
	ld	-17 (ix),h
	ld	a,-5 (ix)
	ld	-19 (ix),a
	ld	a,-2 (ix)
	ld	-21 (ix),a
	ld	a,-1 (ix)
	ld	-20 (ix),a
00107$:
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	a,(hl)
	ld	-25 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-24 (ix),a
	ld	e,-7 (ix)
	ld	d,#0x00
	ld	a,-25 (ix)
	add	a,e
	ld	e,a
	ld	a,-24 (ix)
	adc	a,d
	ld	d,a
	ld	a,-21 (ix)
	sub	a,e
	ld	a,-20 (ix)
	sbc	a,d
	jp	NC,00109$
	ld	l,-14 (ix)
	ld	h,-13 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-21 (ix)
	sub	a,e
	ld	a,-20 (ix)
	sbc	a,d
	jp	NC,00109$
;list_view.c:53: FLOS_SetCursorPos(x, y);
	push	bc
	ld	h,-19 (ix)
	ld	l,-4 (ix)
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;list_view.c:54: FLOS_PrintString(" "); 
	push	bc
	ld	hl,#__str_9
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;list_view.c:55: FLOS_SetCursorPos(x+width-1, y);
	push	bc
	ld	h,-19 (ix)
	ld	l,-22 (ix)
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;list_view.c:56: FLOS_PrintString(" "); 
	push	bc
	ld	hl,#__str_9
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;list_view.c:59: (i == this->selectedIndex) ? FLOS_SetPen(PEN_SELECTED) : FLOS_SetPen(PEN_DEFAULT); 
	ld	l,-16 (ix)
	ld	h,-15 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-21 (ix)
	sub	e
	jr	NZ,00129$
	ld	a,-20 (ix)
	sub	d
	jr	Z,00130$
00129$:
	jr	00116$
00130$:
	push	bc
	ld	a,#0xA0
	push	af
	inc	sp
	call	_FLOS_SetPen
	inc	sp
	pop	bc
	jr	00117$
00116$:
	push	bc
	ld	a,#0x07
	push	af
	inc	sp
	call	_FLOS_SetPen
	inc	sp
	pop	bc
00117$:
;list_view.c:61: if(strstr(p, ".EXE") != NULL && i != this->selectedIndex) FLOS_SetPen(PEN_FILE_EXE); 
	push	bc
	ld	hl,#__str_10
	push	hl
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ex	de,hl
	pop	bc
	ld	a,e
	or	a,d
	jr	Z,00102$
	ld	l,-16 (ix)
	ld	h,-15 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-21 (ix)
	sub	e
	jr	NZ,00132$
	ld	a,-20 (ix)
	sub	d
	jr	Z,00102$
00132$:
	push	bc
	ld	a,#0x05
	push	af
	inc	sp
	call	_FLOS_SetPen
	inc	sp
	pop	bc
00102$:
;list_view.c:65: FLOS_SetCursorPos(x+1, y);
	push	bc
	ld	h,-19 (ix)
	ld	l,-23 (ix)
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;list_view.c:66: FLOS_PrintStringLFCR(p); 
	push	bc
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
	pop	bc
;list_view.c:68: strl = strlen(p);
	push	bc
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	call	_strlen
	pop	af
	ld	e,l
	pop	bc
	ld	-10 (ix),e
;list_view.c:70: if(strl < this->width-2) {
	ld	l,-18 (ix)
	ld	h,-17 (ix)
	ld	e,(hl)
	ld	d,#0x00
	dec	de
	dec	de
	ld	a,-10 (ix)
	ld	-25 (ix),a
	ld	-24 (ix),#0x00
	ld	a,-25 (ix)
	sub	a,e
	ld	a,-24 (ix)
	sbc	a,d
	jp	P,00105$
;list_view.c:71: FLOS_SetCursorPos(x+1+strl, y);
	ld	a,-23 (ix)
	add	a,-10 (ix)
	ld	e,a
	push	bc
	ld	a,-19 (ix)
	ld	d,a
	push	de
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;list_view.c:72: for(k=0; k<(this->width-2-strl); k++) FLOS_PrintString(" "); 
	ld	-3 (ix),#0x00
00110$:
	ld	l,-18 (ix)
	ld	h,-17 (ix)
	ld	e,(hl)
	ld	d,#0x00
	dec	de
	dec	de
	ld	a,e
	sub	a,-25 (ix)
	ld	-27 (ix),a
	ld	a,d
	sbc	a,-24 (ix)
	ld	-26 (ix),a
	ld	e,-3 (ix)
	ld	d,#0x00
	ld	a,e
	sub	a,-27 (ix)
	ld	a,d
	sbc	a,-26 (ix)
	jp	P,00105$
	push	bc
	ld	hl,#__str_9
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
	inc	-3 (ix)
	jr	00110$
00105$:
;list_view.c:76: FLOS_SetPen(PEN_DEFAULT);
	push	bc
	ld	a,#0x07
	push	af
	inc	sp
	call	_FLOS_SetPen
	inc	sp
	pop	bc
;list_view.c:78: p = p + strlen(p) + 1;
	push	bc
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	call	_strlen
	pop	af
	ex	de,hl
	pop	bc
	ld	a,-9 (ix)
	add	a,e
	ld	e,a
	ld	a,-8 (ix)
	adc	a,d
	ld	d,a
	ld	hl,#0x0001
	add	hl,de
	ld	-9 (ix),l
	ld	-8 (ix),h
;list_view.c:92: y++;
	inc	-19 (ix)
;list_view.c:93: i++;
	inc	-21 (ix)
	jr	NZ,00133$
	inc	-20 (ix)
00133$:
	jp	00107$
00109$:
;list_view.c:96: ListView_update_own_textfield(this);
	push	bc
	call	_ListView_update_own_textfield
	pop	af
	ld	sp,ix
	pop	ix
	ret
_ListView_Update_end::
__str_9:
	.ascii " "
	.db 0x00
__str_10:
	.ascii ".EXE"
	.db 0x00
;list_view.c:99: word ListView_GetNumItems(ListView* this) {
;	---------------------------------
; Function ListView_GetNumItems
; ---------------------------------
_ListView_GetNumItems_start::
_ListView_GetNumItems:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:100: return this->numItems;
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,c
	ld	h,b
	pop	ix
	ret
_ListView_GetNumItems_end::
;list_view.c:103: word ListView_GetSelectedIndex(ListView* this)
;	---------------------------------
; Function ListView_GetSelectedIndex
; ---------------------------------
_ListView_GetSelectedIndex_start::
_ListView_GetSelectedIndex:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:105: return this->selectedIndex;
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,c
	ld	h,b
	pop	ix
	ret
_ListView_GetSelectedIndex_end::
;list_view.c:107: void ListView_SetSelectedIndex(ListView* this, word selectedIndex)
;	---------------------------------
; Function ListView_SetSelectedIndex
; ---------------------------------
_ListView_SetSelectedIndex_start::
_ListView_SetSelectedIndex:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:109: this->selectedIndex = selectedIndex;
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
	pop	ix
	ret
_ListView_SetSelectedIndex_end::
;list_view.c:112: void ListView_Init(ListView* this)
;	---------------------------------
; Function ListView_Init
; ---------------------------------
_ListView_Init_start::
_ListView_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:114: this->firstVisibleIndex = 0;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x000A
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;list_view.c:115: this->firstVisibleStr = this->strArr;
	ld	hl,#0x000C
	add	hl,bc
	ex	de,hl
	ld	l,c
	ld	h,b
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	pop	ix
	ret
_ListView_Init_end::
;list_view.c:118: char* ListView_GetItem(ListView* this, word itemIndex)
;	---------------------------------
; Function ListView_GetItem
; ---------------------------------
_ListView_GetItem_start::
_ListView_GetItem:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:120: return ListView_get_item_by_index(this, itemIndex);
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ListView_get_item_by_index
	pop	af
	pop	af
	pop	ix
	ret
_ListView_GetItem_end::
;list_view.c:125: char* ListView_GetSelectedItem(ListView* this)
;	---------------------------------
; Function ListView_GetSelectedItem
; ---------------------------------
_ListView_GetSelectedItem_start::
_ListView_GetSelectedItem:
	push	ix
	ld	ix,#0
	add	ix,sp
;list_view.c:131: selectedIndex = ListView_GetSelectedIndex(this);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ListView_GetSelectedIndex
	pop	af
	ld	b,h
	ld	c,l
;list_view.c:132: p = ListView_GetItem(this, selectedIndex);
	push	bc
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ListView_GetItem
	pop	af
	pop	af
	ld	b,h
	ld	c,l
	ld	l,c
	ld	h,b
;list_view.c:133: return p;
	pop	ix
	ret
_ListView_GetSelectedItem_end::
;list_view.c:137: void ListView_check_visible_part(ListView* this)
;	---------------------------------
; Function ListView_check_visible_part
; ---------------------------------
_ListView_check_visible_part_start::
_ListView_check_visible_part:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-8
	add	hl,sp
	ld	sp,hl
;list_view.c:143: if( this->selectedIndex >= (this->firstVisibleIndex+this->height) ) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0004
	add	hl,bc
	ld	a,(hl)
	ld	-4 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-3 (ix),a
	ld	hl,#0x000A
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	hl,#0x0009
	add	hl,bc
	ld	a,(hl)
	ld	-8 (ix),a
	ld	-7 (ix),#0x00
	ld	a,-6 (ix)
	add	a,-8 (ix)
	ld	e,a
	ld	a,-5 (ix)
	adc	a,-7 (ix)
	ld	d,a
	ld	a,-4 (ix)
	sub	a,e
	ld	a,-3 (ix)
	sbc	a,d
	jr	C,00102$
;list_view.c:144: this->firstVisibleIndex = this->selectedIndex - this->height + 1;
	ld	a,-4 (ix)
	sub	a,-8 (ix)
	ld	e,a
	ld	a,-3 (ix)
	sbc	a,-7 (ix)
	ld	d,a
	inc	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
00102$:
;list_view.c:147: if( this->selectedIndex < this->firstVisibleIndex ) 
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-4 (ix)
	sub	a,e
	ld	a,-3 (ix)
	sbc	a,d
	jr	NC,00104$
;list_view.c:148: this->firstVisibleIndex = this->selectedIndex;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,-4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-3 (ix)
	ld	(hl),a
00104$:
;list_view.c:151: p = ListView_get_item_by_index(this, this->firstVisibleIndex);
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	push	bc
	call	_ListView_get_item_by_index
	pop	af
	pop	af
	ld	b,h
	ld	c,l
;list_view.c:152: this->firstVisibleStr = p;    
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	hl,#0x000C
	add	hl,de
	ld	(hl),c
	inc	hl
	ld	(hl),b
	ld	sp,ix
	pop	ix
	ret
_ListView_check_visible_part_end::
;list_view.c:157: char* ListView_get_item_by_index(ListView* this, word itemIndex)
;	---------------------------------
; Function ListView_get_item_by_index
; ---------------------------------
_ListView_get_item_by_index_start::
_ListView_get_item_by_index:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;list_view.c:162: p = this->strArr;
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	c,0 (iy)
	ld	b,1 (iy)
;list_view.c:163: for(i=0; i<itemIndex; i++)
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
00101$:
	ld	a,-2 (ix)
	sub	a,6 (ix)
	ld	a,-1 (ix)
	sbc	a,7 (ix)
	jr	NC,00104$
;list_view.c:164: p = p + strlen(p) + 1;
	push	bc
	push	bc
	call	_strlen
	pop	af
	ex	de,hl
	pop	bc
	ld	a,c
	add	a,e
	ld	e,a
	ld	a,b
	adc	a,d
	ld	c,e
	ld	b,a
	inc	bc
;list_view.c:163: for(i=0; i<itemIndex; i++)
	inc	-2 (ix)
	jr	NZ,00110$
	inc	-1 (ix)
00110$:
	jr	00101$
00104$:
;list_view.c:166: return p;
	ld	l,c
	ld	h,b
	ld	sp,ix
	pop	ix
	ret
_ListView_get_item_by_index_end::
;list_view.c:169: void ListView_update_own_textfield(ListView* this)
;	---------------------------------
; Function ListView_update_own_textfield
; ---------------------------------
_ListView_update_own_textfield_start::
_ListView_update_own_textfield:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;list_view.c:174: FLOS_SetCursorPos(this->x, this->y+this->height);
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0007
	add	hl,bc
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0009
	add	hl,bc
	ld	e,(hl)
	ld	a,-1 (ix)
	add	a,e
	ld	-1 (ix),a
	ld	hl,#0x0006
	add	hl,bc
	ld	e,(hl)
	push	bc
	ld	a,-1 (ix)
	ld	d,a
	push	de
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;list_view.c:175: FLOS_PrintString("---> ");
	push	bc
	ld	hl,#__str_11
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;list_view.c:177: numitems = ListView_GetNumItems(this); 
	push	bc
	call	_ListView_GetNumItems
	pop	af
	ld	b,h
	ld	c,l
;list_view.c:178: _uitoa(numitems, buffer, 10);
	ld	a,#0x0A
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	bc
	call	__uitoa
	pop	af
	pop	af
	inc	sp
;list_view.c:179: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;list_view.c:181: FLOS_PrintString(" entries");
	ld	hl,#__str_12
	push	hl
	call	_FLOS_PrintString
	pop	af
	ld	sp,ix
	pop	ix
	ret
_ListView_update_own_textfield_end::
__str_11:
	.ascii "---> "
	.db 0x00
__str_12:
	.ascii " entries"
	.db 0x00
;config.c:20: void replace_new_lines_with_zero_bytes(void)
;	---------------------------------
; Function replace_new_lines_with_zero_bytes
; ---------------------------------
_replace_new_lines_with_zero_bytes_start::
_replace_new_lines_with_zero_bytes:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;config.c:23: for(i=0; i<CONFIG_FILE_MAX_SIZE; i++) {
	ld	bc,#0x0000
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
00106$:
	ld	a,-2 (ix)
	sub	a,#0x00
	ld	a,-1 (ix)
	sbc	a,#0x04
	jr	NC,00110$
;config.c:24: if(config_file_buffer[i] == 0) {
	ld	a,#<_config_file_buffer
	add	a,-2 (ix)
	ld	e,a
	ld	a,#>_config_file_buffer
	adc	a,-1 (ix)
	ld	d,a
	ld	a,(de)
	ld	e,a
	or	a,a
	jr	NZ,00102$
;config.c:25: config.config_file_buffer_size = i;
	ld	hl,#_config
	ld	(hl),c
	inc	hl
	ld	(hl),b
;config.c:26: return;
	jr	00110$
00102$:
;config.c:28: if(config_file_buffer[i] == '\x0D' || config_file_buffer[i] == '\x0A') {
	ld	a,e
	sub	a,#0x0D
	jr	Z,00103$
	ld	a,e
	sub	a,#0x0A
	jr	NZ,00108$
00103$:
;config.c:29: config_file_buffer[i] = 0;
	ld	a,#<_config_file_buffer
	add	a,-2 (ix)
	ld	e,a
	ld	a,#>_config_file_buffer
	adc	a,-1 (ix)
	ld	d,a
	ld	a,#0x00
	ld	(de),a
00108$:
;config.c:23: for(i=0; i<CONFIG_FILE_MAX_SIZE; i++) {
	inc	-2 (ix)
	jr	NZ,00119$
	inc	-1 (ix)
00119$:
	ld	c,-2 (ix)
	ld	b,-1 (ix)
	jr	00106$
00110$:
	ld	sp,ix
	pop	ix
	ret
_replace_new_lines_with_zero_bytes_end::
;config.c:37: void iterate_trough_extensions(void)
;	---------------------------------
; Function iterate_trough_extensions
; ---------------------------------
_iterate_trough_extensions_start::
_iterate_trough_extensions:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;config.c:41: byte *p = config_file_buffer;
	ld	-2 (ix),#<_config_file_buffer
	ld	-1 (ix),#>_config_file_buffer
;config.c:42: config.is_in_ext_section = FALSE;
	ld	de,#_config + 2
	ld	a,#0x00
	ld	(de),a
;config.c:44: while(p < p + config.config_file_buffer_size) {
00113$:
	ld	hl,#_config
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-2 (ix)
	add	a,c
	ld	c,a
	ld	a,-1 (ix)
	adc	a,b
	ld	b,a
	ld	a,-2 (ix)
	sub	a,c
	ld	a,-1 (ix)
	sbc	a,b
	jp	NC,00116$
;config.c:45: if(strcmp(p, "[Ext]") == 0) config.is_in_ext_section = TRUE;
	push	de
	ld	hl,#__str_13
	push	hl
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_strcmp
	pop	af
	pop	af
	ld	b,h
	ld	c,l
	pop	de
	ld	a,c
	or	a,b
	jr	NZ,00102$
	ld	a,#0x01
	ld	(#_config + 2),a
00102$:
;config.c:46: p += strlen(p);
	push	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_strlen
	pop	af
	ld	b,h
	ld	c,l
	pop	de
	ld	a,-2 (ix)
	add	a,c
	ld	-2 (ix),a
	ld	a,-1 (ix)
	adc	a,b
	ld	-1 (ix),a
;config.c:47: if(*p == 0) p++;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00104$
	inc	-2 (ix)
	jr	NZ,00126$
	inc	-1 (ix)
00126$:
00104$:
;config.c:48: if(*p == 0) p++;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00106$
	inc	-2 (ix)
	jr	NZ,00127$
	inc	-1 (ix)
00127$:
00106$:
;config.c:49: if(*p == 0) return;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
	jp	Z,00116$
;config.c:50: if(config.is_in_ext_section) {
	ld	a,(de)
	or	a,a
	jp	Z,00113$
;config.c:52: pEqualChar = strstr(p, "=");
	push	de
	ld	hl,#__str_14
	push	hl
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	c,l
	pop	de
;config.c:53: if(pEqualChar) {
	ld	a,c
	or	a,b
	jp	Z,00113$
;config.c:54: *pEqualChar = 0;        // split string to two, e.g "BMP=SHOWBMP" to "BMP",0,"SHOWBMP"
	ld	a,#0x00
	ld	(bc),a
;config.c:55: add_user_action_based_on_ext(p, p+strlen(p)+1);
	push	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_strlen
	pop	af
	ld	b,h
	ld	c,l
	pop	de
	ld	a,-2 (ix)
	add	a,c
	ld	c,a
	ld	a,-1 (ix)
	adc	a,b
	ld	b,a
	inc	bc
	push	de
	push	bc
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_add_user_action_based_on_ext
	pop	af
	pop	af
	pop	de
	jp	00113$
00116$:
	ld	sp,ix
	pop	ix
	ret
_iterate_trough_extensions_end::
__str_13:
	.ascii "[Ext]"
	.db 0x00
__str_14:
	.ascii "="
	.db 0x00
;config.c:65: void add_user_action_based_on_ext(const char *pExt, const char *pAction)
;	---------------------------------
; Function add_user_action_based_on_ext
; ---------------------------------
_add_user_action_based_on_ext_start::
_add_user_action_based_on_ext:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-7
	add	hl,sp
	ld	sp,hl
;config.c:68: config.user_action_based_on_ext[config.user_action_based_on_ext_index][0] = pExt;
	ld	bc,#_config + 3
	ld	hl,#_config + 259
	ld	-3 (ix),l
	ld	-2 (ix),h
	ld	a,(hl)
	ld	-1 (ix),a
	ld	-5 (ix),a
	ld	-4 (ix),#0x00
	ld	a,-5 (ix)
	ld	-7 (ix),a
	ld	a,-4 (ix)
	ld	-6 (ix),a
	ld	a,#0x02+1
	jr	00107$
00106$:
	sla	-7 (ix)
	rl	-6 (ix)
00107$:
	dec	a
	jr	NZ,00106$
	ld	a,c
	add	a,-7 (ix)
	ld	e,a
	ld	a,b
	adc	a,-6 (ix)
	ld	l,e
	ld	h,a
	ld	a,4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,5 (ix)
	ld	(hl),a
;config.c:69: config.user_action_based_on_ext[config.user_action_based_on_ext_index][1] = pAction;
	ld	a,c
	add	a,-7 (ix)
	ld	c,a
	ld	a,b
	adc	a,-6 (ix)
	ld	l,c
	ld	h,a
	inc	hl
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;config.c:71: if(config.user_action_based_on_ext_index+1 < CONFIG_FILE_MAX_EXT_ACTIONS)
	ld	c,-5 (ix)
	ld	b,-4 (ix)
	inc	bc
	ld	a,c
	sub	a,#0x40
	ld	a,b
	sbc	a,#0x00
	jp	P,00103$
;config.c:72: config.user_action_based_on_ext_index++;
	ld	a,-1 (ix)
	inc	a
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	(hl),a
00103$:
	ld	sp,ix
	pop	ix
	ret
_add_user_action_based_on_ext_end::
;config.c:76: const char* get_user_action_based_on_ext(const char *pExt)
;	---------------------------------
; Function get_user_action_based_on_ext
; ---------------------------------
_get_user_action_based_on_ext_start::
_get_user_action_based_on_ext:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;config.c:80: for(i=0; i<CONFIG_FILE_MAX_EXT_ACTIONS; i++) {
	ld	-1 (ix),#0x00
00103$:
	ld	a,-1 (ix)
	sub	a,#0x40
	jp	NC,00106$
;config.c:81: r = strcmp(config.user_action_based_on_ext[i][0], pExt);
	ld	de,#_config + 3
	ld	c,-1 (ix)
	ld	b,#0x00
	sla	c
	rl	b
	sla	c
	rl	b
	ld	a,e
	add	a,c
	ld	e,a
	ld	a,d
	adc	a,b
	ld	l,e
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	push	de
	call	_strcmp
	pop	af
	pop	af
	ex	de,hl
	pop	bc
;config.c:82: if(r==0) return config.user_action_based_on_ext[i][1];
	ld	a,e
	or	a,d
	jr	NZ,00105$
	ld	de,#_config + 3
	ld	a,e
	add	a,c
	ld	c,a
	ld	a,d
	adc	a,b
	ld	l,c
	ld	h,a
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,c
	ld	h,b
	jr	00107$
00105$:
;config.c:80: for(i=0; i<CONFIG_FILE_MAX_EXT_ACTIONS; i++) {
	inc	-1 (ix)
	jp	00103$
00106$:
;config.c:85: return NULL;
	ld	hl,#0x0000
00107$:
	ld	sp,ix
	pop	ix
	ret
_get_user_action_based_on_ext_end::
;config.c:90: void init_config_file_parser(void) {
;	---------------------------------
; Function init_config_file_parser
; ---------------------------------
_init_config_file_parser_start::
_init_config_file_parser:
;config.c:91: config.user_action_based_on_ext_index = 0;
	ld	a,#0x00
	ld	(#_config + 259),a
;config.c:93: memset(config.user_action_based_on_ext, 0 , sizeof(config.user_action_based_on_ext));
	ld	bc,#_config + 3
	ld	hl,#0x0100
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	push	bc
	call	_memset
	pop	af
	pop	af
	inc	sp
	ret
_init_config_file_parser_end::
;config.c:99: BOOL load_config_file(void)
;	---------------------------------
; Function load_config_file
; ---------------------------------
_load_config_file_start::
_load_config_file:
;config.c:101: init_config_file_parser();
	call	_init_config_file_parser
;config.c:103: FLOS_RootDir();
	call	_FLOS_RootDir
;config.c:104: if(!FLOS_ChangeDir(CONFIG_FILE_DIR))
	ld	hl,#__str_15
	push	hl
	call	_FLOS_ChangeDir
	pop	af
	xor	a,a
	or	a,l
	jr	NZ,00102$
;config.c:106: FLOS_PrintStringLFCR("Failed to cahange dir to /" CONFIG_FILE_DIR);
	ld	hl,#__str_16
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;config.c:107: return FALSE;
	ld	l,#0x00
	ret
00102$:
;config.c:110: memset(config_file_buffer, 0, CONFIG_FILE_MAX_SIZE);
	ld	hl,#0x0400
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_config_file_buffer
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
;config.c:111: if(!load_file_to_buffer("FS_WALK.CFG", 0, config_file_buffer, CONFIG_FILE_MAX_SIZE, 0))
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0400
	push	hl
	ld	hl,#_config_file_buffer
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_17
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;config.c:112: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00104$
	ld	l,a
	ret
00104$:
;config.c:115: replace_new_lines_with_zero_bytes();
	call	_replace_new_lines_with_zero_bytes
;config.c:116: iterate_trough_extensions();
	call	_iterate_trough_extensions
;config.c:119: return TRUE;
	ld	l,#0x01
	ret
_load_config_file_end::
__str_15:
	.ascii "COMMANDS"
	.db 0x00
__str_16:
	.ascii "Failed to cahange dir to /COMMANDS"
	.db 0x00
__str_17:
	.ascii "FS_WALK.CFG"
	.db 0x00
;user_actions.c:14: BOOL enter_pressed(void)
;	---------------------------------
; Function enter_pressed
; ---------------------------------
_enter_pressed_start::
_enter_pressed:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-26
	add	hl,sp
	ld	sp,hl
;user_actions.c:21: char dirname[FILENAME_LEN +1] = "";
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	a,#0x00
	ld	(bc),a
;user_actions.c:23: p = ListView_GetSelectedItem(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_GetSelectedItem
	pop	af
	ld	b,h
	ld	c,l
;user_actions.c:26: if(!extract_filename_from_buffer(p, filename))
	ld	hl,#0x000D
	add	hl,sp
	push	bc
	push	hl
	push	bc
	call	_extract_filename_from_buffer
	pop	af
	pop	af
	ld	e,l
	pop	bc
	xor	a,a
;user_actions.c:27: return FALSE;
	or	a,e
	jr	NZ,00102$
	ld	l,a
	jp	00109$
00102$:
;user_actions.c:29: if(strstr(p, "[DIR]") != NULL) {
	ld	hl,#__str_19
	push	hl
	push	bc
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	a,l
	or	a,b
	jr	Z,00106$
;user_actions.c:36: if(filename[0] == '.') {
	ld	hl,#0x000D
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	a,(bc)
	sub	a,#0x2E
	jr	NZ,00104$
;user_actions.c:40: r = FLOS_ParentDir();
	call	_FLOS_ParentDir
	ld	e,l
;user_actions.c:41: fill_ListView_by_entries_from_current_dir();
	push	de
	call	_fill_ListView_by_entries_from_current_dir
	pop	de
;user_actions.c:46: return r;
	ld	l,e
	jr	00109$
00104$:
;user_actions.c:51: r = FLOS_ChangeDir(filename);
	push	bc
	call	_FLOS_ChangeDir
	pop	af
	ld	c,l
	ld	e,c
;user_actions.c:52: fill_ListView_by_entries_from_current_dir();
	push	de
	call	_fill_ListView_by_entries_from_current_dir
	pop	de
;user_actions.c:53: return r;
	ld	l,e
	jr	00109$
00106$:
;user_actions.c:57: if(!do_action_based_on_file_extension(filename))
	ld	hl,#0x000D
	add	hl,sp
	push	hl
	call	_do_action_based_on_file_extension
	pop	af
;user_actions.c:58: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00108$
	ld	l,a
	jr	00109$
00108$:
;user_actions.c:60: return TRUE;
	ld	l,#0x01
00109$:
	ld	sp,ix
	pop	ix
	ret
_enter_pressed_end::
__str_19:
	.ascii "[DIR]"
	.db 0x00
;user_actions.c:63: BOOL extract_filename_from_buffer(const char* pFrom, char* pTo)
;	---------------------------------
; Function extract_filename_from_buffer
; ---------------------------------
_extract_filename_from_buffer_start::
_extract_filename_from_buffer:
	push	ix
	ld	ix,#0
	add	ix,sp
;user_actions.c:68: pFromEnd = strstr(pFrom, " ");
	ld	hl,#__str_20
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	c,l
;user_actions.c:69: if(pFromEnd == NULL)
	ld	a,c
	or	a,b
	jr	NZ,00102$
;user_actions.c:70: return FALSE;
	ld	l,#0x00
	jr	00105$
00102$:
;user_actions.c:72: pFromLen = pFromEnd - pFrom;
	ld	a,c
	sub	a,4 (ix)
	ld	c,a
	ld	a,b
	sbc	a,5 (ix)
	ld	b,a
;user_actions.c:73: if(pFromLen > FILENAME_LEN)
	ld	a,#0x0C
	sub	a,c
	jr	NC,00104$
;user_actions.c:74: return FALSE;
	ld	l,#0x00
	jr	00105$
00104$:
;user_actions.c:76: memset(pTo, 0, FILENAME_LEN +1);
	ld	e,6 (ix)
	ld	d,7 (ix)
	push	bc
	ld	hl,#0x000D
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	push	de
	call	_memset
	pop	af
	pop	af
	inc	sp
	pop	bc
;user_actions.c:77: memcpy(pTo, pFrom, pFromLen);
	ld	l,6 (ix)
	ld	h,7 (ix)
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	b,#0x00
	ex	de,hl
	ldir
;user_actions.c:79: return TRUE;
	ld	l,#0x01
00105$:
	pop	ix
	ret
_extract_filename_from_buffer_end::
__str_20:
	.ascii " "
	.db 0x00
;user_actions.c:84: BOOL do_action_based_on_file_extension(const char* filename)
;	---------------------------------
; Function do_action_based_on_file_extension
; ---------------------------------
_do_action_based_on_file_extension_start::
_do_action_based_on_file_extension:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-87
	add	hl,sp
	ld	sp,hl
;user_actions.c:91: const char* p = filename;           // just alias
	ld	a,4 (ix)
	ld	-5 (ix),a
	ld	a,5 (ix)
	ld	-4 (ix),a
;user_actions.c:93: char full_command_str[80] = "";     // big enough string (hm..)
	ld	hl,#0x0002
	add	hl,sp
	ld	-87 (ix),l
	ld	-86 (ix),h
	ld	(hl),#0x00
;user_actions.c:95: pExt = strstr(p, ".") + 1;
	ld	hl,#__str_22
	push	hl
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	c,l
	ld	hl,#0x0001
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
;user_actions.c:96: if(strstr(p, ".EXE") != NULL) {
	ld	hl,#__str_23
	push	hl
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	a,l
	or	a,b
	jr	Z,00107$
;user_actions.c:97: isExecuteCommand = TRUE;
	ld	-3 (ix),#0x01
;user_actions.c:98: command = "";
	ld	bc,#__str_21
	jr	00108$
00107$:
;user_actions.c:100: if(pExt == NULL || strlen(pExt) == 0) return TRUE;
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jr	Z,00101$
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_strlen
	pop	af
	ld	d,h
	ld	a,l
	or	a,d
	jr	NZ,00102$
00101$:
	ld	l,#0x01
	jp	00113$
00102$:
;user_actions.c:101: pAction = get_user_action_based_on_ext(pExt);
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_get_user_action_based_on_ext
	pop	af
	ex	de,hl
;user_actions.c:102: if(pAction == NULL) return TRUE;
	ld	a,e
	or	a,d
	jr	NZ,00105$
	ld	l,#0x01
	jr	00113$
00105$:
;user_actions.c:104: isExecuteCommand = TRUE;
	ld	-3 (ix),#0x01
;user_actions.c:105: command = pAction;
	ld	c,e
	ld	b,d
00108$:
;user_actions.c:117: strcat(full_command_str, command);
	push	bc
	ld	l,-87 (ix)
	ld	h,-86 (ix)
	push	hl
	call	_strcat
	pop	af
	pop	af
;user_actions.c:118: strcat(full_command_str, " ");
	ld	hl,#0x0002
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#__str_24
	push	hl
	push	bc
	call	_strcat
	pop	af
	pop	af
;user_actions.c:120: if(isExecuteCommand) {
	xor	a,a
	or	a,-3 (ix)
	jr	Z,00112$
;user_actions.c:121: if(!request_to_exit_and_execute_command_with_filename(full_command_str, p))
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	ld	l,-87 (ix)
	ld	h,-86 (ix)
	push	hl
	call	_request_to_exit_and_execute_command_with_filename
	pop	af
	pop	af
;user_actions.c:122: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00112$
	ld	l,a
	jr	00113$
00112$:
;user_actions.c:125: return TRUE;
	ld	l,#0x01
00113$:
	ld	sp,ix
	pop	ix
	ret
_do_action_based_on_file_extension_end::
__str_21:
	.db 0x00
__str_22:
	.ascii "."
	.db 0x00
__str_23:
	.ascii ".EXE"
	.db 0x00
__str_24:
	.ascii " "
	.db 0x00
;user_actions.c:131: BOOL request_to_exit_and_execute_command_with_filename(const char* command, const char* filename)
;	---------------------------------
; Function request_to_exit_and_execute_command_with_filename
; ---------------------------------
_request_to_exit_and_execute_command_with_filename_start::
_request_to_exit_and_execute_command_with_filename:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-32
	add	hl,sp
	ld	sp,hl
;user_actions.c:133: char cmd[32] = "";
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	a,#0x00
	ld	(bc),a
;user_actions.c:135: if(strlen(filename) > FILENAME_LEN)
	push	bc
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_strlen
	pop	af
	ex	de,hl
	pop	bc
	ld	a,#0x0C
	sub	a,e
	ld	a,#0x00
	sbc	a,d
	jp	P,00102$
;user_actions.c:136: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;user_actions.c:139: strcat(cmd, command);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	push	bc
	call	_strcat
	pop	af
	pop	af
;user_actions.c:140: strcat(cmd, filename);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	push	bc
	call	_strcat
	pop	af
	pop	af
;user_actions.c:141: RequestToExitAndExecuteCommandString(cmd);
	ld	hl,#0x0000
	add	hl,sp
	push	hl
	call	_RequestToExitAndExecuteCommandString
	pop	af
;user_actions.c:143: return TRUE;
	ld	l,#0x01
00103$:
	ld	sp,ix
	pop	ix
	ret
_request_to_exit_and_execute_command_with_filename_end::
;user_actions.c:147: BOOL f4_pressed(void)
;	---------------------------------
; Function f4_pressed
; ---------------------------------
_f4_pressed_start::
_f4_pressed:
;user_actions.c:149: const char *p = GetFilenameOfSelectedItem(&lview);
	ld	hl,#_lview
	push	hl
	call	_GetFilenameOfSelectedItem
	pop	af
	ld	b,h
	ld	c,l
;user_actions.c:150: if(!p) return FALSE;
	ld	a,c
	or	a,b
	jr	NZ,00102$
	ld	l,a
	ret
00102$:
;user_actions.c:154: if(IsSelectedItem_DIR(&lview))
	push	bc
	ld	hl,#_lview
	push	hl
	call	_IsSelectedItem_DIR
	pop	af
	ld	e,l
	pop	bc
	xor	a,a
	or	a,e
	jr	Z,00104$
;user_actions.c:155: return TRUE;
	ld	l,#0x01
	ret
00104$:
;user_actions.c:157: if(!request_to_exit_and_execute_command_with_filename("TEXTEDIT ", p))
	push	bc
	ld	hl,#__str_26
	push	hl
	call	_request_to_exit_and_execute_command_with_filename
	pop	af
	pop	af
;user_actions.c:158: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00106$
	ld	l,a
	ret
00106$:
;user_actions.c:161: return TRUE;
	ld	l,#0x01
	ret
_f4_pressed_end::
__str_26:
	.ascii "TEXTEDIT "
	.db 0x00
;user_actions.c:165: BOOL IsSelectedItem_DIR(ListView* pLview)
;	---------------------------------
; Function IsSelectedItem_DIR
; ---------------------------------
_IsSelectedItem_DIR_start::
_IsSelectedItem_DIR:
	push	ix
	ld	ix,#0
	add	ix,sp
;user_actions.c:167: char *p = ListView_GetSelectedItem(pLview);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ListView_GetSelectedItem
	pop	af
	ld	b,h
	ld	c,l
;user_actions.c:169: if(strstr(p, "[DIR]") != NULL)
	ld	hl,#__str_27
	push	hl
	push	bc
	call	_strstr
	pop	af
	pop	af
	ld	b,h
	ld	a,l
	or	a,b
	jr	Z,00102$
;user_actions.c:170: return TRUE;
	ld	l,#0x01
	jr	00104$
00102$:
;user_actions.c:172: return FALSE;
	ld	l,#0x00
00104$:
	pop	ix
	ret
_IsSelectedItem_DIR_end::
__str_27:
	.ascii "[DIR]"
	.db 0x00
;user_actions.c:182: const char* GetFilenameOfSelectedItem(ListView* pLview)
;	---------------------------------
; Function GetFilenameOfSelectedItem
; ---------------------------------
_GetFilenameOfSelectedItem_start::
_GetFilenameOfSelectedItem:
	push	ix
	ld	ix,#0
	add	ix,sp
;user_actions.c:187: char *p = ListView_GetSelectedItem(pLview);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ListView_GetSelectedItem
	pop	af
	ld	b,h
	ld	c,l
;user_actions.c:192: if(!extract_filename_from_buffer(p, filename))
	ld	hl,#_GetFilenameOfSelectedItem_filename_1_1
	push	hl
	push	bc
	call	_extract_filename_from_buffer
	pop	af
	pop	af
	xor	a,a
	or	a,l
	jr	NZ,00102$
;user_actions.c:193: return NULL;
	ld	hl,#0x0000
	jr	00103$
00102$:
;user_actions.c:195: return filename;
	ld	hl,#_GetFilenameOfSelectedItem_filename_1_1
00103$:
	pop	ix
	ret
_GetFilenameOfSelectedItem_end::
;user_actions.c:199: void print_box(byte x, byte y, byte w, byte h)
;	---------------------------------
; Function print_box
; ---------------------------------
_print_box_start::
_print_box:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;user_actions.c:203: for(i=0; i<h; i++) {
	ld	-1 (ix),#0x00
00105$:
	ld	a,-1 (ix)
	sub	a,7 (ix)
	jp	NC,00121$
;user_actions.c:204: FLOS_SetCursorPos(x, y+i); 
	ld	a,5 (ix)
	add	a,-1 (ix)
	ld	b,a
	push	bc
	inc	sp
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_FLOS_SetCursorPos
	pop	af
;user_actions.c:205: if(i == 0)   { for(j=0; j<w; j++) FLOS_PrintString("-"); continue; }
	xor	a,a
	or	a,-1 (ix)
	jr	NZ,00102$
	ld	b,#0x00
00109$:
	ld	a,b
	sub	a,6 (ix)
	jp	NC,00107$
	push	bc
	ld	hl,#__str_28
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
	inc	b
	jr	00109$
00102$:
;user_actions.c:206: if(i == h-1) { for(j=0; j<w; j++) FLOS_PrintString("-"); continue; }
	ld	e,7 (ix)
	ld	d,#0x00
	dec	de
	ld	c,-1 (ix)
	ld	b,#0x00
	ld	a,c
	sub	e
	jr	NZ,00137$
	ld	a,b
	sub	d
	jr	Z,00138$
00137$:
	jr	00104$
00138$:
	ld	c,#0x00
00113$:
	ld	a,c
	sub	a,6 (ix)
	jr	NC,00107$
	push	bc
	ld	hl,#__str_28
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
	inc	c
	jr	00113$
00104$:
;user_actions.c:207: FLOS_PrintString("+"); for(j=0; j<w-2; j++) FLOS_PrintString(" "); FLOS_PrintString("+");
	ld	hl,#__str_29
	push	hl
	call	_FLOS_PrintString
	pop	af
	ld	-2 (ix),#0x00
00117$:
	ld	e,6 (ix)
	ld	d,#0x00
	dec	de
	dec	de
	ld	c,-2 (ix)
	ld	b,#0x00
	ld	a,c
	sub	a,e
	ld	a,b
	sbc	a,d
	jp	P,00120$
	ld	hl,#__str_30
	push	hl
	call	_FLOS_PrintString
	pop	af
	inc	-2 (ix)
	jr	00117$
00120$:
	ld	hl,#__str_29
	push	hl
	call	_FLOS_PrintString
	pop	af
00107$:
;user_actions.c:203: for(i=0; i<h; i++) {
	inc	-1 (ix)
	jp	00105$
00121$:
	ld	sp,ix
	pop	ix
	ret
_print_box_end::
__str_28:
	.ascii "-"
	.db 0x00
__str_29:
	.ascii "+"
	.db 0x00
__str_30:
	.ascii " "
	.db 0x00
;user_actions.c:213: BOOL delete_dir_entry(void)
;	---------------------------------
; Function delete_dir_entry
; ---------------------------------
_delete_dir_entry_start::
_delete_dir_entry:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-6
	add	hl,sp
	ld	sp,hl
;user_actions.c:215: BOOL r = TRUE;
	ld	-5 (ix),#0x01
;user_actions.c:218: const char *p = GetFilenameOfSelectedItem(&lview);
	ld	hl,#_lview
	push	hl
	call	_GetFilenameOfSelectedItem
	pop	af
	ld	d,h
	ld	-4 (ix),l
	ld	-3 (ix),d
;user_actions.c:219: if(!p) return FALSE;
	ld	a,-4 (ix)
	or	a,-3 (ix)
	jr	NZ,00102$
	ld	l,#0x00
	jp	00111$
00102$:
;user_actions.c:221: if(strstr(p, "..") != NULL)
	ld	hl,#__str_31
	push	hl
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_strstr
	pop	af
	pop	af
	ld	e,h
	ld	a,l
	or	a,e
	jr	Z,00104$
;user_actions.c:222: return TRUE;
	ld	l,#0x01
	jp	00111$
00104$:
;user_actions.c:226: print_box(x, y, 20, 4+2);
	ld	hl,#0x0614
	push	hl
	ld	hl,#0x0101
	push	hl
	call	_print_box
	pop	af
	pop	af
;user_actions.c:227: FLOS_SetCursorPos(x+2, y+1);  FLOS_PrintString("Delete "); 
	ld	hl,#0x0203
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	ld	hl,#__str_32
	push	hl
	call	_FLOS_PrintString
	pop	af
;user_actions.c:228: FLOS_SetCursorPos(x+2, y+2);  FLOS_PrintString(p); 
	ld	hl,#0x0303
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
;user_actions.c:229: FLOS_SetCursorPos(x+2, y+3);
	ld	hl,#0x0403
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
;user_actions.c:230: FLOS_PrintString("Y/N ?"); 
	ld	hl,#__str_33
	push	hl
	call	_FLOS_PrintString
	pop	af
;user_actions.c:232: FLOS_WaitKeyPress(&asciicode, &scancode);
	ld	hl,#0x0004
	add	hl,sp
	ex	de,hl
	ld	hl,#0x0005
	add	hl,sp
	ld	c,l
	ld	b,h
	push	de
	push	bc
	call	_FLOS_WaitKeyPress
	pop	af
	pop	af
;user_actions.c:233: if(scancode == SC_Y) {
	ld	a,-2 (ix)
	sub	a,#0x35
	jr	NZ,00109$
;user_actions.c:236: if(IsSelectedItem_DIR(&lview))
	ld	hl,#_lview
	push	hl
	call	_IsSelectedItem_DIR
	pop	af
	xor	a,a
	or	a,l
	jr	Z,00106$
;user_actions.c:237: r = FLOS_DeleteDir(p);
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_FLOS_DeleteDir
	pop	af
	ld	-5 (ix),l
	jr	00107$
00106$:
;user_actions.c:239: r = FLOS_EraseFile(p);
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_FLOS_EraseFile
	pop	af
	ld	-5 (ix),l
00107$:
;user_actions.c:241: fill_ListView_by_entries_from_current_dir();
	call	_fill_ListView_by_entries_from_current_dir
	jr	00110$
00109$:
;user_actions.c:244: clear_area(lview.x, lview.y, lview.width, lview.height);     
	ld	hl,#_lview + 9
	ld	c,(hl)
	ld	de,#_lview + 8
	ld	a,(de)
	ld	b,a
	ld	de,#_lview + 7
	ld	a,(de)
	ld	-6 (ix),a
	ld	hl,#_lview + 6
	ld	e,(hl)
	ld	a,c
	push	af
	inc	sp
	push	bc
	inc	sp
	ld	a,-6 (ix)
	ld	d,a
	push	de
	call	_clear_area
	pop	af
	pop	af
00110$:
;user_actions.c:248: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
;user_actions.c:250: return r;
	ld	l,-5 (ix)
00111$:
	ld	sp,ix
	pop	ix
	ret
_delete_dir_entry_end::
__str_31:
	.ascii ".."
	.db 0x00
__str_32:
	.ascii "Delete "
	.db 0x00
__str_33:
	.ascii "Y/N ?"
	.db 0x00
;fs_walk.c:74: int main (void)
;	---------------------------------
; Function main
; ---------------------------------
_main_start::
_main:
;fs_walk.c:79: if(!check_OS_version()) {
	call	_check_OS_version
	xor	a,a
	or	a,l
	jr	NZ,00102$
;fs_walk.c:80: FLOS_PrintString("FLOS v");
	ld	hl,#__str_34
	push	hl
	call	_FLOS_PrintString
	pop	af
;fs_walk.c:81: _uitoa(OS_VERSION_REQ, buffer, 16);
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	ld	hl,#0x0560
	push	hl
	call	__uitoa
	pop	af
	pop	af
	inc	sp
;fs_walk.c:82: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;fs_walk.c:83: FLOS_PrintStringLFCR("+ req. to run this program");
	ld	hl,#__str_35
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;fs_walk.c:84: return NO_REBOOT;
	ld	hl,#0x0000
	ret
00102$:
;fs_walk.c:87: FLOS_StoreDirPosition();
	call	_FLOS_StoreDirPosition
;fs_walk.c:88: if(!load_config_file()) {
	call	_load_config_file
	xor	a,a
	or	a,l
	jr	NZ,00104$
;fs_walk.c:89: FLOS_PrintStringLFCR("Failed to load config file.");
	ld	hl,#__str_36
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;fs_walk.c:90: return NO_REBOOT;
	ld	hl,#0x0000
	ret
00104$:
;fs_walk.c:92: FLOS_RestoreDirPosition();
	call	_FLOS_RestoreDirPosition
;fs_walk.c:95: MarkFrameTime(0x00f);
	ld	hl,#0x000F
	push	hl
	call	_MarkFrameTime
	pop	af
;fs_walk.c:96: FLOS_ClearScreen();
	call	_FLOS_ClearScreen
;fs_walk.c:97: clear_keyboard_buffer();
	call	_clear_keyboard_buffer
;fs_walk.c:107: lview.width = 24; lview.height = 23;
	ld	a,#0x18
	ld	(#_lview + 8),a
	ld	a,#0x17
	ld	(#_lview + 9),a
;fs_walk.c:108: lview.x = 1;      lview.y = 1;
	ld	a,#0x01
	ld	(#_lview + 6),a
	ld	(#_lview + 7),a
;fs_walk.c:113: fill_ListView_by_entries_from_current_dir();
	call	_fill_ListView_by_entries_from_current_dir
;fs_walk.c:114: main_loop();
	call	_main_loop
;fs_walk.c:123: if(request_spawn_command)
	xor	a,a
	ld	hl,#_request_spawn_command + 0
	or	a,(hl)
	jr	Z,00106$
;fs_walk.c:124: return SPAWN_COMMAND;
	ld	hl,#0x00FE
	ret
00106$:
;fs_walk.c:126: return NO_REBOOT;
	ld	hl,#0x0000
	ret
_main_end::
__str_34:
	.ascii "FLOS v"
	.db 0x00
__str_35:
	.ascii "+ req. to run this program"
	.db 0x00
__str_36:
	.ascii "Failed to load config file."
	.db 0x00
;fs_walk.c:130: void fill_ListView_by_entries_from_current_dir(void)
;	---------------------------------
; Function fill_ListView_by_entries_from_current_dir
; ---------------------------------
_fill_ListView_by_entries_from_current_dir_start::
_fill_ListView_by_entries_from_current_dir:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;fs_walk.c:135: clear_area(lview.x, lview.y, lview.width, lview.height);
	ld	hl,#_lview + 9
	ld	c,(hl)
	ld	de,#_lview + 8
	ld	a,(de)
	ld	b,a
	ld	de,#_lview + 7
	ld	a,(de)
	ld	-1 (ix),a
	ld	hl,#_lview + 6
	ld	e,(hl)
	ld	a,c
	push	af
	inc	sp
	push	bc
	inc	sp
	ld	a,-1 (ix)
	ld	d,a
	push	de
	call	_clear_area
	pop	af
	pop	af
;fs_walk.c:137: clear_area(lview.x, lview.y + lview.height, lview.width, 1);
	ld	hl,#_lview + 8
	ld	c,(hl)
	ld	de,#_lview + 7
	ld	a,(de)
	ld	b,a
	ld	hl,#_lview + 9
	ld	e,(hl)
	ld	a,b
	add	a,e
	ld	b,a
	ld	hl,#_lview + 6
	ld	e,(hl)
	ld	a,#0x01
	push	af
	inc	sp
	ld	a,c
	push	af
	inc	sp
	push	bc
	inc	sp
	ld	a,e
	push	af
	inc	sp
	call	_clear_area
	pop	af
	pop	af
;fs_walk.c:140: tmp1[0] = 0;
	ld	bc,(_tmp1)
	ld	a,#0x00
	ld	(bc),a
;fs_walk.c:142: numStrings = do_dir();
	call	_do_dir
	ld	b,h
	ld	c,l
	ld	hl,#_numStrings + 0
	ld	(hl), c
	ld	hl,#_numStrings + 1
	ld	(hl), b
;fs_walk.c:143: mybuf = tmp1;       
	ld	bc,(_tmp1)
;fs_walk.c:145: lview.strArr = mybuf; 
	ld	hl,#_lview
	ld	(hl),c
	inc	hl
	ld	(hl),b
;fs_walk.c:146: lview.numItems = numStrings;
	ld	hl, #_lview + 2
	ld	a,(#_numStrings+0)
	ld	(hl),a
	inc	hl
	ld	a,(#_numStrings+1)
	ld	(hl),a
;fs_walk.c:147: lview.selectedIndex = 0;
	ld	hl, #_lview + 4
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;fs_walk.c:148: ListView_Init(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Init
	pop	af
;fs_walk.c:149: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
	ld	sp,ix
	pop	ix
	ret
_fill_ListView_by_entries_from_current_dir_end::
;fs_walk.c:153: void main_loop(void)
;	---------------------------------
; Function main_loop
; ---------------------------------
_main_loop_start::
_main_loop:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-5
	add	hl,sp
	ld	sp,hl
;fs_walk.c:159: asciicode = scancode = 0;
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
;fs_walk.c:160: while(scancode != SC_ESC && !request_exit) {
00130$:
	ld	a,-2 (ix)
	sub	a,#0x76
	jp	Z,00133$
	xor	a,a
	ld	hl,#_request_exit + 0
	or	a,(hl)
	jp	NZ,00133$
;fs_walk.c:161: FLOS_WaitKeyPress(&asciicode, &scancode);
	ld	hl,#0x0003
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0004
	add	hl,sp
	push	bc
	push	hl
	call	_FLOS_WaitKeyPress
	pop	af
	pop	af
;fs_walk.c:162: if(scancode == SC_DOWN || scancode == SC_PGDOWN) {
	ld	a,-2 (ix)
	sub	a,#0x72
	jr	Z,00104$
	ld	a,-2 (ix)
	sub	a,#0x7A
	jp	NZ,00105$
00104$:
;fs_walk.c:163: step = (scancode == SC_DOWN) ? 1 : 5;
	ld	a,-2 (ix)
	sub	a,#0x72
	jr	NZ,00135$
	ld	c,#0x01
	jr	00136$
00135$:
	ld	c,#0x05
00136$:
	ld	-5 (ix),c
;fs_walk.c:164: numitems      = ListView_GetNumItems(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_GetNumItems
	pop	af
;fs_walk.c:165: selectedIndex = ListView_GetSelectedIndex(&lview);
	push	hl
	ld	hl,#_lview
	push	hl
	call	_ListView_GetSelectedIndex
	pop	af
	ld	b,h
	ld	c,l
	pop	de
	ld	-4 (ix),c
	ld	-3 (ix),b
;fs_walk.c:167: if(selectedIndex + step < numitems) {
	ld	c,-5 (ix)
	ld	b,#0x00
	ld	a,-4 (ix)
	add	a,c
	ld	c,a
	ld	a,-3 (ix)
	adc	a,b
	ld	b,a
	ld	a,c
	sub	a,e
	ld	a,b
	sbc	a,d
	jr	NC,00102$
;fs_walk.c:168: ListView_SetSelectedIndex(&lview, selectedIndex+step);
	push	bc
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
	jr	00103$
00102$:
;fs_walk.c:170: ListView_SetSelectedIndex(&lview, numitems-1);
	ld	c,e
	ld	b,d
	dec	bc
	push	bc
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
00103$:
;fs_walk.c:171: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
00105$:
;fs_walk.c:174: if(scancode == SC_UP || scancode == SC_PGUP) {
	ld	a,-2 (ix)
	sub	a,#0x75
	jr	Z,00110$
	ld	a,-2 (ix)
	sub	a,#0x7D
	jp	NZ,00111$
00110$:
;fs_walk.c:175: step = (scancode == SC_UP) ? 1 : 5;
	ld	a,-2 (ix)
	sub	a,#0x75
	jr	NZ,00137$
	ld	c,#0x01
	jr	00138$
00137$:
	ld	c,#0x05
00138$:
	ld	-5 (ix),c
;fs_walk.c:176: numitems      = ListView_GetNumItems(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_GetNumItems
	pop	af
;fs_walk.c:177: selectedIndex = ListView_GetSelectedIndex(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_GetSelectedIndex
	pop	af
	ld	b,h
	ld	-4 (ix),l
	ld	-3 (ix),b
;fs_walk.c:179: if(selectedIndex >= step ) {
	ld	c,-5 (ix)
	ld	b,#0x00
	ld	a,-4 (ix)
	sub	a,c
	ld	a,-3 (ix)
	sbc	a,b
	jr	C,00108$
;fs_walk.c:180: ListView_SetSelectedIndex(&lview, selectedIndex-step);
	ld	c,-5 (ix)
	ld	b,#0x00
	ld	a,-4 (ix)
	sub	a,c
	ld	c,a
	ld	a,-3 (ix)
	sbc	a,b
	ld	b,a
	push	bc
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
	jr	00109$
00108$:
;fs_walk.c:182: ListView_SetSelectedIndex(&lview, 0);
	ld	hl,#0x0000
	push	hl
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
00109$:
;fs_walk.c:183: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
00111$:
;fs_walk.c:187: if(scancode == SC_HOME) {
	ld	a,-2 (ix)
	sub	a,#0x6C
	jr	NZ,00114$
;fs_walk.c:188: ListView_SetSelectedIndex(&lview, 0);
	ld	hl,#0x0000
	push	hl
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
;fs_walk.c:189: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
00114$:
;fs_walk.c:192: if(scancode == SC_END) {
	ld	a,-2 (ix)
	sub	a,#0x69
	jr	NZ,00116$
;fs_walk.c:193: numitems = ListView_GetNumItems(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_GetNumItems
	pop	af
	ld	b,h
	ld	c,l
;fs_walk.c:194: ListView_SetSelectedIndex(&lview, numitems-1);
	dec	bc
	push	bc
	ld	hl,#_lview
	push	hl
	call	_ListView_SetSelectedIndex
	pop	af
	pop	af
;fs_walk.c:195: ListView_Update(&lview);
	ld	hl,#_lview
	push	hl
	call	_ListView_Update
	pop	af
00116$:
;fs_walk.c:198: if(scancode == SC_F4) {
	ld	a,-2 (ix)
	sub	a,#0x0C
	jr	NZ,00120$
;fs_walk.c:199: if(!f4_pressed())
	call	_f4_pressed
	xor	a,a
	or	a,l
	jr	NZ,00120$
;fs_walk.c:200: MarkFrameTime(0xf00);   // set pal zero color to red, if error
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
00120$:
;fs_walk.c:203: if(scancode == SC_F8) {
	ld	a,-2 (ix)
	sub	a,#0x0A
	jr	NZ,00124$
;fs_walk.c:204: if(!delete_dir_entry())
	call	_delete_dir_entry
	xor	a,a
	or	a,l
	jr	NZ,00124$
;fs_walk.c:205: MarkFrameTime(0xf00);   // set pal zero color to red, if error
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
00124$:
;fs_walk.c:211: if(scancode == SC_ENTER) {
	ld	a,-2 (ix)
	sub	a,#0x5A
	jp	NZ,00130$
;fs_walk.c:212: if(!enter_pressed())
	call	_enter_pressed
	xor	a,a
	or	a,l
	jp	NZ,00130$
;fs_walk.c:213: MarkFrameTime(0xf00);   // set pal zero color to red, if error
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	jp	00130$
00133$:
	ld	sp,ix
	pop	ix
	ret
_main_loop_end::
;fs_walk.c:225: void clear_area(byte x, byte y, byte width, byte height)
;	---------------------------------
; Function clear_area
; ---------------------------------
_clear_area_start::
_clear_area:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;fs_walk.c:229: for(cur_y=y; cur_y<y+height; cur_y++) {
	ld	c,5 (ix)
00105$:
	ld	a,5 (ix)
	ld	-2 (ix),a
	ld	-1 (ix),#0x00
	ld	b,7 (ix)
	ld	e,#0x00
	ld	a,-2 (ix)
	add	a,b
	ld	-2 (ix),a
	ld	a,-1 (ix)
	adc	a,e
	ld	-1 (ix),a
	ld	d,c
	ld	b,#0x00
	ld	a,d
	sub	a,-2 (ix)
	ld	a,b
	sbc	a,-1 (ix)
	jp	P,00109$
;fs_walk.c:230: for(cur_x=x; cur_x<x+width; cur_x++) {
	ld	b,4 (ix)
00101$:
	ld	a,4 (ix)
	ld	-2 (ix),a
	ld	-1 (ix),#0x00
	ld	e,6 (ix)
	ld	d,#0x00
	ld	a,-2 (ix)
	add	a,e
	ld	-2 (ix),a
	ld	a,-1 (ix)
	adc	a,d
	ld	-1 (ix),a
	ld	e,b
	ld	d,#0x00
	ld	a,e
	sub	a,-2 (ix)
	ld	a,d
	sbc	a,-1 (ix)
	jp	P,00107$
;fs_walk.c:231: FLOS_SetCursorPos(cur_x, cur_y);
	push	bc
	ld	a,c
	push	af
	inc	sp
	push	bc
	inc	sp
	call	_FLOS_SetCursorPos
	pop	af
	pop	bc
;fs_walk.c:232: FLOS_PrintString(" "); 
	push	bc
	ld	hl,#__str_37
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;fs_walk.c:230: for(cur_x=x; cur_x<x+width; cur_x++) {
	inc	b
	jr	00101$
00107$:
;fs_walk.c:229: for(cur_y=y; cur_y<y+height; cur_y++) {
	inc	c
	jp	00105$
00109$:
	ld	sp,ix
	pop	ix
	ret
_clear_area_end::
__str_37:
	.ascii " "
	.db 0x00
;fs_walk.c:239: BOOL check_OS_version(void)
;	---------------------------------
; Function check_OS_version
; ---------------------------------
_check_OS_version_start::
_check_OS_version:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;fs_walk.c:243: FLOS_GetVersion(&os_version_word, &hw_version_word);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0002
	add	hl,sp
	push	bc
	push	hl
	call	_FLOS_GetVersion
	pop	af
	pop	af
;fs_walk.c:248: if(os_version_word < OS_VERSION_REQ)
	ld	a,-2 (ix)
	sub	a,#0x60
	ld	a,-1 (ix)
	sbc	a,#0x05
	jr	NC,00102$
;fs_walk.c:249: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;fs_walk.c:251: return TRUE;
	ld	l,#0x01
00103$:
	ld	sp,ix
	pop	ix
	ret
_check_OS_version_end::
;fs_walk.c:254: void clear_keyboard_buffer(void) {
;	---------------------------------
; Function clear_keyboard_buffer
; ---------------------------------
_clear_keyboard_buffer_start::
_clear_keyboard_buffer:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;fs_walk.c:257: while( FLOS_GetKeyPress(&ASCII, &Scancode) );
00101$:
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0001
	add	hl,sp
	push	bc
	push	hl
	call	_FLOS_GetKeyPress
	pop	af
	pop	af
	xor	a,a
	or	a,l
	jr	NZ,00101$
	ld	sp,ix
	pop	ix
	ret
_clear_keyboard_buffer_end::
	.area _CODE
	.area _CABS
