
; Demonstrates the use of a custom IRQ handler for a video based IRQ (which also
; calls the FLOS keyboard and mouse routines.)

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------

irq_line	equ $60			; position of colour bar
	
;-----------------------------------------------------------------------------

	di			; disable interrupts

	ld a,%00000111
	out (sys_clear_irq_flags),a	; clear all irq flags 


;--------- Set up custom IRQ handler ------------------------------------------


	ld hl,my_irq_handler		
	ld (irq_vector),hl		; change the default FLOS IRQ vector

	ld a,irq_line
	ld (vreg_rastlo),a		; Set raster interrupt position LSB

	ld a,%00000010
	ld (vreg_rasthi),a		; Set raster interrupt position MSb and Raster IRQ enable

	ld b,%10000001
	push bc
	call kjt_get_mouse_position
	pop bc
	jr nz,nomouse
	ld b,%10000011
nomouse	ld a,b
	out (sys_irq_enable),a	; Enable Keyboard + Mouse (if enabled) + Master IRQs
	
	ei			; allow IRQs @ CPU

;--------------------------------------------------------------------------------

	call set_up_pointer_sprite
	
	call kjt_clear_screen
	
	ld hl,info_txt
	call kjt_print_string
	

;--------- Main "background code" ------------------------------------------------	


mainloop	call update_mouse_pointer	; move mouse (if driver enabled)

	call kjt_get_key		; any key presses?
	or a
	jr z,mainloop

	cp $76
	jr z,quit			; quit to FLOS if pressed ESC
	
	ld hl,text_output		
	ld (hl),b
	call kjt_print_string	; show keypresses
	
	jr mainloop
		
quit	xor a
	ld a,$ff			;quit (restart OS)
	ret

;---------------------------------------------------------------------------------

my_irq_handler

	push af
	push bc
	push de
	push hl

	in a,(sys_irq_ps2_flags)	;handle video irq
	bit 3,a
	call nz,raster_bar
	
	in a,(sys_irq_ps2_flags)	;handle keyboard irq
	bit 0,a
	call nz,kjt_keyboard_irq_code	
	
	in a,(sys_irq_ps2_flags)	;handle mouse irq
	bit 1,a
	call nz,kjt_mouse_irq_code	

	pop hl
	pop de
	pop bc
	pop af
	ei			; re-enable interrupts
	reti			; return to "background code"


;--------------------------------------------------------------------------------

raster_bar

	ld hl,$f0f		; show a colour bar
	ld (palette),hl
	ld b,0
delaylp	djnz delaylp
	ld hl,0
	ld (palette),hl
	
	ld a,%10000000
	ld (vreg_rasthi),a		; clear irq flag (leaves rest of register intact)
	ret


;--------------------------------------------------------------------------------------

set_up_pointer_sprite
	
	call kjt_get_mouse_position		; return immediately if no mouse driver enabled
	ret nz
	
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
	ret


update_mouse_pointer

	call kjt_get_mouse_position		;get absolute mouse pos 
	ret nz				;return if mouse driver not enabled
	
	push de				;update sprite register
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
	ret
			
;-------------------------------------------------------------------------------

info_txt		db "Keypresses and mouse should respond",11
		db "normally whilst video IRQ is active..",11,11,0

text_output	db "x",0

;-------------------------------------------------------------------------------

spr_colours	incbin "pointer_palette.bin"

spr_def		incbin "pointer_sprite.bin"

;------------------------------------------------------------------------------------------------
