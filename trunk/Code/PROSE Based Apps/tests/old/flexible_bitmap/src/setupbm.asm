; Set up bitmap display...

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

bm_registers	equ 0fc0000h+(8*4)

bm_base			equ 0h
bm_pixel_step	equ 1h
bm_modulo		equ 0h
bm_datafetch	equ 320					;bytes read per line (note resolution of register!)

		ld ix,bm_registers
		ld (ix),bm_base
		ld (ix+04h),bm_pixel_step
		ld (ix+08h),0
		ld (ix+0ch),bm_modulo
		ld (ix+10h),0+(bm_datafetch/8)-1

		ld hl,message_txt				; ADL mode program
		ld a,kr_print_string			; desired kernal routine
		call.lil prose_kernal			; call PROSE routine
		xor a
		jp.lil prose_return				; back to OS

;-----------------------------------------------------------------------------------------------

message_txt

		db 'Bitmap display set up!',11,0

;-----------------------------------------------------------------------------------------------
		
		