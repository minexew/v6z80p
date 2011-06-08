; Test audio output (test hardware in config EZ80P_020)

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld hl,message1_txt				
			call print_string
			ld de,0f80000h
			ld hl,wave1
			call copy_wave
			call waitkey
			ld hl,0f80000h
			call silence

			ld hl,message2_txt				
			call print_string
			ld de,0f80400h
			ld hl,wave1
			call copy_wave
			call waitkey
			ld hl,0f80400h
			call silence
			
			ld hl,message3_txt				
			call print_string
			ld de,0f80000h
			ld hl,wave2
			call copy_wave
			call waitkey
			ld hl,0f80000h
			call silence

			ld hl,message4_txt				
			call print_string
			ld de,0f80400h
			ld hl,wave2
			call copy_wave
			call waitkey
			ld hl,0f80400h
			call silence
		
			xor a
			jp.lil prose_return				; back to OS

			

silence		ld bc,0h
sillp		ld (hl),0
			inc hl
			inc bc
			ld a,b
			cp 4
			jr nz,sillp
			ret


copy_wave
			ld b,16						;copy 64 bytes from hl to de 16 times
cpyw1		push bc
			push hl
			ld bc,64
			ldir
			pop hl
			pop bc
			djnz cpyw1
			ret
			


print_string

			ld a,kr_print_string			 
			call.lil prose_kernal			 
			ret
		
waitkey

			ld a,kr_wait_key
			call.lil prose_kernal
			ret
		
;-----------------------------------------------------------------------------------------------

message1_txt

		db 'Left channel - square wave',11,0

message2_txt

		db 'Right channel - square wave',11,0
		
message3_txt

		db 'Left channel - triangle wave',11,0

message4_txt

		db 'Right channel - triangle wave',11,0
		
		
wave1	blkb 32,07fh
		blkb 32,080h


wave2	db 000h,008h,010h,018h,020h,028h,030h,038h,040h,048h,050h,058h,060h,068h,070h,078h
		db 07fh,078h,070h,068h,060h,058h,050h,048h,040h,038h,030h,028h,020h,018h,010h,008h
		db 000h,0f8h,0f0h,0e8h,0e0h,0d8h,0d0h,0c8h,0c0h,0b8h,0b0h,0a8h,0a0h,098h,090h,088h
		db 080h,088h,090h,098h,0a0h,0a8h,0b0h,0b8h,0c0h,0c8h,0d0h,0d8h,0e0h,0e8h,0f0h,0f8h
		

		
;-----------------------------------------------------------------------------------------------
		
		