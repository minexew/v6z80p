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
			ld hl,0f80000h
			call square
			call waitkey
			ld hl,0f80000h
			call silence

			ld hl,message2_txt				
			call print_string
			ld hl,0f80400h
			call square
			call waitkey
			ld hl,0f80400h
			call silence
			
			ld hl,message3_txt				
			call print_string
			ld hl,0f80000h
			call triangle
			call waitkey
			ld hl,0f80000h
			call silence

			ld hl,message4_txt				
			call print_string
			ld hl,0f80400h
			call triangle
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
		


square		ld bc,0h
audsflp		ld a,80h
			bit 4,c
			jr z,bclr
			ld a,7fh
bclr		ld (hl),a
			inc hl
			inc bc
			ld a,b
			cp 4
			jr nz,audsflp
			ret



triangle	ld bc,0h
audtflp		ld a,c
			sla a
			sla a
			sla a
			sla a
			jr nc,tririse
			xor 0f0h
tririse		sub 080h
			ld (hl),a
			inc hl
			inc bc
			ld a,b
			cp 4
			jr nz,audtflp
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
			
		
;-----------------------------------------------------------------------------------------------
		
		