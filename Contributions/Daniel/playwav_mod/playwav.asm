;-----------------------------------------------------------------------------------------
; .wav file player v1.01 - by Phil 09
; v1.01: Daniel I. -> added mono output on 2 channels 
;
; Any sample size supported
; .wav file must be 8 bit / mono / unsigned 
; Sample rate max 30KHz
;
; Use: Playwav.exe filename
;-----------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"
	
	org $5000	


;--------- Test FLOS version ---------------------------------------------------------------------

	push hl
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$548
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	pop hl
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v548+",11,11,0

flos_ok	pop hl	

;-----------------------------------------------------------------------------------------

	ld de,$5000		; if being run from G command (debugging) HL which is 
	xor a			; normally the argument string will be $5000 - in this
	sbc hl,de			; case use the test filename.
	jr nz,argok
	ld hl,test_fn
	ld de,0
	
argok	add hl,de
fnd_para	ld a,(hl)			; examine argument text, if encounter 0: give up
	or a			
	jp z,show_use
	cp " "			; ignore leading spaces...
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para

fn_ok	push hl			; copy args to working filename string
	ld de,filename
	ld b,16
fnclp	ld a,(hl)
	or a
	jr z,fncdone
	cp " "
	jr z,fncdone
	ld (de),a
	inc hl
	inc de
	djnz fnclp
fncdone	xor a
	ld (de),a			; null terminate filename

	ld hl,loading_txt
	call kjt_print_string
	pop hl

;--------------------------------------------------------------------------------------------

	ld hl,filename		; does filename exist?
	call kjt_find_file
	jp nz,load_error
	
	ld ix,0
	ld iy,44
	call kjt_set_load_length
	
	ld hl,header
	ld b,0
	call kjt_force_load		; load wav file header
	jp nz,load_error	
	
	ld a,(header+8)		; check file format
	cp "W"
	jp nz,notwav
	ld a,(header+9)
	cp "A"
	jp nz,notwav
	ld a,(header+22)		; 1 = mono
	cp 1
	jp nz,badwavtype

	ld bc,(header+24)		; sample rate
	ld hl,$2400		; convert to period
	ld e,$f4
	ld ix,0
divloop	xor a
	sbc hl,bc
	jr nc,nobo
	dec e
	ld a,e
	cp $ff
	jr z,divdone
nobo	inc ix
	jr divloop
divdone	ld (period),ix
	push ix
	pop hl
	xor a
	ld de,$210
	sbc hl,de
	jp c,sampratebad

	ld a,(header+32)		; 1 = 8 bit
	cp 1
	jp nz,badwavtype
	
	ld iy,(header+40)
	ld ix,(header+42)
	ld (samp_len_lo),iy
	ld (samp_len_hi),ix
	ld a,(samp_len_hi)		; is sample > 128KB?
	cp 2
	jr c,short_samp
	ld hl,(samp_len_lo)
	ld a,h
	or l
	jp nz,long_samp


;----------------------------------------------------------------------------------------------------------------

short_samp

	ld hl,filename		; load from end of header
	call kjt_find_file
	jp nz,load_error
	ld ix,0
	ld iy,44
	call kjt_set_file_pointer
	ld hl,$8000
	ld b,3			; load sample data (continuing from header) 
	call kjt_force_load		; at start of audio accessible system RAM
	
	ld a,3
	call kjt_forcebank		; convert to signed samples
	call convertsamples
	ld a,4
	call kjt_forcebank
	call convertsamples
	ld a,5
	call kjt_forcebank
	call convertsamples
	ld a,6
	call kjt_forcebank
	call convertsamples
	ld hl,0
	ld ($fffe),hl		; put $00,$00 at last bytes of sample RAM, this is
	ld a,0			; used for the loop data (end on silence)
	call kjt_forcebank
	
	call wait_dma		; wait for post-audio DMA time
	ld a,%00000000
	out (sys_audio_enable),a	; stop channel 0 playback

	ld bc,(samp_len_hi)		; convert length in bytes to words (/2)
	ld de,(samp_len_lo)
	srl c
	rr d			
	rr e			; de = length
	ld bc,0			; bc = loc
	ld hl,(period)		; hl = period
	ld a,$40			; a = volume
	call set_up_channel0
	
	call wait_dma		; wait for post-audio DMA time
	ld a,%00000001
	out (sys_audio_enable),a	; start channel 0 playback

	call wait_dma		; wait for post-audio DMA time
	ld bc,$ffff
	ld de,1
	ld hl,(period)
	ld a,$40
	call set_up_channel0	; set loop values (= set it to silence) 

	ld a,%00010000
	out (sys_clear_irq_flags),a	;clear sample loop flags and all irq flags

ss_loop	in a,(sys_audio_enable)	;wait for channel 0 loop flag
	bit 4,a
	jp nz,quit
	in a,(sys_keyboard_data)	;quit if ESC pressed
	cp $76
	jr nz,ss_loop			
	jp quit
	
;-------------------------------------------------------------------------------------

long_samp
	
 	ld ix,2			; continuing from header, load in first 128KB of sample data
 	ld iy,0
 	call kjt_set_load_length
 
	ld hl,$8000
	ld b,3			; load sample data at start of audio accessible system RAM
	call kjt_force_load		; both buffers will be filled as sample is > 128KB	

	ld a,3
	call kjt_forcebank		; convert to signed samples
	call convertsamples
	ld a,4
	call kjt_forcebank
	call convertsamples
	ld a,5
	call kjt_forcebank
	call convertsamples
	ld a,6
	call kjt_forcebank
	call convertsamples

	ld a,(samp_len_hi)		; reduce file length
	sub 2
	ld (samp_len_hi),a

	call wait_dma		; wait for post-audio DMA time
	ld a,%00000000
	out (sys_audio_enable),a	; stop channel 0 playback

	ld bc,0			; bc = loc (first 64KB buffer)
	ld de,$8000		; de = length (entire 64KB buffer)
	ld hl,(period)		; hl = period
	ld a,$40			; a = volume
	call set_up_channel0	
	call wait_dma		; wait for post-audio DMA time
	ld a,%00000011
	out (sys_audio_enable),a	; start channel 0 playback - buffer 0 plays

	call wait_dma		; wait for post-audio DMA time
	ld bc,$8000		; bc = loc (second 64KB buffer)
	ld de,$8000		; de = length (entire 64KB buffer)
	ld hl,(period)		; hl = period
	ld a,$40			; a = volume
	call set_up_channel0	; buffer 1 to play when channel loops
	ld a,%11110111
	out (sys_clear_irq_flags),a	; clear sample loop flags and all irq flags
	
ls_loop	in a,(sys_keyboard_data)	; quit if ESC pressed
	cp $76
	jp z,quit			
	in a,(sys_audio_enable)	; wait for channel 0 loop flag to become set
	bit 4,a
	jr z,ls_loop
	
;	ld hl,loop_txt		; for testing only
;	call kjt_print_string
	
	ld a,%00010000
	out (sys_clear_irq_flags),a	; clear chan 0 loop flag. Other buffer is now playing, safe to..
	
	ld ix,1			; ..load in 64KB of sample data to alternate buffer (0 on first pass)
 	ld iy,0
 	call kjt_set_load_length

	ld hl,$8000
	ld a,(buffer)		; load to bank 3 or 5 depending on buffer flag
	rlca
	add a,3
	ld b,a
	call kjt_force_load		; load sample data at start of audio accessible system RAM
	jr nz,last_load	
	ld a,(samp_len_hi)		; subtract 64K from sample length
	dec a
	ld (samp_len_hi),a

	ld a,(buffer)		; load to bank 3 or 5 depending on buffer flag
	rlca
	add a,3
	push af
	call kjt_forcebank		; convert to signed samples
	call convertsamples
	pop af
	inc a
	call kjt_forcebank
	call convertsamples
	ld a,0			; used for the loop data
	call kjt_forcebank

	call wait_dma		; wait for post-audio DMA time
	ld a,(buffer)
	rrca 
	ld b,a
	ld c,0			; bc = location, depends on buffer
	ld de,$8000		; de = length (entire 64KB buffer)
	ld hl,(period)		; hl = period
	ld a,$40			; a = volume
	call set_up_channel0	; set registers to location for next buffer

	ld a,(buffer)
	xor 1
	ld (buffer),a		; switch buffer
	jr ls_loop
		
last_load
	
	call wait_dma		; wait for post-audio DMA time
	ld a,(buffer)
	rrca 
	ld b,a
	ld c,0			; bc = location, depends on buffer
	ld de,(samp_len_lo)
	srl d
	rr e			; de = length (remaining words)
	ld hl,(period)		; hl = period
	ld a,$40			; a = volume
	call set_up_channel0	; set registers to location for next buffer

es_loop	in a,(sys_keyboard_data)	;quit if ESC pressed
	cp $76
	jp z,quit			
	in a,(sys_audio_enable)	;wait for channel 0 loop flag
	bit 4,a
	jr z,es_loop

quit	xor a
	out (sys_audio_enable),a	;silence channel
	ret
	
;-------------------------------------------------------------------------------------

set_up_channel0

	out (audchan0_vol),a	;vol
	out (audchan1_vol),a	;vol
	ld a,c
	ld c,audchan0_loc
	out (c),a			;loc
	ld c,audchan1_loc
	out (c),a			;loc
	ld b,d
	ld c,audchan0_len
	out (c),e			;len
	ld c,audchan1_len
	out (c),e			;len
	ld b,h
	ld c,audchan0_per
	out (c),l			;per
	ld c,audchan1_per
	out (c),l			;per
	ret

;-------------------------------------------------------------------------------------

wait_dma	ld a,(vreg_read)		;wait for LSB for scanline count to change
	and $40
	ld b,a
loop2	ld a,(vreg_read)
	and $40
	cp b
	jr z,loop2
	ret

;--------------------------------------------------------------------------------------

convertsamples

	ld hl,$8000
cslp	ld a,(hl)
	sub $80
	ld (hl),a
	inc l
	jr nz,cslp
	inc h
	jr nz,cslp
	ret
	
;--------------------------------------------------------------------------------------

load_error

	ld hl,fnf_txt
	call kjt_print_string
	xor a
	ret


show_use

	ld hl,use_txt
	call kjt_print_string
	xor a
	ret

notwav

	ld hl,notwav_txt
	call kjt_print_string
	xor a
	ret
	

badwavtype

	ld hl,badwav_txt
	call kjt_print_string
	xor a
	ret


sampratebad

	ld hl,samprate_txt
	call kjt_print_string
	xor a
	ret

;---------------------------------------------------------------------------------------

notwav_txt	db "File is not a .wav",11,0

badwav_txt	db "Wav file is not of correct type",11,0

samprate_txt	db "Wav file sample rate is too high",11,0


loop_txt		db "Loop",11,0

use_txt		db 11,"USE: Playwav.exe filename",11,11
		db "Wav file must be 8 bit, mono, PCM",11
		db "with sample rate below 30KHz",11,0 
	

loading_txt	db "Loading...",11,0

fnf_txt		db "Load error - file not found?",11,0

test_fn		db "sample1.wav",0

filename		ds 32,0

original_irq	dw 0

buffer		db 0

samp_len_lo	dw 0
samp_len_hi	dw 0

period		dw 0 		; IE: 22050 Hz (16000000/22050)

header		ds 44,0

;--------------------------------------------------------------------------------------
