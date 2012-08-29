; Tests samples crossing 128K boundaries
; Tests samples at $1f800-$20800, $3f800-$20800, $5f800-$20800, $7c000-$7c800
; All played on channel 0 only.

; REQUIRES: OSCA 672+

;---Standard header for OSCA and FLOS ---------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------

	ld hl,text1
	call kjt_print_string

	ld hl,$f800		;copy sample to $1f800 in system RAM
	ld e,$01
	ld (one_loc),hl
	ld a,e
	ld (one_loc+2),a
	ld ix,one_wav
	ld bc,two_wav-one_wav
	ld (one_len),bc
	call copy_mem
	
	ld hl,$f800		;copy sample to $3f800 in system RAM	
	ld e,$03
	ld (two_loc),hl
	ld a,e
	ld (two_loc+2),a
	ld ix,two_wav
	ld bc,three_wav-two_wav
	ld (two_len),bc
	call copy_mem
	
	ld hl,$f800		;copy sample to $5f800 in system RAM
	ld e,$05
	ld (three_loc),hl
	ld a,e
	ld (three_loc+2),a
	ld ix,three_wav
	ld bc,four_wav-three_wav
	ld (three_len),bc
	call copy_mem
	
	ld hl,$c000		;copy sample to $7c000 in system RAM
	ld e,$07
	ld (four_loc),hl
	ld a,e
	ld (four_loc+2),a
	ld ix,four_wav
	ld bc,end_wav-four_wav
	ld (four_len),bc
	call copy_mem



;-----------------------------------------------------------------------------------------

	
	call key_wait
	
	ld hl,(one_loc)
	ld a,(one_loc+2)			;byte address of sample
	ld e,a
	ld bc,(one_len)			;byte length of sample
	call play_sample
	
	call key_wait
	
	ld hl,(two_loc)
	ld a,(two_loc+2)
	ld e,a
	ld bc,(two_len)
	call play_sample
	
	call key_wait
	
	ld hl,(three_loc)
	ld a,(three_loc+2)
	ld e,a
	ld bc,(three_len)
	call play_sample
	
	call key_wait
	
	ld hl,(four_loc)
	ld a,(four_loc+2)
	ld e,a
	ld bc,(four_len)
	call play_sample

	xor a
	ret
	
;-----------------------------------------------------------------------------------------
;         Set up registers to start the sample playing                                            
;-----------------------------------------------------------------------------------------

play_sample

	call dma_wait

	in a,(sys_audio_enable)	
	and %11111110
	out (sys_audio_enable),a	;stop channel 0 playback

	
	push bc			;protect length
	srl e			;divide location by 2 for WORD location
	rr h
	rr l
	ld b,h			
	ld c,audchan0_loc	
	out (c),l			;write sample WORD address [15:0] to audio port	
	ld a,e
	out (audchan0_loc_hi),a	;write sample WORD address [16:17] to audio port
	
	pop hl			;get length in hl
	srl h			;divide length by 2 for length in WORDS
	rr l
	ld b,h
	ld c,audchan0_len
	out (c),l			;write sample WORD length to port
	
	ld hl,$800		;period = clock ticks between sample bytes
	ld b,h
	ld c,audchan0_per
	out (c),l			;set sample period to relevant port 
	
	ld a,64
	out (audchan0_vol),a	;write sample volume to port (64 = full volume)

	call dma_wait

	in a,(sys_audio_enable)	
	or %00000001
	out (sys_audio_enable),a	;start channel 0 playback
	
	
;-----------------------------------------------------------------------------------------
;         Now re-set registers for when sample loops                                     
;-----------------------------------------------------------------------------------------
	
	
	call dma_wait		;allow time for sample to start playing..

	ld hl,1			;sample loop length (constantly repeat 1st two bytes)
	ld b,h
	ld c,audchan0_len
	out (c),l			;write sample length to port

	xor a
	ret

;-----------------------------------------------------------------------------------------

dma_wait	push bc
	in a,(sys_vreg_read)	;wait for the beginning of a scan line 
	and $40			;(ie: after audio DMA) This is so that all the
	ld b,a			;audio registers are cleanly initialized
dma_loop	in a,(sys_vreg_read)
	and $40
	cp b
	jr z,dma_loop
	pop bc
	ret
		
;-----------------------------------------------------------------------------------------

copy_mem	push de
	push hl
	push bc
	ld a,(ix)
	call kjt_write_sysram_flat
	inc ix
	pop bc
	pop hl
	pop de
	
	inc hl
	ld a,h
	or l
	jr nz,lhiok
	inc e

lhiok	dec bc
	ld a,b
	or c
	jr nz,copy_mem
	ret

;----------------------------------------------------------------------------------------

key_wait

	ld hl,key_text
	call kjt_print_string
	call kjt_wait_key_press
	ld hl,play_text
	call kjt_print_string
	ret
	
;-----------------------------------------------------------------------------------------

text1	db "Copying samples..",11,11,0
play_text	db "Playing sample",11,0
key_text	db "Press a key for next sample",11,0

one_loc	db 0,0,0
one_len	dw 0

two_loc	db 0,0,0
two_len	dw 0

three_loc	db 0,0,0
three_len	dw 0

four_loc	db 0,0,0
four_len	dw 0


one_wav	dw 0
	incbin "one.raw"

two_wav	dw 0
	incbin "two.raw"

three_wav	dw 0
	incbin "three.raw"

four_wav	dw 0
	incbin "four.raw"

end_wav	db 0

;-----------------------------------------------------------------------------------------
