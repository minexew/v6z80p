; Z80-mode Protracker Player.

;----------------------------------------------------------------------------------------------
; Set these two values to suit user program
;----------------------------------------------------------------------------------------------

ADL_mode		equ 0				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; Z80-mode user program follows..
;---------------------------------------------------------------------------------------------

include "ez80_cpu_equates.asm"

audio_registers equ 0f80000h

			call init_tracker

			ld hl,message_txt						 
			call print_string
			
;---------------------------------------------------------------------------------------------------

wll			in0 a,(port_hw_flags)				;run at 60hz
			bit 5,a
			jr z,wll
wfl			in0 a,(port_hw_flags)
			bit 5,a
			jr nz,wfl

			ld bc,5000
wlp1		dec bc
			ld a,b
			or c
			jr nz,wlp1
			
			call do_tracker_update			
		
			ld a,kr_get_key						; Quit if ESC pressed
			call.lil prose_kernal
			cp 076h
			jr nz,wll

			ld a,0
			ld.lil (audio_registers+3),a		; Disable audio playback
			xor a
			jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

do_tracker_update

; call this routine every 50 Hz

;			ld a,08h							; for testing only
;			ld.lil (hw_palette+1),a				; for testing only
			
			call play_tracker					
			
;			ld a,00h							; for testing only
;			ld.lil (hw_palette+1),a				; for testing only
			
			call update_audio_hardware			
			ret
			
;---------------------------------------------------------------------------------------------------

print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret


waitkey		ld a,kr_wait_key
			call.lil prose_kernal
			ret


;-----------------------------------------------------------------------------------------------
		
message_txt

			db 'Initialized song. Playing..',11,0

;-----------------------------------------------------------------------------------------------
		
			include "50Hz_Z80_Protracker_Player_v505.asm"
	
			include "Amiga_to_EZ80P_audio.asm"

;-----------------------------------------------------------------------------------------------

ALIGN 2
			include "tune03_pattern.asm"
			
;------------------------------------------------------------------------------------------------

		