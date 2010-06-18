;-----------------------------------------------------------------------------------------
; Tests sprites - fills in 127 registers
;-----------------------------------------------------------------------------------------


sprite_count	equ 127


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

	ld hl,sine_table		; upload sine table to math unit
	ld de,mult_table
	ld bc,$200
	ldir	

	ld hl,test_pal		;write palette
	ld de,palette
	ld bc,$200
	ldir

;-----------------------------------------------------------------------------------------

	ld hl,spr_registers		;zero all sprite coords
	ld b,0
wsrloop	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	djnz wsrloop
	
	
	ld a,%10000000
	out (sys_mem_select),a	;page out video ram, page in sprite ram @ $1000
	
	ld a,%10000000
	ld (vreg_vidpage),a		;select sprite bank 0
	ld hl,test_sprites
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000001
	ld (vreg_vidpage),a		;select sprite bank 1
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000010
	ld (vreg_vidpage),a		;select sprite bank 2
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000011
	ld (vreg_vidpage),a		;select sprite bank 3
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000100
	ld (vreg_vidpage),a		;select sprite bank 4
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000101
	ld (vreg_vidpage),a		;select sprite bank 5
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000110
	ld (vreg_vidpage),a		;select sprite bank 6
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir
	ld a,%10000111
	ld (vreg_vidpage),a		;select sprite bank 7
	ld de,sprite_base
	ld bc,256*16		;copy test sprite defs
	ldir

	ld a,%00000000
	out (sys_mem_select),a	;page out sprite ram
	ld a,1
	ld (vreg_sprctrl),a		;enable sprites

;--------------------------------------------------------------------------------------------

frame_loop

	call kjt_wait_vrt

	call kjt_get_key		;ESC to quit
	cp $76
	jr nz,do_sprites

	call kjt_flos_display
	xor a
	ret
	

;--------------------------------------------------------------------------------------------

do_sprites

	ld hl,$246
	ld (palette),hl

;--------------------------------------------------------------------------------------------------------

	ld hl,spr_registers		;write sprite coords to registers
	ld ix,xcoords
	ld iy,ycoords
	ld b,sprite_count
	
spwrlp	ld a,(ix)			;get x coord low byte
	ld (hl),a			
	inc hl
	
	ld a,(ix+1)		;get x msb
	and 1
	ld c,a
	ld a,(iy+1)		;get y msb
	rlca
	and 2
	or c
	or $10			;set height (16pixels)
	ld (hl),a
	inc hl
	
	ld a,(iy)			;get y coord low byte
	ld (hl),a
	inc hl
	
	ld a,sprite_count
	sub b
	ld (hl),a			;set defintion
	inc hl

	inc ix
	inc ix
	inc iy
	inc iy
	djnz spwrlp
	
;--------------------------------------------------------------------------------------------------------
	
	ld hl,$88
	ld (palette),hl
	
;--------------------------------------------------------------------------------------------------------

; generate new coordinates

	ld hl,150			;max x radius (mult returns plus or minus this value)
	ld (mult_write),hl
	
	ld b,sprite_count		
	ld hl,xcoords
	ld a,(x_start_offset)
xloop	ld (mult_index),a
	push hl
	ld hl,(mult_read)
	ld de,150+128		;center x origin offset	
	add hl,de
	ex de,hl
	pop hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	sub 3
	djnz xloop

	ld hl,90
	ld (mult_write),hl		;max y radius

	ld b,sprite_count		
	ld hl,ycoords
	ld a,(y_start_offset)
yloop	ld (mult_index),a
	push hl
	ld hl,(mult_read)
	ld de,90+42		;center y origin offset
	add hl,de
	ex de,hl
	pop hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	sub 2
	djnz yloop
	
	ld a,(x_start_offset)
	add a,1
	ld (x_start_offset),a
	
	ld a,(y_start_offset)
	sub 1
	ld (y_start_offset),a

;----------------------------------------------------------------------------------------------------------

	ld hl,0
	ld (palette),hl
			
	jp frame_loop
	
;-------------------------------------------------------------------------------------------

counter       	db 0

xcoords	    	ds 256,0
ycoords	    	ds 256,0
 
x_start_offset	db 0
y_start_offset	db 45
 
;-------------------------------------------------------------------------------------------
	

sine_table	incbin "sin_table.bin"

test_sprites 	incbin "0_127_sprites.bin"
test_pal		incbin "0_127_sprites_palette.bin"
	

;-------------------------------------------------------------------------------------
