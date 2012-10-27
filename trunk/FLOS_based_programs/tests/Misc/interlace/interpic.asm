
; Tests interlace mode

; Loads the even and odd fields of an interlaced picture (256x512)
; then alternates the frames with interlace mode enabled.

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;------- Load pic ----------------------------------------------------------------------

	ld hl,e_pic_filename	;load pic (even lines) to $00000
	call kjt_find_file
	jp nz,fferror
	ld a,0
	ld (bank),a
	ld b,8
loadloop1	push bc
	ld ix,$0000
	ld iy,$2000
	call kjt_set_load_length
	ld hl,buffer
	ld b,0
	call kjt_force_load
	jp nz,lferror
	ld a,(bank)
	ld (vreg_vidpage),a
	inc a
	ld (bank),a
	call kjt_page_in_video
	ld hl,buffer
	ld de,$2000
	ld bc,$2000
	ldir
	call kjt_page_out_video
	pop bc
	djnz loadloop1

	ld hl,o_pic_filename	;pic (odd lines) to $10000
	call kjt_find_file
	jp nz,fferror
	ld a,8
	ld (bank),a
	ld b,8
loadloop2	push bc
	ld ix,$0000
	ld iy,$2000
	call kjt_set_load_length
	ld hl,buffer
	ld b,0
	call kjt_force_load
	jp nz,lferror
	ld a,(bank)
	ld (vreg_vidpage),a
	inc a
	ld (bank),a
	call kjt_page_in_video
	ld hl,buffer
	ld de,$2000
	ld bc,$2000
	ldir
	call kjt_page_out_video
	pop bc
	djnz loadloop2
	
;-------- Initialize video --------------------------------------------------------------------

	ld hl,0
	ld (palette),hl
	ld a,%00000100
	ld (vreg_vidctrl),a		; disable video whilst setting up
	
	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$2e			; set 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld hl,colours
	ld de,palette		; upload palette
	ld bc,512
	ldir
	
	ld ix,bitplane0a_loc	; Even field pic video address
	ld hl,0					
	ld a,0 
	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/
		
	ld ix,bitplane0b_loc	; Odd field pic video address
	ld hl,0			; 	
	ld a,1 
	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/

	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

	ld a,%00000100
	ld (vreg_ext_vidctrl),a	; enable interlace mode


;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
;	ld hl,$f00
;	ld (palette),hl

	call vrt_routines

;	ld hl,0
;	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed
	xor a
	ld a,$ff			;quit (restart OS)
	ret


;-------------------------------------------------------------------------------------------


vrt_routines
	
			
	ld a,(vreg_read)		;show the appropriate field based on the
	rrca			;longframe bit in vreg_read (ideally this
	rrca			;can done automatically with the LineCop)
	cpl
	and %00100000
	or  %10000000
	ld (vreg_vidctrl),a
	ret
	

;-------------------------------------------------------------------------------------------


lferror 	pop bc
fferror	ld hl,error_txt
	call kjt_print_string
	xor a
	ret

	
;-------------------------------------------------------------------------------------------

e_pic_filename	db "tut_even.bin",0
o_pic_filename	db "tut_odd.bin",0

colours		incbin "tut_palette.bin"

error_txt		db "Load error. Missing File?",11,11,0

buffer		ds 8192,0

bank 		db 0

;--------------------------------------------------------------------------------------------