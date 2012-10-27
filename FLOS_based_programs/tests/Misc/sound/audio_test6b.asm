;-----------------------------------------------------------------------------------------
; tests audio loop flags with IRQ - mulitple channels
; This requires OSCA 642+
;-----------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"
	
	org $5000	

;-----------------------------------------------------------------------------------------
;	Copy samples to audio accessible RAM	
;-----------------------------------------------------------------------------------------

	ld a,%00010000
	out (sys_mem_select),a	;use alt write page
	
	ld a,%00000100
	out (sys_alt_write_page),a	;page in audio ram - first bank of 32kb
	call clear_ram
	ld hl,one_samp		;source address of sample
	ld de,$8000		;
	ld bc,4132		;length of sample
	ldir			;copy sample

	ld a,%00000101
	out (sys_alt_write_page),a	;page in audio ram - 2nd bank of 32kb
	call clear_ram
	ld hl,two_samp		;source address of sample
	ld de,$8000		;
	ld bc,4840		;length of sample
	ldir			;copy sample

	ld a,%00000110
	out (sys_alt_write_page),a	;page in audio ram - 3rd bank of 32kb
	call clear_ram
	ld hl,three_samp		;source address of sample
	ld de,$8000		;
	ld bc,4814		;length of sample
	ldir			;copy sample

	ld a,%00000111
	out (sys_alt_write_page),a	;page in audio ram - 4th bank of 32kb
	call clear_ram
	ld hl,four_samp		;source address of sample
	ld de,$8000		;
	ld bc,4490		;length of sample
	ldir			;copy sample

	ld a,%00000000
	out (sys_mem_select),a	;use same write page as read

	ld a,%11110111
	out (sys_clear_irq_flags),a	;clear sample loop flags and all irq flags

;-------------------------------------------------------------------------------------
; Set up Audio IRQ
;--------------------------------------------------------------------------------------

	ld hl,(irq_vector)
	ld (original_irq),hl
	ld hl,audio_irq_routine
	ld (irq_vector),hl
	ld a,%10001000		
	out (sys_irq_enable),a	;allow audio IRQs (only)

;-------------------------------------------------------------------------------------
	
	ld hl,test_txt1
	call kjt_print_string

	ld hl,$8000
	ld (logger),hl

;-------------------------------------------------------------------------------------
; Play sample(s)
;-------------------------------------------------------------------------------------


	call wait_dma		;wait for post-audio DMA time
	ld a,%00000000
	out (sys_audio_enable),a	;stop audio channels

	ld ix,one_data
	ld c,audchan0_loc		;set up channel 0 location/length/period/volume
	call setup_chan

	ld ix,two_data
	ld c,audchan1_loc		;set up channel 1 location/length/period/volume
	call setup_chan

	ld ix,thr_data
	ld c,audchan2_loc		;set up channel 2 location/length/period/volume
	call setup_chan

	ld ix,fou_data
	ld c,audchan3_loc		;set up channel 3 location/length/period/volume
	call setup_chan
	
	call wait_dma		;wait for post-audio DMA time
	ld a,%00001111		;enable channel(s) playback
	out (sys_audio_enable),a
	ld a,%11110000
	out (sys_clear_irq_flags),a


mainloop	in a,(sys_keyboard_data)	;wait in a loop
	cp $76
	jp nz,mainloop		;loop if ESC key not pressed

	ld a,%00000000
	out (sys_audio_enable),a	;stop all channels playback	
	
	ld hl,(original_irq)
	ld (irq_vector),hl
	ld a,%10000011		
	out (sys_irq_enable),a	;enable keyboard and mouse irqs
	xor a			
	ret			;and exit

;-------------------------------------------------------------------------------------
	

audio_irq_routine

	push af
	in a,(sys_audio_enable)

	push hl			;test - stores irq flags @ $8000+
	ld hl,(logger)		;
	ld (hl),a			;
	inc hl			;
	set 7,h			;
	ld (logger),hl		;
	pop hl			;
		
	bit 4,a
	call nz,chan0looped
	bit 5,a
	call nz,chan1looped
	bit 6,a
	call nz,chan2looped
	bit 7,a
	call nz,chan3looped
	
	pop af
	ei
	reti
	


chan0looped

	push af
	push bc
	push de
	push hl
	push ix
	push iy			
	ld hl,ch0txt
	call kjt_print_string
	ld a,%00010000			;clear channel 0 irq flag
	out (sys_clear_irq_flags),a
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret
	
	
chan1looped
	
	push af
	push bc
	push de
	push hl
	push ix
	push iy			
	ld hl,ch1txt
	call kjt_print_string
	ld a,%00100000			;clear channel 1 irq flag
	out (sys_clear_irq_flags),a
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret

	

chan2looped
	
	push af
	push bc
	push de
	push hl
	push ix
	push iy			
	ld hl,ch2txt
	call kjt_print_string
	ld a,%01000000			;clear channel 2 irq flag
	out (sys_clear_irq_flags),a
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret


		
chan3looped
	
	push af
	push bc
	push de
	push hl
	push ix
	push iy			
	ld hl,ch3txt
	call kjt_print_string
	ld a,%10000000			;clear channel 3 irq flag
	out (sys_clear_irq_flags),a
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret

		

	
;-------------------------------------------------------------------------------------


no_loop	ld b,$ff			;msb of location / 2
	ld a,$f0			;lsb of location / 2
	out (c),a			
	inc c
	ld b,$00			;msb of length
	ld a,$01			;lsb of length
	out (c),a
	ret
	
	
;-------------------------------------------------------------------------------------

clear_ram	ld hl,$8000
clrramlp	ld (hl),0
	inc hl
	ld a,h
	or l
	jr nz,clrramlp
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


;-------------------------------------------------------------------------------------

setup_chan

;set c to channel base port address
;set ix to address of sound data_structure

	ld a,(ix+0)		;lsb of location / 2
	ld b,(ix+1)		;msb of location / 2
	out (c),a			
	inc c
	ld a,(ix+2)		;lsb of length
	ld b,(ix+3)		;msb of length
	out (c),a
	inc c
	ld a,(ix+4)		;lsb of sample rate
	ld b,(ix+5)		;msb of sample rate
	out (c),a
	inc c
	ld a,(ix+6)		;volume
	out (c),a
	ret
	
	
setup_chan_loop

;set c to channel base port address
;set ix to address of sound data_structure

	ld a,(ix+0)		;lsb of location / 2
	ld b,(ix+1)		;msb of location / 2
	out (c),a			
	inc c
	ld a,(ix+2)		;lsb of length
	ld b,(ix+3)		;msb of length
	out (c),a
	ret
	

;-------------------------------------------------------------------------------------

pause_long
				
	ld b,0			;wait approx 1 second
twait2	ld a,%00000100
	out (sys_clear_irq_flags),a	;clear timer overflow flag
twait1	in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
	bit 2,a			
	jr z,twait1
	djnz twait2		;loop 256 times
	ret
	
	
;--------------------------------------------------------------------------------------

test_txt1		db "Audio Test - starting playback",11,0

;--------------------------------------------------------------------------------------


one_data	dw $0000,$0812,2000,$40	;location/2, length/2, period, volume
two_data	dw $4000,$0974,2000,$40
thr_data	dw $8000,$0967,2000,$40
fou_data	dw $c000,$08c5,2000,$40

;---------------------------------------------------------------------------------------

one_samp		incbin "one.raw"
two_samp		incbin "two.raw"
three_samp	incbin "three.raw"
four_samp		incbin "four.raw"

;-------------------------------------------------------------------------------------

original_irq	dw 0

logger		dw $8000

;--------------------------------------------------------------------------------------

ch0txt	db "Audio Channel 0 has looped",11,0

ch1txt	db "Audio Channel 1 has looped",11,0

ch2txt	db "Audio Channel 2 has looped",11,0

ch3txt	db "Audio Channel 3 has looped",11,0

;----------------------------------------------------------------------------------------
