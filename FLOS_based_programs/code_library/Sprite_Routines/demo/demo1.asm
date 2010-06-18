; Demo of object_to_sprites routine - most basic code


;---Standard header for OSCA and FLOS ---------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000


;--------- INIT SPRITES -----------------------------------------------------------

	ld a,%10000000		; page in sprite RAM
	out (sys_mem_select),a
	ld hl,my_sprites		; upload sprites to sprite RAM	
	ld de,sprite_base
	ld bc,end_of_sprites-my_sprites
	ldir
	xor a
	out (sys_mem_select),a	; page out sprite RAM

	ld hl,my_colours		; upload palette
	ld de,palette
	ld bc,512
	ldir

	ld a,%00000001
	ld (vreg_sprctrl),a		; enable sprites


;--------- SHOW OBJECTS --------------------------------------------------------------

top_border  	equ $29 ; first visible line of display (currently set for vreg_window x = $5x)
left_border 	equ $7f ; first visible leftmost pixel on the display (currently set for vreg_window x = $8x)

	ld ix,sprite_registers
	ld hl,$140
	ld de,$140
	ld a,0
	call object_to_sprites
	
	ld hl,$180
	ld de,$180
	ld a,1
	call object_to_sprites

	call clear_remaining_sprites

	xor a
	ret

;------------------------------------------------------------------------------------------------------------------------------

	include object_to_sprites.asm

;------------------------------------------------------------------------------------------------------------------------------

object_location_list

	dw birdy	; object 0
	dw mine	; object 1


birdy	db 4			; number of h/w sprite resources used by this object 
	dw 0			; base definition
	db -32,-8, 0, $10		; origin offset x, origin offset y, definition offset, height for 1st sprite/ctrl bits
	db -16,-24, 1, $30		; "" for 2nd sprite
	db 0,-24, 4, $30		; "" for 3rd sprite
	db 16,-8, 7, $10		; "" for 4th sprite

mine	db 2			; number of h/w sprite resources used by this object
	dw 8			; base definition
	db -16,-16, 0, $20		; origin offset x, origin offset y, definition offset, height for 1st sprite/ctrl bits
	db 0,-16, 2, $20		; "" for 2nd sprite	

;------------------------------------------------------------------------------------------------------------------------------

my_sprites

	incbin "birdy_sprites.bin"
	incbin "mine_sprites.bin"

end_of_sprites

	db 0
	
my_colours

	incbin "palette.bin"
	
	
;------------------------------------------------------------------------------------------------------------------------------	