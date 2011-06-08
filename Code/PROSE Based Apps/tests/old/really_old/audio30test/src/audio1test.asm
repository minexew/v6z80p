; Test audio output (test hardware in config EZ80P_030)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

audio_registers	equ 0f80000h

			ld bc,0
			ld (audio_registers),bc					;ch 0 - loc
			ld (audio_registers+20h),bc				;ch 0 - loop loc
			ld bc,8000h
			ld (audio_registers+40h),bc				;ch 0 - len
			ld (audio_registers+60h),bc				;ch 0 - loop len
			ld bc,1000h
			ld (audio_registers+80h),bc				;ch 0 - period
			ld bc,40h
			ld (audio_registers+c0h),bc				;ch 0 - vol
			
			ld a,10000000b
			ld (audio_registers+3),a				;build buffer A (disable playback)
			ld hl,building_a_txt
			call print_string
			
			ld a,00000001b
			ld (audio_registers+3),a				;start audio playback
			ld hl,enabled_txt				
			call print_string

			call wait_buf_req						;wait for build (B) req
			
			ld a,10000011b
			ld (audio_registers+3),a				;build buffer B (enable playback)
			ld hl,building_b_txt
			call print_string

			call wait_buf_req						;wait for build (A) req					

			xor a
			jp.lil prose_return						; back to OS

			
print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret
		
waitkey

			ld a,kr_wait_key
			call.lil prose_kernal
			ret


pause		ld bc,0
lp1			dec bc
			ld a,b
			or c
			jr nz,lp1
			ret


wait_buf_req

			ld hl,waiting_txt
			call print_string
waitbreq	in0 a,(port_hw_flags)
			bit 6,a
			jr z,waitbreq
			ret
			
;-----------------------------------------------------------------------------------------------

enabled_txt

		db 'Enabled playback',11,0

waiting_txt

		db 'Waiting for buffer fill req..',11,0
		
building_a_txt

		db 'Building buffer A..',11,0

building_b_txt

		db 'Building buffer B..',11,0

;-----------------------------------------------------------------------------------------------
		
		