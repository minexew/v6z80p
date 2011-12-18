;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
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


;--------- Test OSCA version ---------------------------------------------------------------------

	call kjt_get_version		
	ex de,hl
	ld de,$669
	xor a
	sbc hl,de
	jr nc,osca_ok
	ld hl,old_osca_txt
	call kjt_print_string
	xor a
	ret

old_osca_txt

	db "Program requires OSCA v669+",11,11,0
	
osca_ok	


;-----------------------------------------------------------------------------------------

	ld hl,stereo_txt
	call kjt_print_string
	ld a,%01011010		;as original mixer
	out ($22),a
	xor a
	ret

;-----------------------------------------------------------------------------------------

stereo_txt	db "Sound config set to stereo",11,0
	
;-----------------------------------------------------------------------------------------
