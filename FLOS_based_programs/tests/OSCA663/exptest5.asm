
; Tests horizontal expand pixels mode
; Tests even number of blocky pixels along a line with no modulo

; Should show rainbow line pattern, with no incrementing x-offset

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------------------------------------------------------------------------------

	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		 
	ld a,$2e			; set 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; set 256 pixels wide window

	ld ix,bitplane0a_loc	; initialize datafetch start address HW pointer.
	ld hl,$0000		; datafetch start address (15:0)
	ld c,0			; data fetch start address (16:18)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c

	ld a,$00
	ld (bitplane1a_loc+3),a	; modulo = 0
	ld a,3
	ld (vreg_yhws_bplcount),a	; expanded pixel size = 4

	ld a,%10001000		; Set bitmap mode (bit0 = 0), chunky pixel mode (bit7 = 1)
	ld (vreg_vidctrl),a		; and enable expand mode (bit3 = 1)

	ld a,%00000000
	ld (vreg_vidpage),a		; video page access msb = 0
	
	ld hl,colours		; write palette
	ld de,palette
	ld bc,512
	ldir

	di
	ld a,%00100001
	out (sys_mem_select),a	; select direct vram write mode
		
	xor a
	ld hl,0			; each line has 64 blocky pixels
lp2	ld b,64			
lp1	ld (hl),a
	inc hl
	djnz lp1
	inc a			; change colour for next line
	jr nz,lp2

	ld a,%00000000
	out (sys_mem_select),a	; deselect direct vram write mode
	ei
	

;------------------------------------------------------------------------------------------------------

wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	call do_stuff
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; loop if ESC key not pressed
	ld a,$ff			; and quit (restart OS)
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	ret

;------------------------------------------------------------------------------------------------------



counter		db 0

colours		incbin "testpic_pal.bin"


;---------------------------------------------------------------------------------------------------------
