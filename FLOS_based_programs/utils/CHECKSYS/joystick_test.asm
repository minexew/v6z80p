		
;---------------------------------------------------------------------------------------		
		
joystick_test	call kjt_clear_screen
		ld hl,joy_text
		call kjt_print_string
		
jtestmain	xor a
		out (sys_ps2_joy_control),a				;select port a
		ld b,15
		ld c,4
		call show_joy
		
		ld a,1
		out (sys_ps2_joy_control),a				;select port b
		ld b,28
		ld c,4
		call show_joy
		
		call kjt_get_key
		cp $76
		jr nz,jtestmain
		xor a
		ret
		
				
show_joy	ld d,1
joyloop		ld e,"0"
		in a,(sys_joy_com_flags)
		and d
		jr z,butnotpressed
		ld e,"1"
butnotpressed	push bc
		push de
		ld a,e
		call kjt_plot_char
		pop de
		pop bc
		inc c
		inc c
		sla d
		bit 6,d
		jr z,joyloop
		ret
		
joy_text	db "Joystick Port Tests (ESC to quit)",11,11
		db "BUTTON:   JOYSTICK A:   JOYSTICK B:",11
		db "-----------------------------------",11
		db "UP",11,11
		db "DOWN",11,11
		db "LEFT",11,11
		db "RIGHT",11,11
		db "FIRE 0",11,11
		db "FIRE 1",0
		
;---------------------------------------------------------------------------------------		

pause_2_seconds	call pause_1_second
		call pause_1_second
		ret
		
;---------------------------------------------------------------------------------------		
		
		
