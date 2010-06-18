
; Tests: Joystick ports

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000	

;-----------------------------------------------------------------------------------------

; Initialize video hardware

	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)
	
	ld a,%01000000
	out (sys_mem_select),a	; page in video ram
	
	ld e,0
	ld a,e
clrabp	ld (vreg_vidpage),a

	ld hl,video_base		; clear all bitplanes
	ld bc,$2000
flp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,flp

	inc e
	ld a,e
	cp 16
	jr nz,clrabp
	
	ld a,0
	ld (vreg_vidctrl),a		;bitmap mode + normal border + video enabled
	ld a,0
	ld (vreg_xhws),a		;x scroll position = 0

	ld a,7
	ld (vreg_yhws_bplcount),a

	ld ix,bitplane0a_loc	;initialize bitplane pointers.
	ld hl,$0			;first bitplane address (15:0)
	ld c,$0			;first bitplane address msb
	ld de,$2000		;size of bitplane
	ld b,16			;number of registers to do
ibpl_lp	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	inc ix
	inc ix
	inc ix
	inc ix
	add hl,de
	jr nc,nobplcr
	set 0,c
nobplcr	djnz ibpl_lp

		
;---------------------------------------------------------------------------------------

; Draw 128x128x8 pic

	ld a,0		
	ld (vid_buffer),a		;software blit writes to bm buffer 0

	ld de,video_base+12+(32*40)	;de = destination address
	ld hl,test_gfx		;source address of graphic
	ld bc,$8010		;b = height / c = width in bytes
	ld a,40-16		;a = destination modulo
	call sw_blit


;-----------------------------------------------------------------------------------------

	ld hl,test_pal		;write palette
	ld de,palette
	ld b,0
pwloop	ld c,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	ld a,c
	ld (de),a
	inc de
	djnz pwloop
		
	ld a,%00000000
	out (sys_mem_select),a	;page out video ram
	
;--------------------------------------------------------------------------------------------

wvrtstart	ld a,(vreg_read)		;wait for Vertical Retrace
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	
	ld hl,counter
	inc (hl)
	
	call do_stuff

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; loop if SPACE key not pressed
	
	ld a,$ff			; quit
	or a
	ret

	
;-----------------------------------------------------------------------------------------
		
		
do_stuff


	ld hl,palette+(240*2)
	ld b,16
pgrey	ld (hl),$88
	inc hl
	ld (hl),$08
	inc hl
	djnz pgrey
	
	ld hl,palette+(240*2)
	xor a
	out (sys_ps2_joy_control),a	;select port a

	ld b,0			;short delay necessart for V4Z80P
lp1	djnz lp1			;as wire-OR selection diodes hold charge for a while
	
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
	
	ld b,0			;short delay necessart for V4Z80P
lp2	djnz lp2			;as wire-OR diodes hold charge for a while
	
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


		
sw_blit	ld ix,blit_vars
	ld (ix),a			;modulo
	ld (ix+1),b		;height
	ld (ix+4),b		;height backup
	ld (ix+2),c		;width
	ld (ix+3),0		;bitplane number
blit_lp2	push de
	ld a,(vid_buffer)
	sla a
	sla a
	sla a
	or (ix+3)
	ld (vreg_vidpage),a
blit_lp1	ld b,0
	ldir
	ld a,(ix)
	add a,e			;add line modulo
	jr nc,nocrmod
	inc d
nocrmod	ld e,a
	ld c,(ix+2)
	dec (ix+1)
	jr nz,blit_lp1
	pop de
	ld a,(ix+4)		;restore height counter
	ld (ix+1),a
	inc (ix+3)		;next bitplane
	ld a,(ix+3)
	cp 8
	jr nz,blit_lp2
	ret
		
;-------------------------------------------------------------------------------------------

blit_vars		db 0,0,0,0,0,0

vid_buffer	db 0

counter 		db 0

showbuffer 	db 0

;-------------------------------------------------------------------------------------------

test_gfx incbin "joystick_bitplanes.bin"
test_pal incbin "joystick_12bit_palette.bin"

;-------------------------------------------------------------------------------------

