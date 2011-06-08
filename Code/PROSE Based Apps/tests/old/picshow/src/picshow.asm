;**************************
; Load a pic direct to VRAM
;**************************

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

begin_app		ld a,0
				out0 (040h),a			;switch off 16 colour mode

				ld a,kr_find_file
				ld hl,filename_pal
				call.lil prose_kernal
				jr nz,load_error
				ld hl,hw_palette
				ld a,kr_read_file
				call.lil prose_kernal
				jr nz,load_error
				
				ld a,kr_find_file
				ld hl,filename_data
				call.lil prose_kernal
				jr nz,load_error
				ld hl,hw_vram_a
				ld a,kr_read_file
				call.lil prose_kernal
				jr nz,load_error
				
				ld a,kr_wait_key
				call.lil prose_kernal
				jr done

load_error		ld hl,load_error_txt
				ld a,kr_print_string
				call.lil prose_kernal
				
done			ld a,0ffh
				jp prose_return						;restart prose on exit

;----------------------------------------------------------------------------------------------

load_error_txt	db "Load error.",11,0
filename_pal	db "palette.bin",0
filename_data	db "picture.bin",0

;------------------------------------------------------------------------------------------------
