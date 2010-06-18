
; Tests:  kjt_get_char_at_xy
;         kjt_get_window_size
;
; Should copy top half of display to bottom (not including attributes)
;
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000


;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$559
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	pop hl
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v559+",11,11,0
		
flos_ok	pop hl


;--------------------------------------------------------------------------------------------------

	call kjt_get_display_size
	push bc				
	pop de				;d = width, e = height
	ld c,0
lp2	ld b,0
lp1	call kjt_get_charmap_addr_xy
	ld a,(hl)
	push bc
	push af
	ld a,c
	ld l,e
	srl l
	add a,l
	ld c,a
	pop af
	call kjt_plot_char
	pop bc
	inc b
	ld a,b
	cp d
	jr nz,lp1
	inc c
	ld a,c
	ld l,e
	srl l
	cp l
	jr nz,lp2
	xor a
	ret
	
;---------------------------------------------------------------------------------------------------	