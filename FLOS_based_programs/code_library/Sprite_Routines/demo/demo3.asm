; Demo of object_to_sprites routine - crude multiplex


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


	ld hl,sprite_registers+$10	; set it so only 4 sprite registers are available
	ld (sprite_max),hl


;--------- SHOW OBJECTS --------------------------------------------------------------

top_border  	equ $29 ; first visible line of display (currently set for vreg_window x = $5x)
left_border 	equ $7f ; first visible leftmost pixel on the display (currently set for vreg_window x = $8x)


loop1	
	ld hl,vreg_read		;wait for last line of visible disply (lower border)
wait_ras1	bit 2,(hl)
	jr z,wait_ras1
wait_ras2	bit 2,(hl)
	jr nz,wait_ras2
	
	ld hl,frame_counter
	inc (hl)
		
	ld hl,$800
	ld (palette),hl		;show raster
		
	ld ix,sprite_registers
	ld hl,(bird_x)		;x
	ld de,(bird_y)		;y
	ld a,0			;object number (bird)
	call object_to_sprites

	ld hl,(mine_x)		;x
	ld de,(mine_y)		;y
	ld a,1			;object number (mine)
	call object_to_sprites

	ld hl,$080
	ld (palette),hl		;show raster

	call clear_remaining_sprites	;remove any old sprite debris

	ld hl,0
	ld (palette),hl		;show raster


;--------- MOVE OBJECTS --------------------------------------------------------------


	ld hl,(bird_x)		;move objects
	ld de,(bird_x_disp)
	add hl,de
	ld (bird_x),hl
	ld de,min_x_coord
	xor a
	sbc hl,de
	jr nc,nmin_bx
	ld de,1
	ld (bird_x_disp),de
nmin_bx	ld hl,(bird_x)
	ld de,max_x_coord
	xor a
	sbc hl,de
	jr c,nmax_bx
	ld de,$ffff
	ld (bird_x_disp),de
nmax_bx	ld hl,(bird_y)
	ld de,(bird_y_disp)
	add hl,de
	ld (bird_y),hl
	ld de,min_y_coord
	xor a
	sbc hl,de
	jr nc,nmin_by
	ld de,1
	ld (bird_y_disp),de
nmin_by	ld hl,(bird_y)
	ld de,max_y_coord
	xor a
	sbc hl,de
	jr c,nmax_by
	ld de,$ffff
	ld (bird_y_disp),de
nmax_by

	ld hl,(mine_x)
	ld de,(mine_x_disp)
	add hl,de
	ld (mine_x),hl
	ld de,min_x_coord
	xor a
	sbc hl,de
	jr nc,nmin_mx
	ld de,1
	ld (mine_x_disp),de
nmin_mx	ld hl,(mine_x)
	ld de,max_x_coord
	xor a
	sbc hl,de
	jr c,nmax_mx
	ld de,$ffff
	ld (mine_x_disp),de
nmax_mx	ld hl,(mine_y)
	ld de,(mine_y_disp)
	add hl,de
	ld (mine_y),hl
	ld de,min_y_coord
	xor a
	sbc hl,de
	jr nc,nmin_my
	ld de,1
	ld (mine_y_disp),de
nmin_my	ld hl,(mine_y)
	ld de,max_y_coord
	xor a
	sbc hl,de
	jr c,nmax_my
	ld de,$ffff
	ld (mine_y_disp),de
nmax_my
	
	in a,(sys_keyboard_data)
	cp $76
	jp nz,loop1

	xor a
	ret


min_x_coord equ $c0
max_x_coord equ $280

min_y_coord equ $e0
max_y_coord equ $1e0


bird_x		dw $100
bird_y		dw $100
bird_x_disp	dw 1
bird_y_disp	dw -1

mine_x		dw $160
mine_y		dw $160
mine_x_disp	dw -1
mine_y_disp	dw 1

;------------------------------------------------------------------------------------------------------------------------------

	include object_to_sprites.asm

;------------------------------------------------------------------------------------------------------------------------------

object_location_list

	dw birdy	; object 0
	dw mine	; object 1


birdy	db 4			; number of h/w sprite resources used by this object 
	dw 0			; base definition
	db -32, -8, 0, $10		; origin offset x, origin offset y, definition offset, height for 1st sprite/ctrl bits
	db -16,-24, 1, $30		; "" for 2nd sprite
	db 0,  -24, 4, $30		; "" for 3rd sprite
	db 16,  -8, 7, $10		; "" for 4th sprite

mine	db 2			; number of h/w sprite resources used by this object
	dw 8			; base definition
	db -16,-16, 0, $20		; origin offset x, origin offset y, definition offset, height for 1st sprite/ctrl bits
	db 0,  -16, 2, $20		; "" for 2nd sprite	

;------------------------------------------------------------------------------------------------------------------------------


my_sprites

	incbin "birdy_sprites.bin"
	incbin "mine_sprites.bin"

end_of_sprites

	db 0
	
my_colours

	incbin "palette.bin"
	
	
;------------------------------------------------------------------------------------------------------------------------------	