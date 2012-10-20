;****************************************************
; FLOS File Manager by Phil @ Retroleum.co.uk - V0.04
;****************************************************

;Updates:
;--------

;V0.04 - Uses new window draw code (FLOS 6.02+)
;
;v0.03 - Added "RX" button to receive files via Serial Link, requires Serial Link 2.8
;        for complete compatibility (EG: Handling file overwrite)
;
;      - Fixed path display code (was inserting "/../" when not needed)
;
;      - Tab swaps panels, CTRL selects buttons.
;
;      - Improved text entry code.
;
;      - Fixed unhandled attempts at copying a file with same name as a dir
;
;      - Tests if MOVE has deleted the folder FLOS was originally in (back to root on exit)


;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000


;--------- Test FLOS version ---------------------------------------------------------------------

required_flos       equ $602
include             "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;-----------------------------------------------------------------------------------------------

plain_colour                  equ $07   ;blue / yellow
highlight_unselected_colour   equ $70   ;yellow / blue

unhighlight_selected_colour   equ $d8   ;lt blue / white
highlight_selected_colour     equ $8d   ;white / lt blue

box_select_colour             equ $80   ; white / blue

file_buffer_length            equ $8000
file_buffer_bank              equ 0

window_cols                   equ 40
window_rows                   equ 25


;--------------------------------------------------------------------------------------------
          
          call w_backup_display
          call kjt_get_cursor_position
          ld (orig_cursor),bc
          
          call kjt_get_volume_info
          ld (original_volume),a
          call kjt_get_dir_cluster
          ld (original_cluster),de
          
          
;--------- Initialize ------------------------------------------------------------------------

begin     call kjt_get_dir_cluster
          ld (src_dir_cluster),de
          
          call kjt_root_dir
          call kjt_get_dir_cluster
          ld (root_cluster),de
          ld (dst_dir_cluster),de
          call go_src_folder
          
;-----------------------------------------------------------------------------------------------
          
redraw_all

          call clear_selection_list
          call draw_file_manager_window
          xor a
          ld (src_dir_sel_pos),a
          ld (dst_dir_sel_pos),a
          ld (ops_activated),a
          
;----------------------------------------------------------------------------------------------
; Main loop - Handle GUI control
;-----------------------------------------------------------------------------------------------

gui_main_loop

          ld a,(src_dst_target)
          add a,2
          call w_set_element_selection
          call highlight_selected_element
          
          ld a,(ops_activated)
          or a
          jr z,no_ops
          ld a,(op_box)
          add a,4
          call w_set_element_selection
          call highlight_box
          
no_ops    call wait_border

          call unhighlight_selected_element
          ld a,(src_dst_target)
          add a,2
          call w_set_element_selection
          call unhighlight_selected_element
                    
          
          call kjt_get_key
          ld (req_current_scancode),a
          ld a,b
          ld (req_current_ascii_char),a 


          ld a,(req_current_scancode)                       ;action for keys in main window
          cp $0d
          jp z,req0_tab_pressed
          cp $72
          jp z,req0_down_pressed
          cp $75
          jp z,req0_up_pressed
          cp $5a
          jp z,req0_enter_pressed
          cp $29
          jp z,req0_space_pressed
          cp $74
          jp z,req0_right_pressed
          cp $6b
          jp z,req0_left_pressed
          cp $76
          jp z,req0_esc_pressed
          cp $14
          jp z,req0_ctrl_pressed
          
          jp gui_main_loop


;----------------------------------------------------------------------------------------------
; Simple Error Window - Wait for Enter/Esc and quit  
;-----------------------------------------------------------------------------------------------

error_window_loop

          call common_window_code
                    
          ld a,(req_current_scancode)                       ;escape from this subroutine is ESC or Enter pressed
          cp $5a
          ret z     
          cp $76
          ret z
          jp error_window_loop

;----------------------------------------------------------------------------------------------
; Yes/No Window - Wait for selection and quit  
;-----------------------------------------------------------------------------------------------

yesno_window_loop

          call common_window_code
                    
          ld a,(req_current_scancode)                       
          cp $0d
          jr nz,yn_ntab
          call w_get_element_selection                      ;if tab pressed swap selection between yes and no buttons
          inc a
          cp 4
          jr nz,yn_nmel
          ld a,2
yn_nmel   call w_set_element_selection
          jr yesno_window_loop
          
          
yn_ntab   ld a,(req_current_scancode)                       ;escape from this subroutine is ESC or Enter pressed
          cp $5a
          jr nz,yn_noent
          call w_get_element_selection
          sub 2                                             ;exits with A = 0/1 = no/yes
          xor 1
          ret       
                    
yn_noent  cp $76                                            ;ESC exits with A = FF = aborted
          jr nz,yesno_window_loop
          ld a,$ff
          or a
          ret
          

;-----------------------------------------------------------------------------------------------
; ASCII input subroutine
;-----------------------------------------------------------------------------------------------

init_text_input

          call w_get_selected_element_coords
          ld (text_input_coord_base),bc
          call w_get_selected_element_data_location
          ld a,(ix+1)
          ld (max_cursor),a
          xor a
          ld (req_ti_cursor),a
          
          
text_input_loop

          ld bc,(text_input_coord_base)
          ld a,(max_cursor)
          ld e,a
          ld a,(req_ti_cursor)
          cp e
          jr nz,curpok
          dec a
curpok    add a,b
          ld b,a
          call kjt_set_cursor_position            
          ld hl,$1000
          call kjt_draw_cursor                    ;draw cursor

no_cursor_draw

          call wait_border

          ld hl,0
          call kjt_draw_cursor                    ;remove cursor

          call kjt_get_key
          ld (req_current_scancode),a
          ld a,b
          ld (req_current_ascii_char),a
          
          ld a,(req_current_scancode)
          cp $76
          jp z,ascii_esc_pressed
          cp $5a
          jp z,ascii_enter_pressed
          cp $66
          jp z,ascii_bs_pressed
          cp $71
          jp z,ascii_del_pressed
          cp $74
          jp z,ascii_right_pressed
          cp $6b
          jp z,ascii_left_pressed

          ld a,(req_current_ascii_char)           ;an ascii key pressed?
          or a
          jp z,text_input_loop

          call w_get_selected_element_data_location
          ld a,(req_ti_cursor)                    
          cp (ix+1)                               ;cant enter more text if at end of line
          jr nz,req_nae
          dec a
          ld (req_ti_cursor),a
req_nae   call req_ascii_cursor_pos
          ld a,(req_current_ascii_char)
          cp $60                                  ;Entered text converted to capitals
          jr c,req_loca
          sub $20
req_loca  call kjt_plot_char
          ld hl,req_ti_cursor                     ;move cursor along
          inc (hl)
req_nai   jp text_input_loop
          

req_ascii_cursor_pos

          call w_get_selected_element_coords
          ld a,(req_ti_cursor)
          add a,b
          ld b,a
          ret


ascii_bs_pressed

          ld a,(req_ti_cursor)                    ;cant move back if cursor at 0
          or a
          jp z,text_input_loop
          ld hl,req_ti_cursor                     ;move back and put a space at current location
          dec (hl)

ascii_del_pressed
          
          call req_ascii_cursor_pos
          call kjt_set_cursor_position
          call kjt_get_charmap_addr_xy
          inc hl
          ld a,(req_ti_cursor)
          ld e,a
          ld a,(max_cursor)
          cp e
          jp z,text_input_loop
          inc e
          inc e
delchars  ld a,(max_cursor)
          cp e
          jr c,chmdone
          ld a,(hl) 
          call kjt_plot_char
          inc hl
          inc b
          inc e
          jr delchars
chmdone   ld a,32
          call kjt_plot_char
          jp text_input_loop
          
          
ascii_enter_pressed


          ld hl,supplied_ascii                    ; clear input string
          ld bc,40
          ld a,32
          call kjt_bchl_memfill                   
          call w_get_selected_element_data_location
          ld c,(ix+1)                             ; c = width of text entry box
          push bc
          call w_get_selected_element_coords
          call kjt_get_charmap_addr_xy            ; hl = address of chars on screen
          pop bc
          ld de,supplied_ascii
          ld b,0                                  ; copy the chars from charmap to ascii string
          ldir
          ld hl,supplied_ascii+39                 ; null terminate the ascii string (reverse look for non-space char
          ld b,40                                 ; and put zero after it)
getnspch  ld a,(hl)
          cp 32
          jr nz,ai_fnsch
          dec hl
          djnz getnspch
ai_fnsch  inc hl
          ld (hl),0
          xor a
          ret                                     ; end of ascii loop, a = ok, chars entered are in "supplied ascii" buffer
          

ascii_esc_pressed

          ld a,1
          or a
          ret                                     ; end of ascii loop, a = 1, Aborted (pressed escape)
          
          
ascii_left_pressed

          ld a,(max_cursor)
          ld e,a
          ld a,(req_ti_cursor)                    ;cant move back if cursor at 0
          cp e
          jr nz,asinar
          dec a
asinar    or a
          jp z,text_input_loop
          dec a
          ld (req_ti_cursor),a
          jp text_input_loop
          
          
          
ascii_right_pressed
          
          ld a,(max_cursor)
          ld e,a
          ld a,(req_ti_cursor)
          cp e
          jp z,text_input_loop
          inc a
          ld (req_ti_cursor),a
          jp text_input_loop
                    
          
;----------------------------------------------------------------------------------------------

common_window_code

          call highlight_box
          call wait_border
          call unhighlight_selected_element
          
          call kjt_get_key
          ld (req_current_scancode),a
          ld a,b
          ld (req_current_ascii_char),a 
          ret
          

;----------------------------------------------------------------------------------------------
copy_files
;----------------------------------------------------------------------------------------------

          call test_selections
          jp z,no_selections

          call test_src_dst
          jp z,same_src_dst

          call go_src_folder

          ld a,1                                  ;show "copying.." window
          ld b,11
          ld c,8
          ld e,0
          call req_draw_window

          ld a,0
          ld (directory_level),a                  ;initial depth of dir tree from selected top level (NOT root)

topofdir  ld bc,0
          call set_dir_step_for_level             ;start from top of this dir
          
dir_scan  call find_dir_entry_bc                  ;returns: HL = filename / B = dir flag  
          jr z,de_ok
          cp $24
          jp z,endofdir
          jp disk_error

de_ok     push bc
          call get_dir_step_for_level
          call is_step_selected
          pop bc
          jp z,nxt_ent                            ;ZF set means entry is not selected
          
          ld a,(hl)                               ;if entry starts with "." it is ignored
          cp "."
          jr z,nxt_ent
          push bc                                 ;cache the filename string.
          ld de,filename
          ld bc,12
          ldir
          pop bc
          
          call show_filename
          push bc
          call kjt_get_key
          pop bc
          cp $76
          jp z,abort          

          bit 0,b                                 ;is this entry a directory?
          jr z,fc_nadir                           

          ld hl,filename                          ;if so change to it at source
          call kjt_change_dir                     
          jp nz,disk_error                        
          call note_src_cluster
          ld a,(directory_level)                  ;increase directory level
          inc a
          ld (directory_level),a                  

          ld a,(src_vol)                          ;make sure we're not attempting to copy overlapping dirs
          ld hl,dst_vol                           ;as this would create an infinite loop
          cp (hl)
          jr nz,cf_sdfd
          call kjt_get_dir_cluster                
          ld (compare_cluster),de                 
          call go_dst_folder                      
cf_nfit   call kjt_get_dir_cluster                ;track back to root, if one of the branches of the
          ld hl,(compare_cluster)                 ;dest dir tree matches the source, then abort the copy
          xor a
          sbc hl,de
          jp z,same_src_dst
          call kjt_parent_dir
          jr z,cf_nfit
          call go_dst_folder                      ;restore the original cluster position

cf_sdfd   call disk_op_create_dest_dir            ;ok to create folder at destination (and move to it)
          jp nz,disk_error
          call note_dst_cluster                   ;note the new dest position
          call go_src_folder
          jp topofdir                             ;start at top of new dir
          
fc_nadir  call disk_op_copy_file                  ;do a file copy
          or a
          jr z,dofc_ok
          cp 6
          jp nz,disk_error
          ld hl,filename_used_txt                 ;if error 6, filename is used by a directory - abort
          call show_error_window
          jp redraw_all
                    
dofc_ok   call go_src_folder
          
nxt_ent   call get_dir_step_for_level             ;move to next entry in directory
          inc bc
          call set_dir_step_for_level
          call kjt_dir_list_next_entry            ;get next dir entry
          jp z,de_ok                              
          cp $24                                  ;at end of directory?
          jp nz,disk_error
endofdir  ld a,(directory_level)                  ;if this is the end of the *top level*, operation is complete
          or a
          jr z,copy_done
          dec a                                   ;otherwise go up a level on directory tree
          ld (directory_level),a
          call get_dir_step_for_level             ;move down to next step in parent dir (after coming out of the
          inc bc                                  ;current folder)
          call set_dir_step_for_level
          call kjt_parent_dir                     ;go to parent dir at dest
          jp nz,disk_error
          call note_src_cluster

          call go_dst_folder                      ;go to parent dir at dest too
          call kjt_parent_dir
          jp nz,disk_error
          call note_dst_cluster                   ;note the new position
          call go_src_folder
          call get_dir_step_for_level             ;get dir pos in BC for loop around
          jp dir_scan

copy_done jp redraw_all


;----------------------------------------------------------------------------------------------
delete_files
;----------------------------------------------------------------------------------------------

          call test_selections
          jp z,no_selections

          call go_src_folder

          ld a,3                                  ;show "deleting.." window
          ld b,11
          ld c,8
          ld e,0
          call req_draw_window

          ld a,0
          ld (directory_level),a                  ;initial depth of dir tree from selected top level (NOT root)

df_topofdir

          ld bc,0
          call set_dir_step_for_level             ;start from top of this dir
          
df_dir_scan

          call find_dir_entry_bc                  ;returns: HL = filename / B = dir flag  
          jr z,df_de_ok
          cp $24
          jp z,df_endofdir
          jp disk_error

df_de_ok  push bc
          call get_dir_step_for_level
          call is_step_selected
          pop bc
          jr nz,df_eisel                          ;ZF not set means entry is selected

df_dot    call inc_dir_step                       ;increment in-dir entry counter
          call kjt_dir_list_next_entry            ;move down dir, returns: HL = filename / B = dir flag       
          jr z,df_de_ok
          cp $24
          jr z,df_endofdir
          jp disk_error                           ;loop until find a selected entry / end of dir
          
df_eisel  ld a,(hl)                               ;if entry starts with "." it is ignored 
          cp "."                                  ;ideally needs changing to test for "." and ".." only
          jr z,df_dot
          
          push bc                                 ;cache the filename string.
          ld de,filename
          ld bc,12
          ldir
          pop bc
          
          call show_filename                      ;show it
          push bc
          call kjt_get_key                        ;abort at this point?
          pop bc
          cp $76
          jp z,abort          

          bit 0,b                                 ;is this entry a directory?
          jr z,df_nadir                           
          ld hl,filename                          ;if so change to it
          call kjt_change_dir                     
          jp nz,disk_error                        
          ld a,(directory_level)                  ;increase directory level
          inc a
          ld (directory_level),a                  
          jp df_topofdir                          ;start a new scan at top of new dir
          
df_nadir  call disk_op_delete_file                ;if not a dir then delete file
          jp nz,disk_error
          call adjust_selections                  ;remove the selection just deleted (if at top of tree)
          
df_nxt_ent

          call kjt_dir_list_next_entry            ;get next dir entry (step is the same as file above was deleted)
          jp z,df_de_ok                           
          cp $24                                  ;at end of this directory?
          jp nz,disk_error

df_endofdir

          ld a,(directory_level)                  ;if this is the end of the *top level*, operation is complete
          or a
          jp z,delete_done
          dec a                                   ;otherwise go up a level on directory tree
          ld (directory_level),a

          call kjt_get_dir_cluster
          ld (deleted_dir_cluster),de
          
          call kjt_parent_dir                     ;go to parent dir
          jp nz,disk_error
          call get_dir_step_for_level             ;find name of the dir we were just in
          call find_dir_entry_bc
          jp nz,disk_error
          ld de,filename
          ld bc,12
          ldir
          call disk_op_remove_dir                 ;and remove the dir
          jp nz,disk_error
          ld hl,(dst_dir_cluster)                 ;have we deleted the folder that the destination panel was at?
          ld de,(deleted_dir_cluster)
          xor a
          sbc hl,de
          jr nz,df_nddf
          ld hl,(root_cluster)                    ;if so set the dest folder at root
          ld (dst_dir_cluster),hl

df_nddf   ld hl,(original_cluster)                ;have we deleted the dir where FLOS was originally at?
          ld de,(deleted_dir_cluster)
          xor a
          sbc hl,de
          jr nz,df_ndoc
          ld a,(original_volume)
          ld hl,current_vol
          cp (hl)
          jr nz,df_ndoc
          ld de,(root_cluster)                    ;if so, reset original FLOS dir to root
          ld (original_cluster),de

df_ndoc   call adjust_selections                  ;remove the selection just deleted (if at top of tree)
          call get_dir_step_for_level             ;because files have effectively moved up a place, leave step as is
          jp df_dir_scan      

deleted_done

          jp redraw_all

          
inc_dir_step

          call get_dir_step_for_level             ;move along to next entry in directory
          inc bc
          call set_dir_step_for_level
          ret       


adjust_selections
          
          ld a,(directory_level)                  ;if at top level move selections up one place from current place
          or a                                    ;to correct for the file/directory just deleted
          ret nz
          call get_dir_step_for_level
          ld hl,selection_list
          add hl,bc
          push hl
          pop de
          inc hl
          push hl
          ld hl,$100
          xor a
          sbc hl,bc
          push hl
          pop bc
          pop hl
          ldir
          ret
          
          
delete_done

          jp redraw_all

;----------------------------------------------------------------------------------------------
move_files
;----------------------------------------------------------------------------------------------

          call test_selections
          jp z,no_selections

          call test_src_dst
          jp z,same_src_dst

          call go_src_folder

          ld a,2                                  ;show "moving.." window
          ld b,11
          ld c,8
          ld e,0
          call req_draw_window

          ld a,0
          ld (directory_level),a                  ;initial depth of dir tree from selected top level (NOT root)

mf_topofdir

          ld bc,0
          call set_dir_step_for_level             ;start from top of this dir
          
mf_dir_scan

          call find_dir_entry_bc                  ;returns: HL = filename / B = dir flag  
          jr z,mf_de_ok
          cp $24
          jp z,mf_endofdir
          jp disk_error

mf_de_ok  push bc
          call get_dir_step_for_level
          call is_step_selected
          pop bc
          jr nz,mf_eisel                          ;ZF not set means entry is selected

mf_dot    call get_dir_step_for_level             ;move to next entry in directory
          inc bc
          call set_dir_step_for_level
          call kjt_dir_list_next_entry            ;get next dir entry
          jr z,mf_de_ok
          cp $24
          jp z,mf_endofdir
          jp disk_error                           ;loop until find a selected entry / end of dir
          
mf_eisel  ld a,(hl)                               ;if entry starts with "." it is ignored (skip "." and "..")
          cp "."
          jr z,mf_dot
          
          push bc                                 ;cache the filename string.
          ld de,filename
          ld bc,12
          ldir
          pop bc
          
          call show_filename
          push bc
          call kjt_get_key
          pop bc
          cp $76
          jp z,abort          

          bit 0,b                                 ;is this entry a directory?
          jr z,mf_nadir                           

          ld hl,filename                          ;if so change to it at source
          call kjt_change_dir                     
          jp nz,disk_error                        
          call note_src_cluster
          ld a,(directory_level)                  ;increase directory level
          inc a
          ld (directory_level),a                  

          ld a,(src_vol)                          ;make sure we're not attempting to move overlapping dirs
          ld hl,dst_vol                           
          cp (hl)
          jr nz,mf_sdfd
          call kjt_get_dir_cluster                
          ld (compare_cluster),de                 
          call go_dst_folder                      
mf_nfit   call kjt_get_dir_cluster                ;track back to root, if one of the branches of the
          ld hl,(compare_cluster)                 ;dest dir tree matches the source, then abort the copy
          xor a
          sbc hl,de
          jp z,same_src_dst
          call kjt_parent_dir
          jr z,mf_nfit
          call go_dst_folder                      ;restore the original cluster position

mf_sdfd   call disk_op_create_dest_dir            ;ok to create dir at destination (and move to it)
          jp nz,disk_error                        ;(if it already exists, so be it)
          call note_dst_cluster                   ;note the new dest position
          call go_src_folder
          jp mf_topofdir                          ;start a new scan at top of new dir
          
mf_nadir  call disk_op_copy_file                  ;if not a dir, just copy the file...
          jr z,mffc_ok
          cp 6
          jp nz,disk_error
          ld hl,filename_used_txt                 ;if error 6, filename is used by a directory - abort
          call show_error_window
          jp redraw_all
mffc_ok   call go_src_folder
          call disk_op_delete_file                ;..then delete it at source
          jp nz,disk_error
          call adjust_selections                  ;remove the selection just deleted (if at top of tree)
          
mf_nxt_ent

          call kjt_dir_list_next_entry            ;get next dir entry (step is the same as file above was deleted)
          jp z,mf_de_ok                           
          cp $24                                  ;at end of directory?
          jp nz,disk_error

mf_endofdir

          ld a,(directory_level)                  ;if this is the end of the *top level*, operation is complete
          or a
          jr z,move_done
          dec a                                   ;otherwise go up a level on directory tree
          ld (directory_level),a
          
          call kjt_get_dir_cluster
          ld (deleted_dir_cluster),de

          call kjt_parent_dir                     ;go to parent (source) dir
          jp nz,disk_error
          call get_dir_step_for_level             ;find name of this parent dir
          call find_dir_entry_bc
          jp nz,disk_error
          ld de,filename
          ld bc,12
          ldir
          call disk_op_remove_dir                 ;and remove the dir
          jp nz,disk_error
          
          ld hl,(original_cluster)                ;have we deleted the dir where FLOS was originally at?
          ld de,(deleted_dir_cluster)
          xor a
          sbc hl,de
          jr nz,mf_ndoc
          ld a,(original_volume)
          ld hl,current_vol
          cp (hl)
          jr nz,mf_ndoc
          ld de,(root_cluster)                    ;if so, reset original FLOS dir to root
          ld (original_cluster),de

mf_ndoc   call note_src_cluster
          call go_dst_folder                      ;go to parent dir at dest too
          call kjt_parent_dir
          jp nz,disk_error
          call note_dst_cluster                   ;note the new position
          call go_src_folder
          call adjust_selections                  ;remove the selection just deleted (if at top of tree)
          call get_dir_step_for_level             ;because files have effectively moved up a place, leave step as is
          jp mf_dir_scan      

move_done jp redraw_all


;----------------------------------------------------------------------------------------------
rename_files
;----------------------------------------------------------------------------------------------

          call test_selections
          jp z,no_selections

          call go_src_folder

          ld a,0
          ld (directory_level),a                  ;initial depth of dir tree from selected top level (NOT root)

rf_topofdir         
          
          ld bc,0
          call set_dir_step_for_level             ;start from top of this dir
          
rf_dir_scan

          call find_dir_entry_bc                  ;returns: HL = filename / B = dir flag  
          jr z,rf_de_ok
          cp $24
          jp z,rf_endofdir
          jp disk_error

rf_de_ok  call get_dir_step_for_level
          call is_step_selected
          jr z,rf_nxt_ent                         ;ZF set means entry is not selected
          
          ld de,filename                          ;cache the filename string.
          ld bc,12
          ldir

rename_prompt

          ld a,6                                  ;show "rename.." window
          ld b,11
          ld c,8
          ld e,1
          call req_draw_window
          call show_filename

          call init_text_input                    ;get new name ascii string

          jr nz,file_rename_abort
          ld hl,filename
          ld de,supplied_ascii          
          ld a,(de)                               ;if supplied filename first char is null or space
          cp 33                                   ;abort the rename
          jr c,file_rename_abort
          push hl
          push de
fn_comp   ld a,(de)                               ;if the supplied filename is the same as the original
          cp 33                                   ;abort the rename
          jr c,file_rename_abort
          cp (hl)
          jr nz,fn_diff
          inc hl
          inc de
          jr fn_comp
fn_diff   pop de
          pop hl
          
          call kjt_rename_file
          jr z,rf_nxt_ent
          cp 9                                    ;if filename exists show error requester
          jp nz,disk_error
          ld hl,filename_exists_txt
          call show_error_window

retry_rename

          call draw_file_manager_window
          call go_src_folder
          call get_dir_step_for_level
          call find_dir_entry_bc
          jr rename_prompt
          

file_rename_abort
          
rf_nxt_ent

          call get_dir_step_for_level             ;move to next entry in directory
          inc bc
          call set_dir_step_for_level
          call kjt_dir_list_next_entry            ;get next dir entry
          jp z,rf_de_ok                           
          cp $24                                  ;at end of directory?
          jp nz,disk_error

rf_endofdir

          jp redraw_all

;---------------------------------------------------------------------------------------------
make_a_dir
;---------------------------------------------------------------------------------------------

          ld b,4                                  ; position window on left or right depending
          ld a,(src_dst_target)                   ; whether src or dst is the target
          or a
          jr z,md_src
          ld b,20
md_src    ld a,5                                  ; set 'new dir name' window active
          ld c,8
          ld e,1                                  ; set element selection = 1
          call req_draw_window
          
          call init_text_input
          jr nz,new_dir_end
          
          call go_src_folder                      ;choose appropriate target "window"
          ld a,(src_dst_target)
          or a
          call nz,go_dst_folder
          
          ld hl,supplied_ascii
          ld a,(hl)                               ;if supplied filename first char is null or space, abort
          cp 33                                   
          jr c,new_dir_end

          call kjt_make_dir
          jr z,new_dir_end
          cp 9                                    ;if filename exists show error requester
          jp nz,disk_error
          ld hl,filename_exists_txt
          call show_error_window

          
new_dir_end

          jp redraw_all                           ;aborted

                    
;--------------------------------------------------------------------------------------------------------
rs232_receive
;--------------------------------------------------------------------------------------------------------

          call go_src_folder                      ;choose appropriate target "window"
          ld a,(src_dst_target)
          or a
          call nz,go_dst_folder

          in a,(sys_serial_port)                  ; flush serial buffer at start

          call show_main_rx_window
          call req_rs232_say_waiting
          call highlight_box  
          call wait_no_enter

          
req_rs232_header_wait

          ld hl,wildcard_txt                      ; filename address of * wildcard
          ld a,$c5                                ; time out = 5 seconds or with ESC/ENTER key
          call kjt_serial_receive_header
          jr z,rx_go                              ; file header loaded ok?
          cp $14                                  ; only a time-out error?
          jr z,req_rs232_header_wait              ; otherwise say "serial error" and quit the serial download
          cp $2a
          jp z,rs232exit
ser_err   call req_rs232_say_error                ; when the cancel button is pressed
          call error_window_loop
rs232exit call wait_no_enter                      ; quit rs232 receive mode
          jp redraw_all       


rx_go     push ix                                 ; copy filename and convert to uppercase
          ld hl,serial_filename
          ld bc,14
          xor a
          call kjt_bchl_memfill
          pop hl
          ld de,serial_filename         
          ld b,8
s_tuclp   ld a,(hl)                                         
gdot      cp $21
          jr c,gotsfn         
          call uppercasify
          ld (de),a
          inc hl
          inc de
          cp "."
          jr z,pdot
          djnz s_tuclp
          ld b,h
          ld c,l
fdotlp    ld a,(hl)
          inc hl
          cp "."
          jr z,gotdot
          cp $21
          jr nc,fdotlp
          ld h,b
          ld l,c
gotdot    ld a,"."
          ld (de),a
          inc de
pdot      ld b,3
pdotch    ld a,(hl)
          cp $21
          jr c,gotsfn         
          call uppercasify
          ld (de),a
          inc hl
          inc de
          djnz pdotch

gotsfn    
          ld e,(ix+$10)                           ; get file length
          ld d,(ix+$11)
          ld l,(ix+$12)
          ld h,(ix+$13)
          ld (ser_length_lo),de
          ld (ser_length_hi),hl
          
          ld hl,serial_filename                   ; does this file already exist?
          call kjt_find_file
          jr nz,sr_fnex
          
          call s_waitack                          ; a file exists with this name - send "WW" ack wait to sender
          call find_fn_len
          ld a,11
          srl c
          sub c
          ld (fn_xpos),a
          call backup_display
          call show_replace_window                ; ask user if want to replace the file
          cp $ff
          jp z,rs232exit
          push af
          call restore_display                    ; remove requester
          pop af
          cp 1
          jr z,oktorep                                      
          call s_badack                           ; dont want to replace it, so send back ack "XX" and
          jp rs232_receive                        ; go back to waiting
          
sr_fnex   cp 2                                    ; if file not found error, just go ahead
          jr z,sr_okmf
          cp 6                                    ; if the filename is in use by a dir, cannot proceed
          jp nz,disk_error
          call s_badack
          call backup_display
          ld hl,filename_used_txt
          call show_error_window
          call restore_display
          jp rs232_receive

oktorep   call show_main_rx_window                ; replace the main rx window (to make it active again)
          ld hl,serial_filename                   ; remove old file with this name
          call kjt_erase_file
          jp nz,disk_error

sr_okmf   ld hl,serial_filename                   ; create a new file with this name
          call kjt_create_file
          jp nz,disk_error                        

          call req_rs232_say_receiving            ; say receiving "filename.xxx"
                    
rxbuff_lp ld de,(ser_length_lo)                   ; length of file low
          ld hl,(ser_length_hi)                   ; length of file high
          ld iy,file_buffer                       ; $7e00 byte buffer
          ld c,file_buffer_length/256
rx_filelp call s_goodack                          ; prompt sender for a file block
          call receive_block                      ; get block of file data
          jp c,ser_err                            ; if carry set = there was an error (code in A)
          ld ix,rx_sector_buffer                  ; copy sector buffer to load buffer
          ld b,0
scopylp   ld a,(ix)
          ld (iy),a
          inc ix
          inc iy
          dec de                                  ; countdown file length
          ld a,e
          and d
          inc a
          jr nz,s_rfmb
          dec hl
s_rfmb    ld a,e                                  
          or d
          or l
          or h
          jr z,all_bytes_rec                      ; if zero, last byte
          djnz scopylp                            
          dec c                                   
          jr nz,rx_filelp                         ; loop to next block of load buffer

          ld (ser_length_lo),de                   ; reduce length of file
          ld (ser_length_hi),hl
          ld de,file_buffer_length
          ld c,0                                  ; C,DE = File lenth
          ld b,file_buffer_bank                   ; B = bank
          ld ix,file_buffer                       ; IX = source address
          ld hl,serial_filename                   ; HL = filename
          call kjt_write_bytes_to_file            ; write buffered bytes to file
          jr z,rxbuff_lp                          ; loop around for next chunk                      
          jp disk_error
          

all_bytes_rec


          push iy
          pop hl
          ld de,file_buffer
          xor a
          sbc hl,de
          ex de,hl
          ld c,0                                  ; C,DE = File length
          ld b,file_buffer_bank                   ; B = bank
          ld ix,file_buffer                       ; IX = source address
          ld hl,serial_filename                   ; HL = filename
          call kjt_write_bytes_to_file            ; write (remaining) bytes to file
          jp nz,disk_error                        
          call s_goodack
          jp rs232_receive                        ; Done - ready for next file

                    
receive_block

          push hl
          push de
          push bc
          ld hl,rx_sector_buffer                  ; load a block of 256 bytes
          ld b,0
          exx
          ld hl,$ffff                             ; CRC checksum
          exx
s_lgb     ld a,1
          call kjt_serial_rx_byte
          jr c,s_gbtoerr                          ; timed out if carry = 1      
          ld (hl),a
          exx
          xor h                                   ; do CRC calculation                    
          ld h,a                        
          ld b,8
rxcrcbyte add hl,hl
          jr nc,rxcrcnext
          ld a,h
          xor 10h
          ld h,a
          ld a,l
          xor 21h
          ld l,a
rxcrcnext djnz rxcrcbyte
          exx
          inc hl
          djnz s_lgb
          exx                                     ; hl = calculated CRC

          call kjt_serial_rx_byte                 ; get 2 more bytes - block checksum in bc
          jr c,s_gbtoerr
          ld c,a
          call kjt_serial_rx_byte       
          jr c,s_gbtoerr                
          ld b,a
          
          xor a                                   ; compare checksum
          sbc hl,bc
          jr z,s_gbcsok
          ld a,$0f                                ;A=$0f : bad checksum
          scf
s_gberr   pop bc
          pop de
          pop hl
          ret

s_gbtoerr ld a,$14                                ;A=$14 : time out
          scf
          jr s_gberr
          
s_gbcsok  xor a                                   ;A=$00 : all ok
          jr s_gberr



s_goodack ld a,"O"                                ; send "OK" ack to start file TX
          call kjt_serial_tx_byte
          ld a,"K"
          call kjt_serial_tx_byte
          ret


                    
s_badack  ld a,"X"                                ; send "bad ack" to stop file TX
          call kjt_serial_tx_byte
          ld a,"X"
          call kjt_serial_tx_byte       
          ret



s_waitack ld a,"W"                                ; send "please wait" ack to sender
          call kjt_serial_tx_byte
          ld a,"W"
          call kjt_serial_tx_byte       
          ret
          

show_main_rx_window

          ld b,10
          ld a,7                                  ; set 'receive file rs232' window active
          ld c,7
          ld e,2                                  ; set element selection = 2 (cancel button)
          call req_draw_window
          ret
          
                    
req_rs232_say_waiting

          ld a,1
          ld hl,req_waiting_txt
          call req_put_text_at_element
          ret       



req_rs232_say_receiving

          ld a,1
          ld hl,req_receiving_txt
          call req_put_text_at_element
          ret                                     
                                        


req_rs232_say_error

          ld a,1
          ld hl,req_serial_err_txt
          call req_put_text_at_element
          ret
          

find_fn_len
          
          ld hl,serial_filename
          ld b,12
          ld c,0
ffnlen    ld a,(hl)
          or a
          ret z
          cp " "
          ret z
          inc hl
          inc c
          djnz ffnlen
          ret
                    


uppercasify

          cp $61
          jr c,s_notuc
          sub $20
s_notuc   ret

          
;--------------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------
                                        
wait_no_enter

          call kjt_get_key
          cp $5a
          jr z,wait_no_enter
          ret                           
                                        
          
                                        

test_selections

          ld hl,selection_list                    ;if nothing selected zero flag = set    
          ld b,0
tsellist  ld a,(hl)
          or a
          ret nz
          inc hl
          djnz tsellist
          xor a     
          ret



no_selections

          ld hl,no_selections_txt
          call show_error_window
          jp redraw_all


same_src_dst

          ld hl,same_src_dst_txt
          call show_error_window
          jp redraw_all
          

abort     ld hl,aborted_txt
          call show_error_window
          jp redraw_all


disk_error

          or a
          jr nz,norm_de
          ld hl,driver_error_code_txt
          call kjt_hex_byte_to_ascii
          ld hl,driver_error_txt
          jr disk_err
norm_de   ld hl,disk_error_code_txt
          call kjt_hex_byte_to_ascii
          ld hl,disk_error_txt
disk_err  call show_error_window
          jp begin

          
show_error_window
          
          ld (error_msg_addr),hl
          ld a,4                                  ;show error message window
          ld b,6
          ld c,7
          ld e,2
          call req_draw_window
          call error_window_loop
          ret
                    


key_wait  push hl
          push de
          push bc
          call kjt_wait_key_press
          pop bc
          pop de
          pop hl    
          ret


show_replace_window

          ld a,8                                  ;show error message window
          ld b,7
          ld c,7
          ld e,2
          call req_draw_window
          call yesno_window_loop
          ret

;--------------------------------------------------------------------------------------------------

is_step_selected

          ld a,(directory_level)                  ;Set BC to directory step. If ZF returns not set, entry is selected
          or a
          ret nz                                  ;only if we're at the top level do we need to check for selected files
          push hl
          ld hl,selection_list
          add hl,bc
          ld a,(hl)
          or a
          pop hl
          ret
          


set_dir_step_for_level

          push hl                                 ;set BC to directory step for this level
          push de
          ld a,(directory_level)
          ld e,a
          ld d,0
          ld hl,dir_level_list
          add hl,de
          add hl,de
          ld (hl),c
          inc hl
          ld (hl),b
          pop de
          pop hl
          ret
          
          
get_dir_step_for_level

          push hl                                 ;returns BC = directory step for this level
          push de
          ld a,(directory_level)
          ld e,a
          ld d,0
          ld hl,dir_level_list
          add hl,de
          add hl,de
          ld c,(hl)
          inc hl
          ld b,(hl)
          pop de
          pop hl
          ret       

          
          
find_dir_entry_bc

;set BC to entry number in current directory required

          ld (dir_step),bc
          call kjt_dir_list_first_entry           
          ret nz
          push bc
loc_dent  ld bc,(dir_step)
          ld a,b
          or c
          dec bc
          ld (dir_step),bc
          pop bc
          ret z
          call kjt_dir_list_next_entry
          ret nz
          push bc
          jr loc_dent



show_filename

          push bc
          push de
          ld a,1
          call w_get_element_a_coords
          call kjt_set_cursor_position
          ld hl,blank_txt
          call kjt_print_string
          ld a,1
          call w_get_element_a_coords
          call kjt_set_cursor_position
          ld hl,filename
          call kjt_print_string
          pop de
          pop bc
          ret


;------------------------------------------------------------------------------------------------

disk_op_copy_file

; Put ASCII filename string at "filename" before calling
; (This routine assumes the filename is a file, not a directory) 


          call go_src_folder
          
          ld hl,filename                          
          call kjt_find_file
          ret nz
          ld (file_length_hi),ix                  ;note the file length
          ld (file_length_lo),iy
          xor a
          ld (fc_eof),a                           ;zero end of file flag
          ld hl,0
          ld (file_pointer_lo),hl                 ;zero the file pointer
          ld (file_pointer_hi),hl

          call go_dst_folder
          
cf_mkf    ld hl,filename                          ;create new file on dest dir
          call kjt_create_file
          jr z,fc_loop
          cp 9                                    ;does filename already exist?
          ret nz

          ld hl,filename                          ;If so.. at present always erase it
          call kjt_erase_file
          jr z,cf_mkf
          cp 6                                    ;Is filename used by a directory?
          jr nz,fc_loop
          or a
          ret
                              
fc_loop   call go_src_folder
          
          ld hl,filename                          ;set up pointers (in)to source file     
          call kjt_find_file
          ret nz
          
          push ix                                 ;if source file = zero bytes in length dont do anything else
          push iy
          pop hl
          ld a,l
          or h
          pop hl
          or l
          or h
          jr z,fc_done
          ld ix,(file_pointer_hi)
          ld iy,(file_pointer_lo)
          call kjt_set_file_pointer
          ld ix,0
          ld iy,file_buffer_length
          call kjt_set_load_length
          ld hl,file_buffer                       ;read a chunk of file into buffer
          ld b,file_buffer_bank
          call kjt_force_load
          jr z,fc_slok
          cp $1b                                  ;dont care if tried to load beyond end of file
          ret nz
                    
fc_slok   call go_dst_folder
          
          ld hl,file_buffer_length                ;is the buffer size bigger than the remaining bytes in file?
          ld de,(file_length_lo)
          xor a
          sbc hl,de
          ld hl,0
          ld de,(file_length_hi)
          sbc hl,de
          jr nc,fc_ufl
          ld de,file_buffer_length                ;if not, use the buffer length as the write length
          ld c,0
          jr fc_ufbl
fc_ufl    ld de,(file_length_lo)                  ;otherwise use bytes remaining as the write length and flag EOF
          ld bc,(file_length_hi)
          ld a,1
          ld (fc_eof),a                           ;set end of file flag
fc_ufbl   ld b,file_buffer_bank
          ld hl,filename
          ld ix,file_buffer
          call kjt_write_bytes_to_file            ;append buffer bytes to dest file
          ret nz
                    
          ld a,(fc_eof)                           ;reached end of source file?
          or a
          jr z,fc_mbytd
fc_done   xor a                                   ;exit: ALL OK
          ret
          
fc_mbytd  ld hl,(file_pointer_lo)                 ;move file pointer along by buffer_length
          ld de,file_buffer_length
          add hl,de
          ld (file_pointer_lo),hl
          ld hl,(file_pointer_hi)
          ld de,0
          adc hl,de
          ld (file_pointer_hi),hl
          
          ld hl,(file_length_lo)                  ;decrease the bytes remaining by buffer_length
          ld de,file_buffer_length
          xor a
          sbc hl,de
          ld (file_length_lo),hl
          ld hl,(file_length_hi)
          ld de,0
          sbc hl,de
          ld (file_length_hi),hl
          jp fc_loop
          

;------------------------------------------------------------------------------------------------

disk_op_create_dest_dir

; Put ASCII filename string at "filename" before calling


          call go_dst_folder
          
          ld hl,filename                          
          call kjt_change_dir                     ;if we can change to this dir, it already exists
          ret z                                   ;so nothing more needs to be done
          cp $23                                  ;if "dir not found" error, create it - otherwise report disk error    
          ret nz                                  ;EG: error 4 - name in use by a file                                  
          
          ld hl,filename                          ;create dir and move to it
          call kjt_make_dir
          ret nz
          ld hl,filename
          call kjt_change_dir
          ret

;------------------------------------------------------------------------------------------------

disk_op_delete_file

; Put ASCII filename string at "filename" before calling

          ld hl,filename
          call kjt_erase_file
          ret

;------------------------------------------------------------------------------------------------

disk_op_remove_dir

; Put ASCII filename string at "filename" before calling

          ld hl,filename
          call kjt_delete_dir
          ret
          
;------------------------------------------------------------------------------------------------

test_src_dst

          ld a,(src_vol)                          ;if source and dest folders are same
          ld hl,dst_vol                           ;zero flag is set
          cp (hl)
          ret nz
          ld hl,(src_dir_cluster)
          ld de,(dst_dir_cluster)
          xor a
          sbc hl,de
          ret


go_src_folder

          push bc
          push de
          push hl
          ld a,(src_vol)
          ld (current_vol),a
          call kjt_change_volume
          ld de,(src_dir_cluster)
          call kjt_set_dir_cluster
          pop hl
          pop de
          pop bc
          ret



go_dst_folder

          push bc
          push de
          push hl
          ld a,(dst_vol)
          ld (current_vol),a
          call kjt_change_volume
          ld de,(dst_dir_cluster)
          call kjt_set_dir_cluster
          pop hl
          pop de
          pop bc
          ret
          

note_src_cluster

          push bc
          push de
          push hl
          call kjt_get_dir_cluster
          ld (src_dir_cluster),de
          pop hl
          pop de
          pop bc
          ret

          
          
note_dst_cluster

          push bc
          push de
          push hl
          call kjt_get_dir_cluster
          ld (dst_dir_cluster),de       
          pop hl
          pop de
          pop bc
          ret

;----------------------------------------------------------------------------------------------
; Responses to keypresses in main window
;----------------------------------------------------------------------------------------------

req0_esc_pressed
          
          ld a,(original_volume)
          call kjt_get_volume_info
          ld de,(original_cluster)
          call kjt_set_dir_cluster
          
          call w_restore_display
          ld bc,(orig_cursor)
          call kjt_set_cursor_position
          xor a
          ret

;----------------------------------------------------------------------------------------------

req0_tab_pressed

          ld a,(ops_activated)                    ;dont switch panels if operation boxes selected
          or a
          jp nz,req0_right_pressed                ;cycle the op boxes instead
          
swap_box  ld a,(src_dst_target)
          xor 1
          ld (src_dst_target),a
          jp gui_main_loop

;-----------------------------------------------------------------------------------------------

req0_ctrl_pressed

          ld a,(ops_activated)
          xor 1
          ld (ops_activated),a
          jp z,gui_main_loop
          xor a
          ld (op_box),a
          jp gui_main_loop
          
;----------------------------------------------------------------------------------------------


req0_down_pressed

          ld a,(ops_activated)
          or a
          jp nz,gui_main_loop

          ld a,(src_dst_target)
          or a
          jr nz,dst_win_down

src_win_down

          call w_get_selected_element_data_location
          ld b,(ix+2)                             ; b = lines in element (text window)
          dec b
          ld hl,src_dir_sel_pos                   ;can only scroll down..
          ld a,(hl)
          cp b                                    ;if selection line is at the bottom of text area
          jr z,req_sdd
          inc (hl)
          jr req_dpok
          
req_sdd   xor a                                   ;move down directory list (if not already at end)
          call get_eod
          or a
          jr nz,req_dpok
          ld hl,(src_dirpos)
          inc hl
          ld (src_dirpos),hl
          xor a
          call show_dir_page
req_dpok  jp gui_main_loop


dst_win_down

          call w_get_selected_element_data_location
          ld b,(ix+2)                             ; b = lines in element (text window)
          dec b
          ld hl,dst_dir_sel_pos                   ;can only scroll down..
          ld a,(hl)
          cp b                                    ;if selection line is at the bottom of text area
          jr z,req_dsdd
          inc (hl)
          jr req_ddpok
          
req_dsdd  ld a,1                                  ;move down directory list (if not already at end)
          call get_eod
          or a
          jr nz,req_ddpok
          ld hl,(dst_dirpos)
          inc hl
          ld (dst_dirpos),hl
          ld a,1
          call show_dir_page
req_ddpok jp gui_main_loop
          
          
;----------------------------------------------------------------------------------------------


req0_up_pressed
          
          ld a,(ops_activated)
          or a
          jp nz,gui_main_loop

          ld a,(src_dst_target)
          or a
          jr nz,dst_win_up

          ld hl,src_dir_sel_pos                   ;can only scroll up if selection line
          ld a,(hl)                               ;is at the top
          or a                          
          jr z,req_sdu
          dec (hl)
          jr req_pdok
          
req_sdu   ld hl,(src_dirpos)                      ;move up the dir list (if not already at 0)
          ld a,h
          or l
          jr z,req_pdok
          dec hl
          ld (src_dirpos),hl
          xor a
          call clr_eod
          xor a
          call show_dir_page
req_pdok  jp gui_main_loop


dst_win_up

          ld hl,dst_dir_sel_pos                   ;can only scroll up if selection line
          ld a,(hl)                               ;is at the top
          or a                          
          jr z,req_dsdu
          dec (hl)
          jr req_dpdok
          
req_dsdu  ld hl,(dst_dirpos)                      ;move up the dir list (if not already at 0)
          ld a,h
          or l
          jr z,req_pdok
          dec hl
          ld (dst_dirpos),hl
          ld a,1
          call clr_eod
          ld a,1
          call show_dir_page
req_dpdok jp gui_main_loop


;----------------------------------------------------------------------------------------------

req0_left_pressed
          
          ld a,(op_box)
          dec a
          cp $ff
          jr nz,decob_ok
          ld a,5
decob_ok  ld (op_box),a
          jp gui_main_loop

;----------------------------------------------------------------------------------------------
          
req0_right_pressed

          ld a,(op_box)
          inc a
          cp 6
          jr nz,incob_ok
          xor a
incob_ok  ld (op_box),a
          jp gui_main_loop
          
;----------------------------------------------------------------------------------------------
          
req0_enter_pressed

          ld a,(ops_activated)                    ;pressed Enter      
          or a
          jr nz,do_func
          
          ld a,(src_dst_target)                   ;if the operation boxes are not active
          or a                                    ;enter directories
          jp z,req_ch_src_dir                     
          jp req_ch_dst_dir
          
do_func   ld a,(op_box)                           ;select an operation based on selected box
          cp 0
          jp z,copy_files
          cp 1
          jp z,move_files
          cp 2
          jp z,delete_files
          cp 3
          jp z,make_a_dir
          cp 4
          jp z,rename_files
          cp 5
          jp z,rs232_receive
          jp gui_main_loop


req_ch_src_dir

          call w_get_selected_element_coords      ; Pressed enter in src dir box...
          ld a,(src_dir_sel_pos)                  
          add a,c
          ld c,a
          call kjt_get_charmap_addr_xy  
          ld a,(hl)
          cp " "
          jp z,gui_main_loop                      ; no action if entry is a space
          cp "."                                  ; is this a parent dir entry?
          jr nz,req_npdir
          ld a,(src_vol)
          call kjt_change_volume
          ld de,(src_dir_cluster)
          call kjt_set_dir_cluster
          call kjt_parent_dir
          jp nz,disk_error                        
          call kjt_get_dir_cluster
          ld (src_dir_cluster),de
          jr req_rfshd
          
req_npdir ld de,req_dir_name                      ; copy line to dir filename buffer and change dir           
          push de
          ld bc,12
          ldir
          ld a,(src_vol)
          call kjt_change_volume
          ld de,(src_dir_cluster)
          call kjt_set_dir_cluster
          pop hl
          call kjt_change_dir
          jr z,chdsok
          cp 4
          jr z,req_peofs                          ; user pressed enter on a file
          jp disk_error                           
chdsok    call kjt_get_dir_cluster
          ld (src_dir_cluster),de
req_rfshd xor a
          ld hl,selection_list
          ld bc,256
          call kjt_bchl_memfill                   ; clear selections
          xor a
          call clr_eod
          xor a
          ld (src_dir_sel_pos),a
          ld hl,0
          ld (src_dirpos),hl
          xor a
          call show_dir_page                      ; show new dir
req_peofs jp gui_main_loop

                                        

req_ch_dst_dir

          call w_get_selected_element_coords      ; Pressed enter in dst dir box...
          ld a,(dst_dir_sel_pos)                  
          add a,c
          ld c,a
          call kjt_get_charmap_addr_xy  
          ld a,(hl)
          cp " "
          jp z,gui_main_loop                      ; no action if entry is a space
          cp "."                                  ; is this a parent dir entry?
          jr nz,req_npdrd
          ld a,(dst_vol)
          call kjt_change_volume
          ld de,(dst_dir_cluster)
          call kjt_set_dir_cluster
          call kjt_parent_dir
          jp nz,disk_error                        
          call kjt_get_dir_cluster
          ld (dst_dir_cluster),de
          jr req_rfsdd
          
req_npdrd ld de,req_dir_name                      ; copy line to dir filename buffer and change dir           
          push de
          ld bc,12
          ldir
          ld a,(dst_vol)
          call kjt_change_volume
          ld de,(dst_dir_cluster)
          call kjt_set_dir_cluster
          pop hl
          call kjt_change_dir
          jr z,chddok
          cp 4
          jr z,req_peofd                          ; user pressed enter on a file
          jp disk_error                           
chddok    call kjt_get_dir_cluster                
          ld (dst_dir_cluster),de
req_rfsdd ld a,1
          call clr_eod
          xor a
          ld (dst_dir_sel_pos),a
          ld hl,0
          ld (dst_dirpos),hl
          ld a,1
          call show_dir_page                      ; show new dir
req_peofd jp gui_main_loop


;---------------------------------------------------------------------------------------------

clear_selection_list

          xor a
          ld hl,selection_list
          ld bc,256
          call kjt_bchl_memfill                   ; clear selections
          ret
          
;----------------------------------------------------------------------------------------------

req0_space_pressed

          ld a,(ops_activated)                    ;pressed Space      
          or a                          
          jp nz,gui_main_loop                     ;only select/deselect when panels window

          ld a,(src_dst_target)                   ;and only when in the source window
          or a
          jp nz,gui_main_loop
          
          call w_get_selected_element_coords      
          ld a,(src_dir_sel_pos)                  
          add a,c
          ld c,a
          call kjt_get_charmap_addr_xy  
          ld a,(hl)
          cp " "
          jp z,gui_main_loop                      ; no action if entry is a space
          cp "."                                  ; or parent dir
          jp z,gui_main_loop
          
          ld hl,(src_dirpos)  
          ld a,(src_dir_sel_pos)
          ld e,a
          ld d,0
          add hl,de
          ld h,0                                  ;only the first 256 entries can be selected
          ld de,selection_list
          add hl,de
          ld a,(hl)
          xor 1
          ld (hl),a                               ;toggle selection status for this line
          
          jp gui_main_loop

;----------------------------------------------------------------------------------------------
          
req0_backspace_pressed

          jp gui_main_loop

;----------------------------------------------------------------------------------------------

show_dir_page

; set A to 0/1 (src or destination)
          
          ld (which_panel),a
          call set_volume_and_dir
          
          ld a,(which_panel)                      ;show path
          or a
          jr nz,updpath
          xor a
          call w_get_element_a_coords
          call kjt_set_cursor_position
          ld hl,blank_line
          call kjt_print_string
          call kjt_set_cursor_position
          call show_path
          jr pathupd
updpath   xor a
          call w_get_element_a_coords
          inc c
          call kjt_set_cursor_position
          ld hl,blank_line
          call kjt_print_string
          call kjt_set_cursor_position
          call show_path
pathupd   
          
          ld a,(which_panel)
          ld e,a
          ld d,0
          ld ix,src_dirpos
          add ix,de
          add ix,de
          push ix
          call kjt_dir_list_first_entry           ; find starting point in dir list
          pop ix
          ret nz
          ld l,(ix)
          ld h,(ix+1)                             ; skip "HL" entries 
          ld (dir_entry_count),hl
req_fdsp  ld a,h
          or l
          jr z,req_dsp
          dec hl
          push hl
          call kjt_dir_list_next_entry
          jp nz,req_dlhe
          pop hl
          jr req_fdsp
          
req_dsp   ld a,(which_panel)
          add a,2
          call w_get_element_a_data_location
          ld b,(ix+2)                             ; b = lines in element (text window)
          ld c,0                                  ; line offset
req_fdplp ld e,c
          push bc                       
          ld a,(which_panel)
          add a,2
          call w_get_element_a_coords
          ld a,e
          add a,c
          ld c,a
          push bc
          ld a,(which_panel)
          add a,2
          call w_get_element_a_data_location
          ld e,(ix+1)                             ; width of element
          call set_pen
req_dirbl ld a,32                                 ; put a blank string on line
          call kjt_plot_char
          inc b
          dec e
          jr nz,req_dirbl
          pop bc
          ld (req_dircurpos),bc
          call kjt_set_cursor_position
          
          ld a,(which_panel)
          call get_eod
          or a
          jr nz,req_neod
          call kjt_dir_list_get_entry
          jp c,req_dlhe
          cp $24                                  ; end of dir?
          jr z,req_lde

          push iy                                 ; push filelength etc
          push ix
          push bc
          call set_pen        
          ld de,(dir_entry_count)
          inc de
          ld (dir_entry_count),de
          call kjt_print_string                   ; show filename
          pop bc
          ld a,(which_panel)
          or a
          jr nz,req_ndf
          ld a,b
          or a
          jr z,req_df
req_ndf   pop ix
          pop iy
          jr req_denaf
req_df    ld bc,(req_dircurpos)
          ld a,b
          add a,13
          ld b,a
          call kjt_set_cursor_position
          pop de
          ld a,e
          ld hl,req_fn_len+1
          call kjt_hex_byte_to_ascii
          pop de
          ld a,d
          call kjt_hex_byte_to_ascii
          ld a,e
          call kjt_hex_byte_to_ascii
          ld hl,req_fn_len
          call kjt_print_string                   ; show file length
                    
req_denaf call kjt_dir_list_next_entry
          jr z,req_neod                           ; dir entry advance ok?
          or a
          jr z,req_dlhe
req_lde   ld a,(which_panel)
          call set_eod
req_neod  pop bc
          inc c
          dec b
          jp nz,req_fdplp
          
          call kjt_dir_list_get_entry             ; check if reached end of dir on last line
          jr z,req_neod2
          or a                          
          jr z,req_dlhwe
          ld a,(which_panel)
          call set_eod
req_neod2 xor a                                   ; ZF set = all ok
          ret

req_dlhe  pop bc                                  ; ZF not set, error
req_dlhwe xor a
          inc a
          ret


get_eod   push de                                 ; Set A = 0 for src, a = 1 for dest
          push hl
          ld hl,req_eodfs
          ld e,a
          ld d,0
          add hl,de
          ld a,(hl)
          pop hl
          pop de
          ret
          
          
set_eod   push de                                 ; Set A = 0 for src, a = 1 for dest
          push hl
          ld hl,req_eodfs
          ld e,a
          ld d,0
          add hl,de
          ld (hl),1
          pop hl
          pop de
          ret
                    
clr_eod   push de                                 ; Set A = 0 for src, a = 1 for dest
          push hl
          ld hl,req_eodfs
          ld e,a
          ld d,0
          add hl,de
          ld (hl),0
          pop hl
          pop de
          ret


set_volume_and_dir

          ld e,a                                  ;set a to 0 to set up vol/dir for source,
          ld d,0                                  ;set a to 1 to set ip vol/dir for dest
          ld hl,src_vol
          add hl,de
          ld a,(hl)
          push de
          call kjt_change_volume
          pop de
          ld ix,src_dir_cluster
          add ix,de
          add ix,de
          ld e,(ix)
          ld d,(ix+1)
          call kjt_set_dir_cluster
          ret       
          
          
set_pen   push bc
          push hl
          push de
          ld b,plain_colour                       ; choose pen colour for line
          ld a,(which_panel)
          or a                                    ; nothing can be selected in the dest panel
          jr nz,itnosel                           
          ld hl,selection_list                    ; depending on whether the dir entry is selected or not
          ld de,(dir_entry_count)
          add hl,de
          ld a,(hl)
          or a
          jr z,itnosel
          ld b,unhighlight_selected_colour
itnosel   ld a,b
          call kjt_set_pen
          pop de
          pop hl
          pop bc
          ret

;---------------------------------------------------------------------------------

unhighlight_selected_element

          ld a,plain_colour                       ;normal colour for unselected, unhighlighted text
          jr hl_penset
          
highlight_selected_element

          ld a,highlight_unselected_colour        ;colour for unselected, but highlighted text
hl_penset ld (use_pen),a
          call kjt_set_pen

          call w_get_selected_element_data_location
          call w_get_selected_element_coords
          bit 0,(ix+3)                            ;is this element selectable?
          ret z
          bit 1,(ix+3)                            ;is this special selection type (one line at a time)?
          jr z,nspsel
          ld l,(ix+5)                             ;if so use the associated data variable as an
          ld h,(ix+6)                             ;index to offset the selection point and only
          ld a,c                                  ;highlight one line
          add a,(hl)
          ld c,a
          ld d,1
          call w_get_element_selection            ;ignore special highlighting of selection in for dest dir box
          cp 3
          jr z,hlp2
          push de                                 ;special case for source dir selection:
          ld d,0                                  ;check if item on this line is selected
          ld e,(hl)                               ;and use highlight+selection colour if so
          ld hl,selection_list
          add hl,de
          ld de,(src_dirpos)
          add hl,de
          pop de
          ld a,(hl)
          or a
          jr z,hlp2
          ld a,(use_pen)
          cp plain_colour
          jr nz,hscpen
          ld a,unhighlight_selected_colour
          jr gotpen
hscpen    ld a,highlight_selected_colour
gotpen    call kjt_set_pen
          jr hlp2
nspsel    ld d,(ix+2)                             ;y size
hlp2      ld e,(ix+1)                             ;x size
hlp1      call kjt_get_charmap_addr_xy
          ld a,(hl)
          call kjt_plot_char
          inc b
          dec e
          jr nz,hlp1
          ld a,b
          sub (ix+1)
          ld b,a
          inc c
          dec d
          jr nz,hlp2

          ld a,plain_colour
          call kjt_set_pen
          ret       

use_pen   db 0

;--------------------------------------------------------------------------------------
          
req_draw_window     

          call draw_window
          ld a,e
          call w_set_element_selection
          ret

;--------------------------------------------------------------------------------------

draw_file_manager_window
          
          ld a,0
          ld b,0
          ld c,0
          ld e,2
          call req_draw_window
          
          xor a
          ld (req_eodfs),a
          ld (req_eodfd),a

          ld a,0
          call show_dir_page
          ld a,1
          call show_dir_page
          ret

;--------------------------------------------------------------------------------------------

req_put_text_at_element

          call w_get_element_a_coords
          call kjt_set_cursor_position
          call kjt_print_string                   
          ret
                              
;--------------------------------------------------------------------------------------------


wait_border         

          push hl             
          ld hl,vreg_read
wait_ras1 bit 2,(hl)
          jr z,wait_ras1
wait_ras2 bit 2,(hl)
          jr nz,wait_ras2
          pop hl
          ret


;--------------------------------------------------------------------------------------------

backup_display

          ld hl,OS_charmap
          ld de,charmap_buffer
          ld bc,window_rows*window_cols
          ldir
          ld a,$0e                      
          ld (vreg_vidpage),a
          call kjt_page_in_video
          ld hl,video_base
          ld de,attribute_buffer
          ld bc,window_rows*window_cols
          ldir
          call kjt_page_out_video       
          ret
                    
          
          
restore_display

          call kjt_get_pen
          push af
          ld de,attribute_buffer
          ld hl,charmap_buffer
          ld c,0
rdylp     ld b,0
rdxlp     ld a,(de)
          call kjt_set_pen
          ld a,(hl)
          call kjt_plot_char
          inc hl
          inc de
          inc b
          ld a,b
          cp window_cols
          jr nz,rdxlp
          inc c
          ld a,c
          cp window_rows
          jr nz,rdylp
          pop af
          call kjt_set_pen
          ret
                    
;--------------------------------------------------------------------------------------------

highlight_box

          ld a,box_select_colour
          jp hl_penset
                              
;--------------------------------------------------------------------------------------------

          
test_flash

          ld hl,(foo)
          ld de,$111
          add hl,de
          ld (foo),hl
          ld (palette),hl
          ret
                    
foo       dw 0
          
;---------------------------------------------------------------------------------------------

show_path
          call kjt_store_dir_position
          call display_path
          call kjt_restore_dir_position
          ret
          
          
display_path

          max_chars equ 31                        ;max allowable window width for path (min 28)
                    
          ld c,max_chars-9                        ;Paths always have "VOL0:" and may also have "/../"
          ld b,0                                  ;untruncated dir count
          ld de,text_buffer
          ld a,$2f
          ld (de),a
          inc de
          
gdnlp     push bc
          push de
          call kjt_get_dir_name                   ;are we at ROOT?
          pop de
          pop bc
          push hl
          pop ix
          ld a,(ix+4)
          cp ":"
          jr z,ds_end
                    
cpy_dn    ld a,c                                  ;is the text buffer full?
          or a
          jr z,trunc

          ld a,(hl)                               ;copy dir name char
          cp 33                                   
          jr c,eodn                               ;unless its 0 or space
          ld (de),a
          inc hl
          inc de
          dec c                                   ;is text buffer full?
          jr cpy_dn
eodn      ld a,$2f                                ;add a "/"
          ld (de),a
          ld (last_full),de                       ;note the position of the end of this untruncated entry
          inc de
          inc b                                   ;increase count of untruncated dir names
          dec c                                   ;dec char buffer count
                                        
ndirup    push bc
          push de
          call kjt_parent_dir
          ret nz                                  ;error return
          pop de
          pop bc
          jr gdnlp                                 

trunc     ld de,0

ds_end    push de
          call kjt_root_dir
          call kjt_get_dir_name
          call kjt_print_string                   ;show the volume name
          pop de
          
          xor a
          or b                                    ;if no dir names in buffer, all done
          ret z
          
          ld hl,trunc_txt                         ;if the dir list was truncated show "/../"
          ld a,e
          or d
          call z,kjt_print_string       

notrutxt  ld hl,(last_full)                       ;position of trailing "/"
          inc hl
nxtdlev   ld (hl),0                               ;replace with zero (stop print)
          dec hl
dnbacklp  dec hl
          ld a,(hl)
          cp $2f                                  ;find preceeding "/"
          jr nz,dnbacklp
          inc hl
          push hl
          call kjt_print_string                   ;show dir name
          pop hl
          djnz nxtdlev                            ;any more dirs?
          xor a
          ret
                              

last_full dw 0

trunc_txt db "/../",0

text_buffer ds max_chars+8,0
          
;---------------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\window_routines\inc\window_draw_routines.asm"
include "FLOS_based_programs\code_library\window_routines\inc\Window_Support_Routines.asm"

;---------------------------------------------------------------------------------------------

window_list         dw main_fm_window             ;0
                    dw copying_window             ;1
                    dw moving_window              ;2
                    dw deleting_window            ;3
                    dw error_msg_window           ;4
                    dw new_dir_window             ;5
                    dw rename_window              ;6
                    dw rx_window                  ;7
                    dw replace_window             ;8
                    
main_fm_window      db 0,0
                    db 38,23
                    db 0
                    db 0
                    
                    db 6,1                        ;0
                    dw path_box
                    db 1,1                        ;1
                    dw src_dst_box
                    db 1,4                        ;2
                    dw src_dir_window             
                    db 24,4                       ;3
                    dw dst_dir_window

                    db 1,21                       ;4
                    dw copy_button
                    db 7,21                       ;5
                    dw move_button
                    db 13,21                      ;6
                    dw del_button
                    db 18,21                      ;7
                    dw mkdir_button
                    db 25,21                      ;8
                    dw rename_button
                    db 33,21                      ;9
                    dw rx_button                  
                    db 255


copying_window      db 0,0
                    db 16,5
                    db 0
                    db 0
                    
                    db 4,1                        ;0
                    dw copying_element
                    db 2,3                        
                    dw current_file_element       ;1
                    db 255
                                        
moving_window       db 0,0
                    db 16,5
                    db 0
                    db 0
                    
                    db 4,1                        ;0
                    dw moving_element
                    db 2,3                        
                    dw current_file_element       ;1
                    db 255


deleting_window     db 0,0
                    db 16,5
                    db 0
                    db 0
                    
                    db 3,1                        ;0
                    dw deleting_element
                    db 2,3                        
                    dw current_file_element       ;1
                    db 255
                                                            

error_msg_window    db 0,0
                    db 26,7
                    db 0
                    db 0
                    db 10,1
                    dw error_element
                    db 1,3                        ;0
                    dw error_msg_element
                    db 12,5
                    dw ok_button
                    
                    db 255    


new_dir_window      db 0,0
                    db 15,5
                    db 0
                    db 0

                    db 1,1
                    dw win_element_j              ;0
                    db 3,3
                    dw win_element_k              ;1
                    db 255

                    
rename_window       db 0,0
                    db 16,5
                    db 0
                    db 0
                    
                    db 4,1                        ;0
                    dw rename_element
                    db 2,3                        
                    dw current_file_element       ;1
                    db 255


rx_window           db 0,0
                    db 18,7
                    db 0
                    db 0

                    db 3,1                                  ;0
                    dw win_element_rs232rectxt
                    db 1,3                                  ;1
                    dw win_element_rs232_status
                    db 6,5                                  ;2
                    dw win_element_cancel
                    db 255


replace_window      db 0,0
                    db 23,7
                    db 0
                    db 0
                    
fn_xpos             db 5,1                                  ;1
                    dw show_filename_elem
                    db 1,3                                  ;0
                    dw win_element_replace
                    db 7,5                                  ;2
                    dw yes_button
                    db 14,5                                 ;3
                    dw no_button                            
                    db 255



                                                                                
;---- Window elements for Main Window ----------------------------------------------------

path_box            db 1
                    db 31
                    db 2
                    db 0
                    db 0
                    
                    
src_dst_box         db 2
                    db 4
                    db 2
                    db 0
                    db 0
                    dw src_dst_box_txt

src_dir_window      db 1
                    db 21
                    db 16
                    db 3
                    db 0
                    dw src_dir_sel_pos
                    
dst_dir_window      db 1
                    db 13
                    db 16
                    db 3
                    db 0
                    dw dst_dir_sel_pos
                    
copy_button         db 0
                    db 4
                    db 1
                    db 1
                    db 0
                    dw copy_txt
                    
move_button         db 0
                    db 4
                    db 1
                    db 1
                    db 0
                    dw move_txt

del_button          db 0
                    db 3
                    db 1
                    db 1
                    db 0
                    dw del_txt

mkdir_button        db 0
                    db 5
                    db 1
                    db 1
                    db 0
                    dw mkdir_txt

rename_button       db 0
                    db 6
                    db 1
                    db 1
                    db 0
                    dw rename_txt

rx_button           db 0
                    db 2
                    db 1
                    db 1
                    db 0
                    dw rx_txt


;-- Elements for pop ups ---------------------------------------------------------------------------------


copying_element     db 2
                    db 8
                    db 1
                    db 0
                    db 0
                    dw copying_txt

moving_element      db 2
                    db 8
                    db 1
                    db 0
                    db 0
                    dw moving_txt

deleting_element    db 2
                    db 9
                    db 1
                    db 0
                    db 0
                    dw deleting_txt

current_file_element

                    db 1
                    db 12
                    db 1
                    db 0
                    db 0

error_element       db 2
                    db 6,1
                    db 0
                    db 0
                    dw error_txt
                                                  
error_msg_element   db 2
                    db 24
                    db 5
                    db 0
                    db 0
error_msg_addr      dw 0                          ;dynamically updated by program


win_element_j       db 2                          ; for new dir requester
                    db 13,1
                    db 0
                    db 0
                    dw req_new_dir_txt

win_element_k       db 1                          ; for new dir requester
                    db 8,1
                    db 0
                    db 0
                    dw filename

ok_button           db 0
                    db 2,1
                    db 1
                    db 0
                    dw req_ok_txt
                    
rename_element      db 2
                    db 8
                    db 1
                    db 0
                    db 0
                    dw req_rename_txt
                                        
win_element_cancel  db 0
                    db 6,1
                    db 1
                    db 0
                    dw req_cancel_txt                                 
                                        
win_element_rs232rectxt

                    db 2
                    db 13,1
                    db 0
                    db 0
                    dw req_rs232rec_txt                     
                                        
win_element_rs232_status

                    db 1
                    db 16,1
                    db 0
                    db 0
                    dw req_waiting_txt                                

win_element_replace

                    db 2
                    db 21,1
                    db 0
                    db 0
                    dw file_exists_txt


yes_button          db 0
                    db 3
                    db 1
                    db 1
                    db 0
                    dw yes_txt
                    
                    
no_button           db 0
                    db 2
                    db 1
                    db 1
                    db 0
                    dw no_txt 
                    
show_filename_elem  db 2
                    db 12,1
                    db 0
                    db 0
                    dw serial_filename  
                                                  
;---------------------------------------------------------------------------------------------
                                        

blank_line          ds 31,32
                    db 0
copying_txt         db "COPYING:",0
moving_txt          db "MOVING:",0
deleting_txt        db "DELETING:",0
no_selections_txt   db "    Nothing Selected.",0
same_src_dst_txt    db "Same Source/Destination",0
aborted_txt         db "    Function Aborted.",0
req_new_dir_txt     db "NEW DIR NAME:",0
req_ok_txt          db "OK",0
error_txt           db "ERROR!",0
filename_exists_txt db "Filename Already Exists",0
req_rename_txt      db "RENAME:",0
src_dst_box_txt     db "Src:Dst:",0
req_cancel_txt      db "CANCEL",0
req_rs232rec_txt    db "RS232 RECEIVE",0
req_waiting_txt     db "    Waiting..",0
req_receiving_txt   db "Rec:"
serial_filename     db "                ",0
req_serial_err_txt  db "Header Error!",0
file_exists_txt     db "File Exists. Replace?",0
yes_txt             db "YES",0
no_txt              db "NO",0
filename_used_txt   db "Filename In Use By A Dir",0

;---------------------------------------------------------------------------------------------
                              
src_dir_txt         db "                    ",0
dst_dir_txt         db "                    ",0
copy_txt            db "COPY",0
move_txt            db "MOVE",0
del_txt             db "DEL",0
mkdir_txt           db "MKDIR",0
rename_txt          db "RENAME",0
rx_txt              db "RX",0

;---------------------------------------------------------------------------------------------

original_volume     db 0
original_cluster    dw 0

current_vol         db 0

src_vol             db 0
dst_vol             db 0
src_dirpos          dw 0
dst_dirpos          dw 0

which_panel         db 0
src_dir_cluster     dw 0
dst_dir_cluster     dw 0
root_cluster        dw 0
deleted_dir_cluster dw 0
compare_cluster     dw 0

req_eodfs           db 0
req_eodfd           db 0
req_dircurpos       dw 0

req_fn_len          db "$xxxxxx",0

src_dir_sel_pos     db 0
dst_dir_sel_pos     db 0

req_current_scancode   db 0
req_current_ascii_char db 0

req_dir_name        ds 12,0

dir_step            dw 0
blank_txt           db "            ",0
wildcard_txt        db "*",0

src_dst_target      db 0
op_box              db 0
ops_activated       db 0

recommence_addr     dw 0

driver_error_txt      db "    Driver error: $"
driver_error_code_txt db "xx",0

disk_error_txt        db "     Disk Error: $"
disk_error_code_txt   db "xx",0

;---------------------------------------------------------------------------------------------

req_ti_cursor       db 0
supplied_ascii      ds 42,0             ;buffer for ascii input in windows 40 chars max

filename            ds 16,0
file_length_hi      dw 0
file_length_lo      dw 0
file_pointer_lo     dw 0
file_pointer_hi     dw 0
fc_eof              db 0

dir_entry_count     dw 0
                    
selection_list      ds 256,0            ;lines in the dir itself that have been selected
                    db 0                ;makes sure zero is always placed at end of collapsing selection list
                    
directory_level     db 0

dir_level_list      ds 256,0            ;max 128 directory levels allowed

text_input_coord_base         dw 0
max_cursor                    db 0

orig_cursor         dw 0

;---------------------------------------------------------------------------------------------

ser_length_lo       dw 0
ser_length_hi       dw 0

rx_sector_buffer    ds 256,0

;---------------------------------------------------------------------------------------------

charmap_buffer      ds window_rows*window_cols,0
attribute_buffer    ds window_rows*window_cols,0

file_buffer         db 0                ;start of file buffer - do not place any variables beyond this point

