; CHECKSYS - V6Z80P/OSCA/FLOS test program
;
; Keep program < $8000, paged area used for samples, memtest etc
;
; V1.04 - Added Blitter test
;       - Added SD Card Tests
;       - Simplified RGB test
;       - Pass count shown in decimal
;
; V1.03 - added plot char test
;       - audio dma now disabled after audio test
;
;---Standard header for OSCA and FLOS -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000	

;------------------------------------------------------------------------------------------------------------

main_menu	call kjt_clear_screen
	
		ld hl,menu_txt
		call kjt_print_string
	
menu_loop	call kjt_wait_key_press
		cp $76
		jr z,quit
		ld a,b
		cp "1"
		jr z,test_keyboard
		cp "2"
		jr z,test_mouse
		cp "3"
		jr z,test_joystick
		cp "4"
		jr z,test_serial
		cp "5"
		jr z,test_video
		cp "6"
		jr z,test_audio
		cp "7"
		jr z,test_memory
		cp "i"
		jr z,show_sysinfo
		cp "8"
		jr z,test_sdcard
		jr menu_loop

quit		ld a,1			
		ld (baud),a				;set baud to 115200 on exit
		xor a
		ret
		
test_keyboard	call keyboard_tests
		jr main_menu
test_mouse	call mouse_test
		jr main_menu
test_joystick	call joystick_test
		jr main_menu
test_serial	call serial_tests		
		jr main_menu
test_memory	call memory_tests
		jr main_menu
test_video	call video_tests
		jr main_menu
test_audio	call audio_tests
		jr main_menu
show_sysinfo	call system_info
		jr main_menu
test_sdcard	call sd_tests
		jr main_menu
		
		
		
menu_txt	db "--------------------------",11
		db "V6Z80P System Tester V1.05",11
		db "--------------------------",11,11
		db "Press:",11,11
		db "1. For keyboard tests",11
		db "2. For mouse test",11
		db "3. For joystick test",11
		db "4. For serial tests",11
		db "5. For video tests",11
		db "6. For audio tests",11
		db "7. For memory tests",11
		db "8. For SD card tests",11,11
		
		db "I. For system info",11,11
		
		db "ESC - Quit",11,11,0

;--------------------------------------------------------------------------------------------------------

	include "FLOS_based_programs\utils\checksys\joystick_test.asm"
	include "FLOS_based_programs\utils\checksys\keyboard_tests.asm"
	include "FLOS_based_programs\utils\checksys\serial_tests_675.asm"
	include "FLOS_based_programs\utils\checksys\mouse_test.asm"
	include "FLOS_based_programs\utils\checksys\memory_tests.asm"
	include "FLOS_based_programs\utils\checksys\video_tests.asm"
	include "FLOS_based_programs\utils\checksys\audio_tests.asm"
	include "FLOS_based_programs\utils\checksys\system_info.asm"
	include "FLOS_based_programs\utils\checksys\sdcard_tests.asm"
	
;--------------------------------------------------------------------------------------------------------
