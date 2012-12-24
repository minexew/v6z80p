
init_linecop
		ld ix,lc_bm_scroller				; fill in address in linecop of scroller display section
		ld hl,scroll_bitmap_loc_lo+(16*bitmap_width)	
		ld (ix+0),l					; skip first 8 lines of this bitmap, they're only used for delete data
		ld (ix+2),h
		ld (ix+4),scroll_bitmap_loc_hi	
		
		ld ix,lc_menu_bm				; fill in address in linecop of scroller display section
		ld hl,menu_bitmap_loc_lo	
		ld a,menu_bitmap_loc_hi
		ld bc,8*bitmap_width
		add hl,bc
		adc a,0
		ld (ix+0),l					; skip first 8 lines of this bitmap, they're only used for delete data
		ld (ix+2),h
		ld (ix+4),a	
		
		
		ld ix,lc_bm_mirror				; fill in addresses in linecop list for reflected scroller
		ld hl,scroll_bitmap_loc_lo+(96*bitmap_width)
		ld b,40	
		ld c,0						; linecop list mirror lines, number of addrs to init
imirlnlp	ld (ix+0),l
		ld (ix+2),h
		ld (ix+4),scroll_bitmap_loc_hi			; does not cross 64KB page so same MSb each time
		ld de,bitmap_width*2
		xor a
		sbc hl,de					; hl = address of previous line in bitmap (reverse order, skip alternate lines)
		ld de,12
		add ix,de					; ix = address of next linecop address to init
		inc c
		djnz imirlnlp
		ld hl,0
		ld (ix+0),l
		ld (ix+2),h
		ld (ix+4),scroll_bitmap_loc_hi			; at last line return to blank vram
		
		
		ld hl,logo_palette
		ld de,lc_logo_palette				; copy the logo palette colours to linecop
		ld b,64
		call write_linecop_colours
		
		ld hl,star_colours				; copy the star colours to linecop list
		ld de,lc_star_colrs1
		ld b,9
		call write_linecop_colours

		ld hl,star_tint_colours				; copy the star (tinted) colours to linecop list
		ld de,lc_star_colrs2
		ld b,9
		call write_linecop_colours

		ld hl,star_colours				; copy the star colours to linecop list 
		ld de,lc_star_colrs3
		ld b,9
		call write_linecop_colours
		
		ld hl,scrolly_palette
		ld de,lc_scr_palette				; copy the scrolly font palette colours to linecop list
		ld b,16
		call write_linecop_colours
			
		ld hl,reflection_palette
		ld de,lc_scrr_palette				; copy the scrolly font reflection colours to linecop list
		ld b,16
		call write_linecop_colours
	
		ld hl,selector_palette
		ld de,lc_msel_palette				; copy music selector line colours to linecop list
		ld b,16
		call write_linecop_colours

		ld hl,menu_fade_colours
		ld de,lc_menu_colrs				; copy menu fade line colours to linecop list
		ld b,40
fsrploop2	ld a,(hl)
		ld (de),a
		inc de
		inc de
		inc hl
		ld a,(hl)
		ld (de),a
		inc de
		inc de
		inc hl
		inc de
		inc de
		djnz fsrploop2


		ld ix,linecop_addr0
		ld de,linecop_list
		ld (ix+2),%10000000				; set bits [18:16] of linecop address (bit 7 must be set when writing linecop hi address)
		ld (ix+1),d					; set bits [15:8] of linecop address
		set 0,e						; set "enable linecop" (bit 0)
		ld (ix+0),e					; set bits [7:1] of list address (and start line cop)
		ret


;----------------------------------------------------------------------------------------------------------------------------------------------------

write_linecop_colours

		sla b
fsrploop	ld a,(hl)
		ld (de),a
		inc de
		inc de
		inc hl
		djnz fsrploop	
		ret		

;----------------------------------------------------------------------------------------------------------------------------------------------------

; Linecop mnemonics and their opcodes..

lc_wr        equ $0000		; Write Register
lc_wril      equ $2000		; Write Register & Inc Line (then wait)
lc_wrir      equ $4000		; Write Register & Inc Reg
lc_wrilir    equ $6000		; Write Register & Inc Reg & Inc Line (then wait)
lc_sr        equ $8000		; Select Register
lc_wl	     equ $c000		; Wait Line

;------------------------------------------------------------------------------------------------------------------------------------------------------

sine_scroll_scanline	equ $044
msel_scanline		equ $0cc
menu_scanline		equ $0da

		org ($+1) & $FFFE			; Linecop lists must be aligned to even bytes
			
linecop_list	dw lc_wl+$008				; wait for line 
		dw lc_sr+palette			
		dw lc_wrir+$000				; set background colour: black
		dw lc_wr+$000		
		dw lc_sr+bitplane0a_loc			; select bitmap loc register (for logo section)
		dw lc_wrir+(logo_bitmap_loc_lo&$FF)	; write to reg and inc selected reg
		dw lc_wrir+(logo_bitmap_loc_lo>>8)	; write to reg and inc selected reg
		dw lc_wrir+(logo_bitmap_loc_hi)		; write to reg and inc selected reg
		dw lc_sr+bitplane1a_loc+3
		dw lc_wr+$00				; zero modulo		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		
		dw lc_sr+palette+(0*2)			; update colours 0-8 for starfield
lc_star_colrs1	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir
		
				
		dw lc_sr+palette+(192*2)		; write colours 192-255 for logo
lc_logo_palette	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
	
		dw lc_wrir				; + 16
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 24
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
	
		dw lc_wrir				; + 032
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 40
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
	
		dw lc_wrir				; + 48
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 56
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		
;--------------- SPLIT SCREEN: SINE SCROLL AREA---------------------------------------------------------------------------------------------------------------------------------------

		dw lc_wl+sine_scroll_scanline		; wait for line 		

		dw lc_sr+bitplane0b_loc			; select bitmap loc register (for scroller section)
lc_bm_scroller	dw lc_wrir+(scroll_bitmap_loc_lo&$FF)	; write to reg and inc selected reg
		dw lc_wrir+(scroll_bitmap_loc_lo>>8)	; write to reg and inc selected reg
		dw lc_wrir+(scroll_bitmap_loc_hi)	; write to reg and inc selected reg
		dw lc_sr+bitplane0a_loc+3
		dw lc_wr+$00				; reset the bitmap counter
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		
		dw lc_sr+palette+(192*2)		; update colours 192-208 for scrolling message
lc_scr_palette	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		
		
		dw lc_wl+sine_scroll_scanline+$4c	; wait for line
		
		dw lc_sr+palette+(0*2)			; update colours 0-8 for tinted starfield
lc_star_colrs2	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir

		dw lc_wl+sine_scroll_scanline+$54	; mirrored scroller bitmap (update bitmap loc each line)
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane1a_loc+3
		dw lc_wr+$ff				; set modulo to $ff (resets offset at start of each line)
		
		dw lc_sr+palette+(192*2)		; update colours 192-208 for reflected scrolling message
lc_scrr_palette	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		
		dw lc_sr+bitplane0a_loc			; 0
lc_bm_mirror	dw lc_wrir				; locations are filled in by init routine
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 1
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 2
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 3
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 4
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 5
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 6
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 7
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 8
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 9
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;a
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc 		; b
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; c
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; d
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; e
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; f
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 10
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 11
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 12
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 13
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 14
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 15
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 16
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 17
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 18
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 19
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			; 1a
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			; 1b
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
				
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;1c
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;1d
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;1e
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;1f
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;20
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;21
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;22
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;23
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;24
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;25
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;26
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				;chunky mode, use bitmap location regs B
		dw lc_sr+bitplane0b_loc			;27
		dw lc_wrir
		dw lc_wrir
		dw lc_wril
		
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				;chunky mode, use bitmap location regs A
		dw lc_sr+bitplane0a_loc			;reflection terminator line
		dw lc_wrir
		dw lc_wrir
		dw lc_wr
		
		dw lc_wl+sine_scroll_scanline+$82	; wait for line
		dw lc_sr+palette+(0*2)			; update colours for starfield (back to untinted)
lc_star_colrs3	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir




;--------------- SPLIT SCREEN: MUSIC SELECTOR LINE AREA------------------------------------------------------------------------------------------------------

		dw lc_wl+msel_scanline			; wait for line - menu section
		dw lc_sr+bitplane0b_loc			; select bitmap loc register
		dw lc_wrir+(msel_bitmap_loc_lo&$FF)	; write to reg and inc selected reg
		dw lc_wrir+(msel_bitmap_loc_lo>>8)	; write to reg and inc selected reg
		dw lc_wrir+(msel_bitmap_loc_hi)		; write to reg and inc selected reg
		dw lc_sr+bitplane1b_loc+3
		dw lc_wr+$00				; zero modulo
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$a0				; chunky mode, use bitmap location regs B
		
		dw lc_sr+palette+(192*2)		; update colours 128-143 for music selector graphic
lc_msel_palette	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir	
		dw lc_wrir				; + 8
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir
		dw lc_wrir				
		

;--------------- SPLIT SCREEN: FILE MENU AREA---------------------------------------------------------------------------------------------------------------------------------------


		dw lc_wl+menu_scanline			; wait for line - menu section
		dw lc_sr+bitplane0a_loc			; select bitmap loc register
lc_menu_bm	dw lc_wrir+(menu_bitmap_loc_lo&$FF)	; write to reg and inc selected reg
		dw lc_wrir+(menu_bitmap_loc_lo>>8)	; write to reg and inc selected reg
		dw lc_wrir+(menu_bitmap_loc_hi)		; write to reg and inc selected reg
		dw lc_wr				; reset bitmap counter
		dw lc_sr+bitplane1a_loc+3
		dw lc_wr+$00				; zero modulo
		dw lc_sr+vreg_vidctrl
		dw lc_wr+$80				; chunky mode, use bitmap location regs A
		
		dw lc_sr+palette+(192*2)
lc_menu_colrs	dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wril
		dw lc_sr+palette+(192*2)
		dw lc_wrir				; + 0	(values filled in by init routine)
		dw lc_wr

;-----------------------------------------------------------------------------------------------------

		dw $c1ff				; wait for line $1ff (end of list)
	
;-----------------------------------------------------------------------------------------------------
