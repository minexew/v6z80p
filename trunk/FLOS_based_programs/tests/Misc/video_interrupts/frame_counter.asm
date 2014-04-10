; video IRQ using old style enable bits

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"
	
	org $5000

;-----------------------------------------------------------------------------

	di

        ld  hl,(irq_vector)            		; The label "irq_vector" = $A01 (contained in equates file)
        ld  (original_irq_vector),hl   		; Store the original FLOS vecotr for restoration later.
        ld  hl,my_custom_irq_handler
        ld  (irq_vector),hl

	ld a,1					; interrupt at raster line [bits 7:0]
	ld (vreg_rastlo),a
	ld a,%00000010
	ld (vreg_rasthi),a			; bit 0 = irq line's MSB, bit 1 = video IRQ enable (legacy style)

        ld  a,%10000001                		; Enable keyboard and video interrupts
        out  (sys_irq_enable),a

	ei
	
	xor a
	ret
	
 
 
; ----------------------------------
; Custom Interrupt handlers
; ----------------------------------

my_custom_irq_handler:

	push af
	
	in  a,(sys_irq_ps2_flags)

	bit  0,a        
	call nz,kjt_keyboard_irq_code      ; Kernal keyboard irq handler
        
	bit  3,a
        call nz,my_video_irq_code          ; User's video irq handler

        pop af
        ei
        reti

	
my_video_irq_code:

        push af                            
        push hl
	
	ld hl,(frames)
	inc hl
	ld (frames),hl
	
	ld (palette),hl
	
	ld a,h
	or l
	jr nz,video_irq_count_done
	ld hl,(frames+2)
	inc hl
	ld (frames+2),hl

video_irq_count_done

	ld a,%10000000
	ld (vreg_rasthi),a		; clear irq flag (leaves rest of register intact)
	
	pop hl
	pop af
	ret
	
original_irq_vector:

	defw 0


frames:

	defw 0
	defw 0
	
	