
; Ultra simple OSCA sprite demonstration. 

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

sprite_x_coord	dw 0
sprite_y_coord	dw 0

display_width	equ 320
display_height	equ 200


sp_loop		call kjt_wait_vrt		; wait for last scan line of display

		ld bc,(obj_x_coord)		; move coord 1 pixel right
		inc bc
		xor a
		ld h,b
		ld l,c
		ld de,display_width
		sbc hl,de			; has it moved out of the visible display?
		jr nz,spr_x_ok
		ld bc,0				; reset x coord to zero if so
spr_x_ok	ld (obj_x_coord),bc
		
		ld bc,(obj_y_coord)		; move coord 1 pixel down
		inc bc
		xor a
		ld h,b
		ld l,c
		ld de,display_height
		sbc hl,de			; has it moved out of the visible display?
		jr nz,spr_y_ok
		ld bc,0				; reset y coord to zero if so
spr_y_ok	ld (obj_y_coord),bc
		
		call update_sprite_register	; actually write the new coords to the sprite registers
		
		call kjt_get_key		; return current scancode in A (ASCII in B)
		cp $76
		jr nz,sp_loop			; loop if ESC key not pressed

;--------------------------------------------------------------------------------------------------------

		ld a,0
		ld (vreg_sprctrl),a		; Disable sprites

		xor a				; quit to FLOS
		ret

;--------------------------------------------------------------------------------------------------------

obj_x_coord 	dw 0
obj_y_coord	dw 0

;-------- Update Sprite Register -----------------------------------------------------------------------

display_window_x equ $7f	; Values determined by vreg_window_size, standard PAL FLOS window assumed here 
display_window_y equ $29	; "" ""


update_sprite_register

		ld ix,spr_registers		; First sprite 0 register
		
		ld hl,(obj_x_coord)
		ld de,display_window_x		; add window x offset
		add hl,de
		push hl
		pop bc
		ld hl,(obj_y_coord)
		ld de,display_window_y		; add window y offset
		add hl,de
		
		ld (ix+0),c			; set x coord LSB register
		ld (ix+2),l			; set y coord LSB register
		ld (ix+3),0			; set definition LSB register	
		
		ld a,h				; Get MSB of y coord
		rlca				; shift it left to put in bit 1
		or b				; OR in the MSB of x coord
		or $10				; OR in the height ($10 = 16 pixels)
		ld (ix+1),a			; set misc bits part of register
		ret
		
;--------------------------------------------------------------------------------------------------------
