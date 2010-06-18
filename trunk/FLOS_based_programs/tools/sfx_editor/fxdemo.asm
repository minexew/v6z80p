
;---Standard header for V5Z80P and OS ----------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	
	org $5000

;----------------------------------------------------------------------------------------

	ld hl,message
	call kjt_print_string
	
	call upload_samples

;--------- Main loop ---------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

wait_bord	ld a,(vreg_read)		; wait until raster on screen so we can see how much
	bit 2,a			; time routine is taking via colour bars
	jr z,wait_bord

	
	ld hl,$f00 		; border colour = red
	ld (palette),hl

	call play_fx		; main z80 tracker code
	
	ld hl,$007		; border colour = blue 
	ld (palette),hl

	
	call kjt_get_key		; non-waiting key press test
	or a
	jr z,wvrtstart		; loop if no key pressed
	cp $76
	jr z,quitfx
	
	ld a,b			; press keys 1-9 to hear samples
	cp $31
	jr c, wvrtstart
	cp $38
	jr nc, wvrtstart
	sub $30
	call new_fx
	jr wvrtstart
	
quitfx	call silence_fx		; silence channels
	call kjt_flos_display	; restore border colour
	xor a			; and quit
	ret

;--------------------------------------------------------------------------------------------

upload_samples
	
	ld a,4
	out (sys_alt_write_page),a	;dest bank
	ld a,$10
	out (sys_mem_select),a	;src bank (use alt write page)
	ld hl,sample_data
	ld de,$8000
	xor a
	ld bc,end_of_sample_data-sample_data
	dec bc
	bit 7,b
	jr z,sizeok
	ld bc,$8001
	inc a
sizeok	dec bc
	ldir
	or a
	jr z,cpydone
	ex de,hl
	ld hl,end_of_sample_data-sample_data
	ld bc,$8000
	xor a
	sbc hl,bc
	jr z,cpydone
	ld b,h
	ld c,l
	ex de,hl
	ld de,$8000
	ld a,5
	out (sys_alt_write_page),a
	ldir
cpydone	xor a
	out (sys_mem_select),a
	ret
	

;---------------------------------------------------------------------------------------------

message	db 11,11,"Sound FX tester...",11,11
	db "Press keys 1-7 to init FX",11,11
	db "ESC to quit.",11,11,0
	
;---------------------------------------------------------------------------------------------

include "fx_player.asm"

;---------------------------------------------------------------------------------------------

fx_data		incbin "my_fx1.dat"
	
sample_data	incbin "my_fx1.sam"

end_of_sample_data 	db 0

;----------------------------------------------------------------------------------------------