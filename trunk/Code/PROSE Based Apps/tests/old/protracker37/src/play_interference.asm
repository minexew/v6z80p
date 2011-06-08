; Test ADL-mode Protracker Player, 50Hz.
; Need to preload samples to $c00000

;----------------------------------------------------------------------------------------------
; Set these two values to suit user program
;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; Z80-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld sp,0ffffh						; Set stack pointer for Z80 mode programs

			call init_tracker
			
			ld hl,message_txt						 
			call print_string
						
			
;---------------------------------------------------------------------------------------------------

			ld de,655							; set count to 655 ticks (50Hz)
			ld a,e							
			out0 (TMR0_RR_L),a					; set count value lo
			ld a,d
			out0 (TMR0_RR_H),a					; set count value hi
			ld a,00010011b							
			out0 (TMR0_CTL),a					; enable and start timer 0 (continuous mode)

wait_50hz	in0 a,(TMR0_CTL)					; has 50Hz timer count looped?			
			bit 7,a
			call nz,do_tracker_update			
		
			ld a,kr_get_key						; Quit if ESC pressed
			call.lil prose_kernal
			cp 076h
			jr nz,wait_50hz

endit		ld a,0
			ld (hw_audio_registers+3),a			; Disable audio playback
			xor a
			jp.lil prose_return					; switch back to ADL mode and jump to os return handler

;-----------------------------------------------------------------------------------------------

do_tracker_update

; call this routine every 50 Hz

			ld a,08h							; for testing only
			ld (hw_palette+1),a					; for testing only
			
			call play_tracker					
			
			ld a,00h							; for testing only
			ld (hw_palette+1),a					; for testing only
			
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

			db 'Samples required at $c00000. Initialized song. Playing..',11,0

;-----------------------------------------------------------------------------------------------
		
			include "ADL_mode_Protracker_Player_v100.asm"
	
			include "ADL_mode_Protracker_to_EZ80P.asm"

;-----------------------------------------------------------------------------------------------

ALIGN 2

			include "interfer.asm"

;------------------------------------------------------------------------------------------------

		