
;--------- Set up scanline IRQ ---------------------------------------------------------------

set_up_interrupts

irq_line	equ $d0

		di				; temp disable IRQs
		ld hl,(irq_vector)
		ld (flos_irq_vector),hl		; save original FLOS IRQ vector
		ld hl,my_irq_vector		
		ld (irq_vector),hl		; set new IRQ vector
		ld a,irq_line
		ld (vreg_rastlo),a		; set scanline IRQ position LSB
		ld a,2+(irq_line>>8)
		ld (vreg_rasthi),a		; set scanline IRQ position MSB and video IRQ enable
		ld a,%10000001
		out (sys_irq_enable),a		; master irq enable + keyboard enable
		ei				; allow IRQ @ CPU
		ret


;----------------------------------------------------------------------------------------------------------

my_irq_vector	push af			; at very least we need to push AF
				
		in a,(sys_irq_ps2_flags)
		bit 0,a
		jr nz,keyboard_interrupt
			
		in a,(sys_irq_ps2_flags)
		bit 3,a
		jr nz,video_interrupt
		
		ld a,%00001110			; if any other source of interrupt clear it and return
		out (sys_clear_irq_flags),a	 
		
		pop af
		ei				
		reti
		

video_interrupt
		
		push bc
		push de
		push hl
		push ix
		push iy
		ex af,af'
		exx
		push af
		push bc
		push de
		push hl
		
		in a,(sys_mem_select)		; save upper bank setting 
		ld (pre_irq_mem_select),a

		ld a,%10000000
		ld (vreg_rasthi),a		; clear video irq flag (doesn't change other bits of vreg_rasthi register)
		ei				; enable interrupts immediately - keyboard interrupt will still be handled
		
		call do_every_frame
		
		ld a,(pre_irq_mem_select)	; restore upper bank setting
		out (sys_mem_select),a
		pop hl
		pop de
		pop bc
		pop af
		exx
		ex af,af'
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		
		pop af
		reti


keyboard_interrupt

		push hl
		call keyboard_handler		; keyboard IRQ doesn't change or care about the upper bank setting
		ld a,1
		out (sys_clear_irq_flags),a	; clear keyboard IRQ interrupt
		pop hl
		
		pop af
		ei				; IRQs not reenabled until keyboard handler finished
		reti


keyboard_handler
	
		in a,(sys_keyboard_data)       ; get the scancode
		cp $f0
		jr nz,not_rel
		ld hl,key_release
		ld (hl),1
		ret
          
not_rel  	ld hl,up_pressed
		cp $75				;up?
		jr z,got_key

		inc hl
		cp $72				;down?
		jr z,got_key
		
		inc hl				
		cp $6b				;left?
		jr z,got_key		

		inc hl
		cp $74				;right?
		jr z,got_key			
		
		inc hl 
		cp $76				;esc?
		jr z,got_key
		
		inc hl		
		cp $5a				;enter?
		jr z,got_key

		inc hl

got_key   	ld a,(key_release)
		or a
		jr z,pressed
		xor a
		ld (hl),a
		ld (key_release),a
		ret

pressed     	ld (hl),1
		ret



up_pressed	db 0
down_pressed	db 0
left_pressed	db 0
right_pressed	db 0
esc_pressed	db 0
enter_pressed	db 0
other_pressed	db 0

key_release	db 0

pre_irq_mem_select db 0
flos_irq_vector    dw 0
	
;----------------------------------------------------------------------------------------------------------
		
		
		
		
		
		
		
		
		
		