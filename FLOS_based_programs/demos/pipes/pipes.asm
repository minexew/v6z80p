; -------------------------------------------------
; Pipes Demo (Line Sync'd Blits) - Phil Ruston 2009
; -------------------------------------------------
;
;V1.01 - Automatic NTSC / VGA adjustments
;
;SOURCE TAB SIZE = 10
;
;---Standard header for OSCA and FLOS  -----------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------- Test OSCA version ---------------------------------------------------------------------

	
	call kjt_get_version		; check running under FLOS v541+ 
	ex de,hl
	ld de,$650
	xor a
	sbc hl,de
	jr nc,osca_ok
	ld hl,old_osca_txt
	call kjt_print_string
	xor a
	ret

old_osca_txt

	db "Program requires OSCA v650+",11,0
	
osca_ok	

;--------- Get video mode --------------------------------------------------------------------

	ld b,0					
	in a,(sys_hw_flags)			;VGA jumper on?
	bit 5,a
	jr z,not_vga
	ld b,2
	jr got_mode 
not_vga	ld a,(vreg_read)			;60 Hz?
	bit 5,a
	jr z,got_mode
	ld b,1
got_mode	ld a,b
	ld (video_mode),a			;0=PAL, 1=NTSC, 2=VGA


;--------- Initialize ------------------------------------------------------------------------

	call set_up_tune
	call set_up_display
	call set_up_scroll_sprites
	call set_up_logo_sprites
	call set_up_linecop_pipes

	call kjt_wait_vrt
	ld a,%10000000			; enable video
	ld (vreg_vidctrl),a			; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)


;--------- Main loop -------------------------------------------------------------------------	

wvrtstart	ld a,(vreg_read)			; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	call per_frame_routines

	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart			; quit if ESC key pressed
	xor a
	ld a,$ff
	ret
		
;---------------------------------------------------------------------------------------------

per_frame_routines

	
	call swap_sprite_buffer
	
	call anim_pipes

	call vblinds_effect

	call anim_scroller
	
	call play_tracker
	call update_sound_hardware
	ld hl,0
	ld (mult_table),hl			;reset sin 0 table entry
		
	ret
	
		
;--------------------------------------------------------------------------------------------------------------

set_up_tune

	ld a,%00010000
	out (sys_mem_select),a		;use alternative write page, source page = 1
	ld a,4
	out (sys_alt_write_page),a		;dest = sample RAM

	ld hl,samples			;copy samples to audio ram
	ld de,$8000
	ld bc,$8000
	ldir
	
	xor a
	out (sys_mem_select),a
	
	ld hl,0
	ld (force_sample_base),hl		; Force sample base location to $0
	call init_tracker			; Initialize mod with forced sample_base
	ret

;--------------------------------------------------------------------------------------------------------------


set_up_display

	call kjt_wait_vrt

	ld hl,palette
	ld bc,$200
	xor a
	call kjt_bchl_memfill		; zero palette at start
	
	ld a,%00000000			; select y window pos register
	ld (vreg_rasthi),a			 
	ld b,$2e				; PAL window
	ld a,(video_mode)
	cp 1
	jr nz,notntsc
	ld b,$39				; NTSC window
notntsc	cp 2
	jr nz,gotywin
	ld b,$2b				; VGA window
gotywin	ld a,b				; set display y window
	ld (vreg_window),a
	ld a,%00000100			; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$7e
	ld (vreg_window),a			; set 368 pixels wide window

	ld ix,bitplane0a_loc		; initialize datafetch start address HW pointer.
	ld hl,$0000			; datafetch start address (15:0)
	ld c,0				; data fetch start address (16)
	ld (ix),l
	ld (ix+1),h
	ld (ix+2),c
	ld (ix+7),$ff			; modulo = $ff: reuse same line
	
	ld a,%10000100			; disable video
	ld (vreg_vidctrl),a			; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)
	ret


;--------------------------------------------------------------------------------------------------------------

set_up_linecop_pipes

bar_width equ 33


	call kjt_page_in_video		;copy pipe image to vram $200
	ld a,0
	ld (vreg_vidpage),a		
	ld hl,large_pipe_image
	ld de,video_base+$200
	ld bc,64
	ldir
	call kjt_page_out_video
	 

	ld hl,large_pipe_colours
	ld de,palette
	ld bc,48*2
	ldir


	ld hl,sin_table			; upload sine table to math unit
	ld de,$0600
	ld bc,$200
	ldir	

	
	ld hl,$200			;setup blitter registers for linecop pipes
	ld (blit_src_loc),hl	
	ld a,0
	ld (blit_src_msb),a
	ld a,0
	ld (blit_src_mod),a
	ld a,0
	ld (blit_dst_msb),a		
	ld a,0
	ld (blit_dst_mod),a
	ld a,0
	ld (blit_height),a
	ld a,%01000000
	ld (blit_misc),a			;Transparency = off, ascending = 1 
	
	
	ld hl,$8000			;build_linecop_list
	ld a,13
	call kjt_forcebank			;put linecop at $70000 in system RAM

	
	ld bc,$102			;number of lines (two extra for buffer) PAL
	ld de,$10				;first wait line PAL
	ld a,(video_mode)
	or a
	jr z,build_lcl
	cp 1
	jr nz,vga_lcl
	ld bc,$e2				;number of lines (two extra for buffer) NTSC
	ld de,$18				;first wait line NTSC
	jr build_lcl
vga_lcl	ld bc,$f2				;number of lines (two extra for buffer) VGA
	ld de,$18				;first wait line NTSC

build_lcl	push de
	
	call lci_setwaitline		;line to wait for
		
	ld de,0				;choose "palette index 0"
	call lci_setreg
	ld d,$40				;control bits = inc reg after write
	ld e,0
	call lci_writereg			;colour lo
	call lci_writereg			;colour hi
		
	ld de,$212			;choose "blit dest" reg
	call lci_setreg
	ld d,$40				;control bits = inc reg after write
	ld e,0				;this byte is updated each frame by routine
	call lci_writereg			;write lo
	call lci_writereg			;write_hi

	ld de,$217			;choose "blit width / start" reg
	call lci_setreg
	ld de,bar_width-1			;write to reg
	call lci_writereg
	
	pop de
	inc de
	dec bc
	ld a,b
	or c
	jr nz,build_lcl
	
	ld de,$112
	call lci_setwaitline		;line to wait for
	ld de,0				;choose "palette index 0"
	call lci_setreg
	ld d,$40				;control bits = inc reg after write
	ld e,$00
	call lci_writereg			;colour lo
	call lci_writereg			;colour hi
	ld de,$1ff			;end of linecop list, wait for line $1ff
	call lci_setwaitline
	
	ld a,0
	call kjt_forcebank			;put linecop at $70000 in system RAM

	ld hl,1
	ld (vreg_linecop_lo),hl		;set linecop address and start

	ret


;-------- build line cop list sub routines --------------------------------------------------------

lci_setwaitline

	ld (hl),e				;set hl to address of linecop instruction
	inc hl				;set de to line to wait for
	ld a,d
	or $c0
	ld (hl),a
	inc hl
	ret

	
lci_setreg

	ld (hl),e				;set hl to address of linecop instruction
	inc hl				;set de to register to update
	ld a,d
	or $80
	ld (hl),a
	inc hl
	ret


lci_writereg

	ld (hl),e				;set hl to address of linecop instruction
	inc hl				;set e to value to write to reg
	ld (hl),d				;set d to control bits. 4 = reload linecop address
	inc hl				;5 = inc waitline, 6 = inc register (all after the write)
	ret

;---------------------------------------------------------------------------------------------

set_up_scroll_sprites


	ld a,%10000000
	out (sys_mem_select),a		;page in sprite ram
	ld b,0				;pre build 64 48x16 sprites
	ld c,%10000000			;(one for each possible font defination slice)
msplp	ld a,c
	ld (vreg_vidpage),a
	ld de,sprite_base
	call make_spr_group
	ld de,sprite_base+$400
	call make_spr_group
	ld de,sprite_base+$800
	call make_spr_group
	ld de,sprite_base+$c00
	call make_spr_group
	inc c
	ld a,c
	cp 192
	jr nz,msplp
	ld a,%00000000
	out (sys_mem_select),a		;page out sprite ram



	ld ix,sprite_coords			
	ld hl,0
	ld de,8				;gap between slices (sprites)
	ld a,0
	ld b,46				;number of sprites
scrxlp	ld (ix),l				;x coord lo
	ld (ix+46),h			;x coord hi
	ld (ix-46),a			;y coord
	add a,4				;in-wave offset
	add hl,de
	inc ix
	djnz scrxlp	


	ld hl,scroll_colours
	ld de,palette+(48*2)
	ld bc,16*2
	ldir

		
	ld a,%00001001
	ld (vreg_sprctrl),a			;enable sprites / double buffer regs
	ret
	
	
	
make_spr_group
	
	push bc
	ld a,b

	ld hl,scroll_sprite_def0
	bit 0,a
	jr z,spzero
	ld hl,scroll_sprite_def1
spzero	ld bc,128
	ldir
		
	ld hl,scroll_sprite_def0
	bit 1,a
	jr z,spzerob
	ld hl,scroll_sprite_def1
spzerob	ld bc,128
	ldir
	
	ld hl,scroll_sprite_def0
	bit 2,a
	jr z,spzeroc
	ld hl,scroll_sprite_def1
spzeroc	ld bc,128
	ldir
	
	ld hl,scroll_sprite_def0
	bit 3,a
	jr z,spzerod
	ld hl,scroll_sprite_def1
spzerod	ld bc,128
	ldir

	ld hl,scroll_sprite_def0
	bit 4,a
	jr z,spzeroe
	ld hl,scroll_sprite_def1
spzeroe	ld bc,128
	ldir
	
	ld hl,scroll_sprite_def0
	bit 5,a
	jr z,spzerof
	ld hl,scroll_sprite_def1
spzerof	ld bc,128
	ldir
	
	pop bc
	inc b
	ret

	
;---------------------------------------------------------------------------------------------------
	
set_up_logo_sprites

	ld a,16
	ld hl,logo_gfx
	ld de,sprite_base
	ld bc,end_logo_gfx-logo_gfx
	call unpack_sprites
	
	ld ix,spr_registers+(46*4)		;position logo sprites
	call position_logo
	ld ix,spr_registers+256+(46*4)	;repeat for 2nd buffer registers
	call position_logo

	ld hl,logo_colours			;upload colours
	ld de,palette+(64*2)
	ld bc,64*2
	ldir
	ret


position_logo

	ld l,$f6			;PAL position
	ld a,(video_mode)
	or a
	jr z,lsset
	cp 1
	jr nz,vgalsp		;NTSC position
	ld l,$ce
	jr lsset
vgalsp	ld l,$de			;VGA position
				
lsset	ld a,$78			;x
	ld c,$00			;1st def
	ld b,7
	ld de,4
sulsplp	ld (ix),a			;x
	ld (ix+1),$25		;height/msbs
	ld (ix+2),l		;y
	ld (ix+3),c		;def
	add ix,de
	inc c
	inc c
	add a,16
	djnz sulsplp
	ret

	
;---------------------------------------------------------------------------------------------


anim_pipes

pal_pipe_count equ 256

	call kjt_page_in_video		;wipe line (obviously blitter would be faster)
	ld hl,video_base
	xor a
	ld b,192
clrline	ld (hl),a
	inc l
	ld (hl),a
	inc hl
	djnz clrline
	call kjt_page_out_video


	ld a,13				;update linecop list with x coords of pipes
	call kjt_forcebank			;select sysram page $d at $8000 (linecop address $0)
	ld ix,$8000+$a			;addr of blit dst lo byte in copper list
	ld hl,96				;min amplitude
	ld b,pal_pipe_count
	ld a,(video_mode)
	or a
	jr z,got_pc
	ld b,pal_pipe_count-32		;number of coords

got_pc	ld a,(x_start_offset1)
	ld e,a
	ld a,(x_start_offset2)
	ld d,a
xloop	ld (mult_write),hl			;set sinus max amplitude
	ld a,e
	ld (mult_index),a			;set sine index 1
	ld a,d
	exx
	ld hl,(mult_read)
	ld (mult_index),a			;set sine index 2
	ld de,(mult_read)
	add hl,de				;add two waves together
	sra h
	rr l
	sra h
	rr l
	ld de,164				;centre origin on screen
	add hl,de				
	ld (ix),l
	ld (ix+2),h
	ld de,18
	add ix,de	
	exx
	inc e				;sine 1 displacement
	inc e
	inc e
	dec d				;sine 2 displacement
	dec d				;sine 2 displacement
	inc hl
	djnz xloop

	ld a,(x_start_offset1)
	add a,2
	ld (x_start_offset1),a

	ld a,(x_start_offset2)
	add a,1
	ld (x_start_offset2),a

	ld a,0
	call kjt_forcebank			;bank 0
	ret


;---------------------------------------------------------------------------------------------

swap_sprite_buffer


	ld a,(buffer)
	xor 1
	ld (buffer),a
	rlca
	rlca
	or %00001001
	ld (vreg_sprctrl),a
	ret
	



anim_scroller


	ld hl,$40				;transfer coords to sprite registers	
	ld (mult_write),hl			;set sinus max positive amplitude	
	ld de,108				;x left offset / y origin
	ld bc,128				;PAL y origin
	ld a,(video_mode)
	or a
	jr z,gotyorg
	ld bc,$70				;NTSC y origin
gotyorg	exx
	
	ld iy,sprite_registers
	ld a,(buffer)
	or a
	jr nz,sbuf0
	ld iy,sprite_registers+$100
sbuf0	ld ix,sprite_coords
	ld de,4				;offset to next spr reg
	ld b,46				;number of sprites
		
spreglp	ld a,(ix-46)
	ld (mult_index),a			;y sine index for this sprite
	exx
	ld hl,(mult_read)
	add hl,bc				;centre y coords on screen
	ld (iy+2),l
	
	ld l,(ix)				;x coord low
	ld h,(ix+46)
	add hl,de				;add left edge offset
	ld (iy),l
	ld a,h
	or $30
	ld (iy+1),a			;x coord hi / misc bits
	exx

	ld a,(ix-92)			;def
	sla a
	sla a
	ld (iy+3),a
	
	add iy,de
	inc ix
	djnz spreglp


	
	
	ld ix,sprite_coords			;update sprite coords
	ld b,46
movsplp	ld a,(ix-46)			;y index		
	add a,2				;y-wave per frame offset
	ld (ix-46),a
	
	ld l,(ix)				;x coord
	ld h,(ix+46)
	ld de,4				;speed of scroller
	xor a
	sbc hl,de
	ld (ix),l
	ld (ix+46),h
	jr nc,spstif
	ld de,368				;reposition this sprite at right edge
	add hl,de
	ld (ix),l
	ld (ix+46),h
	ld a,(ix-46)					
	add a,46*4			;fix the y index (number of sprites * in-wave offset)						
	ld (ix-46),a
	

swrap	ld iy,(scroll_text_loc)		;get new definition for sprite
	ld a,(iy)
	sub 32
	jr nc,nowrap
	ld iy,scroll_text
	ld (scroll_text_loc),iy
	jr swrap
nowrap	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,font
	add hl,de
	ld de,(font_slice)
	add hl,de
	ld a,(hl)
	ld (ix-92),a			;new sprite definition 
	inc de
	bit 3,e
	jr z,sliceok
	ld de,0
	inc iy
	ld (scroll_text_loc),iy
sliceok	ld (font_slice),de		
	
spstif	inc ix
	djnz movsplp
	
	ret



;---------------------------------------------------------------------------------------
; Unpacks my RLE packed data to sprite RAM - Phil_V5Z80P @ Retroleum.co.uk 2008
; Keeps destination within $1000-$1fff and updates vreg_vidpage as required
;----------------------------------------------------------------------------------------

unpack_sprites

;set  A = initial sprite bank (0-31)
;set HL = source address of packed file
;set DE = destination address for unpacked data (within sprite page $1000-$1fff)
;set BC = length of packed file

	dec bc			; less 1 to skip match token
	push hl
	pop ix
	exx
	ld b,a
	exx
	or $80
	ld (vreg_vidpage),a		; select initial sprite bank

	in a,(sys_mem_select)
	and $1f
	or $80
	out (sys_mem_select),a	; page in sprite memory
	
	inc hl
unp_gtok	ld a,(ix)			; get token byte
unp_next	bit 5,d			; test for next sprite page
	jp z,nchsb1
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,(ix)
nchsb1	cp (hl)			; is byte at source location same as token?
	jr z,unp_brun		; if it is, there's a byte run to expand
	ldi			; if not, simply copy this byte to destination
	jp pe,unp_next		; last byte of source?
	jr packend
	
unp_brun	push bc			; stash B register
	inc hl		
	ld a,(hl)			; get byte value
	inc hl		
	ld b,(hl)			; get run length
	inc hl
	
unp_rllp	ld (de),a			; write byte value, byte run length
	inc de		
	bit 5,d			; test for next sprite page
	jp z,nchsb2
	ld c,a
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,c
nchsb2	djnz unp_rllp
	
	pop bc	
	dec bc			; last byte of source?
	dec bc
	dec bc
	ld a,b
	or c
	jp nz,unp_gtok

packend	in a,(sys_mem_select)	;page out sprite memory
	and $7f
	out (sys_mem_select),a	
	ret

;----------------------------------------------------------------------------------------------

vblinds_effect

	ld b,32*2			; PAL blind count
	ld a,(video_mode)
	or a
	jr z,bc_ok
	cp 1
	jr nz,ntsc_bc
	ld b,26*2			; NTSC blind count
	jr bc_ok
ntsc_bc	ld b,28*2			; VGA blind count
bc_ok	ld a,b
	ld (mod_inst+1),a
	ld a,13
	call kjt_forcebank
	
	ld bc,18			; = step between bgnd colour entries in linecop list
	exx
	ld ix,$8000+(18*2)+4	; = first line cop background colour location (offset due to buffer)
	ld de,0			; 32 "blinds"
nxtbar	ld hl,(blinds_loc)
	add hl,de
	ld b,8			; 8 lines per "blind"
barseg	ld a,(hl)
	ld (ix),a			; col lo
	inc hl
	ld a,(hl)			; col hi
	ld (ix+2),a
	inc hl
	exx
	add ix,bc
	exx
	djnz barseg
	inc e
	inc e
	ld a,e
mod_inst	cp 64			;blind count * 2
	jr nz,nxtbar

	ld a,0
	call kjt_forcebank

	ld a,(counter)
	inc a
	ld (counter),a
	and $1
	ret nz

	ld hl,(blinds_loc)
	inc hl
	inc hl
	ld (blinds_loc),hl
	ld de,end_of_bar
	xor a
	sbc hl,de
	ret nz
	ld hl,blinds_bar
	ld (blinds_loc),hl
	ret

;-----------------------------------------------------------------------------------------------

video_mode	db 0	

;---------Data and vars for background blinds effect -------------------------------------------


blinds_loc	dw blinds_bar

blinds_bar	dw $300,$410,$520,$630,$741,$852,$963,$a74
		dw $b85,$c96,$da7,$eb8,$fc9,$fda,$feb,$ffd
		dw $fff,$ffd,$feb,$fda,$fc9,$eb8,$da7,$c96
		dw $b85,$a74,$963,$852,$741,$630,$520,$410
		
end_of_bar	dw $300,$410,$520,$630,$741,$852,$963,$a74
		dw $b85,$c96,$da7,$eb8,$fc9,$fda,$feb,$ffd
		dw $fff,$ffd,$feb,$fda,$fc9,$eb8,$da7,$c96
		dw $b85,$a74,$963,$852,$741,$630,$520,$410

		dw $300,$410,$520,$630,$741,$852,$963,$a74
		dw $b85,$c96,$da7,$eb8,$fc9,$fda,$feb,$ffd
		dw $fff,$ffd,$feb,$fda,$fc9,$eb8,$da7,$c96
		dw $b85,$a74,$963,$852,$741,$630,$520,$410


		
;--------Data and vars for pipes --------------------------------------------------------------
		

counter		db 0

large_pipe_image	incbin "blu_mag_bar.bin"

large_pipe_colours	incbin "blu_mag_bar_palette.bin"

sin_table	   	incbin "sin_table.bin"
	
x_start_offset1	db 0
x_start_offset2	db 0



;--------Data and vars for scroller ------------------------------------------------------------


scroll_sprite_def0  ds 128,0

scroll_sprite_def1	incbin "8x8crystal_sprite.bin"

scroll_colours	incbin "8x8crystal_palette.bin"

font		incbin "rotated_fontb.bin"

scroll_text	db "  WELCOME TO ANOTHER V6Z80P INTRO.. THIS TIME ITS A TEST "
		db "OF LINE SYNCD BLITS... HELLO TO: "
		DB "JIM B, GRAHAM C, VALEN, DANIEL I, MARTIN M, BRANISLAV B, HENK K, "
		DB "DAVID R, SLAWOMIR B, TAN YONG LAK, BRANDER, ERIK L, PETER MCQ, "
		DB "GREY, HUW W, STEVE G, GEOFF O, RICHARD D, ALAN G, DANIEL T, JIM FA, IVAN, BOOTBLOCK, PETER G "
		DB "AND ANYONE I FORGOT...    CODE: PHIL RUSTON 2009, TUNE: DANDELION BY DADDY FREDDY.... WRAP!      ",0

scroll_text_loc	dw scroll_text

font_slice	dw 0

wave_index_start	db 0

		ds 46*2,0
sprite_coords	ds 46*2,0

buffer		db 0


;------- Data and vars for logo -------------------------------------------------------------------------


logo_gfx		incbin "v6logo_sprites_packed.bin"
end_logo_gfx	db 0

logo_colours	incbin "v6logo_palette.bin"


;---------------------------------------------------------------------------------------------------------

include		"50Hz_60Hz_Protracker_code_v513.asm"

		org (($+2)/2)*2		;WORD align song module in RAM

music_module	incbin "tune.pat"

samples		incbin "tune.sam"
		
;------------------------------------------------------------------------------------------
	