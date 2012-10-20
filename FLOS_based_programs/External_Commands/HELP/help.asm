
; Help [command] - shows help text files By Phil '12

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------


window_rows equ 25
window_cols equ 40

	call kjt_store_dir_position

	ld a,(hl)			; examine argument text, if 0 show use
	or a			
	jr nz,fn_ok

show_use	call div_line
	ld hl,usage_txt
	call kjt_print_string
	call div_line
	xor a
	ret
	
fn_ok	ld de,colon_cmd_txt		;is the command specified : < > or ?
	cp ":"
	jp z,got_nonalpha_cmd
	ld de,gtr_cmd_txt
	cp ">"
	jp z,got_nonalpha_cmd
	ld de,ltn_cmd_txt
	cp "<"
	jp z,got_nonalpha_cmd
	ld de,query_cmd_txt
	cp "?"
	jp z,got_nonalpha_cmd
	
	ld de,vol_txt		;is it VOL0 to VOL9?
	ld b,3
	call kjt_compare_strings
	jr nc,notvol
	ld de,vol_cmd_txt
	push hl
	pop ix
	ld a,(ix+3)
	cp "x"
	jp z,got_nonalpha_cmd
	cp "X"
	jp z,got_nonalpha_cmd
	cp " "
	jp z,got_nonalpha_cmd
	cp $30
	jr c,notvol
	cp $3a
	jp c,got_nonalpha_cmd
	
notvol	ld de,filename		; copy args to working filename string
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
fncdone	ex de,hl
	ld (hl),"."		;append ".txt" extension to command name
	inc hl
	ld (hl),"T"
	inc hl
	ld (hl),"X"
	inc hl
	ld (hl),"T"
	inc hl
	ld (hl),0			; null terminate filename
	
	call kjt_root_dir		; go to root dir

	ld hl,docs_txt		; go to docs dir
	call kjt_change_dir
	jr nz,doc_dir_nf
	
	ld hl,filename		; does filename exist here?
	call kjt_open_file
	jr z,gotdocf

	ld hl,cmds_txt		; go to /cmds subdir if possible
	call kjt_change_dir
	jr nz,nodocf
	
	ld hl,filename		; does filename exist?
	call kjt_open_file
	jr nz,nodocf
	
gotdocf	call div_line
			
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
	
	call div_line
	
	ld a,(original_pen)
	call kjt_set_pen

	call kjt_restore_dir_position
	xor a
	ret

;============================================================================================

nodocf	ld hl,no_doc_file_txt
	jr print_end
	

doc_dir_nf

	ld hl,no_doc_dir_txt
print_end	call kjt_print_string
	call kjt_restore_dir_position
	xor a
	ret



got_nonalpha_cmd
	
	ex de,hl
	call div_line
	call kjt_print_string
	call div_line
	call kjt_restore_dir_position
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

div_line
	push hl
	ld hl,div_line_txt
	call kjt_print_string
	pop hl
	ret
	
;-------------------------------------------------------------------------------------------

docs_txt		db "docs",0

cmds_txt		db "int_cmds",0

no_doc_dir_txt	db 11,"Cannot find 'DOCS' dir in root.",11,0

no_doc_file_txt	db 11,"Cannot find associated .txt file.",11,0

usage_txt		db 11,"HELP v1.00 - shows command docs.",11,"Usage: HELP command",11,11,0

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

div_line_txt	ds 39,"-"
		db 11,0

vol_txt		db "VOL",0

;--------------------------------------------------------------------------------------------
; These commands cannot have associated doc files because of their non-alphanumeric names
; Therefore the text is just included in the source.
;--------------------------------------------------------------------------------------------


colon_cmd_txt	db 11,": - Put bytes in memory",11,11
		db "Usage: ",$22,": address byte1 [b2 b3..]",$22,11,11,0
		
gtr_cmd_txt	db 11,"> - Put text in memory",11,11
		db "Usage: > address ",$22,"text",$22,11,11,0

ltn_cmd_txt	db 11,"< - Put bytes in memory & disassemble",11,11
		db "Usage: < address hex_bytes",11,11,0

query_cmd_txt	db 11,"? - Show internal commands",11,11
		db "Usage: ?",11,11,0

vol_cmd_txt	db 11,"VOLx: - Change volume",11,11
		db "Usage: VOLx:",11,11
		db "Where x ix 0 to 7",11,11,0
		

;-------------------------------------------------------------------------------------------

