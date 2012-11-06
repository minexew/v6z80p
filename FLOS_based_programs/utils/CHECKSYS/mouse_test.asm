
;---------------------------------------------------------------------------------------		
		
mouse_test	call kjt_clear_screen
		ld hl,mouse_menu_text
		call kjt_print_string
		call init_ms_sprite
		
mouse_tlp	call kjt_wait_key_press
		cp $76
		jr nz,notquitmt

		xor a
		ld (vreg_sprctrl),a		; disable sprites
		ret

notquitmt	ld a,b
		cp "1"
		jr z,mouse_init
		cp "2"
		jr z,mouse_move
		jr mouse_tlp

mouse_init	call initialize_mouse
		jr mouse_test

mouse_move	call show_mouse_data
		jr mouse_test

mouse_menu_text

		db "Mouse Test Menu. Press:",11,11
		db "1. Initialize mouse",11
		db "2. Test mouse input",11,11
		db "ESC - Quit to main menu",11,11,0

;---------------------------------------------------------------------------------------		
			
initialize_mouse
		
		ld hl,ms_init_txt
		call kjt_print_string
		
		call init_mouse
		or a
		jr z,minit_ok
nomouse		ld hl,no_mouse_txt
		call kjt_print_string
		call press_any_key
		xor a
		ret
		
minit_ok	call kjt_get_display_size		;get pointer boundaries
		ld l,c
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		ex de,hl
		ld l,b
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		call kjt_enable_mouse			;activate mouse IRQ in FLOS
		
		ld hl,mouse_enabled_txt
		call kjt_print_string
		call pause_2_seconds
		xor a
		ret

show_mouse_data

		ld bc,$0005
		call kjt_set_cursor_position
		
		ld hl,mouse_loc_test_txt
		call kjt_print_string
		
mst_noesc	ld bc,$0007
		call kjt_set_cursor_position
		
		call kjt_get_mouse_position
		jr nz,askinit
		ld (ms_x),hl
		ld (ms_y),de
		ld hl,mbuttons_txt		
		call kjt_hex_byte_to_ascii
		ld a,(ms_x+1)
		ld hl,mousex_txt
		call kjt_hex_byte_to_ascii
		ld a,(ms_x)
		call kjt_hex_byte_to_ascii
		ld a,(ms_y+1)
		ld hl,mousey_txt
		call kjt_hex_byte_to_ascii
		ld a,(ms_y)
		call kjt_hex_byte_to_ascii
		
		ld hl,mouse_txt
		call kjt_print_string
		
		call update_ms_sprite
		
		call kjt_get_key
		or a
		jr z,mst_noesc

		xor a
		ret

askinit		ld hl,init_txt
		call kjt_print_string
		call kjt_wait_key_press
		ld a,b
		cp "y"
		jr z,okinit
		cp "Y"
		jr z,okinit
		xor a
		ret

okinit		call initialize_mouse
		ret


init_txt	db "Mouse driver not active.",11,11
		db "Init mouse? (y/n)",11,11,0

mouse_loc_test_txt

		db "Testing mouse motion - ESC to QUIT",0
ms_init_txt
		db "Initializing mouse..",11,0
		
;-----------------------------------------------------------------------------------------------		
		
ms_x		dw 0
ms_y		dw 0		

mouse_txt	db "Mouse X:"
mousex_txt	db "xxxx",11
		db "Mouse Y:"
mousey_txt	db "xxxx",11
		db "Buttons:"
mbuttons_txt	db "00",0

;-----------------------------------------------------------------------------------------------

mouse_enabled_txt

	db 11,"OK, Mouse detected and enabled.",11,11,0
	
no_mouse_txt
	
	db 11,"ERROR: No mouse detected!",11,11,0

;-----------------------------------------------------------------------------------------------
	
init_mouse

; returns A=$00 if mouse initialized ok
;         A=$01 if no mouse found

		ld a,%10000001
		out (sys_irq_enable),a		;disable mouse interrupts
		ld a,%00000010
		out (sys_clear_irq_flags),a	;clear mouse IRQ flag
		
		ld a,$ff			;send "reset" command to mouse
		call write_to_mouse		
		jr c,mouse_timeout
		call wait_2_mouse_bytes		;should be FF,FA (byte seen by input HW when written and ack)
		jr c,mouse_timeout
		call wait_2_mouse_bytes		;should be AA,00 (mouse passed self test and mouse ID)
		
		ld a,$f4			;send "enable data reporting" command to mouse
		call write_to_mouse
		jr c,mouse_timeout
		call wait_2_mouse_bytes		;should be $F4,$FA (as written) and (ack)
		jr c,mouse_timeout
		
		xor a				;A=0, mouse initialized OK
		ret

mouse_timeout

		xor a				;A=1, no mouse detected
		inc a
		ret

wait_2_mouse_bytes

		call wait_mouse_byte
		call wait_mouse_byte
		ret	
		
	
write_to_mouse

; Put byte to send to mouse in A

		ld c,a				; copy output byte to c
		ld d,1				; initial parity count
		ld a,%01000000			; pull clock line low
		out (sys_ps2_joy_control),a
		ld a,7
		call kjt_timer_wait		; wait 100 microseconds
		ld a,%11000000
		out (sys_ps2_joy_control),a	; pull data line low also
		ld a,%10000000
		out (sys_ps2_joy_control),a	; release clock line
		
		ld b,8				; loop for 8 bits of data
mdoloop		call wait_mouse_clk_low	
		ret c
		xor a
		set 7,a
		bit 0,c
		jr z,mdbzero
		res 7,a
		inc d
mdbzero		out (sys_ps2_joy_control),a	; set data line according to output byte
		call wait_mouse_clk_high
		rr c
		djnz mdoloop

		call wait_mouse_clk_low
		ret c
		xor a
		bit 0,d
		jr nz,parone
		set 7,a
parone		out (sys_ps2_joy_control),a	; set data line according to parity of byte
		call wait_mouse_clk_high

		call wait_mouse_clk_low
		ret c
		xor a
		out (sys_ps2_joy_control),a	; release data line

wmdlow		in a,(sys_irq_ps2_flags)	; wait for mouse to pull data low (ack)
		bit 7,a
		jr nz,wmdlow
		call wait_mouse_clk_low	
		ret c
		
wmdchi		in a,(sys_irq_ps2_flags)	; wait for mouse to release data and clock
		and %11000000
		cp %11000000
		jr nz,wmdchi
		xor a
		ret



wait_mouse_clk_low

		push bc
		xor a 				; timer overflows every 4 ms
		ld c,a
		out (sys_timer),a		
		ld a,%00000100
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		
dbcrs1		ld b,8				; clk must be continuously low for a few loops
dbloop1		in a,(sys_irq_ps2_flags)
		ld e,a
		bit 2,e				; timer carry set?
		jr z,mtfl_ok
		ld a,%00000100
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		inc c				; inc timeout counter
		jr nz,mtfl_ok
		pop bc
		scf				; carry flag set = op timed out
		ret
			
mtfl_ok		bit 6,e
		jr nz,dbcrs1
		djnz dbloop1		
		pop bc
		xor a				; carry clear = op was ok
		ret
		

wait_mouse_clk_high

		push bc
dbrs2		ld b,8				; clk must be continuously hi for n cycles
dbloop2		in a,(sys_irq_ps2_flags)
		bit 6,a
		jr z,dbrs2
		djnz dbloop2
		pop bc
		ret
		



wait_mouse_byte

		xor a
		out (sys_timer),a

		ld b,0
mouse_tcd	out (sys_clear_irq_flags),a	; clear timer overflow flag

wait_mlp	in a,(sys_irq_ps2_flags)	; wait for mouse IRQ flag to be set
		bit 1,a
		jr nz,mbyte_rdy
		
		in a,(sys_irq_ps2_flags)
		bit 2,a				; if bit 2 of status flags = 1, timer has overflowed
		jr z,wait_mlp
		djnz mouse_tcd
		scf				; set carry flag = timed out
		ret	
		
mbyte_rdy	ld a,%00000010
		out (sys_clear_irq_flags),a	; clear mouse IRQ
		in a,(sys_mouse_data)		; read mouse data byte
		or a				; clear carry flag
		ret


;-------- Set up sprite ------------------------------------------------------

init_ms_sprite
		ld hl,spr_registers  		; zero all 128 4-byte sprite registers
		ld b,0
wsprrlp 	ld (hl),0
		inc hl
		ld (hl),0
		inc hl
		djnz wsprrlp

		ld a,%10000000
		out (sys_mem_select),a		; page sprite RAM into $1000-$1fff
	
		ld a,%10000000
		ld (vreg_vidpage),a		; select sprite page 0

		ld hl,sprite_base		; make sprite block 0 definition @ $1000
		ld b,16				; simple sprite image (16x16 outline)
lp1		ld (hl),255
		inc hl
		djnz lp1
		
		ld c,14
lp3		ld (hl),255
		inc hl
		ld b,14
lp2		ld (hl),0
		inc hl
		djnz lp2
		ld (hl),255
		inc hl
		dec c
		jr nz,lp3
		ld b,16
lp4		ld (hl),255
		inc hl
		djnz lp4
		
		xor a
		out (sys_mem_select),a		; page sprite RAM out of $1000-$1fff
	
		ld hl,$fff
		ld (palette+$1fe),hl		; colour reg for sprite
		
		ld a,1
		ld (vreg_sprctrl),a		; Set bit 0 to enable sprites
		ret
		
;-------- Update Sprite ---------------------------------------------------------


update_ms_sprite

		ld ix,spr_registers		; First sprite 0 register
		
		ld hl,(ms_x)
		ld de,127			; add window offset
		add hl,de
		push hl
		pop bc
		ld hl,(ms_y)
		ld de,41			; add window offset
		add hl,de
		
		ld (ix+0),c			; set x coord LSB
		ld (ix+2),l			; set y coord LSB
		ld (ix+3),$0			; definition LSB		
		
		ld a,h
		rlca
		and 2
		or b
		or $10
		ld (ix+1),a			; height = 16 pixels
		ret
		
;---------------------------------------------------------------------------------
