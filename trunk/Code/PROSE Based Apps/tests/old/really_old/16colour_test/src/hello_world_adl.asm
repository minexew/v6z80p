; Example of ADL mode program at $010000 calling a PROSE kernal routine (with a pointer)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'includes/PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld hl,message_txt				; ADL mode program
		ld a,kr_print_string			; desired kernal routine
		call.lil prose_kernal			; call PROSE routine
		xor a
		jp.lil prose_return				; back to OS

;-----------------------------------------------------------------------------------------------

message_txt

		db 'Hello (ADL mode) world!',11,0

;-----------------------------------------------------------------------------------------------
		
		