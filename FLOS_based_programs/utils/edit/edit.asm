; EDIT.EXE v0.03 for FLOS by Phil Ruston 2011 (to replace TEXTEDIT.EXE)
; ---------------------------------------------------------------------

; V0.03 - Allow path in filename
; V0.02 - New requester code for FLOS 6.02
; V0.01 - First release

; Use: EDIT [filename] [-G hex_number]
;
; If no filename is supplied, a new document called "NEW.TXT" is created.
; [-G hex_number] is line to go to at start (also optional).
; 
; Keys:
; ----
; CTRL + ESC = QUIT
; CTRL + L   = LOAD
; CTRL + S   = SAVE
; CTRL + G   = GOTO LINE
; CTRL + N   = NEW DOCUMENT
;
; Other keys supported: Page_Up, Page_Down, Home, Insert

; Notes:
; ------
;
; Max line length = 248 characters
; Max file size = 384KB
; When saving, if a file exists with same name, that file is renamed *.BAK
; Tabs fixed at 8 characters


; Tech info
; ----------
; Stores text file in VRAM $20000-$7ffff for ease/speed of manipulation with blitter
; Also uses VRAM $0-$1fff for buffer


;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

required_flos       equ $607
include             "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

;---------------------------------------------------------------------------------------------

max_path_length equ 40

          call save_dir_vol
          call edit_go
          call restore_dir_vol
          ret
          
;-----------------------------------------------------------------------------------------------

win_x_size          equ 40
win_y_size          equ 24

;-----------------------------------------------------------------------------------------------


edit_go   ld de,1
          ld (goto_line),de

          ld a,(hl)
          or a
          jr z,args_done
          
          ld a,(hl)
          cp "-"
          jr z,args_done
          
          call extract_path_and_filename
          ld hl,path_txt
          call kjt_parse_path           ;change dir according to the path part of the string
          ret nz

fna1      ld a,(hl)                     ;find next arg
          or a
          jr z,args_done
          cp " "
          jr z,findpar
          inc hl
          jr fna1

findpar   inc hl
          ld a,(hl)
          or a
          jr z,args_done
          cp "G"
          jr nz,findpar
          inc hl
          call kjt_ascii_to_hex_word
          or a
          jr nz,args_done
          ld (goto_line),de

;------------------------------------------------------------------------------------------------   
          
args_done call store_charmap
          
          call kjt_get_pen
          ld (normal_video_colour),a
          ld a,$b1
          ld (inv_video_colour),a

          xor a
          ld (rebuild_flag),a

          ld hl,filename_txt
          call commence_load

          ld hl,(goto_line)
          call go_line_number

;================================================================================================

main_loop

          call show_info_bar

key_loop  call kjt_wait_vrt             ;flash cursor whilst waiting for key press
          call cursor_flash
          call kjt_get_key
          or a
          jr z,key_loop
          ld (current_scancode),a       ;store scancode
          ld a,b
          ld (current_asciicode),a      ;store ascii version of key
          
          call delete_cursor
          ld a,24                       ;ensures cursor is mainly visible 
          ld (cursor_flash_timer),a     ;during held key operations etc
          xor a
          ld (cursor_status),a

          ld a,(current_scancode)       
                    
          cp $6b                                            
          jp z,cursor_left_pressed
          
          cp $74                        
          jp z,cursor_right_pressed
          
          cp $75                        
          jp z,cursor_up_pressed
          
          cp $72
          jp z,cursor_down_pressed
          
          cp $66
          jp z,backspace_pressed
          
          cp $71
          jp z,delete_pressed
          
          cp $5a
          jp z,enter_pressed
          
          cp $0d
          jp z,tab_pressed
          
          cp $6c
          jp z,home_pressed
          
          cp $7d
          jp z,pgup_pressed
          
          cp $7a
          jp z,pgdown_pressed
          
          cp $58
          jp z,caps_pressed
          
          cp $70
          jp z,insert_pressed

          call kjt_get_key_mod_flags              
          bit 1,a
          jr z,ctrl_not_held
          
          ld a,(current_scancode)
          cp $4b
          jp z,ctrl_l_pressed
          cp $1b
          jp z,ctrl_s_pressed
          cp $34
          jp z,ctrl_g_pressed
          cp $31
          jp z,ctrl_n_pressed
          cp $76
          jp z,esc_pressed

                    
ctrl_not_held       
          
          ld a,(current_asciicode)
          or a
          jp nz,new_ascii_char
          
          jp main_loop
                    
          
;==================================================================================================================

          
cursor_left_pressed
          
          call do_cursor_left
          jp main_loop

do_cursor_left
          
          ld hl,char_pos      
          ld a,(hl)
          or a
          jr nz,cl_notc0
          
          call do_cursor_up                       ;if a column zero, cursor up and move to end of that line
          ret nz                                  
          call find_line_end                      
          ld a,l
          ld (char_pos),a
          call column_offset_adj
          xor a
          ret
          
cl_notc0  dec (hl)
          call column_offset_adj_lr
          xor a
          ret


;-----------------------------------------------------------------------------------------------------------------


cursor_right_pressed
          
          call do_cursor_right
          jp main_loop


do_cursor_right
          
          call get_char_addr                      
          ld a,(hl)
          or a                                    ;if at end of file, cant go right
          jr z,cr_eof
          cp 11
          jr nz,cr_simple
          
          ld hl,cursor_y                          ;if at end of line, move down and go to start of line
          inc (hl)
          ld a,(hl)
          cp win_y_size                 
          jr nz,cr_nbot
          ld (hl),win_y_size-1                    ; bottom limit reached, scroll
          xor a
          ld (char_pos),a
          ld (cursor_x),a
          ld (column_offset),a
          call next_line 
          ret

cr_nbot   xor a
          ld (char_pos),a
          ld (cursor_x),a
          ld (column_offset),a
          call show_text_page
          ret
          

cr_simple ld hl,char_pos
          inc (hl)
          call column_offset_adj_rl
          ret
          
cr_eof    call error_flash
          xor a
          inc a
          ret
          
                    
;-----------------------------------------------------------------------------------------------------------------


cursor_up_pressed
          
          call do_cursor_up
          jp nz,main_loop
          call relocate_cursor                    ; position cursor in text at approximately the same place
          jp main_loop
          
do_cursor_up

          ld hl,cursor_y                          ;if cursor is at top of screen need to scroll up a line
          dec (hl)
          ld a,(hl)
          cp $ff
          jr z,cu_prevln
          xor a
          ret
          
cu_prevln ld (hl),0                               ; top limit reached, scroll (if possible)
          call previous_line
          push af
          call nz,error_flash
          pop af
          ret
          
          

;-----------------------------------------------------------------------------------------------------------------


cursor_down_pressed
          
          call do_cursor_down
          jp nz,main_loop
          call relocate_cursor                    ; position cursor in text at approximately the same place
          jp main_loop                            ; on line below
          
do_cursor_down
          
          call get_char_addr                      ; scan this line for a LF, if not found do nothing
          ld b,254
cd_flflp  ld a,(hl)
          or a
          jr z,cd_eof                             ; do nothing if EOF encountered
          cp 11
          jr z,cd_ok
          inc l
          djnz cd_flflp
cd_eof    xor a
          inc a
          ret
          
cd_ok     ld hl,cursor_y
          inc (hl)
          ld a,(hl)
          cp win_y_size                 
          jr z,cd_scr
          xor a
          ret
          
cd_scr    ld (hl),win_y_size-1                    ; bottom limit reached, scroll
          call next_line
          ret

;-----------------------------------------------------------------------------------------------------------------


pgup_pressed

          ld a,win_y_size
          ld b,a
pguplp    push bc
          call pgup_prev_line
          pop bc
          djnz pguplp
          
          call make_work_buffer
          call show_text_page
          call relocate_cursor
          jp main_loop
          
          
;-----------------------------------------------------------------------------------------------------------------


pgdown_pressed

          call rebuild_main                       ;apply any edits made 

          ld b,win_y_size
pgdwnlp   push bc
          call make_work_buffer                   ;attempt to make work buffer
          pop bc
          jr nz,pgd_eof                           ;if build attempt encounters EOF, stop here
          push bc
          call pgdown_next_line                   ;quietly move down a line
          pop bc
          djnz pgdwnlp
          
pgd_eof   call show_text_page
          call relocate_cursor
          jp main_loop


          
;-----------------------------------------------------------------------------------------------------------------


enter_pressed
          
          call get_char_addr  
          push hl                                 ;copy everything from the char_pos to end of line to temp_line string
          ld de,wb_temp_line            
          ld b,0
ep_tllp   ld a,(hl)
          ld (de),a
          or a
          jr z,ep_cchok
          cp 11
          jr z,ep_cchok
          inc hl
          inc de
          djnz ep_tllp
ep_cchok  pop hl
          ld (hl),11                              ;break the original line at the cursor with 11
          
          ld a,(cursor_y)                         ;deflate lines upto/including the newly split line to VRAM $0 onwards 
          inc a                                   
          ld b,a                                  ;number of lines to do
          ld hl,work_buffer
          ld de,$2000
          call deflate_lines

          ld hl,wb_temp_line                      ;add the temp line..
          ld b,1    
          call deflate_lines  
          
          ld hl,work_buffer                       ;deflate the rest of the lines below the original line cursor..
          ld a,(cursor_y)
          inc a
          ld b,a
          add a,h
          ld h,a
          ld a,win_y_size
          sub b
          jr z,ep_nola
          ld b,a                                  ;remaining lines count (if below edit window, nothing to do)
          call deflate_lines
          
ep_nola   ld a,d
          sub $20
          ld d,a                                  ;de = length of total deflated workbuffer text
          ld (deflated_wb_size),de
          call rebuild_text_file                  ;insert the new data into the main text file
          call make_work_buffer                   

          xor a                                   
          ld (char_pos),a
          ld (cursor_x),a
          ld (column_offset),a

          call show_text_page
          
          call do_cursor_down                     ;cursor down to start of next line
          jp main_loop
          




;-----------------------------------------------------------------------------------------------------------------


delete_pressed


          call do_delete
          jp main_loop
          
          
do_delete 
          
          call set_rebuild_flag                   ;routine will clear the flag itself if necessary

          call get_char_addr                      
          ld a,(hl)                               
          or a                                    ;dont do anything if EOF
          ret z                                   
          cp 11                                   ;if char at curpos = 11 this is the end of a line so
          jr z,del_gcfnl                          ;need to pull chars from next line
          
          ld a,l                                  ;simply move everything on line from "cursor+1" to "cursor"..
          cpl
          dec a
          ld c,a                                  
          ld b,0
          ld d,h
          ld e,l
          inc hl
          ldir
          call get_char_addr
          ld b,0                                  ;x
          ld a,(cursor_y)
          ld c,a                                  ;y
          ld l,0
          call draw_line                          ;and redraw the line
          ret
          

del_gcfnl call test_line_length                   ;cant add chars if line is already max length
          ret nz

          ld a,(cursor_y)                         ;
          cp win_y_size-1
          jr nz,dj_nlok                           ;if next line is not in work buffer, need to scroll down
          call next_line
          ret nz                                  ;if end of file do nothing
          ld hl,cursor_y      
          dec (hl)                                ;everything has moved up a line so adjust cursor
          
dj_nlok   xor a
          ld (long_line),a
          call get_char_addr
          ld d,h                                  
          ld e,l
          inc h                                   ;source is line below cursor
          ld l,0                                  ;de=dest, hl = source

dj_jlp    ld a,(hl)                               ;copy the characters from line below
          ld (de),a
          cp 11
          jr z,dj_llok                            ;if encounter EOF, stop
          or a
          jr z,dj_llok                            ;if encounter EOL, stop
          inc l
          inc e
          ld a,e                                  ;if dest = end of line, must leave some text on original line
          cp 248
          jr nz,dj_jlp
          ld a,11                                 ;long line = terminate receiving line
          ld (de),a
          ld a,l
          ld (long_line),a
          
dj_llok   ld a,(cursor_y)                         ;deflate lines upto/including the line where the cursor is
          inc a
          ld b,a                                  ;number of lines to do
          ld hl,work_buffer
          ld de,$2000
          call deflate_lines

          ld hl,work_buffer
          ld a,(long_line)                        ;if any chars left on donor line, deflate that line from
          or a                                    ;from last char copied + 1
          jr z,dj_nrch
          ld l,a                        
          ld a,(cursor_y)
          inc a
          add a,h
          ld h,a
          ld b,1
          call deflate_lines  

dj_nrch   ld hl,work_buffer                       ;deflate everything else
          ld a,(cursor_y)
          add a,2
          ld b,a
          add a,h
          ld h,a
          ld a,win_y_size
          sub b
          jr z,dj_nola
          ld b,a                                  ;remaining lines to do (if at last line of window, nothing to do)
          call deflate_lines
          
dj_nola   ld a,d
          sub $20
          ld d,a                                  ;de = length of total deflated workbuffer text
          ld (deflated_wb_size),de

          call rebuild_text_file                  ;insert the new data into the main text file
          call make_work_buffer
          call show_text_page
          ret

long_line db 0

;-----------------------------------------------------------------------------------------------------------------


backspace_pressed

          call do_cursor_left
          jp nz,main_loop
          call do_delete
          jp main_loop
          
                    
;-----------------------------------------------------------------------------------------------------------------

tab_pressed

          ld a,9
          ld (current_asciicode),a
          
          
new_ascii_char
          
          call test_line_length
          jr z,nac_llok
          call error_flash
          jp main_loop
          
nac_llok  ld ix,mode_bits
          call get_char_addr
          bit 0,(ix)
          jr z,ins_mode

          ld a,(hl)                               ;if overwriting and current char is LF
          or a
          jr z,nac_nt
          cp 11                                   ;put new LF at char + 1
          jr nz,over_wr
          inc hl
          ld (hl),11
nac_nt    inc hl
          ld (hl),0
          jr over_wr
          
ins_mode  ld a,l
          cpl
          dec a
          ld c,a                                  ;move everything at cursor+ 1 char right
          ld b,0
          ld d,h
          ld e,$fe
          ld l,$fd
          lddr
          
over_wr   call get_char_addr
          ld a,(current_asciicode)
          bit 1,(ix)
          jr z,nofcaps
          cp "a"
          jr c,nofcaps
          cp "z"+1
          jr nc,nofcaps
          sub $20
nofcaps   ld (hl),a                               ;put in new char
          ld b,0
          ld a,(cursor_y)
          ld c,a
          ld l,0
          call draw_line
          call do_cursor_right
          call set_rebuild_flag
          jp main_loop
          
          
set_rebuild_flag

          ld a,1
          ld (rebuild_flag),a
          ret

                              
;-----------------------------------------------------------------------------------------------------------------


insert_pressed

          ld a,(mode_bits)
          xor 1
          ld (mode_bits),a
          jp main_loop


;-----------------------------------------------------------------------------------------------------------------


caps_pressed

          ld a,(mode_bits)
          xor 2
          ld (mode_bits),a
          jp main_loop


;-----------------------------------------------------------------------------------------------------------------


home_pressed

          xor a
          ld (char_pos),a
          ld (column_offset),a
          ld (cursor_x),a
          call show_text_page
          jp main_loop

          
;------------------------------------------------------------------------------------------------------------------


esc_pressed

          call update_text_file
          call get_file_size                      ; show confirm req if filesize > 0
          jp z,ok_quit
          ld hl,quit_req_txt
          xor a
          call alert_box
          call kjt_wait_key_press                 ; wait for a key
          ld a,b
          cp "y"
          jp z,ok_quit
          call show_text_page
          jp main_loop
          

;------------------------------------------------------------------------------------------------------------------


ctrl_l_pressed

          call update_text_file
          call get_file_size                      ; show confirm req if filesize > 0
          jr z,ok_load
          ld hl,load_req_txt
          xor a
          call alert_box
          call kjt_wait_key_press                 ; wait for a key
          ld a,b
          cp "y"
          jr z,ok_load
          call show_text_page
          jp main_loop

ok_load   call load_req                           ;CTRL + L? - Load a file.               
          ld hl,1
          call go_line_number
          jp main_loop        
          
;------------------------------------------------------------------------------------------------------------------


ctrl_n_pressed

          call update_text_file                   ; new file
          call get_file_size                      ; show confirm req if filesize > 0
          jr z,ok_newf
          ld hl,load_req_txt
          xor a
          call alert_box
          call kjt_wait_key_press                 
          ld a,b
          cp "y"
          jr z,ok_newf
          call show_text_page
          jp main_loop

ok_newf   call new_document                                           
          ld hl,1
          call go_line_number
          jp main_loop        
          
;------------------------------------------------------------------------------------------------------------------


ctrl_s_pressed

          call update_text_file
          call get_file_size
          jr nz,save_ok
          
          ld hl,fl_zero_txt
          ld a,1
          call alert_box
          call kjt_wait_key_press
          call show_text_page
          jp main_loop
                    
save_ok   call save_req                           ;CTRL + S? - Save a file.
          call make_work_buffer                   ;wb needs remaking as save trashes it
          call show_text_page
          jp main_loop
          

;------------------------------------------------------------------------------------------------------------------


ctrl_g_pressed

          ld a,2                                  ;CTRL + G? - Goto line
          ld hl,goto_line_txt
          call input_requester
          jr nz,ctrlgl_done
          ld hl,input_txt
          call ascii_dec_to_hex_word
          jr nz,ctrlgl_done
          jr c,ctrlgl_done
          ex de,hl
          ld a,h
          or l
          jr z,ctrlgl_done
          call go_line_number
          jp z,main_loop
          ld hl,goto_too_big_txt                  ;failed - show error
          ld a,1
          call alert_box
          call kjt_wait_key_press

ctrlgl_done

          call show_text_page                     ;removes requester
          jp main_loop


;------------------------------------------------------------------------------------------------------------------
          

ok_quit   call restore_charmap
          xor a
          ret


;-----------------------------------------------------------------------------------------------



cursor_flash

          ld hl,cursor_flash_timer
          inc (hl)
          ld a,(hl)
          cp 25
          ret nz
          ld (hl),0
          ld a,(cursor_status)
          xor 1
          ld (cursor_status),a
          or a
          jr z,delete_cursor



draw_cursor

          ld a,(cursor_x)
          cp win_x_size
          jr nz,cposok
          ld a,win_x_size
          dec a
cposok    ld b,a                        ;draw cursor at extreme right if end of a line
          ld a,(cursor_y)
          ld c,a
          call kjt_set_cursor_position
          
          ld hl,$1000                   ;cursor image = block (for insert mode)
          ld a,(mode_bits)
          and 1
          jr nz,block_cur
          ld hl,$085f                   ;normal underscore cursor
block_cur call kjt_draw_cursor
          ret
          
          


delete_cursor

          ld a,(cursor_x)
          cp win_x_size
          jr nz,cposok2
          ld a,win_x_size
          dec a
cposok2   ld b,a
          ld a,(cursor_y)
          ld c,a
          call kjt_set_cursor_position

          ld hl,0
          call kjt_draw_cursor
          ret


cursor_status       db 0

cursor_flash_timer  db 0

cursor_x            db 0

cursor_y            db 0
          
;-----------------------------------------------------------------------------------------------------------------


include   "flos_based_programs\utils\edit\inc\text_manipulation.asm"

include   "flos_based_programs\utils\edit\inc\infobar.asm"

include   "flos_based_programs\utils\edit\inc\load_save.asm"

include   "flos_based_programs\utils\edit\inc\alerts.asm"

include   "flos_based_programs\utils\edit\inc\maths.asm"

include   "flos_based_programs\code_library\requesters\inc\\file_requesters.asm"

include   "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

include   "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;-----------------------------------------------------------------------------------------------


current_scancode    db 0
current_asciicode   db 0
mode_bits           db 0      ;bit0 = insert, 1= caps

;-----------------------------------------------------------------------------------------------


          org ($+255) & $ff00

wb_temp_line

          ds 256,0
                    
work_buffer

          db 0                          ;$2000 bytes (also used by file load routine)
          
;-----------------------------------------------------------------------------------------------
          