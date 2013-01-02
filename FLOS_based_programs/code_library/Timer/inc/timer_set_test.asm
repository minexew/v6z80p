
;----------------------------------------------------------------------------------------------

set_timer

; put timer reload value in A before calling, remember - timer counts upwards!

		out (sys_timer),a			; load and restart timer
		ld a,%00000100
		jr clr_tirq				; clear timer overflow flag


;------------------------------------------------------------------------------------------
		
test_timer

; zero flag is set on return if timer has not overflowed

		in a,(sys_irq_ps2_flags)		; check for timer overflow..
		and 4
		ret z	
clr_tirq	out (sys_clear_irq_flags),a		; clear timer overflow flag
		ret

;----------------------------------------------------------------------------------------------
