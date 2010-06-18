
; Example of adding 32-user defined character to the FLOS font
; (characters 128-160) - REQUIRES FLOS 557


;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000


;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$557
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	pop hl
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v557+",11,11,0
		
flos_ok	pop hl

;-------------------------------------------------------------------------------

	call set_user_chars		;insert the new 32 chars into the FLOS font

;-------------------------------------------------------------------------------

	
	ld d,$20			;this just shows the charset 
	ld e,$00			
testloop	ld a,e
	call kjt_set_pen		
	ld a,e
	and $f
	ld b,a			;x coord
	ld a,e
	rrca
	rrca
	rrca
	rrca
	and $f
	ld c,a			;y coord
	ld a,d			;ascii char to plot
	push de
	call kjt_plot_char
	pop de	
	inc d			;next char
	ld a,d
	cp $a0
	jr nz,charok
	ld d,$20
charok	inc e			;next pen colour
	jr nz,testloop
	ld a,$07
	call kjt_set_pen		;select pen colour
	xor a			;no error on return 
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

my_chars	incbin "mychars.bin"

;--------------------------------------------------------------------------------------
