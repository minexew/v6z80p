
; Ultra simple OSCA sprite demonstration. (Note that because the coordinate
; range used for simplicity here is 0-255 and no window offsets are added,
; the sprite spends a lot of time outside of the visible display window).
; (Source tab width=8)

;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;-------- Set up sprite ------------------------------------------------------

		ld hl,spr_registers  		; zero all 128 4-byte sprite registers
		ld b,0
wsprrlp 	ld (hl),0
		inc hl
		ld (hl),0
		inc hl
		djnz wsprrlp

		ld a,%10000000
		out (sys_mem_select),a		; page sprite RAM into $1000-$1fff
	
		ld a,%10000000
		ld (vreg_vidpage),a		; select sprite page 0

		ld hl,sprite_base		; fill sprite block 0 definition @ $1000
		ld b,0				; with ones to make a simple sprite image
lp1		ld (hl),1
		inc hl
		djnz lp1
	
		xor a
		out (sys_mem_select),a		; page sprite RAM out of $1000-$1fff
	
		ld a,1
		ld (vreg_sprctrl),a		; Set bit 0 to enable sprites


;-------- Move Sprite ---------------------------------------------------------


sp_loop		call kjt_wait_vrt		; wait for last scan line of display

		ld ix,spr_registers		; First sprite 0 register
		ld a,(x_coordinate)
		ld (ix+0),a			; set x coord
		inc a				; move x coord 1 pixel right
		ld (x_coordinate),a		; update x coord variable
		ld (ix+1),$10			; height = 16 pixels, control bits = 0000
		ld a,(y_coordinate)		
		ld (ix+2),a			; set y coord
		dec a				; move y coord 1 pixel up
		ld (y_coordinate),a		; update y coord variable
		ld (ix+3),$0			; definition LSB

		call kjt_get_key		; return current scancode in A (ASCII in B)
		cp $76
		jr nz,sp_loop			; loop if ESC key not pressed

;-------------------------------------------------------------------------------

		ld a,0
		ld (vreg_sprctrl),a		; Disable sprites

		xor a				; quit to OS
		ret

;--------------------------------------------------------------------------------------------------------

x_coordinate 	db 0

y_coordinate	db 0

;---------------------------------------------------------------------------------------------------------
