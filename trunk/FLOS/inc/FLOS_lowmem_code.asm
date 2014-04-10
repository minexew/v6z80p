;******************************************************************************
;* Routines and Data positioned low in RAM to keep out of video page RAM area *
;******************************************************************************

max_bank	equ 14

packed_font	incbin "flos/data/philfont1_packed.bin"
char_colour	db 0

end_of_font	equ char_colour

;----------------------------------------------------------------------------------------
; Ports / System set up
;----------------------------------------------------------------------------------------

initialize_os	call page_out_hw_registers		; write underneath the video registers

		ld hl,env_var_list		 	; erase environment variables
		ld bc,max_envars*8
		call os_bchl_memclear	

		ld hl,keymaps		
		ld bc,$180				; clear the unshifted, shifted and alt keymaps
		call os_bchl_memclear

		ld ix,shifted_keymap			; copy the default UK keymap	
		ld iy,keymaps+$8e
		ld e,1
		ld d,62
kmcpylp		ld a,(ix)
		ld (iy),a
		ld a,(ix-62)
		ld (iy-128),a
		dec d
		jr z,kmcdone
		inc iy
		inc ix
		dec e
		jr nz,kmcpylp
		inc iy
		inc iy
		ld e,6
		jr kmcpylp
	
kmcdone		xor a
		out (sys_alt_write_page),a	  	; page video registers back in at $200
		ld (bank_pre_cmd),a		  	; reset "original bank" register


nmi_freeze_os_init

		xor a
		out (sys_audio_enable),a		; disable audio channels
		out (sys_hw_settings),a                 ; NMI unmasked etc

		
;-------------------------------------------------------------------------------
; Video set up
;-------------------------------------------------------------------------------


		call kjt_wait_vrt
		ld a,%00000100
		ld (vreg_vidctrl),a			; disable video		

		ld a,15					; prepare VRAM $10000 - $1FFFF for FLOS display	
		ld (vreg_vidpage),a			; writes go to video page 8+ ($10000-$1ffff)
		ld a,%00100000		
		out (sys_mem_select),a			; use all-writes-to-vram mode - interrupts will be off
		ld hl,$8000		
clrvlp1		ld (hl),$ff				; Fill $18000-$19fff = $ff (paper bitplane)	
		inc hl
		bit 5,h
		jr z,clrvlp1
		xor a
clrvlp2		ld (hl),a				; Fill rest of VRAM 64KB page $1A000=$1ffff = $00
		inc hl
		bit 7,h
		jr nz,clrvlp2
		out (sys_mem_select),a			; vram paged out / default upper RAM bank is 0

		call os_page_in_video			; prepare font in VRAM (@ $1E000-$1FFFF) for char plot routine		
		ld hl,packed_font			; unpack font to VRAM (@ $1E800)
		ld de,video_base+$800
		push de
		ld bc,end_of_font-packed_font
		call unpack_rle
		pop bc					; make inverse charset (@ $1F000)
		ld de,video_base+$1000			; and fill $1F800-$1FFFF with $ff
		ld hl,video_base+$1800
finvloop	ld a,(bc)
		cpl
		ld (de),a
		ld (hl),$ff
		inc bc
		inc hl
		inc de
		bit 3,b
		jr nz,finvloop
		call os_page_out_video

		call os_clear_screen			; clear charmap and display


os_restore_video_mode

		call os_set_display_mode

enable_video
	
		call os_wait_vrt
		xor a
		ld (vreg_vidctrl),a			; Enable video & Use set bitmap loc register set A
		ret
	


os_set_display_mode

		call kjt_wait_vrt			; only for neatness
		
		ld hl,video_registers			; zero all video registers
		ld c,16
		call os_chl_memclear_short
		
		call default_colours

		xor a
		out (sys_vram_location),a		; ensures video window is at default $2000
		
		ld hl,priority_registers		; Set the sprite priority registers to the default scheme
		ld b,16					; 0-7 = 00b, 8-15 = 01b
sprprilp1	ld (hl),a			
		inc hl			
		bit 3,l					; Note: relies on sprite 1st priority register location [0:3] = $0
		jr z,nxtsprpr		
		or %01			
nxtsprpr	djnz sprprilp1
		
		ld hl,sprite_registers			; zero sprite registers
		ld bc,$200
		call os_bchl_memclear
		
		ld a,5
		ld (vreg_yhws_bplcount),a		; 6 bitplane display 

		ld hl,bitplane0a_loc			; initialize buffer A bitplane pointers to $10000,$12000,$14000,$16000,$18000,$1a000	
		ld b,6
		xor a
inbplp		ld (hl),0
		inc hl
		ld (hl),a
		inc hl
		ld (hl),1
		inc hl
		ld (hl),0				; clear modulo
		inc hl
		add a,$20
		djnz inbplp

		ld hl,vreg_window
		ld e,$5a				; y display settings for PAL display
		in a,(sys_vreg_read)
		bit 5,a
		jr z,paltv
		ld e,$38			
paltv		ld (hl),e				; set y window size/position (200 lines)
		ld a,%00000100
		ld (vreg_rasthi),a			; set x window reg
		ld a,$8c
		ld (hl),a				; set x window size/position (320 pixels)

		xor a
		out (sys_irq_enable),a
		cpl 
		out (sys_clear_irq_flags),a		; clear irq flags except keyboard, handled later 		
		ld a,%10000000
		ld (vreg_rasthi),a			; clear any outstanding video IRQ request
		in a,(sys_serial_port)			; clear any outstanding serial IRQ request		
		call clear_keyboard_buffer
                call set_irq_vectors
		call os_enable_irq			; enable keyboard (and mouse if enabled) interrupts
		ret
	

;-------------------------------------------------------------------------------


set_irq_vectors	ld hl,default_irq_instructions  	; set interrupts for kernal
		ld de,irq_jp_inst
		ld bc,6
		ldir
                ret
                
	
	
;============================================================================
; CORE VIDEO ROUTINES
;============================================================================

os_print_string_cond

		call test_quiet_mode
		ret nz
		
	
os_print_string

; prints ascii at current cursor position
; set hl to start of 0-termimated ascii string

		
		push bc
		ld bc,(cursor_y)			;c = y, b = x
prtstrlp	ld a,(hl)			
		inc hl
		or a
		jr nz,not_eos				
		
prts_end	ld (cursor_y),bc			;updates cursor position on exit
		pop bc
		ret
		
		

not_eos		cp 13					;is character a CR? (13)
		jr nz,nocr
		ld b,0
		jr prtstrlp
nocr		cp 10					;is character a LF? (10)
		jr z,linefeed
		cp 11					;is character a LF+CR? (11)
		jr nz,nolf
		ld b,0
		jr linefeed
		
nolf		call os_plotchar
		inc b					;move right a character
		ld a,b
		cp OS_window_cols			;right edge of screen?
		jr nz,prtstrlp
		ld b,0
linefeed	inc c
		ld a,c
		cp OS_window_rows			;last line?
		jr nz,prtstrlp
		call scroll_up
		ld c,OS_window_rows-1
		jr prtstrlp

		
;---------------------------------------------------------------------------------

os_plotchar

		push af
		xor a					;make sure the hardware registers are paged in
		out (sys_alt_write_page),a
		
		ld a,(current_pen)
		ld (char_colour),a
		ld a,b					; make sure coordinates are in range
		cp OS_window_cols			; if not, set them at 0
		jr c,x_in_rng	
		ld b,0			
x_in_rng	ld a,c
		cp OS_window_rows
		jr c,y_in_rng
		ld c,0
y_in_rng	pop af

os_pltchr_specific_attribute
		
		push hl
		push de
		push bc
		push af
		
		ld h,0					; multiply charpos_y by 40
		ld d,h
		ld a,c
		rlca
		rlca
		rlca
		ld e,a
		ld l,a
		add hl,hl
		add hl,hl
		add hl,de	
		ld e,b					; add on charpos_x
		add hl,de
		ex de,hl				; de = charmap offset
	
		ld a,$0e				; store char's colour attribute
		ld (vreg_vidpage),a
		call os_page_in_video
		ld hl,video_base
		add hl,de
		ld a,(char_colour)
		ld (hl),a
		call os_page_out_video	

		pop af
		ld hl,OS_charmap			; store char in charmap
		add hl,de	
		ld (hl),a			

		ex de,hl
		ld e,b
		ld d,0
		or a
		sbc hl,de				; get y line offset in hl
		add hl,hl				; multiply by 8 for bitmap offset
		add hl,hl
		add hl,hl			
		add hl,de				; add on bitplane offset and x coord. HL = dest

		ld (blit_src_loc),a			; low byte of source location (Font starts $1E000 in VRAM (in linear format)
		ld a,l
		ld (blit_dst_loc),a			; set blit dest low byte

		call setup_char_blitter

		ld a,(char_colour)			; select correct font bitplane based on ink/paper colours
		ld l,a
		rrca
		rrca
		rrca
		rrca
		ld c,a
		ld b,4
plchbplp	ld a,$07			
		srl c
		rla
		srl l
		rla
		rlca
		rlca
		rlca
		ld (blit_src_loc+1),a			; set source location - high byte 

		ld a,h	
		ld (blit_dst_loc+1),a			; set blit destination - high byte
		add a,$20
		ld h,a					; adj for next bitplane 
		
		call waitblit				; make sure blitter is not busy before starting
		
		xor a			 
		ld (blit_width),a			; set width and start blit
		djnz plchbplp		

		pop bc
		pop de
		pop hl

		call waitblit				; make sure blitter has ended on exit

		ret

	
setup_char_blitter

		ld a,255
		ld (blit_src_mod),a			; set blit source modulo
		ld a,OS_window_cols-1
		ld (blit_dst_mod),a			; set blit dest modulo
		ld a,%01110000		
		ld (blit_misc),a			; Ascending blit, src and dst in VRAM bank 1
		ld bc,0
		ld (blit_src_msb),bc			; Not using VRAM > 128KB
		ld a,7
		ld (blit_height),a			; Set height of blit
		ret
	
	
	
waitblit	in a,(sys_vreg_read)	
		bit 4,a 			 
		jr nz,waitblit		 
		ret
				
;-----------------------------------------------------------------------------------------	


cursor_keywait
	
		call os_wait_vrt			;flash cursor (image loc = DE) whilst waiting for key press
		
		call cursor_flash
		
		call os_get_key_press
		or a
		jr z,cursor_keywait
		
		ld (current_scancode),a
		ld a,b
		ld (current_asciicode),a		;store ascii version
		
		call delete_cursor
		ld a,24					;ensures cursor is mainly visible 
		ld (cursorflashtimer),a			;during held key operations etc
		xor a
		ld (cursorstatus),a
		ret
	
	

cursor_flash


		ld hl,cursorflashtimer
		inc (hl)
		ld a,(hl)
		cp 25
		ret nz
		ld (hl),0
		ld a,(cursorstatus)
		xor 1
		ld (cursorstatus),a
		jr z,delete_cursor
		push de				; put cursor image address in hl
		pop hl
		jr draw_cursor


delete_cursor

		ld hl,$0				; zero cursor (erase)


draw_cursor
	
		push de	
		ld a,h
		or $e0
		ld h,a
		ld (blit_src_loc),hl			; hl = cursor image in font area

		call mult_cursor_y_window_cols
		add hl,hl
		add hl,hl	
		add hl,hl
		ld d,$a0				; 6th bitplane
		ld a,(cursor_x)
		ld e,a
		add hl,de
		ld (blit_dst_loc),hl
		call setup_char_blitter
		xor a
		ld (blit_width),a			; set width and start blit
		call waitblit
		pop de
		ret
	

	
;----------------------------------------------------------------------------------

os_clear_screen

		ld hl,OS_charmap					; fill character map with spaces
		ld a,32				
		ld bc,OS_window_cols*OS_window_rows
		call os_bchl_memfill

		call os_wait_raster

		ld de,0							; home the cursor to top left
		ld (cursor_y),de			
		ld b,4							; clear the 4 text-plotting bitplanes
cltbplp		push bc
		ld bc,0+((OS_window_rows*8)-1)+((OS_window_cols-1)*256)	
		call blit_wipe
		ld a,d
		add a,$20
		ld d,a
		pop bc
		djnz cltbplp
		
		ld d,$c0						; clear the attributes also
		ld bc,0+(OS_window_rows-1)+((OS_window_cols-1)*256)
		call blit_wipe
		xor a
		ret


	
scroll_up	push hl
		push de
		push bc	

		ld bc,OS_window_cols*(OS_window_rows-1)			; scroll charmap up one line
		ld de,OS_charmap
		ld hl,OS_charmap+OS_window_cols
		ldir
		ld b,OS_window_cols					; fill bottom line with spaces			
		ld a,32
subllp		ld (de),a
		inc de
		djnz subllp
		
		ld hl,$c000+OS_window_cols				; scroll attributes up a line also
		ld de,$c000
		ld bc,0+(OS_window_rows-2)+((OS_window_cols-1)*256)
		call blit_copy
		ld de,$c000+((OS_window_rows-1)*OS_window_cols)
		call blit_wipe						; zero last line of attributes also
				
		call os_wait_raster
		
		ld hl,OS_window_cols*8					; start source 8 lines down
		ld de,0							; start dest at top
		ld b,4							; number of bitplanes to do
scrlbplp	push bc
		ld bc,0+(((OS_window_rows-1)*8)-1)+((OS_window_cols-1)*256)	
		call blit_copy
		
		push hl						; clear the bottom line (doing so directly prevents current
		push de						; pen colour filling entire line)
		ld de,8*(OS_window_cols*(OS_window_rows-2))
		add hl,de
		ex de,hl
		ld bc,7+((OS_window_cols-1)*256)			; height c = 7, width b = OS_window_cols
		call blit_wipe
		pop de
		pop hl
		
		ld a,h
		add a,$20						; adjust for next bitplane
		ld h,a
		ld a,d
		add a,$20			
		ld d,a

		pop bc
		djnz scrlbplp
		
		pop bc
		pop de
		pop hl
		ret
	
	
	
blit_wipe	ld hl,$a000				; for wipes use the cursor bitplane as source as its all zeroes
blit_copy	ld (blit_src_loc),hl		
		ld (blit_dst_loc),de
		push hl
		ld hl,0
		ld (blit_src_mod),hl			; set blit modulos
		ld (blit_src_msb),hl			; Not using VRAM > 128KB
		pop hl
		ld a,%01110000			 
		ld (blit_misc),a			; Ascending blit, src and dst in VRAM bank 1
		ld (blit_height),bc			; set size and go!
		
		call waitblit
		ret	

	
	
	
redraw_ui_line

		ld b,0					; set de = offset in char/attrib map appropriate for line
rs_xloop	ld hl,video_base			; set c to line 
		add hl,de
		ld a,$0e
		ld (vreg_vidpage),a
		call os_page_in_video
		ld a,(hl)
		ld (char_colour),a
		call os_page_out_video
		ld hl,OS_charmap
		add hl,de
		ld a,(hl)				
		call os_pltchr_specific_attribute
		inc de
		inc b
		ld a,b
		cp OS_window_cols
		jr nz,rs_xloop
		ret	



		

os_page_in_video

		in a,(sys_mem_select)
		or %01000000
wr_memsel	out (sys_mem_select),a
		ret
		



os_page_out_video

		in a,(sys_mem_select)
		and %10111111
		jr wr_memsel



os_wait_vrt

		push af
wait_vrt1	in a,(sys_vreg_read)
		bit 0,a
		jr nz,wait_vrt1
wait_vrt2	in a,(sys_vreg_read)
		bit 0,a
		jr z,wait_vrt2
		pop af
		ret



os_wait_raster

		push af
wait_ras1	in a,(sys_vreg_read)
		bit 2,a
		jr z,wait_ras1
wait_ras2	in a,(sys_vreg_read)
		bit 2,a
		jr nz,wait_ras2
		pop af
		ret

	
os_chl_memclear_short
	
		ld b,0
	
os_bchl_memclear

		xor a

os_bchl_memfill

; fill memory from HL with A. Count in BC.

memfillp	ld (hl),a
		cpi					; HL=HL+1,BC=BC-1, PO = if BC-1=0
		jp pe,memfillp
		ret
	

;------------------------------------------------------------------------------------------------------------------

os_patch_font

; set A to char number
;     HL to source char address

		push af
		ld a,15					; writes go to video page 15+ ($1e000-$1ffff)
		ld (vreg_vidpage),a
		call os_page_in_video
		pop af
		
		ex de,hl
		ld c,$28
		ld l,a
		ld b,8
fpatchlp	call do_font_bytes
		inc c
		djnz fpatchlp
		
		call os_page_out_video
		xor a
		ret
		
do_font_bytes

		ld a,(de)
		inc de
		ld h,c
		ld (hl),a
		cpl
		res 3,h
		set 4,h
		ld (hl),a
		ret
	
;------------------------------------------------------------------------------------------------------------------

default_colours

		ld a,%00000010				; make sure palette 0 is target
		ld (vreg_palette_ctrl),a	

		ld a,$ff				; set all cursor+char combinations to white
		ld hl,palette
		ld bc,128
		call os_bchl_memfill

		ld hl,default_paper
	

os_set_ui_colours

; set hl to list of colours..

		ld a,%00000010				; set up OS colour palette 
		ld (vreg_palette_ctrl),a		; ensure palette 0 receives writes

		push hl
		call get_colour
		ld (palette+(16*2)),de			; paper colour
		call get_colour
		ld (palette),de				; border
		call get_colour
		ld (palette+(48*2)),de			; cursor
		ld de,palette+(17*2)	
		ld bc,15*2				; pens
		ldir						
		pop hl

		call page_out_hw_registers
		ld de,colours_mirror
		ld bc,18*2
		ldir
		call page_in_hw_registers
		ret

	

get_colour

		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ret
		

os_get_ui_colours

		ld hl,colours_mirror			; return address of RGB list: paper, border, cursor, 15 pen colours
		ret


os_set_pen

		ld (current_pen),a
		ret


os_get_pen

		ld a,(current_pen)
		ret	



;------------------------------------------------------------------------------------------------------------------


mult_cursor_y_window_cols

		ld a,(cursor_y)				; returns cursor y * 40 in HL
		rlca
		rlca
		rlca
		ld l,a	
		ld h,0
		add hl,hl
		add hl,hl
		add a,l
		ld l,a
		ret nc
		inc h
		ret
	
	
	
attributes_left
	
		call attr_move_preamble	
		ld de,video_base			; move attributes along left - called by the
		add hl,de				; backspace routine (ensure below $2000 as it pages
		ld d,h					; out system RAM)
		ld e,l
		dec de
		ldir
		xor a
		ld (de),a
at_movend	call os_page_out_video
		ret

	
	
attributes_right
		
		call attr_move_preamble
		call mult_cursor_y_window_cols		; push attributes along right - called by the
		ld de,video_base+OS_window_cols-2	; "enter ascii text" part of the editor. (ensure
		add hl,de				; this routine is below $2000 as it pages out system RAM)
		ld d,h
		ld e,l
		inc de		
		lddr
		jr at_movend



attr_move_preamble

		ld a,$e					; move attributes along left - called by the
		ld (vreg_vidpage),a			; backspace routine (ensure below $2000 as it pages
		call os_page_in_video			; out system RAM)
		ret



;---------------------------------------------------------------------------------------
; Unpacks VxZ80P_RLE packed files 
; V1.01 - Note: Cannot unpack across upper RAM pages
;----------------------------------------------------------------------------------------

unpack_rle

;set HL = source address of packed file
;set DE = destination address for unpacked data
;set BC = length of packed file

		push hl
		pop ix
		dec bc					; length less one (for token byte)
		inc hl
unp_gtok	ld a,(ix)				; get token byte
unp_next	cp (hl)					; is byte at source location same as token?
		jr z,unp_brun				; if it is, there's a byte run to expand
		ldi					; if not, simply copy this byte to destination
		jp pe,unp_next				; last byte of source?
		ret
	
unp_brun	push bc				; stash B register
		inc hl		
		ld a,(hl)				; get byte value
		inc hl		
		ld b,(hl)				; get run length
		inc hl
		
unp_rllp	ld (de),a				; write byte value, byte run length
		inc de		
		djnz unp_rllp
		
		pop bc	
		dec bc					; last byte of source?
		dec bc
		dec bc
		ld a,b
		or c
		jr nz,unp_gtok
		ret	


;------------------------------------------------------------------------------------------


os_store_CPU_regs

		push af			
		push bc
		ld a,r
		ld c,a
		ld a,i
		ld b,a
		ld (ir_store),bc			;store IR regs
		ld b,0
		jp pe,iff2zero
		inc b
iff2zero	ld a,b
		ld (iff2_store),a			;store IFF2 value
		
		in a,(sys_mem_select)
		ld (mem_select_store),a			;store port0 (mem paging reg)
		pop bc
		pop af
		
		di
		ld (sp_store),sp			;store_register_values - PC is not stored at present
		ld sp,sp_store
		push iy
		push ix
		exx
		ex af,af'
		push hl
		push de
		push bc
		push af
		exx
		ex af,af'
		push hl
		push de
		push bc
		push af
		ld sp,(sp_store)
		ei
		ret
		
	
;-------- Memory bank switching /paging functions ---------------------------


os_forcebank

; sets which of the 32KB banks is mapped into address space $8000-$ffff
; set A to required bank (range: 0 - max_bank)

		push bc			
		inc a					
		and %00001111
set_op1		ld b,a
		in a,(sys_mem_select)
		and %11110000
		or  b
		pop bc
set_op2		out (sys_mem_select),a
		ret
		



os_getbank

; returns current bank number in A

		in a,(sys_mem_select)		
		and %00001111	
		ret z					;if %000, forcebank has not been called previously.
		dec a					;range is normally %001 to %111 so sub 1 to give 0-maxbank
		ret



os_cachebank

		in a,(sys_mem_select)			; stores the current bank number internally
		and %00001111
		ld (banksel_cache),a
		ret


	
os_restorebank
	
		push bc				; restores the bank saved with above function
		ld a,(banksel_cache)
		jr set_op1
		
	
	
os_incbank

		call os_getbank				; selects the next bank, if > max_bank, error 8 is returned in A
		inc a					; A=0 if successful
		cp max_bank+1
		jr z,fs_iberr
		call os_forcebank
		xor a					; set zero flag
		ret
fs_iberr	ld a,8					; error 8 - address out of range
		or a					; clear carry flag / reset zero flag
		ret




restore_bank_no_script

		ld a,(bank_pre_cmd)			; restore original bank when finally returning to OS
		call os_forcebank
		xor a
		ld (in_script_flag),a
		ret
		
			
;------------------------------------------------------------------------------------------

include "flos/inc/FLOS_irq_code.asm"		

include	"flos/inc/FLOS_keyboard_routines.asm"				

;====================================================================================
; END OF ROUTINES THAT NEED TO BE BELOW $2000 TO AVOID POTENTIAL VIDEO PAGING ISSUES
;====================================================================================
