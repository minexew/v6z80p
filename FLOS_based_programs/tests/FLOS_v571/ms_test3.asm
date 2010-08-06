; Moves pointer sprite using mouse displacements

;---Standard source header for OSCA and FLOS ------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000
	
;--------------------------------------------------------------------------------------
	
	ld a,%10000000			; copy sprite pointer to last definition block
	out (sys_mem_select),a		; of sprite ram
	ld a,%10011111
	ld (vreg_vidpage),a		
	ld hl,spr_def
	ld de,$1f00
	ld bc,$100
	ldir
	xor a
	out (sys_mem_select),a

	ld hl,spr_colours			;copy colours to live palette
	ld de,palette+(248*2)
	ld bc,8*2
	ldir

	ld a,%00000001
	ld (vreg_sprctrl),a			;enable sprites


;---------------------------------------------------------------------------------------


lp1	call kjt_wait_vrt			;wait for a new frame

	call kjt_get_mouse_motion		;get movement of mouse since last loop
	jr nz,error
	
	ld bc,(pointer_x)
	add hl,bc
	ld (pointer_x),hl			;add relative displacements to sprite position
	ex de,hl
	ld bc,(pointer_y)
	add hl,bc
	ld (pointer_y),hl
	

	ld hl,(pointer_x)			;update sprite register
	ld de,(pointer_y)	
	push de
	ld de,$7f				;add x offset for 40 char column window
	add hl,de
	ld ix,spr_registers
	ld (ix),l				;x coord low
	ld b,h
	pop de
	ex de,hl
	ld de,$29				;add y offset for PAL window
	in a,(sys_vreg_read)
	bit 5,a
	jr z,paltvwin
	ld de,$19				;y offset for non-PAL window
paltvwin	add hl,de
	ld (ix+2),l			;y coord low
	sla h	
	ld a,$14
	or b
	or h
	ld (ix+1),a
	ld (ix+3),$ff
	

	call kjt_get_key			;quit?
	or a
	jr z,lp1
	xor a
	ret

error	ld hl,error_txt
	call kjt_print_string
	xor a
	ret


pointer_x	dw 0
pointer_y	dw 0


;--------------------------------------------------------------------------------------

error_txt	db "Mouse driver not installed.",11,11,0

;-----------------------------------------------------------------------------------------------

spr_colours	incbin "pointer_palette.bin"

spr_def		incbin "pointer_sprite.bin"

;------------------------------------------------------------------------------------------------
	