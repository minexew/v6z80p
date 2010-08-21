
; App: Set - set environment variable - v1.00 By Phil @ retroleum
; Usage: set "var_name" "var_value" (if no parameters supplied, en_vars are listed)

;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;======================================================================================
; Program Location File Header:
; FLOS v568+ will use this data to load the program a specific location
; Earlier versions of FLOS will ignore it and load the program to $5000
;======================================================================================

my_location	equ $f000
my_bank		equ $0e


	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; dont truncate the program load

exec_addr	


;=======================================================================================	
; Location Check:
; As an earlier version of FLOS may have loaded the program, or it has
; simply been loaded into memory somwhere as a binary file we can check to
; see if it is in the desired location before the main code attempts to run.
;=======================================================================================

	push hl		; Tests to see if code is located in the correct place to run
	ld hl,sector_buffer	; use sector buffer location 0 for the test routine
	ld a,(hl)		; preserve the byte that was there
	ld (hl),$c9	; place a RET instruction there	
	call sector_buffer	; Call the RET, PC of true_loc is pushed on stack and returns back here
true_loc	ld (hl),a		; put the preserved byte back where RET was placed
	ld ix,0		
	add ix,sp		; get SP in IX
	ld l,(ix-2)	; HL = PC of true_loc from stack (load_loc + 8 + 11)
	ld h,(ix-1)
	ld de,true_loc-load_loc
	xor a
	sbc hl,de		; HL = actual location that program was loaded to
	push hl
	pop ix		
	ld e,(ix+4)
	ld d,(ix+5)	; DE = address where program is SUPPOSED to be located
	xor a
	sbc hl,de		; are we in the right place?
	pop hl	
	jr z,loc_ok	
	push ix		; No, so show an error message (using relative addressing)
	pop hl
	ld de,locer_txt-load_loc
	add hl,de
	call kjt_print_string
	xor a	
	ret

locer_txt	db "Program cannot run from this location.",11,0	

loc_ok	


;=======================================================================================		
;  Main Code starts here
;=======================================================================================



;--------- Test FLOS version -----------------------------------------------------------


required_flos equ $575


	push hl
	call kjt_get_version	
	ld de,required_flos 	
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	ld hl,hex_txt
	push hl
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	inc hl
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v",0
hex_txt	db "----+",11,11,0

flos_ok


;-------- Parse command line arguments -------------------------------------------------
	

fnd_para1	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jp z,show_vars
	cp " "			; ignore leading spaces...
	jr nz,para1_ok
	inc hl
	jr fnd_para1

para1_ok	push hl
	ld de,var_name
	ld b,4
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl

fnd_spc	inc hl
	ld a,(hl)			; locate next space
	or a
	jp z,missing_value
	cp " "
	jr nz,fnd_spc

fnd_para2	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jp z,missing_value
	cp " "			; ignore leading spaces...
	jr nz,para2_ok
	inc hl
	jr fnd_para2

para2_ok				

;------------------------------------------------------------------------------------------------------------

	ld b,8			; convert ascii to long word
lp4	ld a,(hl)
	or a
	jr z,got_evd
	cp " "
	jr z,got_evd
	push bc
	cp $60
	jr c,upcase
	sub $20
upcase	sub $3a			
	jr c,zeronine
	add a,$f9
zeronine	add a,$a
	push hl
	ld hl,(var_data)
	ld de,(var_data+2)
	ld b,4
rotquad	add hl,hl
	rl e
	rl d
	djnz rotquad
	ld (var_data),hl
	ld (var_data+2),de
	ld hl,var_data
	and $f
	or (hl)
	ld (hl),a
	pop hl
	inc hl
	pop bc
	djnz lp4
	
got_evd	ld hl,var_name		;set the environment variable
	ld de,var_data
	call kjt_set_envar
	ret z
	ld hl,no_room_txt
	jr err_quit

;------------------------------------------------------------------------------------------------------------

	
show_vars	

	ld hl,defined_vars_txt
	call kjt_print_string
	
	ld hl,fake_var_txt
	call kjt_get_envar		;just get start of list and max vars count
	ld b,a
	
lp2	push bc	
	ld a,(hl)
	or a
	jr z,skp_ev
	
	push hl
	ld de,var_name
	ld bc,4
	ldir
	ld hl,var_name
	call kjt_print_string	;show env_var name
	pop hl
	
	push hl

	ld de,4
	add hl,de
	ld de,var_data
	ld bc,4
	ldir
	ld de,var_data+3		;show env_var databytes
	ld hl,hex_output_txt+4
	ld b,4
lp1	ld a,(de)
	push de
	call kjt_hex_byte_to_ascii
	pop de
	dec de
	djnz lp1
	call kjt_get_cursor_position
	ld b,4
	call kjt_set_cursor_position
	ld hl,hex_output_txt	
	call kjt_print_string
	
	pop hl
	ld de,8
	add hl,de
skp_ev	pop bc
	djnz lp2
	xor a
	ret
	
	
;------------------------------------------------------------------------------------------------------------
	
missing_value

	ld hl,missing_value_txt
err_quit	call kjt_print_string
	xor a
	ret


;-------------------------------------------------------------------------------------------

var_name	ds 5,0
var_data  ds 5,0

missing_value_txt	db "No value given for variable.",11,11,0
no_room_txt	db "Not enough space for variable.",11,11,0

hex_output_txt	db " = $xxxxxxxx",11,0

fake_var_txt	db "@@@@",0
defined_vars_txt	db 11,"Environment variables:",11
		db "----------------------",11,11,0
		
;-------------------------------------------------------------------------------------------

