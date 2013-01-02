
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
		
		call kjt_clear_screen
		
		ld hl,ms_init_txt
		call kjt_print_string
		
		call init_mouse
		jr nc,minit_ok
nomouse		ld hl,no_mouse_txt
		call kjt_print_string
		call press_any_key
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
		ret


show_mouse_data
		
		call kjt_clear_screen

		ld bc,$0000
		call kjt_set_cursor_position
		
		ld hl,mouse_loc_test_txt
		call kjt_print_string
		
mst_noesc	ld bc,$0002
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
		ret nz	
		jp show_mouse_data


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
	
init_mouse	call do_ms_reset		
		ei
		ret


do_ms_reset	di
		ld a,$ff			;"reset" command
		call show_msend
		ret c
		call show_mresponse		;should be FA (ack)
		ret c
		call show_mresponse		;should be AA (pass self test)
		ret c
		call show_mresponse		;should be 00 (mouse ID)
		ret c
		
		ld a,$f4			;"enable data reporting" command
		call show_msend
		ret c
		call show_mresponse		;should be FA (ack)
		ret

;---------------------------------------------------------------------------------------------		

show_msend	call show_send_byte
		call ms_send_byte
		ret nc
		ld hl,send_mto_txt
		call kjt_print_string
		scf
		ret

send_mto_txt	db "Send timed out",11,0




show_mresponse	call ms_get_response
		jr c,rec_mtimedout
		call show_rec_byte
		xor a
		ret

rec_mtimedout	ld hl,rec_mto_txt
		call kjt_print_string
		scf
		ret

rec_mto_txt	db "Timed out waiting for response",11,0


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
		
;----------------------------------------------------------------------------------------------------------

include "flos_based_programs/code_library/peripherals/inc/mouse_low_level.asm"

;-----------------------------------------------------------------------------------------------------------

