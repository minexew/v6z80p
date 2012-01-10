
; Type [filename] command - shows text files By Phil '09
;
; v1.03 - tab positioning added

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 		"force_load_location.asm"

required_flos	equ $594
include 		"test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------


window_rows equ 25
window_cols equ 40


fnd_para	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jr nz,fn_ok

show_use	ld hl,usage_txt
	call kjt_print_string
	xor a
	ret
	
fn_ok	push hl			; copy args to working filename string
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
	
	ld hl,filename		; does filename exist?
	call kjt_find_file
	ret nz
			
	call kjt_get_cursor_position
	ld (cursor_pos),bc
	ld hl,$ffff
	ld (textfile_offset_hi),hl
	ld hl,$ff00		
	ld (textfile_offset_lo),hl	
	ld a,$ff
	ld (buffer_offset),a
	xor a
	ld (line_count),a
	call kjt_get_pen
	ld (original_pen),a

	call main_loop

	ld bc,(cursor_pos)
	call kjt_set_cursor_position
	ld a,(original_pen)
	call kjt_set_pen
	ld hl,new_line
	call kjt_print_string
	xor a
	ret
	
;============================================================================================

	
main_loop	call get_next_char
	or a
	ret z
	
	ld bc,(cursor_pos)
	cp 9
	jr z,tab
	cp 10
	jr z,linefeed
	cp 13
	jr z,car_ret
	cp 11
	jr z,crlf
	
	push bc
	call kjt_plot_char
	pop bc
	inc b
	ld a,b
	cp window_cols
	jr nz,sameline
crlf	ld b,0
linefeed	inc c
	ld a,window_rows
	cp c
	jr nz,noscroll
	dec a
	ld c,a
	push bc
	call kjt_scroll_up
	pop bc
	
noscroll	ld a,(line_count)
	inc a
	ld (line_count),a
	ld e,a
	ld a,window_rows-1
	cp e
	jr nz,sameline
	xor a
	ld (line_count),a
	call more_prompt		
	ret nz
	
sameline	ld (cursor_pos),bc
	jr main_loop
	
car_ret	ld b,0
	jr sameline

tab	ld a,b
	add a,8
	and $f8
	ld b,a
	cp window_cols
	jr c,sameline
	jr crlf


;---------------------------------------------------------------------------------------------


get_next_char
	
	push hl
	push de
	push bc
	
	ld a,(buffer_offset)
	inc a
	ld (buffer_offset),a
	jr nz,ltb_ok
	ld hl,(textfile_offset_lo)
	ld de,256
	add hl,de
	ld (textfile_offset_lo),hl
	jr nc,nochhi
	ld hl,(textfile_offset_hi)
	inc hl
	ld (textfile_offset_hi),hl

nochhi	ld hl,text_buffer			;zero text buffer
	ld bc,256
	xor a
	call kjt_bchl_memfill
	
	ld ix,0
	ld iy,256				;only load enough chars to fill buffer
	call kjt_set_load_length
	ld ix,(textfile_offset_hi)
	ld iy,(textfile_offset_lo)		;index from start of file
	call kjt_set_file_pointer
	ld hl,text_buffer			;load in part of the file	
	ld b,my_bank
	call kjt_force_load
	or a			
	jr z,ltb_ok			;file system error?
	cp $1b			
	jr z,ltb_ok			;Dont cared if attempted to load beyond end of file
ltb_fail	pop bc
	pop de
	pop hl
	xor a				;if fail, return a zero (EOF) byte
	ret
		
ltb_ok	ld hl,text_buffer
	ld a,(buffer_offset)
	ld e,a
	ld d,0
	add hl,de
	ld a,(hl)
	
	pop bc
	pop de
	pop hl
	ret
	

;-------------------------------------------------------------------------------------------

more_prompt

	push bc
	ld b,0
	ld c,window_rows-1
	call kjt_set_cursor_position
	ld a,$81
	call kjt_set_pen
	ld hl,more_txt
	call kjt_print_string

	call kjt_wait_key_press
	ld a,b
	cp "y"

	push af
	ld a,$00
	call kjt_set_pen
	ld hl,more_gone_txt
	call kjt_print_string
	ld a,(original_pen)
	call kjt_set_pen
	pop af

	pop bc
	ret
	
;-------------------------------------------------------------------------------------------

usage_txt		db "TYPE v1.03 - shows ASCII text",11,"Usage: TYPE filename",11,0

more_txt		db " More? (y/n) ",13,0
more_gone_txt	db "             ",0
	
filename		ds 32,0
text_buffer	ds 256,0			

cursor_pos	dw 0
original_pen	db 0
line_count	db 0

textfile_offset_lo	dw 0
textfile_offset_hi	dw 0

buffer_offset	db 0

new_line		db 11,0

;-------------------------------------------------------------------------------------------

