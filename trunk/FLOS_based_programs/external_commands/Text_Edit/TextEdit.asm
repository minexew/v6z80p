
; Simple Text Editor v0.10 for FLOS - By Phil 2009-2010
;
; Changes:
; --------
;
; v0.10 - Added file requesters and CTRL+L / CTRL+S
; V0.09 - Changed to new FLOS font system where extra chars (arrows) are user defined.
; V0.08 - Whole page redrawn to remove dialog box on esc/cancel
; v0.07 - Speeded up page redraw. (Added character check to 'plot char'
;         if character is the same as that already on display, dont plot it)


;---Standard header for OSCA and FLOS ----------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

window_cols	equ 40
window_rows	equ 24

	org $5000

;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$562
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v562+",11,11,0
	
;-------- Load and Init -----------------------------------------------------------------------
	
flos_ok	ld de,0
	ld (filesize),de
	
	ld de,$5000		; if being run from G command, HL which is normally
	xor a			; the argument string will be $5000
	sbc hl,de
	jr z,ed_fnf
	
	add hl,de
fnd_para	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jr z,ed_fnf
	cp " "			; ignore leading spaces...
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para

fn_ok	call hl_to_working_filename

	ld hl,filename		; does filename exist?
load_file	call kjt_find_file
	jp nz,ed_fnf
	push ix			; will the file fit in unpaged memory?
	pop hl
	ld a,h
	or l
	jr nz,too_big
	ld (filesize),iy
	ld de,text_buffer
	add iy,de
	jr c,too_big
	ld (iy),0			; zero terminate the text file in memory
	ld b,0			; load the existing file if it does
	ld hl,text_buffer		 
	call kjt_force_load
	jr z,ed_fnf
	ld hl,load_error_txt
	call kjt_print_string
	xor a
	ret
too_big	ld hl,file_too_big
	call kjt_print_string
	xor a
	ret

	
ed_fnf	call set_user_chars
	call kjt_clear_screen
	call clear_charmap_buffer

	ld bc,$0000
	ld hl,title_bar
	call print_string_inv
	ld bc,$0500
	ld hl,filename
	call print_string_inv
	ld bc,$0018
	ld hl,footer_bar
	call print_string_inv
	
	ld hl,text_buffer
	ld (text_base),hl
	xor a
	ld (eof_flag),a
	inc a
	ld (sof_flag),a
	call draw_text_page

	ld a,0
	ld (cursor_x),a
	ld a,1
	ld (cursor_y),a
	ld hl,0
	ld (line_count),hl
		
;============================================================================================

main_loop	ld a,(cursor_x)		;update onscreen coord values
	ld l,a
	ld h,0
	inc hl
	call hex_to_dec
	ld bc,$0418
	call print_string_inv
	ld hl,(line_count)
	ld a,(cursor_y)
	ld e,a
	ld d,0
	add hl,de
	call hex_to_dec
	ld bc,$1118
	call print_string_inv
	ld hl,(filesize)
	call hex_to_dec
	ld bc,$1f18
	call print_string_inv


key_loop	call kjt_wait_vrt		;flash cursor whilst waiting for key press
	call cursor_flash
	call kjt_get_key
	or a
	jr z,key_loop
	ld (current_scancode),a	;store scancode
	ld a,b
	ld (current_asciicode),a	;store ascii version of key
	
	call backup_charmap
		
	call delete_cursor
	ld a,24			;ensures cursor is mainly visible 
	ld (cursorflashtimer),a	;during held key operations etc
	xor a
	ld (cursorstatus),a


	ld a,(current_scancode)	;insert mode on/off?
	cp $70
	jr nz,notins
	ld a,(insert_mode)
	xor 1
	ld (insert_mode),a
	jr main_loop




notins	cp $6b			; arrow key moving cursor left?		
	jr nz,ntlft
curs_left	ld hl,cursor_x
	dec (hl)
	ld a,(hl)
	cp $ff			; reached leftmost column?
	jr nz,main_loop
	ld (hl),0
	ld hl,(line_count)		; cant go further left if at line 1, col 1
	ld a,(cursor_y)
	ld e,a
	ld d,0
	add hl,de
	dec hl
	ld a,h
	or l
	jr z,curs_up
	ld a,window_cols-1
	ld (cursor_x),a
	jr curs_up		




ntlft	cp $74			; arrow key moving cursor right?
	jr nz,ntright
curs_righ	ld a,(cursor_x)		; cannot move further right if at max column
	cp window_cols
	jp z,main_loop
	call locate_cursor_char
	ld a,(hl)			; cant move right if at end of file
	or a
	jp z,main_loop
	cp $a			;if at end of text line, move to 
	jr z,atcr			;start of next line
	cp $d
	jr nz,notatcr
atcr	xor a
	ld (cursor_x),a
	jp curs_down
notatcr	ld hl,cursor_x
	inc (hl)			;move cursor right
	jp main_loop
	
	
	
	

ntright	cp $75			; arrow key moving cursor up?
	jr nz,ntup
curs_up	ld hl,cursor_y
	dec (hl)
	jr nz,cu_rpc
	ld (hl),1			; top limit reached, scroll down
	ld a,(sof_flag)
	or a
	jp nz,main_loop
	call move_text_base_up_a_line
	call draw_text_page
	ld a,(sof_flag)		; remove scroll up arrow if at start of file
	or a
	jr z,cu_rpc
	ld b,window_cols-1
	ld c,0
	ld hl,arrow_up+2
	call print_string_inv	
cu_rpc	ld a,(cursor_x)		; reposition cursor
	push af
	call reposition_cursor_x	
	pop bc
	ld a,(cursor_x)		; if new position is > than old position
	cp b			; use old position
	jp c,main_loop
	ld a,b
	ld (cursor_x),a
	
	jp main_loop
	




ntup	cp $72
	jr nz,ntdwn		; arrow key moving cursor down?
curs_down	call locate_cursor_char
chksd	ld a,(hl)			; prevent cursor down if EOF reached
	or a			; before new line
	jp z,main_loop
	cp $a
	jr z,oksd
	cp $d
	jr z,oksd
	inc hl
	jr chksd	
oksd	ld hl,cursor_y
	inc (hl)
	ld a,(hl)
	cp window_rows		; at last line of window?
	jr nz,cd_rpc
	ld (hl),window_rows-1	; bottom limit reached, scroll down
	call move_text_base_down_a_line
	call draw_text_page
	ld b,window_cols-1
	ld c,0
	ld hl,arrow_up
	call print_string_inv
cd_rpc	jp cu_rpc






ntdwn	cp $66			; backspace?
	jp nz,not_bs
	call locate_cursor_char
	ld (source),hl
	ld de,text_buffer
	xor a
	sbc hl,de
	jp z,main_loop		; cant backspace if at start of file
	ld bc,(source)
	ld hl,text_buffer
	ld de,(filesize)
	add hl,de
	xor a
	sbc hl,bc
	inc hl
	ld (move_count),hl		; bytes from current pos to end of file
	ld a,(cursor_y)
	dec a
	ld b,a
	ld a,(cursor_x)
	or b
	jr nz,norm_bs		
		
	call move_text_base_up_a_line ; special case when cursor is in top left of window
	ld de,(text_base)
	ld bc,0			; find CR at end of previous line
findjoin	ld a,(de)
	cp $a
	jr z,foundjoin
	cp $d
	jr z,foundjoin
	inc de
	inc bc
	jr findjoin
foundjoin	xor a			
	ld (cursor_x),a
	ld h,0
	ld l,window_cols
	sbc hl,bc
	jr c,cx_outwn2		;if the join point is out of the window
	ld a,c			;put the cursor at 0, else put where it landed
	ld (cursor_x),a
cx_outwn2	ld bc,(filesize)
	dec bc
bschfs	dec bc
	ld (filesize),bc
	ld bc,(move_count)
	ld hl,(source)
	ldir			;move bytes to new location
	call null_terminate_file	
	call draw_text_page
	jp main_loop

norm_bs	ld a,(cursor_x)		;is cursor at first column?
	or a
	jr nz,notafc
	call locate_cursor_char
	ld (source),hl
	ld a,(cursor_y)
	dec a			;move cursor up a line
	ld (cursor_y),a	
	call locate_cursor_char
	push hl
	pop de
	ld bc,0
scanline	ld a,(de)			;look for <CR> from start of line
	cp $a			;this is the join point
	jr z,fndj2
	cp $d
	jr z,fndj2
	inc de
	inc bc
	jr scanline
fndj2	xor a			
	ld (cursor_x),a
	ld h,0
	ld l,window_cols
	sbc hl,bc
	jr c,cx_outwin		;if the join point is out of the window
	ld a,c			;put the cursor at 0
	ld (cursor_x),a
cx_outwin	ld bc,(filesize)
	dec bc
bschfs2	dec bc
	ld (filesize),bc
	ld bc,(move_count)
	ld hl,(source)
	ldir			;move bytes to new location
	call null_terminate_file
	call draw_text_page
	jp main_loop
	
notafc	call locate_cursor_char	;straightforward one byte shift/removal
	push hl
	pop de
	dec de
	ld bc,(move_count)
	ldir
	ld bc,(filesize)
	dec bc
	ld (filesize),bc
	call null_terminate_file
	call draw_text_page
	jp curs_left
	





not_bs	cp $71			; Delete?
	jr nz,not_del
	call locate_cursor_char
	push hl
	ld hl,text_buffer
	ld de,(filesize)
	add hl,de
	pop de
	xor a
	sbc hl,de
	ld c,l
	ld b,h			; bc = bytes to move
	ld h,d
	ld l,e			; hl = cursor location+1
	inc hl			; de = cursor location
	ld a,(de)			; prevent del at end of file
	or a
	jp z,main_loop
	cp $a
	jr z,del_cr
	cp $d
	jr nz,del_ncr
del_cr	inc hl			; if deleting a CR, inc source address for the 2 bytes
	ld a,$a
del_ncr	ldir
	ld bc,(filesize)
	dec bc
	cp $a
	jr nz,sch_del
	dec bc			; if removed a <CR> filesize is reduced by 1 extra byte
sch_del	ld (filesize),bc
	call null_terminate_file
	call draw_text_page
	jp main_loop





not_del	cp $5a				; pressed enter? Insert $0d,$0a "<CR>"
	jr nz,not_enter
	ld a,$0a
	call insert_char_at_cursor
	jp z,main_loop			; if insert failed (memory full) do nothing
	ld a,$0d
	call insert_char_at_cursor
	jr nz,incrok		
	ld bc,(filesize)			; if insert failed, remove previous part of CR
	dec bc
	ld (filesize),bc
	call null_terminate_file
	jp main_loop
incrok	call null_terminate_file
	call draw_text_page
	xor a
	ld (cursor_x),a
	jp curs_down
	
	


not_enter	cp $76				; pressed ESC?
	jp nz,notesc
	call kjt_get_key_mod_flags
	bit 1,a				; Must be holding CTRL too
	jp z,main_loop	
	ld bc,$060a
	ld hl,box_spaces
	call print_string_inv		; Save / Quit / Cancel? (currently a non-standard requester)
	ld bc,$060b
	ld hl,quit_req
	call print_string_inv
	ld bc,$060c
	ld hl,box_spaces
	call print_string_inv
esc_act	call kjt_wait_key_press		; wait for a key
	ld a,b
	cp "s"			
	jr z,save_quit
	cp "q"
	jr z,quit_it
	cp "c"
	jp nz,esc_act			; key must be ESC, S or L


cancel	call set_user_chars
	call clear_charmap_buffer	
	call draw_text_page
	jp main_loop
quit_it	ld a,$07
	call kjt_set_pen
	call kjt_clear_screen
	xor a
	ret

save_quit	ld a,1
	ld (quit_on_save),a
save_it	ld bc,(filesize)
	ld a,b
	or c
	jr z,zero_fl
	ld hl,filename
	ld b,7
	ld c,2
	call save_requester
	jr z,commence_save
	cp $ff
	jr z,cancel
sav_error	or a
	jr nz,fil_error
dhw_error	call hw_error_requester
	jr save_it
fil_error	call file_error_requester
	jr save_it

commence_save

	call hl_to_working_filename
	ld ix,text_buffer
	ld b,0
	ld de,(filesize)
	ld c,0
	ld hl,filename
	call kjt_save_file
	jr nz,sav_error
	ld a,(quit_on_save)
	or a
	jp z,cancel
	call kjt_clear_screen		; saved OK..
	ld hl,file_saved
	call kjt_print_string	
	xor a				; exit to FLOS
	ret


zero_fl	call kjt_clear_screen
	ld hl,zero_fl_txt
	call kjt_print_string
	xor a
	ret
		


notesc	cp $4b				;CTRL + L? - Load a file.
	jr nz,not_l
	ld b,a
	call kjt_get_key_mod_flags		
	bit 1,a
	ld a,b
	jr z,not_l
go_lreq	ld hl,filename			;File load requester
	ld b,7
	ld c,2
	call load_requester
	jr z,commence_load
	cp $ff
	jp z,cancel
	or a
	jr z,l_hwerror
load_err	call file_error_requester
	jr go_lreq
l_hwerror	call hw_error_requester
	jp go_lreq
	
commence_load

	call hl_to_working_filename
	jp load_file



not_l	cp $1b				;CTRL + S? - Save a file.
	jr nz,not_s
	ld b,a
	call kjt_get_key_mod_flags
	bit 1,a
	ld a,b
	jr z,not_s
	xor a
	ld (quit_on_save),a
	jp save_it



not_s	ld a,(current_asciicode)		; enter ascii character into file
	or a
	jp z,main_loop
	ld a,(cursor_x)			; can enter text at far side
	cp window_cols
	jp z,main_loop
	ld a,(insert_mode)			; overwrite mode?
	or a
	jr z,norm_ins
	call locate_cursor_char	
	ld a,(hl)				; overwrite can only overwrite normal
	or a				; ascii chars, skip if dest char is <CR>
	jr z,norm_ins			; or EOF (0)
	cp $a
	jr z,norm_ins
	cp $d
	jr z,norm_ins
	ld a,(current_asciicode)
	ld (hl),a
	jr ovwr_done
norm_ins	ld a,(current_asciicode)
	call insert_char_at_cursor
	jr nz,inchok			;if zero flag set, op failed
	call draw_text_page
	jp main_loop
inchok	call null_terminate_file
ovwr_done	call draw_text_page
	jp curs_righ

;---------------------------------------------------------------------------------------------

insert_char_at_cursor

	push af			; set A to byte to enter at cursor pos
	call locate_cursor_char
	ld e,l
	ld d,h
	ld hl,text_buffer
	ld bc,(filesize)
	inc bc
	add hl,bc
	jr c,buff_full
	ld (filesize),bc
	push hl			
	xor a
	sbc hl,de
	ld c,l
	ld b,h
	pop hl
	ld e,l
	ld d,h
	dec hl
	lddr			;push everything after offset one char onwards
	call locate_cursor_char
	pop af
	ld (hl),a			;insert new character
	or a
	ret
buff_full	call locate_cursor_char	;cannot add more chars - memory full
	pop af
	ld (hl),a			
	xor a
	ret



locate_cursor_char
	
	ld de,(text_base)		; find offset based on cursor pos
	ld a,(cursor_y)		; return it in HL
fosl	dec a
	jr z,comlpos
	push af
fnlpos	ld a,(de)			; count lines from text base
	or a
	jr z,fndeof
	cp $a
	jr z,gnlpos
	cp $d
	jr z,gnlpos
	inc de
	jr fnlpos
gnlpos	inc de
	inc de
gnlpos2	pop af
	jr fosl	
fndeof	pop af
comlpos	ld a,(cursor_x)
	ld l,a
	ld h,0
	add hl,de
	ret



find_next_line





reposition_cursor_x
		
	xor a			; move cursor x as far right in new line as text will allow
	ld (cursor_x),a
	ld b,window_cols
checkchar	push bc
	call locate_cursor_char
	pop bc
	ld a,(hl)
	or a
	ret z
	cp $a
	ret z
	cp $d
	ret z
	ld hl,cursor_x
	inc (hl)
	djnz checkchar
newcxpos	ret




null_terminate_file

	ld hl,text_buffer
	ld bc,(filesize)
	add hl,bc
	ld (hl),0
	ret


backup_charmap

	ld hl,OS_charmap
	ld de,charmap_buffer
	ld bc,window_rows*window_cols
	ldir
	ret

	
draw_text_page
	
	xor a
	ld (eof_flag),a

	ld hl,(text_base)
	ld bc,$0001		;b = x, c = y
dtp_loop	ld a,(hl)
	or a
	jr z,eof			;end of file?
	cp $a
	jr z,space_chk
	cp $d
	jr nz,nospc_chk
space_chk	ld a,b
	cp window_cols
	jr z,gotncr		;line is fully populated no need for spaces
	ld a,32
	push hl
	push bc
	call plotchar
	pop bc
	pop hl
	inc b
	jr space_chk
	
nospc_chk	push hl			;plot the char on screen
	push bc
	call plotchar
	pop bc
	pop hl
	inc hl
	inc b
	ld a,b
	cp window_cols
	jr nz,dtp_loop
fnxtl	ld a,(hl)			;line full - move beyond next CR
	or a
	jr z,eof2
	cp $d
	jr z,gotncr
	cp $a
	jr z,gotncr
	inc hl
	jr fnxtl
gotncr	inc hl
	inc hl
	ld b,0
	inc c
	ld a,c
	cp window_rows
x_ok	jr nz,dtp_loop

arrows	ld b,window_cols-1
	ld c,window_rows
	ld hl,arrow_down
	ld a,(eof_flag)
	or a
	jr z,daud
	inc hl
	inc hl
daud	call print_string_inv
	ret
	
eof	push bc			;fill rest of window with spaces
	ld a,32
	call plotchar
	pop bc
	inc b
	ld a,b
	cp window_cols
	jr nz,eof
eof2	ld b,0
	inc c
	ld a,c
	cp window_rows
	jr nz,eof
	ld a,1			;set end of file marker
	ld (eof_flag),a
	jr arrows
	
	


move_text_base_up_a_line

	ld ix,(text_base)		;moves the text base up a line, if possible
	dec ix
	ld a,(ix)
	or a			;textbase cant be changed already at start of file
	jr z,aborttbu		
	cp $a			;if the previous char is CR as expected, go back two bytes
	jr z,normcr
	cp $d
	jr nz,notcr		;if the previous char was not a CR can back max 40 chars
normcr	dec ix			
	dec ix
notcr	ld a,(ix)			;now find the CR before and position text_base after it
	or a			;(goes to the start of long, unbroken lines) 		
	jr z,gotla
	cp $d
	jr z,gotla
	cp $a
	jr z,gotla
	dec ix
	jr notcr
gotla	or a
	jr nz,notsof
	ld a,1
	ld (sof_flag),a
notsof	inc ix
	ld (text_base),ix
	ld bc,(line_count)
	dec bc
	ld (line_count),bc
	xor a
	ld (eof_flag),a
aborttbu	ret

	
	
move_text_base_down_a_line

	ld ix,(text_base)		;moves the text base down a line, if possible
mtbdlp	ld a,(ix)			;any lines of more than 40 chars are treated as one line
	or a
	jr z,aborttbd		
	cp $a			
	jr z,gntbd
	cp $d
	jr z,gntbd		
	inc ix
	jr mtbdlp
gntbd	inc ix
	inc ix
tbdman	ld (text_base),ix
	xor a
	ld (sof_flag),a
	ld bc,(line_count)
	inc bc
	ld (line_count),bc
	ret
aborttbd	ld a,1
	ld (eof_flag),a
	ret

;----------------------------------------------------------------------------------------------
	
clear_charmap_buffer
	
	ld hl,charmap_buffer		; remove dialog box (invalidate text buffer..
	ld bc,window_rows*window_cols		;...forces everthing to be redrawn)
	xor a
	call kjt_bchl_memfill		
	ret
	
;---------------------------------------------------------------------------------------------

set_bitplane

	and %00000111		;set bitplane number in A
	or  %00001000		;use upper 64KB or VRAM
	ld (vreg_vidpage),a
	ret

;---------------------------------------------------------------------------------------------
	
print_string_inv

tbloop	ld a,(hl)
	or a
	jr z,psi_done
	push hl
	push bc
	call plotchar_inv
	pop bc
	pop hl
	inc b
	inc hl
	jr tbloop
	
psi_done	ld a,$07
	call kjt_set_pen
	ret
	
;---------------------------------------------------------------------------------------------

plotchar	push hl			; is the new char in A to be plotted at (B,C) the same	
	push de			; as that already on display? If so, dont botter plotting it
	push bc
	push af
	
	ld hl,window_cols*64	 
	ld (mult_table),hl		
	
	ld l,a			; get offset in charmap based on b/c
	xor a
	ld (mult_index),a		
	ld d,c
	ld e,a
	ld (mult_write),de
	ld a,l
	ld de,(mult_read)		; y line offset (chars)	
	ld l,b
	ld h,0
	add hl,de
	ex de,hl			; de = offset
	
	ld hl,charmap_buffer
	add hl,de	
	pop af
	cp (hl)
	jr nz,diffchar
	pop bc
	pop de
	pop hl
	ret

diffchar	pop bc
	pop de
	pop hl
	
	push af
	ld a,$07
	call kjt_set_pen
	pop af
	call kjt_plot_char
	ret
	
	
plotchar_inv

	push af
	ld a,$70
	call kjt_set_pen
	pop af
	call kjt_plot_char
	ret
	
	
;-----------------------------------------------------------------------------------------	


cursor_flash

	ld hl,cursorflashtimer
	inc (hl)
	ld a,(hl)
	cp 25
	ret nz
	ld (hl),0
	ld a,(cursorstatus)
	xor 1
	ld (cursorstatus),a
	or a
	jr z,delete_cursor



draw_cursor

	ld a,(cursor_x)
	cp window_cols
	jr nz,cposok
	ld a,window_cols
	dec a
cposok	ld b,a			;draw cursor at extreme right if end of a line
	ld a,(cursor_y)
	ld c,a
	call kjt_set_cursor_position
	
	ld hl,$c00		;cursor image = block (for insert mode)
	ld a,(insert_mode)
	or a
	jr nz,block_cur
	ld hl,$43f		;normal underscore cursor
block_cur	ld a,(cursor_x)
	cp window_cols
	jr nz,nspecialc
	ld hl,$464		;right block symbol for right edge
nspecialc	call kjt_draw_cursor
	ret
	
	


delete_cursor

	ld a,(cursor_x)
	cp window_cols
	jr nz,cposok2
	ld a,window_cols
	dec a
cposok2	ld b,a
	ld a,(cursor_y)
	ld c,a
	call kjt_set_cursor_position

	ld hl,0
	call kjt_draw_cursor
	ret


	
;------------------------------------------------------------------------------------------------

hex_to_dec

;set hl to hex word	
;output hl = leading zero skipped dec_string
	
	ld ix,dec_string
	ld de,10000		
	call hex_to_dec_digit
	ld de,1000
	call hex_to_dec_digit
	ld de,100
	call hex_to_dec_digit
	ld de,10
	call hex_to_dec_digit
	ld de,1
	call hex_to_dec_digit
	ld hl,dec_string
	ld b,4
slazlp	ld a,(hl)			;advances HL past leading zeros in ascii string
	cp "0"			;set b to max numner of chars to skip
	jr nz,foundnz
	inc hl
	djnz slazlp
	
foundnz	push hl
	ld hl,dec_string+5		;replaces zeros removed from start with trailing spaces
	ld a,5			
	sub b
	ld b,a
pdsplp	ld (hl),32
	inc hl
	djnz pdsplp
	ld (hl),0
	pop hl
	ret
	
	
hex_to_dec_digit

	ld (ix),$30
htd_lp	xor a
	sbc hl,de
	jr c,htd_dd
	inc (ix)
	jr htd_lp
htd_dd	add hl,de
	inc ix
	ret

;---------------------------------------------------------------------------------
	
set_user_chars

	ld a,%00001111		;set the page of video memory
	ld (vreg_vidpage),a		;for font ($1e000-$1ffff)

	call kjt_page_in_video			
	ld hl,my_chars		
	ld b,8
	ld de,video_base+$460
reorgflp	push bc
	ld bc,32
	ldir
	ld bc,96
	ex de,hl
	add hl,bc
	ex de,hl	
	pop bc
	djnz reorgflp
	
	ld bc,$400		; make inverse charset (@ $1E800)
	ld hl,video_base+$400
	ld de,video_base+$800
invloop	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,invloop
	call kjt_page_out_video
	ret

;--------------------------------------------------------------------------------------

hl_to_working_filename

	push hl			; copy args to working filename string
	ld de,filename
	ld b,16
fnclp	ld a,(hl)
	or a
	jr z,fncdone
	cp " "
	jr z,fncdone
	ld (de),a
	inc hl
	inc de
	djnz fnclp
fncdone	xor a
	ld (de),a			; null terminate filename
	pop hl
	ret
	
;--------------------------------------------------------------------------------------

include	"file_requesters.asm"

my_chars	incbin "symbol_chars.bin"

;--------------------------------------------------------------------------------------
	

text_base		dw 0
filesize		dw 0
line_count	dw 0
source		dw 0
move_count	dw 0

cursor_x		db 0
cursor_y		db 0
eof_flag		db 0
sof_flag		db 0

current_scancode	db 0
current_asciicode	db 0
cursorflashtimer	db 0
cursorstatus	db 0
insert_mode	db 0

quit_on_save	db 0

load_error_txt	db "Load error.",11,11,0
file_save_error	db "** Error whilst saving file! **",11,11,0
file_saved	db "File saved OK",11,11,0
zero_fl_txt	db "Nothing to save",11,11,0
file_too_big	db "File too big!",11,11,0

title_bar		db "EDIT:                           V0.10   ",0
filename		db "NEW.TXT"
		ds 40,0
footer_bar	db "Col:        Line:        Size:          ",0
box_spaces	db "                             ",0
quit_req		db " [S]ave, [Q]uit or [C]ancel? ",0
arrow_up		db $80,0," ",0
arrow_down	db $81,0," ",0

dec_string	db "00000          "

charmap_buffer	ds window_rows*window_cols,0

;------------------------------------------------------------------------------------------------

		db 0			;sof detect
text_buffer 	db 0
		db 0			

;------------------------------------------------------------------------------------------------
