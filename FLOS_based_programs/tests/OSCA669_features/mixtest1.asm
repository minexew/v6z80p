;-----------------------------------------------------------------------------------------
; tests audio playback - one-shot sample play (reloads registers after playback starts)
; plays "one", "two", "three", "four" on successive channels and repeats
;-----------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;-----------------------------------------------------------------------------------------
	org $5000		
;-----------------------------------------------------------------------------------------

	ld hl,test_txt1
	call kjt_print_string

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

;-------------------------------------------------------------------------------------

	ld hl,all_right
	call kjt_print_string
	ld a,%00001111		;all to right
	out ($22),a
	call play_1234
	
	ld hl,all_left
	call kjt_print_string
	ld a,%11110000		;all to left
	out ($22),a
	call play_1234

	ld hl,all_both
	call kjt_print_string
	ld a,%11111111		;all to both
	out ($22),a
	call play_1234
	
	ld hl,original
	call kjt_print_string
	ld a,%01011010		;as original mixer
	out ($22),a
	call play_1234

	xor a
	ret
	
	
play_1234

	call wait_dma
	ld a,%00000000		;stop channel(s) playback req
	out (sys_audio_enable),a
	ld ix,one_data
	ld c,audchan0_loc		;set up channel sample
	call setup_chan
	call wait_dma
	ld a,%00000001		;start channel(s) playback req
	out (sys_audio_enable),a
	ld c,audchan0_loc		;reload loc and length
	call no_loop
	call pause_long
	call pause_long
	
	call wait_dma
	ld a,%00000000		;stop channel(s) playback req
	out (sys_audio_enable),a
	ld ix,two_data
	ld c,audchan1_loc		;set up channel sample
	call setup_chan
	call wait_dma
	ld a,%00000010		;start channel(s) playback req
	out (sys_audio_enable),a
	ld c,audchan1_loc		;reload loc and length
	call no_loop
	call pause_long
	call pause_long
	
	call wait_dma
	ld a,%00000000		;stop channel(s) playback req
	out (sys_audio_enable),a
	ld ix,thr_data
	ld c,audchan2_loc		;set up channel sample
	call setup_chan
	call wait_dma
	ld a,%00000100		;start channel(s) playback req
	out (sys_audio_enable),a
	ld c,audchan2_loc		;reload loc and length
	call no_loop
	call pause_long
	call pause_long
	
	call wait_dma
	ld a,%00000000		;stop channel(s) playback req
	out (sys_audio_enable),a
	ld ix,fou_data
	ld c,audchan3_loc		;set up channel sample
	call setup_chan
	call wait_dma
	ld a,%00001000		;start channel(s) playback req
	out (sys_audio_enable),a
	ld c,audchan3_loc		;reload loc and length
	call no_loop
	call pause_long
	call pause_long
	
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

wait_dma	ld a,(vreg_read)
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

test_txt1		db "Audio Test",11,0

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

all_left		db "All channels left..",11,0
all_right		db "All channels right..",11,0
all_both		db "All to both..",11,0
original		db "Original format..",11,0

;-------------------------------------------------------------------------------------
