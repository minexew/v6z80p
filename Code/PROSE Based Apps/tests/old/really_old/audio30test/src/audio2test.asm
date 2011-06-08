; Test audio output (test hardware in config EZ80P_030)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

audio_registers	equ 0f80000h

vol0 equ 40h
vol1 equ 0h
vol2 equ 0h
vol3 equ 0h
vol4 equ 0h
vol5 equ 0h
vol6 equ 0h
vol7 equ 0h


			ld bc,0
			ld (audio_registers+00h),bc				;ch 0 - loc
			ld bc,8000h
			ld (audio_registers+20h),bc				;ch 0 - loop loc
			ld bc,020000h
			ld (audio_registers+40h),bc				;ch 0 - len
			ld bc,4000h
			ld (audio_registers+60h),bc				;ch 0 - loop len
			ld bc,001fffh
			ld (audio_registers+80h),bc				;ch 0 - period
			ld bc,vol0
			ld (audio_registers+c0h),bc				;ch 0 - vol


			ld bc,0
			ld (audio_registers+04h),bc				;ch 1 - loc
			ld (audio_registers+24h),bc				;ch 1 - loop loc
			ld bc,020000h
			ld (audio_registers+44h),bc				;ch 1 - len
			ld (audio_registers+64h),bc				;ch 1 - loop len
			ld bc,002fffh
			ld (audio_registers+84h),bc				;ch 1 - period
			ld bc,vol1
			ld (audio_registers+c4h),bc				;ch 1 - vol


			ld bc,0
			ld (audio_registers+08h),bc				;ch 2 - loc
			ld (audio_registers+28h),bc				;ch 2 - loop loc
			ld bc,020000h
			ld (audio_registers+48h),bc				;ch 2 - len
			ld (audio_registers+68h),bc				;ch 2 - loop len
			ld bc,003fffh
			ld (audio_registers+88h),bc				;ch 2 - period
			ld bc,vol2
			ld (audio_registers+c8h),bc				;ch 2 - vol



			ld bc,0
			ld (audio_registers+0ch),bc				;ch 3 - loc
			ld (audio_registers+2ch),bc				;ch 3 - loop loc
			ld bc,020000h
			ld (audio_registers+4ch),bc				;ch 3 - len
			ld (audio_registers+6ch),bc				;ch 3 - loop len
			ld bc,007fffh
			ld (audio_registers+8ch),bc				;ch 3 - period
			ld bc,vol3
			ld (audio_registers+cch),bc				;ch 3 - vol


			ld bc,0
			ld (audio_registers+10h),bc				;ch 4 - loc
			ld (audio_registers+30h),bc				;ch 4 - loop loc
			ld bc,020000h
			ld (audio_registers+50h),bc				;ch 4 - len
			ld (audio_registers+70h),bc				;ch 4 - loop len
			ld bc,005fffh
			ld (audio_registers+90h),bc				;ch 4 - period
			ld bc,vol4
			ld (audio_registers+d0h),bc				;ch 4 - vol


			ld bc,0
			ld (audio_registers+14h),bc				;ch 5 - loc
			ld (audio_registers+34h),bc				;ch 5 - loop loc
			ld bc,020000h
			ld (audio_registers+54h),bc				;ch 5 - len
			ld (audio_registers+74h),bc				;ch 5 - loop len
			ld bc,006fffh
			ld (audio_registers+94h),bc				;ch 5 - period
			ld bc,vol5
			ld (audio_registers+d4h),bc				;ch 5 - vol


			ld bc,0
			ld (audio_registers+18h),bc				;ch 6 - loc
			ld (audio_registers+38h),bc				;ch 6 - loop loc
			ld bc,020000h
			ld (audio_registers+58h),bc				;ch 6 - len
			ld (audio_registers+78h),bc				;ch 6 - loop len
			ld bc,007fffh
			ld (audio_registers+98h),bc				;ch 6 - period
			ld bc,vol6
			ld (audio_registers+d8h),bc				;ch 6 - vol


			ld bc,0
			ld (audio_registers+1ch),bc				;ch 7 - loc
			ld (audio_registers+3ch),bc				;ch 7 - loop loc
			ld bc,020000h
			ld (audio_registers+5ch),bc				;ch 7 - len
			ld (audio_registers+7ch),bc				;ch 7 - loop len
			ld bc,008fffh
			ld (audio_registers+9ch),bc				;ch 7 - period
			ld bc,vol7
			ld (audio_registers+dch),bc				;ch 7 - vol
			
			
					
			ld a,10000000b
			ld (audio_registers+3),a				;build buffer A (disable playback)
			call pause
			ld hl,building_a_txt
			call print_string
			
			ld a,00000001b
			ld (audio_registers+3),a				;start audio playback
			ld hl,enabled_txt				
			call print_string

buf_loop	call wait_buf_req						;wait for build (B) req
			
			ld a,10000011b
			ld (audio_registers+3),a				;build buffer B (enable playback) - clears buf req
			call pause
			
			call wait_buf_req						;wait for build (A) req					

			ld a,10000001b
			ld (audio_registers+3),a				;build buffer A (playback still enabled) - clears buf req
			call pause
			
			ld a,kr_get_key
			call.lil prose_kernal
			cp 076h
			jr nz,buf_loop

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


pause		ld b,0
lp3			nop
			djnz lp3
			ret


wait_buf_req

			ld a,0f0h
;			ld (hw_palette),a
	
waitbreq	in0 a,(port_hw_flags)
			bit 6,a
			jr z,waitbreq
			
			ld a,000h
;			ld (hw_palette),a
			
			
;			ld b,0
;lp2			djnz lp2		
			
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
		
		