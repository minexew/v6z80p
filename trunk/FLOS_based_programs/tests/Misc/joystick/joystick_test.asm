
; Tests Joystick ports (simplified 10-08-2010)

;---Standard header for OSCA and FLOS -----------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000	

;---------Set up video --------------------------------------------------------------------------------------


	ld a,%00000000			; select y window pos register
	ld (vreg_rasthi),a		 
	ld a,$2e				; set 256 line display
	ld (vreg_window),a
	ld a,%00000100			; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a			; set 256 pixels wide window

	ld ix,bitplane0a_loc	 
	ld hl,0				; Set video window start address		
	ld a,0 
set_vaddr	ld (ix),l				;\ 
	ld (ix+1),h			;- Video fetch start address for this frame
	ld (ix+2),a			;/
		
	ld a,%10000000
	ld (vreg_vidctrl),a			; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	

	
;--------- Copy 128x128 pic to display ----------------------------------------------------------------------
 
	ld a,0
	ld (vreg_vidpage),a			; select first 64kb of video ram
	
	di				; temp disable interrupts
	ld a,%00100000			; Z80 address space = 64KB page of video RAM for writes
	out (sys_mem_select),a

	ld hl,0
	ld b,0
clrlp1	ld (hl),b				; clear 64kb of vram
	inc hl
	ld a,h
	or l
	jr nz,clrlp1
	
	ld hl,source_pic			; copy the joystick pic to vram (in centre of window)
	ld de,64+(64*256)
	ld a,128
lp1	ld bc,128
	ldir
	ex de,hl
	ld bc,128
	add hl,bc
	ex de,hl
	dec a
	jr nz,lp1
		
	xor a
	out (sys_mem_select),a
	ei				;reenable interrupts
	
	ld hl,colours			;write palette
	ld de,palette
	ld bc,512
	ldir
	
;--------------------------------------------------------------------------------------------

wvrtstart	call kjt_wait_vrt
	
	call do_stuff

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart			; loop if ESC key not pressed
	
	ld a,$ff				; quit
	or a
	ret

	
;-----------------------------------------------------------------------------------------
		
		
do_stuff	ld hl,palette+(240*2)		;show joystick directions by changing colour palette
	ld b,16
pgrey	ld (hl),$88
	inc hl
	ld (hl),$08
	inc hl
	djnz pgrey
	
	xor a
	out (sys_ps2_joy_control),a		;select port a
	
	ld hl,palette+(240*2)
	in a,(sys_joy_com_flags)
	
	bit 0,a
	jr z,not_a0
	ld (hl),$0f00

not_a0	inc hl
	inc hl
	bit 1,a
	jr z,not_a1
	ld (hl),$0f00

not_a1	inc hl
	inc hl
	bit 2,a
	jr z,not_a2
	ld (hl),$0f00

not_a2	inc hl
	inc hl
	bit 3,a
	jr z,not_a3
	ld (hl),$0f00

not_a3	inc hl
	inc hl
	bit 4,a
	jr z,not_a4
	ld (hl),$0f00

not_a4	inc hl
	inc hl
	bit 5,a
	jr z,not_a5
	ld (hl),$0f00
not_a5	

	ld a,%00000001
	out (sys_ps2_joy_control),a	;select port b
	
	ld hl,palette+(248*2)
	in a,(sys_joy_com_flags)
	bit 0,a
	jr z,not_b0
	ld (hl),$0f00

not_b0	inc hl
	inc hl
	bit 1,a
	jr z,not_b1
	ld (hl),$0f00

not_b1	inc hl
	inc hl
	bit 2,a
	jr z,not_b2
	ld (hl),$0f00

not_b2	inc hl
	inc hl
	bit 3,a
	jr z,not_b3
	ld (hl),$0f00

not_b3	inc hl
	inc hl
	bit 4,a
	jr z,not_b4
	ld (hl),$0f00

not_b4	inc hl
	inc hl
	bit 5,a
	jr z,not_b5
	ld (hl),$0f00
	
not_b5	ret


;-----------------------------------------------------------------------------------------

source_pic incbin "joystick_chunky.bin"
colours    incbin "joystick_12bit_palette.bin"

;-------------------------------------------------------------------------------------

