;----------------------------------------------------------------------------------------------
; Test time taken to create / mix 4 channels of audio data in software
; (No actual audio output)
;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

main_loop		ld a,kr_wait_vrt
				call.lil prose_kernal

				ld bc,1000h
rwait1			dec bc
				ld a,b
				or c
				jr nz,rwait1
				
				ld hl,08888h
				ld (hw_palette),hl
				
				call make_channel_0
			
				ld hl,0c8c8h
				ld (hw_palette),hl

				call mix_channels
				
				ld hl,0
				ld (hw_palette),hl
				
				ld a,kr_get_key
				call.lil prose_kernal
				cp 076h
				jr nz,main_loop
				
				xor a
				jp prose_return

;--------------------------------------------------------------------------------------

make_channel_0

				ld ix,(chan0_loc_work)			; source pointer for original sample
				ld de,period_constant			; a constant based on current period register
				ld hl,(chan0_loc_frac)
				ld bc,(chan0_len_work)
				
				ld iy,channel_0_data			; sample data buffer (dest)
				exx
				ld b,0							; length of channel's sample data buffer (256 bytes)
mch0lp			exx
				add hl,de						; add fractional constant 
				jr nc,gotloc					; have we moved onto a new sample byte?
				inc ix							; next sample address
				cpi								; hl=hl+1 (unimportant), bc=bc-1, PE if BC = 0
				jp pe,gotloc
				ld bc,(chan0_len)				; reset the length countdown
				ld ix,(chan0_loc)				; reset the source pointer
	
gotloc			ld a,(ix)
				ld (iy),a
				inc iy
				exx
				djnz mch0lp
				exx
				ld (chan0_len_work),bc			; update working registers for next pass
				ld (chan0_loc_work),ix
				ld (chan0_loc_frac),hl
				ret
				
;-----------------------------------------------------------------------------------------

mix_channels	ld hl,channel_0_data
				ld de,mixed_data
				ld c,h
				ld b,0
mixloop			ld h,c
				ld a,(hl)
				inc h
				add a,(hl)
				inc h
				add a,(hl)
				inc h
				add a,(hl)
				sra a
				sra a
				ld (de),a
				inc e
				inc l
				djnz mixloop
				ret
				
;-----------------------------------------------------------------------------------------
			
period_constant equ 0400000h						; example: new sample every 4 48800Mhz cycles

chan0_loc	 	dw24 sample_a
chan0_loc_work	dw24 chan0_loc
chan0_loc_frac	dw24 0

chan0_len		dw24 256
chan0_len_work	dw24 chan0_len

chan0_period	dw24 128
chan0_volume	db 0

;--------------------------------------------------------------------------------------

			org 10200h

channel_0_data	blkb 256,10
channel_1_data	blkb 256,20
channel_2_data	blkb 256,30
channel_3_data	blkb 256,40

mixed_data		blkb 256,0

;----------------------------------------------------------------------------------------

sample_a		blkb 128,07fh
				blkb 128,080h
				