
sd_tests	call kjt_clear_screen
		
		ld hl,sd_test_menu1
		call kjt_print_string		
		
wait_sdt_menu	call kjt_wait_key_press
		cp $76
		jr nz,not_sdt_quit
		xor a
		ret
		
not_sdt_quit	ld a,b
		cp "1"
		jr z,test_wrrd
		jr wait_sdt_menu
		
test_wrrd	call do_wrrd_test
		jr sd_tests

		
;------------------------------------------------------------------------------------

sd_test_menu1

		db "SD Card Test Menu",11,11

		db "Press:",11,11
		db "1. Write once, constant verify test",11,11

		db "ESC - quit to main menu",11,11,0


;-------------------------------------------------------------------------------------

do_wrrd_test	call kjt_clear_screen
		ld hl,wrrd_txt
		call kjt_print_string
		
		call kjt_check_volume_format
		jr z,sd_ok2
		
		call init_msg
		ret z
		jr do_wrrd_test
		
sd_ok2		call set_custom_irq_handler

		call make_rand_file
		
		ld hl,saving_txt
		call kjt_print_string
		
		call set_counter
		
		ld hl,test_fn				;save random 128 file 
		ld ix,$8000
		ld b,0
		ld c,2
		ld de,0
		call kjt_save_file
		jp nz,sdtsterr
		
		call print_int_thous
		ld hl,seconds_txt
		call kjt_print_string
			
		ld hl,0
		ld (pass_count),hl

read_loop	call show_passes

		ld b,4					;clear memory
		ld c,8
sdclmlp2	ld a,c
		out (sys_mem_select),a
		ld hl,$8000
		xor a
sdclmlp1	ld (hl),a
		inc hl
		bit 7,h
		jr nz,sdclmlp1
		inc c
		djnz sdclmlp2
		
		ld bc,$0006
		call kjt_set_cursor_position
		ld hl,loading_txt
		call kjt_print_string
		
		call set_counter
		
		ld hl,test_fn				;load the random file
		ld ix,$8000
		ld b,7
		call kjt_load_file
		jp nz,sdtsterr

		call print_int_thous
		ld hl,seconds_txt
		call kjt_print_string

		ld b,4
		ld c,0
sdcmplp2	ld hl,$8000
sdcmplp1	ld a,c
		inc a
		out (sys_mem_select),a
		ld e,(hl)
		ld a,c
		add a,8
		out (sys_mem_select),a
		ld a,(hl)
		cp e
		jr nz,sdcmperr
		inc hl
		bit 7,h
		jp nz,sdcmplp1
		inc c
		djnz sdcmplp2
		
		ld hl,(pass_count)
		inc hl
		ld (pass_count),hl
				
		call kjt_get_key
		cp $76
		jr nz,read_loop
		
sd_wrrddone	ld hl,test_fn
		call kjt_erase_file
		call irq_restore
		xor a
		ret

sdcmperr	call irq_restore
		ld hl,sdcmpbad_txt
		call kjt_print_string
		call press_any_key
		jr sd_wrrddone

		

sdtsterr	call irq_restore
		ld hl,disk_err_txt
		call kjt_print_string
		
		ld hl,test_fn
		call kjt_erase_file
				
		call press_any_key
		xor a
		inc a
		ret

		
set_counter	di
		ld hl,0
		ld (counter_loops),hl
		ld a,256-125
		out (sys_timer),a
		ld a,%00000100
		out (sys_clear_irq_flags),a
		ei
		ret


		
		
my_irq		push af
		in a,(sys_irq_ps2_flags)		;timer interrupts every 0.002 seconds
		
		bit 2,a					; timer irq set?
		call nz,my_timer_irq			; call timer irq handler if so
		bit 0,a					; keyboard irq set?
		call nz,kjt_keyboard_irq_code		; call keyboard irq routine if so

		pop af
		ei
		reti
		
		
my_timer_irq	push af
		push hl
		ld hl,(counter_loops)
		inc hl
		inc hl
		ld (counter_loops),hl
		ld a,%00000100
		out (sys_clear_irq_flags),a
		pop hl
		pop af
		ret

		
set_custom_irq_handler

		di
		ld hl,($a01)
		ld (orig_irq),hl
		ld hl,my_irq
		ld ($a01),hl
		ld a,%10000101
		out (sys_irq_enable),a
		ei
		ret
		
		
irq_restore	di
		ld hl,(orig_irq)
		ld ($a01),hl
		call kjt_get_mouse_position		;was the mouse driver previously enabled?
		ld a,%10000001				
		jr nz,nomsirq	
		ld a,%10000011				;if so set the mouse IRQ bit as well as keyboard
nomsirq		out (sys_irq_enable),a
		ld a,%00000100
		out (sys_clear_irq_flags),a		;make sure timer irq flag is cleared
		ei
		ret
		
		
	
rand32kb	ld bc,$8000
rflp1		call rand16
		ld a,h
		ld (bc),a
		inc bc
		ld a,l
		ld (bc),a
		inc bc
		bit 7,b
		jr nz,rflp1
		ret


		
print_int_thous
	
		ld hl,(counter_loops)
		ld e,0
		ld bc,-10000
		call Num1
		inc e
		ld bc,-1000
		call Num1
		push hl
		ld a,"."
		call print_char
		pop hl
		
		ld bc,-100
		call Num1
		ld c,-10
		call Num1
		ld c,-1
Num1		ld a,'0'-1
Num2		inc a
		add hl,bc
		jr c,Num2
		sbc hl,bc
notzero		call print_char
		ret


print_char	cp "0"
		jr nz,chnotzero
		bit 0,e
		ret z
chnotzero	push hl
		ld (text),a
		ld hl,text
		call kjt_print_string
		pop hl
		ret



make_rand_file	ld hl,0
		ld (seed),hl
		ld b,4				;make a random 128KB file in memory
		ld c,0
rmlp1		push bc
		ld a,c
		call kjt_set_bank
		call rand32kb
		pop bc
		inc c
		djnz rmlp1
		ret
		
		
counter_loops	dw 0
orig_irq	dw 0		
test_fn		db "QXTG9YFL.TST",0
text		db "x",0
seconds_txt	db " seconds   ",11,11,0
disk_err_txt	db 11,11,"DISK ERROR!",11,0

wrrd_txt	db "Write Once, Continuous Verify Test",11
		db "ESC to quit.",11,11,0
		
sdcmpbad_txt	db 11,"VERIFY FAILED!",11,0

loading_txt	db "LOADING TEST FILE: ",0
saving_txt	db "TEST FILE SAVE : ",0

fat16_txt	db "Insert a FAT16-formatted SD card",11
		db "and press a key (esc to abort)",11,11,0

		
;---------------------------------------------------------------------------------------------------------------------------

init_msg	call kjt_clear_screen
		
		ld hl,fat16_txt
		call kjt_print_string
		
		call kjt_wait_key_press
		cp $76
		ret z
		xor a
		call kjt_mount_volumes
		call press_any_key	
		xor a
		inc a
		ret

;---------------------------------------------------------------------------------------------------------------------------
		
		