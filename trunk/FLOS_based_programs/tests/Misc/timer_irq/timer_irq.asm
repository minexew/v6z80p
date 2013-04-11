
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

        ld  a,%10000111                		; Enable keyboard, mouse and timer interrupts
        out  (sys_irq_enable),a

	ld a,128				; Time, in 16us periods
	neg					; Timer counts upwards so invert value
	out (sys_timer),a			; Set the timer latch value
        ld  a,%00000100
        out  (sys_clear_irq_flags),a           ; Clear the timer IRQ flag

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
        bit  1,a
        call nz,kjt_mouse_irq_code         ; Kernal mouse irq handler
        bit  2,a
        call nz,my_timer_irq_code          ; User's timer irq handler
        pop af
        ei
        reti
	
my_timer_irq_code:

        push af                            ; must push/pop registers!
        push hl

	ld hl,$fff
	ld (palette),hl			    ; change colour 0 - test purposes

	ld hl,(frames)
	inc hl
	ld (frames),hl
	ld a,h
	or l
	jr nz,timer_irq_count_done
	ld hl,(frames+2)
	inc hl
	ld (frames+2),hl

timer_irq_count_done:

        ld  a,%00000100
        out  (sys_clear_irq_flags),a           ; Clear the timer IRQ flag
        
	ld hl,$000
	ld (palette),hl				; change colour 0 - test purposes
	
	pop  hl
        pop  af
        ret


original_irq_vector:

	defw 0

frames:

	defw 0
	defw 0
	
	