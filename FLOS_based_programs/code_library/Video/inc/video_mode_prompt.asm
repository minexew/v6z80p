;-----------------------------------------------------------------------------------------------

video_mode_prompt

; If video mode not PAL50 gives option to swap (if VGA) continue or abort
; Returns with Zf set is OK to proceed. (A=$2d aborted error code if not)
		
		call get_video_mode
		ld (vmp_orig_video_mode),a
		ret z
		push af
		ld hl,video_warn_txt
		call kjt_print_string
		pop af 
		cp 2
		jr nc,vga_mode
		ld hl,ntsc_warn_txt
warn_cont	call kjt_print_string
		call kjt_wait_key_press
		cp $35
		ret z
abort_prog	ld a,$2d				;"aborted" error
		or a
		ret
		
vga_mode	ld hl,vga50_warn_txt
		bit 0,a
		jr z,warn_cont
		
		ld hl,vga60_warn_txt
		call kjt_print_string
		call kjt_wait_key_press
		cp $16
		ret z
		cp $1e
		jr nz,abort_prog
go50hz		ld a,8
		out (sys_hw_settings),a			;set VGA50 mode
		xor a
		ret


video_warn_txt	db 11,"This program is intended for 50Hz",11
		db "PAL TV and may not work correctly",11
		db "with the current video mode.",11,11,0
		
ntsc_warn_txt	db "Continue in NTSC 60Hz mode? (y/n)",11,11,0

vga60_warn_txt	db "Select:",11,11
		db "1.Continue in 60Hz mode",11
		db "2.Run in VGA 50Hz mode (Non-standard)",11
		db "3.Abort",11,11,0

vga50_warn_txt	db "Continue in VGA 50Hz mode? (y/n)",11,11,0
		
vmp_orig_video_mode	db 0		




restore_original_video_mode

		call get_video_mode			;if video mode has changed, it can only be
		ld hl,vmp_orig_video_mode		;that VGA 50Hz was selected at the prompt.
		cp (hl)
		ret z
		xor a					;return to normal 60Hz Mode
		out (sys_hw_settings),a
		ret



		include "flos_based_programs\code_library\video\inc\get_video_mode.asm"

;-----------------------------------------------------------------------------------------------