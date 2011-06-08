; Test keyboard input routine

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

		ld hl,message_txt				; ADL mode program
		ld a,kr_print_string			; desired kernal routine
		call.lil prose_kernal			; call PROSE routine

myloop	ld a,kr_wait_key_press
		call.lil prose_kernal
		cp 76h
		jr z,endit
		ld hl,char
		ld (hl),b
		ld a,kr_print_string
		call.lil prose_kernal
		jr myloop
		
endit	xor a
		jp.lil prose_return				; back to OS

;-----------------------------------------------------------------------------------------------

message_txt

		db 'Type stuff! ',11,0

char	db 0,0
;-----------------------------------------------------------------------------------------------
		
		