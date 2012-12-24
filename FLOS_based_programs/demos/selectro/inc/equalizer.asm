;----------------------------------------------------------------------------------------

equalizer_pos_y	equ $85

set_up_equalizer_sprites

		ld ix,equalizer_sprites			;put equalizer gfx in sprite ram
		ld iy,equalizer_sprites+$400
		ld de,0
nxteq		ld hl,equalizer_sprites			
		ld bc,$800
		push ix
		push iy
		push de
		xor a
		call copy_to_sprite_ram
		pop de
		pop iy
		pop ix
		ld b,16*4				;make new equalizer image (drop level 4 lines)
mkeqsp		ld (ix),0
		ld (iy),0
		inc ix
		inc iy
		djnz mkeqsp	
		ex de,hl
		ld bc,$800
		add hl,bc
		ex de,hl
		bit 7,d
		jr z,nxteq
		
		ld hl,equalizer_colours
		ld de,palette+(128*2)
		ld bc,64*2
		ldir


		ld ix,sprite_registers+(64*4)		;set up default equalizer sprite registers (spr regs 64-71)
		ld b,4					
		ld hl,$e8				;1st xpos
			
initspr		ld de,$10
		ld (ix+0),l
		ld a,h
		or $40					;height
		ld (ix+1),a				;x coord lo
		ld (ix+2),equalizer_pos_y		;y coord lo
		ld (ix+3),15*8				;def
		add hl,de
			
		ld (ix+4),l
		ld a,h
		or $40					;height
		ld (ix+5),a				;x coord lo
		ld (ix+6),equalizer_pos_y		;y coord lo
		ld (ix+7),(15*8)+4			;def
		add hl,de
		
		ld de,8
		add ix,de
		djnz initspr
		ret
	
;----------------------------------------------------------------------------------------

update_equalizer_sprites

		ld iy,equalizer_levels
		ld ix,sprite_registers+(64*4)		;1st equalizer spr reg is 64
		ld de,8
		ld b,4
anespr		ld a,64
		sub (iy)
		jr nc,eqlok1
		xor a
eqlok1		cp 64
		jr c,eqlok2
		ld a,63
eqlok2		and $fc
		sla a
		ld (ix+3),a				;def for left half of channel's sprite
		add a,4
		ld (ix+7),a				;def for right half of channel's sprite
		
		ld a,(iy)				;level falls
		or a
		jr z,equsmin
		ld a,(iy)
		sub 2
		jr nc,eqlvok
		xor a
eqlvok		ld (iy),a

equsmin		inc iy
		add ix,de
		djnz anespr
		ret
	
	
	
equalizer_scan

		ld a,(pt_channels_triggered)
		ld c,a
		ld ix,channel_data                     ; find which channels are to be (re)triggered
		ld de,vars_per_channel                  
		ld hl,equalizer_levels
		ld b,1
		
echslp		ld a,c					; triggered new sample?
		and b
		jr nz,setevol				

		ld a,(ix+samp_loop_len_hi)		; no trigger, but is this a looping sample?
		or a
		jr nz,lpsamp
		ld a,(ix+samp_loop_len_lo)		; if a one shot sound, the sample loop length will be $0001
		cp 1
		jr z,ecntr
lpsamp		ld a,(frame_count)			; this is a looping sample
		and 3
		jr nz,ecntr
		ld a,(ix+volume)			; put 75% of its volume in the equalizer every 4th frame
		srl a					; (if this is higher than current eq level)
		srl a
		neg
		add a,(ix+volume)
		jr seteq
		
setevol		ld a,(ix+volume)			; if channel's volume level is higher than current eq level
seteq		cp (hl)					; set the eq level to volume
		jr c,ecntr
		ld (hl),a

ecntr		inc hl
		add ix,de				; move to next channel's data
		sla b
		bit 4,b
		jr z,echslp
		ret

;---------------------------------------------------------------------------------------------------------


equalizer_levels

		db 64,48,32,16

equalizer_sprites
			
		incbin "flos_based_programs\demos\selectro\data\spr_eq.bin"

equalizer_colours

		incbin "flos_based_programs\demos\selectro\data\equalizer64col_palette.bin"
	

;---------------------------------------------------------------------------------------------------------
