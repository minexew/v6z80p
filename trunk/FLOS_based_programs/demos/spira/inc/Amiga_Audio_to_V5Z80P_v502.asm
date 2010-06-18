;----------------------------------------------------------------------------------------
; Amiga hardware values to V5Z80P conversion / hardware register updates
; For Z80 Protracker Player (requires "Z80_protracker_player.asm")
;-----------------------------------------------------------------------------------------
;
; v5.02 - Used maths assist HW for period conversion (note: Index 0 is trashed)
;       - Optimized writes to audio registers - now technically correct, ie:
;         Period,volume,loc and len written one scanline, loop loc and len the next 
;       - Corrected loop loc and len writes (registers were being written every frame
;         regardless of a sample being triggered, this masked a bug in the PT Player code)
;----------------------------------------------------------------------------------------

firstchan_period	equ channel_data+period_lo
firstchan_volume	equ channel_data+volume
firstchan_location	equ channel_data+samp_loc_lo
firstchan_length	equ channel_data+samp_len_lo
firstchan_control	equ channel_data+control_bits
firstchan_loop_loc	equ channel_data+samp_loop_loc_lo
firstchan_loop_len	equ channel_data+samp_loop_len_lo

secondchan_period	equ channel_data+vars_per_channel+period_lo
secondchan_volume	equ channel_data+vars_per_channel+volume
secondchan_location	equ channel_data+vars_per_channel+samp_loc_lo
secondchan_length	equ channel_data+vars_per_channel+samp_len_lo
secondchan_control	equ channel_data+vars_per_channel+control_bits
secondchan_loop_loc	equ channel_data+vars_per_channel+samp_loop_loc_lo
secondchan_loop_len	equ channel_data+vars_per_channel+samp_loop_len_lo

thirdchan_period	equ channel_data+(vars_per_channel*2)+period_lo
thirdchan_volume	equ channel_data+(vars_per_channel*2)+volume
thirdchan_location	equ channel_data+(vars_per_channel*2)+samp_loc_lo
thirdchan_length	equ channel_data+(vars_per_channel*2)+samp_len_lo
thirdchan_control	equ channel_data+(vars_per_channel*2)+control_bits
thirdchan_loop_loc	equ channel_data+(vars_per_channel*2)+samp_loop_loc_lo
thirdchan_loop_len	equ channel_data+(vars_per_channel*2)+samp_loop_len_lo

forthchan_period	equ channel_data+(vars_per_channel*3)+period_lo
forthchan_volume	equ channel_data+(vars_per_channel*3)+volume
forthchan_location	equ channel_data+(vars_per_channel*3)+samp_loc_lo
forthchan_length	equ channel_data+(vars_per_channel*3)+samp_len_lo
forthchan_control	equ channel_data+(vars_per_channel*3)+control_bits
forthchan_loop_loc	equ channel_data+(vars_per_channel*3)+samp_loop_loc_lo
forthchan_loop_len	equ channel_data+(vars_per_channel*3)+samp_loop_len_lo

;----------------------------------------------------------------------------------------


update_sound_hardware

	xor a				; set up maths unit
	ld (mult_index),a
	ld hl,18308			; 16000000Hz / 7159090.5Hz * 16384 / 4
	ld (mult_table),hl			; to convert period values to V5Z80P spec
	
	ld hl,(firstchan_period)	  	; Amiga period
	add hl,hl
	add hl,hl
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ch0_convper),hl			
	ld hl,(secondchan_period)		; Amiga period
	add hl,hl
	add hl,hl
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ch1_convper),hl
	ld hl,(thirdchan_period) 		; Amiga period
	add hl,hl
	add hl,hl
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ch2_convper),hl
	ld hl,(forthchan_period)   		; Amiga period
	add hl,hl	
	add hl,hl
	ld (mult_write),hl
	ld hl,(mult_read)
	ld (ch3_convper),hl
	
	ld d,0				; d = composite of retrig bits
	ld hl,firstchan_control
	bit 0,(hl)
	jr z,ch0nort
	set 0,d
	res 0,(hl)
ch0nort	ld hl,secondchan_control
	bit 0,(hl)
	jr z,ch1nort
	set 1,d
	res 0,(hl)
ch1nort	ld hl,thirdchan_control
	bit 0,(hl)
	jr z,ch2nort
	set 2,d
	res 0,(hl)
ch2nort	ld hl,forthchan_control
	bit 0,(hl)
	jr z,ch3nort
	set 3,d
	res 0,(hl)
ch3nort	
						
	ld a,(HW_enabled_channels)
	ld e,a
	

;---------------------------------------------------------------------------------------------------------------
	
;	ld hl,$007
;	ld (palette),hl
	
	ld hl,vreg_read			; wait for display window part of scan line (sound dma is complete)
xwait1	bit 1,(hl)
	jr nz,xwait1
xwait2	bit 1,(hl)				
	jr z,xwait2
	
	ld b,55
zzzzz1	djnz zzzzz1
	
;	ld hl,$0ff
;	ld (palette),hl

;----------------------------------------------------------------------------------------------------------------


	ld hl,(ch0_convper)			; b = period value (hi)
 	ld b,h				; a = period value (lo)
	ld c,audchan0_per	
	out (c),l				; 16 bit write
	ld a,(firstchan_volume)		; volume value
	out (audchan0_vol),a		; write volume to HW register
	bit 0,d				; set loc and len if triggered
	jr z,nnllch0
	ld hl,(firstchan_location)
	ld b,h				 
	ld c,audchan0_loc
	out (c),l				; 16 bit loc write
	ld hl,(firstchan_length)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	res 0,e				; disable this channel to force reg reload

nnllch0	ld hl,(ch1_convper)			; b = period value (hi)
 	ld b,h				; a = period value (lo)
	ld c,audchan1_per	
	out (c),l				; 16 bit write
	ld a,(secondchan_volume)		; volume value
	out (audchan1_vol),a		; write volume to HW register
	bit 1,d				; set loc and len if triggered
	jr z,nnllch1	
	ld hl,(secondchan_location)
	ld b,h				 
	ld c,audchan1_loc
	out (c),l				; 16 bit loc write
	ld hl,(secondchan_length)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	res 1,e				; disable this channel to force reg reload

nnllch1	ld hl,(ch2_convper)			; b = period value (hi)
 	ld b,h				; a = period value (lo)
	ld c,audchan2_per	
	out (c),l				; 16 bit write
	ld a,(thirdchan_volume)
	out (audchan2_vol),a		; write volume to HW register
	bit 2,d				; set loc and len if triggered
	jr z,nnllch2
	ld hl,(thirdchan_location)
	ld b,h				 
	ld c,audchan2_loc
	out (c),l				; 16 bit loc write
	ld hl,(thirdchan_length)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	res 2,e				; disable this channel to force reg reload

nnllch2	ld hl,(ch3_convper)			; b = period value (hi)
 	ld b,h				; a = period value (lo)
	ld c,audchan3_per	
	out (c),l				; 16 bit write
	ld a,(forthchan_volume)
	out (audchan3_vol),a		; write volume to HW register
	bit 3,d				; set loc and len if triggered
	jr z,nnllch3
	ld hl,(forthchan_location)
	ld b,h				 
	ld c,audchan3_loc
	out (c),l				; 16 bit loc write
	ld hl,(forthchan_length)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	res 3,e				; disable this channel to force reg reload

nnllch3	ld a,e
	out (sys_audio_enable),a		; relevent channels temporarily disabled

;----------------------------------------------------------------------------------------------------------------

;	ld hl,$007
;	ld (palette),hl

	ld hl,vreg_read			; wait one scan line 
xwait1b	bit 1,(hl)
	jr nz,xwait1b
xwait2b	bit 1,(hl)				
	jr z,xwait2b

	ld b,55
zzzzz2	djnz zzzzz2
	
;	ld hl,$f00
;	ld (palette),hl

;----------------------------------------------------------------------------------------------------------------


	bit 0,d				; redo loc and len for loop if triggered
	jr z,nnlllch0
	ld hl,(firstchan_loop_loc)
	ld b,h				 
	ld c,audchan0_loc
	out (c),l				; 16 bit loc write
	ld hl,(firstchan_loop_len)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	set 0,e				; disable this channel to force reg reload

nnlllch0	bit 1,d				
	jr z,nnlllch1			; redo loc and len for loop if triggered
	ld hl,(secondchan_loop_loc)
	ld b,h				 
	ld c,audchan1_loc
	out (c),l				; 16 bit loc write
	ld hl,(secondchan_loop_len)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	set 1,e				; disable this channel to force reg reload

nnlllch1	bit 2,d				
	jr z,nnlllch2			; redo loc and len for loop if triggered
	ld hl,(thirdchan_loop_loc)
	ld b,h				 
	ld c,audchan2_loc
	out (c),l				; 16 bit loc write
	ld hl,(thirdchan_loop_len)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	set 2,e				; disable this channel to force reg reload
		
nnlllch2	bit 3,d				
	jr z,nnlllch3			; redo loc and len for loop if triggered
	ld hl,(forthchan_loop_loc)
	ld b,h				 
	ld c,audchan3_loc
	out (c),l				; 16 bit loc write
	ld hl,(forthchan_loop_len)
	ld b,h				 
	inc c
	out (c),l				; 16 bit len write
	set 3,e	

nnlllch3	ld a,e
	out (sys_audio_enable),a		; re-enable affected channels to begin playback
	ld (HW_enabled_channels),a
	ret
	
;--------------------------------------------------------------------------------------------

HW_enabled_channels

	db 0

ch0_convper	dw 0
ch1_convper	dw 0
ch2_convper	dw 0
ch3_convper	dw 0

;============================================================================================
