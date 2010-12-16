
; FLOS for OSCA by Phil Ruston 2007-2010
; Compile with PASMO - Tab size: 10 characters
;
; IMPORTANT:
; ----------
; Assemble OS_symbols.asm first to create up-to-date symbol file
;
; A Note about VRAM paging on V6Z80P
; ----------------------------------
; The OS code and data loads at $1000 and can extend to $4fff.
; As this includes the video RAM page region 2000-3fff ensure that
; video memory is not enabled when the Program Counter is between
; $2000-$3FFF and that no data from that area is required when
; VRAM is paged in.
;----------------------------------------------------------------------

include "symbol_list.symbol"

os_start	 	equ $1000

;----------------------------------------------------------------------
; Assembly options
;----------------------------------------------------------------------

max_volumes	equ 8

;----------------------------------------------------------------------
	org os_start+$10
;----------------------------------------------------------------------
	
	jp os_first_run		; skip low memory data and routines
	
;-----------------------------------------------------------------------
; Kernal Jump Table - Makes OS routines available to user programs
; via indirect jumps. The table entries always remain in the same
; location and order.
;-----------------------------------------------------------------------

kjt_print_string		jp os_print_string		;start + $13
kjt_clear_screen		jp os_clear_screen		;start + $16
kjt_page_in_video		jp os_page_in_video		;start + $19
kjt_page_out_video		jp os_page_out_video	;start + $1c
kjt_wait_vrt		jp os_wait_vrt		;start + $1f
kjt_keyboard_irq_code	jp keyboard_irq_code	;start + $22
kjt_hex_byte_to_ascii	jp hexbyte_to_ascii		;start + $25
kjt_ascii_to_hex_word	jp ascii_to_hexword		;start + $28
kjt_dont_store_registers	jp os_dont_store_registers	;start + $2b
kjt_get_input_string	jp os_user_input		;start + $2e
kjt_check_volume_format	jp os_check_volume_format	;start + $31
kjt_change_volume		jp os_change_volume		;start + $34
kjt_check_disk_available	jp os_check_volume_format	;start + $37 ;obsoleted in v565
kjt_get_volume_info		jp os_get_volume_info	;start + $3a
kjt_format_device		jp os_format		;start + $3d
kjt_make_dir		jp os_make_dir		;start + $40
kjt_change_dir		jp os_change_dir		;start + $43
kjt_parent_dir		jp os_parent_dir		;start + $46
kjt_root_dir		jp os_root_dir		;start + $49
kjt_delete_dir		jp os_delete_dir		;start + $4c
kjt_find_file		jp os_find_file		;start + $4f
kjt_load_file		jp os_load_file		;start + $52
kjt_save_file		jp os_save_file		;start + $55
kjt_erase_file		jp os_erase_file		;start + $58
kjt_get_total_sectors	jp fs_get_total_sectors	;start + $5b
kjt_wait_key_press		jp os_wait_key_press	;start + $5e
kjt_get_key		jp os_get_key_press		;start + $61
kjt_forcebank		jp os_forcebank		;start + $64
kjt_getbank		jp os_getbank		;start + $67
kjt_create_file		jp os_create_file		;start + $6a
kjt_incbank		jp os_incbank		;start + $6d
kjt_compare_strings		jp os_compare_strings	;start + $70
kjt_write_bytes_to_file	jp os_write_bytes_to_file	;start + $73
kjt_bchl_memfill		jp os_bchl_memfill		;start + $76
kjt_force_load		jp os_force_load		;start + $79
kjt_set_file_pointer	jp os_set_file_pointer	;start + $7c
kjt_set_load_length		jp os_set_load_length	;start + $7f
kjt_serial_receive_header	jp os_serial_get_header	;start + $82
kjt_serial_receive_file	jp os_serial_receive_file	;start + $85
kjt_serial_send_file	jp os_serial_send_file	;start + $88
kjt_enable_mouse		jp os_enable_mouse		;start + $8b
kjt_get_mouse_position	jp os_get_mouse_position	;start + $8e
kjt_get_version		jp os_get_version		;start + $91
kjt_set_cursor_position	jp os_set_cursor_position	;start + $94
kjt_serial_tx_byte		jp os_serial_tx		;start + $97
kjt_serial_rx_byte		jp os_serial_rx		;start + $9a
kjt_dir_list_first_entry	jp os_goto_first_dir_entry	;start + $9d (added in v537)
kjt_dir_list_get_entry	jp os_get_dir_entry		;start + $a0 ""
kjt_dir_list_next_entry	jp os_goto_next_dir_entry	;start + $a3 ""
kjt_get_cursor_position	jp os_get_cursor_position	;start + $a6 (added in v538)
kjt_read_sector		jp user_read_sector		;start + $a9 (updated in v565)
kjt_write_sector		jp user_write_sector	;start + $ac ""
kjt_not_used_one		jp os_null		;start + $af obsoleted in V565
kjt_plot_char		jp os_plotchar		;start + $b2 (added in v539)
kjt_set_pen		jp os_set_pen		;start + $b5 ("")
kjt_background_colours	jp os_background_colours	;start + $b8 ("")
kjt_draw_cursor		jp draw_cursor		;start + $bb (added in v541)
kjt_get_pen		jp os_get_pen		;start + $be (added in v544)
kjt_scroll_up		jp scroll_up		;start + $c1 ("")
kjt_flos_display		jp os_restore_video_mode	;start + $c4 (added in v547)
kjt_get_dir_name		jp os_get_current_dir_name	;start + $c7 (added in v555)
kjt_get_key_mod_flags	jp os_get_key_mod_flags	;start + $ca (added in v555)
kjt_get_display_size	jp os_get_display_size	;start + $cd (added in v559)
kjt_timer_wait		jp os_timer_wait		;start + $d0 (added in v559)
kjt_get_charmap_addr_xy	jp os_get_charmap_xy	;start + $d3 (added in v559)
kjt_store_dir_position	jp os_store_dir		;start + $d6 (added in v560)
kjt_restore_dir_position	jp os_restore_dir		;start + $d9 (added in v560)
kjt_mount_volumes		jp os_mount_volumes		;start + $dc (added in v562)
kjt_get_device_info		jp os_get_device_info	;start + $df (added in v565)
kjt_read_sysram_flat	jp os_readmemflat		;start + $e2 (added in v570)
kjt_write_sysram_flat	jp os_writememflat		;start + $e5 (added in v570)
kjt_get_mouse_disp		jp os_get_mouse_motion	;start + $e8 (added in v571)
kjt_get_dir_cluster		jp fs_get_dir_block		;start + $eb (added in v572)
kjt_set_dir_cluster		jp fs_update_dir_block	;start + $ee (added in v572)
kjt_rename_file		jp os_rename_file		;start + $f1 (added in v572)
kjt_set_envar		jp os_set_envar		;start + $f4 (added in v575)
kjt_get_envar		jp os_get_envar		;start + $f7 (added in v572)
kjt_delete_envar		jp os_delete_envar		;start + $fa (added in v572)
kjt_file_sector_list	jp os_file_sector_list	;start + $fd (added in v575)
kjt_mouse_irq_code		jp mouse_irq_code		;start + $100 (added in v579)

;-----------------------------------------------------------------------------------------
 
;******************************************************************************
;* Routines and Data positioned low in RAM to keep out of video page RAM area *
;******************************************************************************


packed_font	incbin "philfont3_packed.bin"
end_of_font	db 0

os_version	dw $0581

char_colour	db 0

;----------------------------------------------------------------------------------------

include "os_irq_code.asm"		

;----------------------------------------------------------------------------------------

initialize_os

;----------------------------------------------------------------------------------------
; Ports / System set up
;----------------------------------------------------------------------------------------

	ld hl,default_irq_instructions	;set kernal interrupts	
	ld de,irq_jp_inst
	ld bc,6
	ldir

	xor a
	out (sys_audio_enable),a	; disable audio channels
	out (sys_hw_settings),a
	
	call page_out_hw_registers	; write underneath the video registers

	ld hl,env_var_list
	ld bc,max_envars*8
	xor a
	call os_bchl_memfill	; erase environment variables
	
	ld hl,keymaps		
	ld bc,$180		; clear the unshifted, shifted and alt keymaps
	xor a
	call os_bchl_memfill

	ld hl,unshifted_keymap	; copy the default UK keymap
	ld de,keymaps+$0e
	ld bc,$62-$0e
	ldir
	ld hl,shifted_keymap
	ld de,keymaps+$8e
	ld bc,$62-$0e
	ldir
	xor a
	out (sys_alt_write_page),a	; put video registers back at $200

	ld a,%00001111
	out (sys_clear_irq_flags),a	; clear irq flags 

	ld a,%10000001		
          out (sys_irq_enable),a	; enable keyboard interrupts

;-------------------------------------------------------------------------------
; Video set up
;-------------------------------------------------------------------------------

	call os_set_display_mode
	
	ld a,7			
	call set_bitplane
	ld a,%00100000		; wipe $10000-$1ffff
	out (sys_mem_select),a	; use all-writes-to-vram mode - interrupts will be off
	ld hl,0			
clrvlp	ld (hl),0
	inc hl
	ld a,h
	or l
	jr nz,clrvlp
	xor a
	out (sys_mem_select),a

	call os_page_in_video	; prepare font in vram (@ $1E000-$1F000) for blitter		
	ld hl,packed_font		; unpack font to VRAM (@ $1E400)
	ld de,video_base+$400
	ld bc,end_of_font-packed_font
	call unpack_rle
	ld b,8
	ld hl,video_base+$45f+(7*$60)
	ld de,video_base+$45f+(7*$80)
reorgflp	push bc
	ld bc,96
	lddr
	ld bc,32
	ex de,hl
	xor a
	sbc hl,bc
	ex de,hl	
	pop bc
	djnz reorgflp
	
	ld bc,$400		; make inverse charset (@ $1E800)
	ld hl,video_base+$400
	ld de,video_base+$800
invloop	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,invloop
	ld bc,$400		; fill $1ec00-$1ef00 with $ff
	ld hl,video_base+$c00
	ld a,$ff
	call os_bchl_memfill

	ld a,4			; fill 4th display bitplane with $FF (paper area)
	call set_bitplane		
	ld a,255			
	ld bc,$2000
	ld hl,video_base
	call os_bchl_memfill

	call os_page_out_video

	call os_clear_screen	; clear charmap and display
	
	call enable_video

	xor a
	ld (bank_pre_cmd),a	
	call os_forcebank		; default upper RAM bank is 0
	
	call os_get_version		
	ld b,6			; 7 banks for v5z80p
	ld a,d
	cp 6
	jr c,v5bank
	ld b,14			; 15 banks for v6z80p
v5bank	ld a,b
	ld (max_bank),a
	ret



os_set_display_mode

	call kjt_wait_vrt		; only for neatness
	
	xor a
	ld hl,video_registers	; zero all video registers
	ld bc,16
	call os_bchl_memfill
	ld (blit_src_msb),a		; zero v6 blit registers - helps backwards compatibility 
	ld (blit_dst_msb),a		; ""                  ""
	ld hl,sprite_registers	; zero sprite registers
	ld bc,$200
	call os_bchl_memfill
	
	ld a,%00000100
	ld (vreg_vidctrl),a		; disable video

	ld a,%10000000
	ld (vreg_rasthi),a		; clear any outstanding video IRQ request

	ld a,$5
	ld (vreg_yhws_bplcount),a	; 6 bitplane display 

	ld hl,bitplane0a_loc	; initialize buffer A bitplane pointers to $10000,$12000,$14000,$16000,$18000	
	ld b,6
	xor a
inbplp	ld (hl),0
	inc hl
	ld (hl),a
	inc hl
	ld (hl),1
	inc hl
	ld (hl),0			; reset modulo
	inc hl
	add a,$20
	djnz inbplp

	ld a,%00000010		; set up OS colour palette 
	ld (vreg_palette_ctrl),a	; ensure palette 0 receives writes
	call os_set_ui_colours
	
	ld hl,vreg_window
	ld e,$5a			; y display settings for PAL display
	in a,(sys_vreg_read)
	bit 5,a
	jr z,paltv
	ld e,$38			
paltv	ld (hl),e			; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; set x window reg
	ld a,$8c
	ld (hl),a			; set x window size/position (320 pixels)

	call setup_mult_table
	ret
	
;-------------------------------------------------------------------------------


os_restore_video_mode

	call os_set_display_mode

enable_video
	
	call os_wait_vrt
	xor a
	ld (vreg_vidctrl),a		; Enable video & Use set bitmap loc register set A
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
	ld bc,(cursor_y)		;c = y, b = x
prtstrlp	ld a,(hl)			
	inc hl	
	or a			
	jr nz,noteos
	ld (cursor_y),bc		;updates cursor position on exit
	pop bc
	ret
	
noteos	cp 13			;is character a CR? (13)
	jr nz,nocr
	ld b,0
	jr prtstrlp
nocr	cp 10			;is character a LF? (10)
	jr z,linefeed
	cp 11			;is character a LF+CR? (11)
	jr nz,nolf
	ld b,0
	jr linefeed
	
nolf	call os_plotchar
	inc b			;move right a character
	ld a,b
	cp OS_window_cols		;right edge of screen?
	jr nz,prtstrlp
	ld b,0
linefeed	inc c
	ld a,c
	cp OS_window_rows		;last line?
	jr nz,prtstrlp
	push hl
	push bc
	call scroll_up
	pop bc
	pop hl
	ld c,OS_window_rows-1
	jr prtstrlp

		
;---------------------------------------------------------------------------------

os_plotchar

	push af
	xor a			;make sure the hardware registers are paged in
	out (sys_alt_write_page),a
	
	ld a,(current_pen)
	ld (char_colour),a
	ld a,b			; make sure coordinates are in range
	cp OS_window_cols		; if not, set them at 0
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
	
	ld hl,OS_window_cols*64	; this needs to be set in case external program calls
	ld (mult_table),hl		; the plotchar routine (and it has changed the index/multiplier)
	xor a			; find char map offset
	ld (mult_index),a		
	ld d,c			; y coord
	ld e,a			
	ld (mult_write),de
	ld de,(mult_read)		; y line offset (chars)	
	ld l,b
	ld h,a
	add hl,de
	ex de,hl			; de = charmap offset

	ld a,$0e			; store char's colour attribute
	ld (vreg_vidpage),a
	call os_page_in_video
	ld hl,video_base
	add hl,de
	ld a,(char_colour)
	ld (hl),a
	call os_page_out_video	

	pop af
	ld hl,OS_charmap		; store char in charmap
	add hl,de	
	ld (hl),a			

	ld hl,(mult_read)		; get y line offset in hl
	add hl,hl			; multiply by 8 for bitmap offset
	add hl,hl
	add hl,hl			
	ld d,0	
	ld e,b
	add hl,de			; add on bitplane offset and x coord. HL = dest

	sub 32			; a = ascii code of character to plot
	ld (blit_src_loc),a		; low byte of source location (Font is at $1E000 in VRAM (in linear format)
	ld a,l
	ld (blit_dst_loc),a		; set blit dest low byte

	call setup_char_blitter

	ld a,(char_colour)
	ld l,a
	rrca
	rrca
	rrca
	rrca
	ld c,a
	ld b,4
plchbplp	ld a,$0e			;IE: $e0/16
	srl c
	rla
	srl l
	rla
	rlca
	rlca
	ld (blit_src_loc+1),a	; set source location - high byte 

	ld a,h	
	ld (blit_dst_loc+1),a	; set blit destination - high byte
	add a,$20
	ld h,a
	
	call waitblit		; make sure blitter is not busy before starting
	
	xor a			 
	ld (blit_width),a		; set width and start blit
	djnz plchbplp		

	pop bc
	pop de
	pop hl

	call waitblit		; make sure blitter has ended on exit

	ret

	
setup_char_blitter

	ld a,128-1
	ld (blit_src_mod),a		; set blit modulos
	ld a,OS_window_cols-1
	ld (blit_dst_mod),a
	ld a,%01110000		
	ld (blit_misc),a		; Ascending blit, src and dst in VRAM bank 1
	ld bc,0
	ld (blit_src_msb),bc	; Not using VRAM > 128KB
	ld a,7
	ld (blit_height),a		; Set height of blit
	ret
	
	
	
waitblit	in a,(sys_vreg_read)	
	bit 4,a 			 
	jr nz,waitblit		 
	ret
				
;-----------------------------------------------------------------------------------------	


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
	or a
	jr z,delete_cursor
	ld hl,$43f			; normal underscore cursor
	ld a,(insert_mode)
	or a
	jr z,draw_cursor
	ld hl,$c00			; full block cursor
	jr draw_cursor


delete_cursor

	ld hl,$0				; zero cursor (erase)


draw_cursor
		
	ld a,h
	or $e0
	ld h,a
	ld (blit_src_loc),hl		; hl = cursor image	in font area

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
	ret
	

	
;----------------------------------------------------------------------------------

os_clear_screen

	ld hl,OS_charmap				; fill character map with spaces
	ld a,32				
	ld bc,OS_window_cols*OS_window_rows
	call os_bchl_memfill

	call os_wait_raster

	ld de,0					; home the cursor to top left
	ld (cursor_y),de			
	ld b,4					; clear the 4 text-plotting bitplanes
cltbplp	push bc
	ld bc,0+((OS_window_rows*8)-1)+((OS_window_cols-1)*256)	
	call blit_wipe
	ld a,d
	add a,$20
	ld d,a
	pop bc
	djnz cltbplp
	
	ld d,$c0					; clear the attributes also
	ld bc,0+(OS_window_rows-1)+((OS_window_cols-1)*256)
	call blit_wipe
	ret


	
scroll_up	ld bc,OS_window_cols*(OS_window_rows-1)		; scroll charmap up one line
	ld de,OS_charmap
	ld hl,OS_charmap+OS_window_cols
	ldir
	ld b,OS_window_cols				; fill bottom line with spaces			
	ld a,32
subllp	ld (de),a
	inc de
	djnz subllp
	
	ld hl,$c000+OS_window_cols			; scroll attributes up a line also
	ld de,$c000
	ld bc,0+(OS_window_rows-2)+((OS_window_cols-1)*256)
	call blit_copy
	ld de,$c000+((OS_window_rows-1)*OS_window_cols)
	call blit_wipe				; zero last line of attributes also
			
	call os_wait_raster
	
	ld hl,OS_window_cols*8			; start source 8 lines down
	ld de,0					; start dest at top
	ld b,4					; number of bitplanes to do
scrlbplp	push bc
	ld bc,0+(((OS_window_rows-1)*8)-1)+((OS_window_cols-1)*256)	
	call blit_copy
	
	push hl					; clear the bottom line (doing so directly prevents current
	push de					; pen colour filling entire line)
	ld de,8*(OS_window_cols*(OS_window_rows-2))
	add hl,de
	ex de,hl
	ld bc,7+((OS_window_cols-1)*256)		; height c = 7, width b = OS_window_cols
	call blit_wipe
	pop de
	pop hl
	
	ld a,h
	add a,$20					; adjust for next bitplane
	ld h,a
	ld a,d
	add a,$20			
	ld d,a

	pop bc
	djnz scrlbplp
	ret
	
	
	
blit_wipe	ld hl,$a000			; for wipes use the cursor bitplane as source as its all zeroes
blit_copy	ld (blit_src_loc),hl		
	ld (blit_dst_loc),de
	push hl
	ld hl,0
	ld (blit_src_mod),hl		; set blit modulos
	ld (blit_src_msb),hl		; Not using VRAM > 128KB
	pop hl
	ld a,%01110000			 
	ld (blit_misc),a			; Ascending blit, src and dst in VRAM bank 1
	ld (blit_height),bc			; set size and go!
	
	call waitblit
	ret	

	
	
	
redraw_ui_line

	ld b,0				; set de = offset in char/attrib map appropriate for line
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



		
refresh_screen

	ld de,0				;(re) create bitmap screen from charmap/attributes
	ld c,e				
rs_yloop	call redraw_ui_line
	inc c
	ld a,c
	cp OS_window_rows
	jr nz,rs_yloop
	ret






set_bitplane

	and %00000111		;set bitplane number in A
	or %00001000		;use upper 64KB or VRAM
	ld (vreg_vidpage),a
	ret



os_page_in_video

	in a,(sys_mem_select)
	or %01000000
	out (sys_mem_select),a
	ret
	


os_page_out_video

	in a,(sys_mem_select)
	and %10111111
	out (sys_mem_select),a
	ret
	
	


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

	


os_bchl_memfill

; fill memory from HL with A. Count in BC.

memfillp	ld (hl),a
	cpi			; HL=HL+1,BC=BC-1, PO = if BC-1=0
	jp pe,memfillp
	ret
	


os_background_colours

	ld (palette),de
	ld (palette+(16*2)),bc
	ret



os_set_ui_colours

	call os_wait_vrt		; make changes off screen
	
	ld a,$ff
	ld hl,palette
	ld bc,128
	call os_bchl_memfill
	
	ld hl,(ui_border)		
	ld (palette),hl
	ld hl,(ui_paper)
	ld (palette+(16*2)),hl
	ld hl,(ui_cursor)
	ld (palette+(48*2)),hl

	ld hl,pen_colours
	ld de,palette+(17*2)	
	ld bc,30
	ldir
	ret
	


os_set_pen

	ld (current_pen),a
	ret




os_get_pen

	ld a,(current_pen)
	ret	




mult_cursor_y_window_cols

	xor a
	ld (mult_index),a
	ld hl,(cursor_y)			; returns cursor y * os_window_cols in HL
	ld h,l
	ld l,0
	ld (mult_write),hl			
	ld hl,(mult_read)
	ret
	


;---------------------------------------------------------------------------------------
	
	
attributes_left

	ld a,$e				; move attributes along left - called by the
	ld (vreg_vidpage),a			; backspace routine (ensure below $2000 as it pages
	call os_page_in_video		; out system RAM)
	ld de,video_base
	add hl,de
	ld d,h
	ld e,l
	dec de
	ldir
	xor a
	ld (de),a
	call os_page_out_video
	ret

	
attributes_right

	ld a,$e				; push attributes along right - called by the
	ld (vreg_vidpage),a			; "enter ascii text" part of the editor. (ensure
	call os_page_in_video		; this routine is below $2000 as it pages out system RAM)
	call mult_cursor_y_window_cols
	ld de,video_base+OS_window_cols-2
	add hl,de
	ld d,h
	ld e,l
	inc de		
	lddr
	call os_page_out_video
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
	dec bc		; length less one (for token byte)
	inc hl
unp_gtok	ld a,(ix)		; get token byte
unp_next	cp (hl)		; is byte at source location same as token?
	jr z,unp_brun	; if it is, there's a byte run to expand
	ldi		; if not, simply copy this byte to destination
	jp pe,unp_next	; last byte of source?
	ret
	
unp_brun	push bc		; stash B register
	inc hl		
	ld a,(hl)		; get byte value
	inc hl		
	ld b,(hl)		; get run length
	inc hl
	
unp_rllp	ld (de),a		; write byte value, byte run length
	inc de		
	djnz unp_rllp
	
	pop bc	
	dec bc		; last byte of source?
	dec bc
	dec bc
	ld a,b
	or c
	jr nz,unp_gtok
	ret	
	
;------------------------------------------------------------------------------------------

include	"keyboard_routines.asm"	;keyboard routines

;------------------------------------------------------------------------------------------

			
;====================================================================================
; END OF ROUTINES THAT NEED TO BE BELOW $2000 TO AVOID POTENTIAL VIDEO PAGING ISSUES
;====================================================================================


; *******************
; *   START UP OS   *
; *******************

os_first_run
	
	or a			; if A = 0, the boot drive is in B
	jr nz,os_cold_start		
	ld a,b
	ld (boot_drive),a		; 0=SERIAL, (1=IDE M, 2=IDE S), 3=MMC/SD card,4=EEPROM

os_cold_start

	di			; Disable irqs
	im 1			; CPU IRQ: mode 1
	ld sp,stack		; Set Stack pointer
	
	ld hl,OS_variables		; Clear all OS system variables
	ld bc,last_os_var-OS_variables
	xor a
	call os_bchl_memfill
	
;-----------------------------------------------------------------------------------------------
		
	call initialize_os

	ei
	ld bc,$0701
	ld (cursor_y),bc
	ld hl,welcome_message	; set up initial os display	
	call os_print_string
	ld bc,$0603
	ld (cursor_y),bc
	call os_cmd_vers		; show FLOS / OSCA versions
	call os_cmd_remount		; set up drives
	call os_new_line		; skip 1 line

	ld hl,boot_script_fn
	ld (os_args_start_lo),hl
	call os_cmd_exec		; any start-up commands?
	jp post_csb		; post command set bank (in case B was in bootscript) 
	
;============================================================================================

os_main_loop

	call os_wait_vrt		;flash cursor whilst waiting for key press
	
	call cursor_flash
	call os_get_key_press
	or a
	jr z,os_main_loop
	
	ld (current_scancode),a
	ld a,b
	ld (current_asciicode),a	;store ascii version
	
	call delete_cursor
	ld a,24			;ensures cursor is mainly visible 
	ld (cursorflashtimer),a	;during held key operations etc
	xor a
	ld (cursorstatus),a

	ld a,(current_scancode)	;insert mode on/off?
	cp $70
	jr nz,os_notins
	ld a,(insert_mode)
	xor 1
	ld (insert_mode),a
	jr os_main_loop

os_notins	ld hl,cursor_x		; arrow key moving cursor left?
	cp $6b			
	jr nz,os_ntlft
	dec (hl)
	ld a,(hl)
	cp $ff
	jr nz,os_main_loop
	ld (hl),OS_window_cols-1	; wrapped around
	jr os_main_loop

os_ntlft	cp $74			; arrow key moving cursor right?
	jr nz,os_ntrig
	inc (hl)
	ld a,(hl)
	cp OS_window_cols
	jr nz,os_main_loop
	ld (hl),0			; wrapped around
	jr os_main_loop

os_ntrig	ld hl,cursor_y
	cp $75			; arrow key moving cursor up?
	jr nz,os_ntup
	dec (hl)
	bit 7,(hl)
	jr z,os_main_loop
	ld (hl),0			; top limit reached
	jr os_main_loop

os_ntup	cp $72
	jr nz,os_ntdwn		; arrow key moving cursor down?
	inc (hl)
	ld a,(hl)
	cp OS_window_rows
	jr nz,os_main_loop
	ld (hl),OS_window_rows-1	; bottom limit reached, scroll the screen
	call scroll_up
	jr os_main_loop

os_ntdwn	cp $71			; delete pressed?
	jr nz,os_nodel		
	ld a,(cursor_x)		; shift chars of this line back onto cursor pos
	ld b,a
	inc b
	jr os_chrbk

os_nodel	cp $66			; backspace pressed?
	jr nz,os_nbksp
	ld a,(cursor_x)		; shift chars of this line back from cursor pos
	or a			; (unless at column 0)
	jp z,os_main_loop
	ld b,a
	dec a
	ld (cursor_x),a		; shift cursor back a char
os_chrbk	call mult_cursor_y_window_cols
	ex de,hl
	ld l,b
	ld h,0
	add hl,de
	push hl
	ld de,OS_charmap
	add hl,de			; hl = first source char
	ld d,h
	ld e,l
	dec de			; de = dest
	ld a,OS_window_cols
	sub b
	ld c,a
	ld b,0			; bc = number of chars to do
	push bc
	ldir
	ld a,32
	ld (de),a			; put a space at right side
	pop bc
	pop hl
	call attributes_left	; ensures this routine is below $2000
	call os_redraw_line
	jp os_main_loop

os_nbksp	cp $5a			; pressed enter?
	jp z,os_enter_pressed
	
	ld a,(current_asciicode)	; not a direction, bkspace, del or enter. 
	or a			; if scancode is not an ascii char
	jr z,os_nvdun		; zero is returned, skip plotting char.

	cp $7b			; upper <-> lower case are flipped in OS 
	jr nc,os_gtcha		; to make unshifted = upper case
	cp $61
	jr c,os_ntupc
	sub $20
	jr os_gtcha
os_ntupc	cp $5b
	jr nc,os_gtcha
	cp $41
	jr c,os_gtcha
	add a,$20
os_gtcha	ld d,a			; need to print character on screen 
	ld a,(insert_mode)		; check for insert mode
	or a
	jr nz,os_schi
	ld a,(cursor_x)		; shift chars of this line right from cursor pos
	cp OS_window_cols-1		; (unless at rightmost column or insert mode active)
	jr z,os_schi
	ld b,a
	push de
	call mult_cursor_y_window_cols	
	ld de,OS_charmap+OS_window_cols-2
	add hl,de			; hl = first source char
	ld d,h
	ld e,l
	inc de			; de = dest
	ld a,OS_window_cols-1
	sub b
	ld c,a
	ld b,0			; bc = number of chars to do
	lddr
	ld c,a
	ld b,0	
	call attributes_right	; ensure this routine is below $2000 as it 
	call os_redraw_line		; pages in Video RAM
	pop de
	
os_schi	ld a,(cursor_x)
	ld b,a
	ld a,(cursor_y)
	ld c,a
	ld a,d
	call os_plotchar		
	ld hl,cursor_x		; move cursor right after char displayed
	inc (hl)
	ld a,(hl)
	cp OS_window_cols		; wrapped around?
	jr nz,os_nvdun
	ld (hl),0

os_nvdun	jp os_main_loop
	


os_redraw_line

	call mult_cursor_y_window_cols	;returns y * OS columns in HL
	ex de,hl
	ld a,(cursor_y)
	ld c,a
	call redraw_ui_line
	ret
	

;---------------------------------------------------------------------------------------------

os_enter_pressed
		
	call mult_cursor_y_window_cols
	ld de,OS_charmap
	add hl,de
	ld de,commandstring				
	ld bc,OS_window_cols	
	ldir
	xor a
	ld (de),a

	ld (cursor_x),a		; home the cursor at the left
	ld hl,cursor_y		; move cursor down a line
	inc (hl)
	ld a,(hl)
	cp OS_window_rows
	jr nz,os_esdok
	ld (hl),OS_window_rows-1
	call scroll_up

os_esdok	call os_getbank		; save the bank the OS was in before any commands launched
	ld (bank_pre_cmd),a		

	call os_parse_cmd_chk_ps

post_csb	ld a,(bank_pre_cmd)		; restore original bank when finally returning to OS
	call os_forcebank
	xor a
	ld (in_script_flag),a
	jp os_main_loop
	


os_parse_cmd_chk_ps

	call os_parse_command_line
	cp $fe			; new command issued by exiting program?
	ret nz
	ld bc,OS_window_cols	; max string length = width of window in chars
	ld de,commandstring		; copy string at HL to command string and reparse it
	ldir
	jr os_parse_cmd_chk_ps

	
;---------------------------------------------------------------------------------------------
	
os_parse_command_line

	ld a,1
	ld (store_registers),a	; by default (external) commands store registers on return

	ld hl,commandstring		; attempt to interpret command
	ld b,OS_window_cols		; max string length = width of window in chars
	push hl
	call uppercasify_string	; make sure command string is all upper case
	pop hl
	call os_scan_for_non_space	; scan from hl until finds a non-space or zero
	or a			; if its a zero, give up parsing line
	ret z
	ld de,dictionary-1		; scan dictionary for command names
	push de
compcstr	pop de
	push hl
	pop iy
notacmd	inc de
	ld a,(de)
	cp 1			; last dictionary entry?
	jp z,os_no_kernal_command_found
	bit 7,a
	jr z,notacmd		; command names have marker bytes > $7f
	sla a
	ld c,a
	ld b,0			; command's start location word index 
	push de
cmdnscan	inc de
	ld a,(de)
	cp (iy)
	inc iy
	jr z,cmdnscan		; this char matches - test the next
nomatch	ld a,(de)			; this char doesnt match (but previous chars did)
	or a
	jr z,posmatch		; is it the end of a command dictionary entry (0 or $80+)?
	bit 7,a
	jr z,compcstr		; look for next command in dictionary
posmatch	ld a,(iy-1)		; if command string char is a space, the command matches
	cp 32
	jr nz,compcstr		; look for next command in dictionary
	
	pop de				
	push iy			; INTERNAL OS command found! Move arg location to HL	
	pop hl
	call os_scan_for_non_space
	ld (os_args_start_lo),hl	; hl = 1st non-space char after command 
	
	ld hl,os_cmd_locs
	add hl,bc
	ld c,(hl)			; get low byte of INTERNAL command routine address
	inc hl
	ld b,(hl)			; get high byte of INTERNAL command routine address
	push bc 
	pop ix			; ix = addr of command subroutine code

	ld hl,(os_args_start_lo)	; hl = 1st char after command + a space 
	call os_exec_command	; call internal command

	ret z			; <- FIRST INSTRUCTION FOLLOWING RETURN FROM INTERNAL COMMAND
	or a
	jr nz,show_erm
os_hwe1	ld a,b			; If ZF is set, but A = 0, show hardware error code from B
os_hwerr	ld hl,hex_byte_txt		
	call hexbyte_to_ascii	
	ld hl,hw_err_msg
	call os_show_packed_text
	xor a
	ret

show_erm	ld b,a			; the program reported an error - show the error message
	ld c,0
	ld hl,packed_msg_list
findmsg	ld a,(hl)
	cp $ff
	ret z			; quit if cant find message
	inc hl
	or a
	jr nz,findmsg		; is this an index marker?
	inc c
	ld a,b			; compare index count - is this the right message?
	cp c
	jr nz,findmsg
	call os_show_packed_text
	call os_new_line
	xor a
	ret
	

os_no_kernal_command_found

	ld a,$30			; was "VOLx:" entered? This is a special case to avoid	
fvolcmd	ld (vol_txt+4),a		; having a seperate command name for each volume.
	push af			
	ld de,vol_txt+1		
	ld b,5			
	call os_compare_strings	
	jr c,gotvolcmd		
	pop af			
	inc a			
	cp $30+max_volumes		
	jr nz,fvolcmd		
	jr novolcmd		
gotvolcmd	pop af
	sub $30
	call os_change_volume
	jp extcmderf		; treat error codes as if external command as routine use ZF error system	
		


novolcmd	ld a,(hl)			; special case for "G" command, this is internal but the code it
	cp "G"			; will be executing will be external, so it should treated as
	jr nz,not_g_cmd		; an external command
	inc hl
	ld a,(hl)
	dec hl
	cp " "
	jr nz,not_g_cmd
	inc hl
	call os_scan_for_non_space
	ld (os_args_start_lo),hl	; hl = 1st non-space char after command 
	or a
	jr nz,gotgargs
	ld a,$1f			; quit with error message
	jr show_erm
gotgargs	call ascii_to_hex_no_scan	; returns DE = goto address
	or a
	jr nz,show_erm
	ld hl,os_nmi_freeze		; allow NMI freezer
	ld (nmi_vector),hl	 
	push de
	pop ix			
	call os_exec_command		
	jp extcmd_r



not_g_cmd	ld (os_args_start_lo),hl	; attempt to load external OS command
	ld (os_args_pos_cache),hl
	call os_args_to_fn_append_exe
	
	call cache_dir_block	; cache dir pos in case we have to look in "root/os_commands"

	call fs_check_disk_format	; System looks on the ACTIVE SELECTED drive only
	jr c,os_ndfxc
	or a			; make sure disk is available
	jr nz,os_ndfxc
	
	call fs_open_file_command	; get header info, test file exists in current dir
	jp c,os_hwerr 		; drive error?
	or a
	jr z,os_gecmd		; 0 = got external command

	call fs_goto_root_dir_command	; cant find it, so move to root dir
	ld hl,os_dos_cmds_txt
	call fs_hl_to_filename
	call fs_change_dir_command	; try to move to dir "commands"
	jp c,os_hwerr
	or a
	jr nz,os_ndfxc		; "unknown command" if that dir isnt there
	
	ld hl,(os_args_pos_cache)	; put original command filename back	
	ld (os_args_start_lo),hl
	call os_args_to_fn_append_exe	
	call fs_open_file_command	; try to find the command in the new dir
	jp c,os_hwerr
	or a
	jr z,os_gecmd
os_ndfxc	call restore_dir_block	; jump back to original dir
	ld a,$0b			; return "unknown command" error
	jp show_erm

os_gecmd	ld hl,(os_args_start_lo)	; Found external command!
	call os_scan_for_non_space	; args start to be 1st non-space character
	ld (os_args_start_lo),hl

	ld ix,0
	ld iy,11
	call os_set_load_length	; load the first 11 bytes into a buffer
	ld hl,scratch_pad
	ld (fs_z80_address),hl
	call fs_read_data_command
	jp c,os_hwerr		; hardware error?
	or a
	jp nz,show_erm		; file sys error?
	ld hl,(scratch_pad)
	ld de,$00ed		; does it have a special FLOS location header?
	xor a
	sbc hl,de
	jr z,loc_header
	call fs_open_file_command	; not a special FLOS header so load as normal
	jp c,os_hwerr		; (open file again to update values)
	or a			
	jr nz,os_ndfxc
	ld hl,(fs_z80_address)	; set HL (load/start address to $5000)
	jr readcode
	
loc_header
	
	call fs_open_file_command	; file has special FLOS header, open file again	
	jp c,os_hwerr
	or a
	jr nz,os_ndfxc
	ld hl,(scratch_pad+4)	; replace normal load address from header
	ld (fs_z80_address),hl
	ld a,h
	cp $50
	jp nc,osok
	call restore_dir_block	; if prog tries to load below $5000, exit with warning
	ld a,$26
	jp show_erm

	
osok	ld a,(scratch_pad+6)	; replace normal load bank from header
	ld (fs_z80_bank),a	
	inc hl
	inc hl			; code execution address (just in case "$de,$00" should cause a problem..)

	ld a,(scratch_pad+7)	; is there a load length specified?
	or a
	jr z,readcode		; if byte at 7 = 0, no load whole file
	ld iy,(scratch_pad+8)	; get load length 15:0
	ld a,(scratch_pad+10)	; get load lenth 23:8
	ld b,0
	ld c,a
	push bc
	pop ix
	call os_set_load_length	; set the load length
	
	
readcode	ld (os_extcmd_jmp_addr),hl	; store code execution address
	call fs_read_data_command
	push af
	call restore_dir_block	; put original dir pos back
	pop af
	jp c,os_hwerr		; drive error?
	or a
	jp nz,show_erm		; file system error?
	
	ld a,(fs_z80_bank)		; set the bank that the program requires
	call os_forcebank
	ld hl,os_nmi_freeze		; allow NMI freezer
	ld (nmi_vector),hl	 
	ld hl,os_extcmd_jmp_addr	; address of external command held at this address
	ld c,(hl)			; get low byte of command routine address
	inc hl
	ld b,(hl)			; get high byte of command routine address
	push bc 
	pop ix			; ix = addr of command subroutine code
	ld hl,(os_args_start_lo)	; hl = 1st char after command + a space 
	
	call os_exec_command	; a call allows commands to return with "ret"

extcmd_r	push af			; <-FIRST INSTRUCTION ON RETURN FROM EXTERNAL COMMAND	
	xor a
	out (sys_alt_write_page),a	; restore critical system settings for FLOS
	ld a,(store_registers)
	or a
	jr z,skp_strg
	push hl
	ld hl,(com_start_addr)
	ld (storepc),hl
	pop hl
	pop af
	call os_store_CPU_regs	; store registers and flags on return
	push af
skp_strg	pop af

cntuasr	call setup_mult_table	; (AF is preserved by this routine)

	ld de,os_no_nmi_freeze	
	ld (nmi_vector),de	 	; prevent NMIs taking any action

extcmderf	jr z,not_errc		; if ZERO FLAG is set, the program completed OK
	or a
	jp z,os_hwe1		; if A = 0 and zero flag is not set, there was a hardware error
	cp $ff			; Not a hardware error, is report code: FF - restart?
	jp z,os_cold_start
	cp $fe			; if command wants to spawn a new command, return now
	ret z
	jp show_erm		; else show the relevent error code message 	
not_errc	cp $ff			; no error but check for a = $ff on return anyway (OS needs to restart..)
	jp z,os_cold_start
	ret


os_exec_command
	
	ld (com_start_addr),ix	;temp store start address of executable
	jp (ix)			;jump to command code
	
		


cache_dir_block

	
	push de
	call fs_get_dir_block	
	ld (os_dir_block_cache),de
	pop de
	ret
		

restore_dir_block

	push de
	ld de,(os_dir_block_cache)
	call fs_update_dir_block
	pop de
	ret
		


;==================================================================================================
; Routines called by command line
;==================================================================================================


os_next_arg

	call os_scan_for_space
	or a
	ret z
	call os_scan_for_non_space
	or a
	ret


;------------------------------------------------------------------------------------------
	

os_scan_for_space

os_sfspl 	ld a,(hl)			;hl = source text, hl = space char on exit	
	or a			;or location of zero if encountered first
	ret z
	cp " "
	ret z
	inc hl
	jr os_sfspl
	

;-----------------------------------------------------------------------------------------
	

os_scan_for_non_space

	dec hl			;hl = source text, hl = 1st non-space char on exit			
os_nsplp	inc hl			
	ld a,(hl)			
	or a			
	ret z			;if zero flag set on return end of line was encountered
	cp " "
	jr z,os_nsplp
	ret
	
	
;----------------------------------------------------------------------------------------

os_args_to_alt_filename

	call os_atfn_pre		;find non-space char	
	ret z
	call fs_hl_to_alt_filename
	jr os_atfrl
	
	
	
		
os_args_to_filename

	call os_atfn_pre		;find non-space char	
	ret z
	call fs_hl_to_filename	

os_atfrl	ld a,(hl)			;look for a space or "/" after the filename ascii
	or a			;(stop looking if reach $00)
	jr z,os_cfne
	cp 32
	jr z,os_cfne
	cp $2f
	jr z,os_cfne
	inc hl
	jr os_atfrl	
os_cfne	ld (os_args_start_lo),hl	;update arg position for next parameter
	ld a,c			
	or a			;a=number of chars in filename (ZF set if none)
	ret




os_args_to_fn_append_exe

	
	call os_atfn_pre		; find non-space char	
	ret z
	ld de,temp_string
ccmdtlp	ld a,(hl)			; copy argument (command name) to temp string
	or a
	jr z,goteocmd
	cp " "
	jr z,goteocmd
	cp "."
	jr z,goteocmd
	ld (de),a
	inc de
	inc hl
	jr ccmdtlp
	
goteocmd	push hl
	ld hl,exe_extension_txt
	ld bc,5
	ldir 
	ld hl,temp_string
	call fs_hl_to_filename
	pop hl
	jr os_atfrl
	



os_atfn_pre

	ld hl,(os_args_start_lo)	;find non-space char
	call os_scan_for_non_space
	or a
	ret z
	ld a,(hl)
	cp $2f			;if forward slash, skip it
	jr nz,notfsl1
	inc hl
notfsl1	xor a
	inc a
	ret


;--------- Number <-> String functions -----------------------------------------------------


os_clear_output_line

	push bc
	push hl			;clear output line
	ld hl,output_line
	ld bc,OS_window_cols
	ld a,32
	call os_bchl_memfill
	pop hl
	pop bc
	ret
	
	
	
os_skip_leading_ascii_zeros

slazlp	ld a,(hl)			;advances HL past leading zeros in ascii string
	cp "0"			;set b to max numner of chars to skip
	ret nz
	inc hl
	djnz slazlp
	ret
	


os_leading_ascii_zeros_to_spaces

	push hl
clazlp	ld a,(hl)			;leading zeros in ascii string (HL) are replaced by spaces
	cp "0"			;set b to max numbner of chars
	jr nz,claze
	ld (hl)," "
	inc hl
	djnz clazlp
claze	pop hl
	ret
	


		
n_hexbytes_to_ascii

	ld a,(de)			; set b to number of digits.
	call hexbyte_to_ascii	; set de to most significant byte address
	dec de
	djnz n_hexbytes_to_ascii
	ret
	

			
hexbyte_to_ascii

	push bc
	ld b,a			;puts ASCII version of hex byte value in A at HL (two chars)
	srl a			;then hl = hl + 2
	srl a
	srl a
	srl a
	call hxdigconv
	ld (hl),a
	inc hl
	ld a,b
	and $f
	call hxdigconv
	ld (hl),a
	inc hl
	pop bc
	ret
hxdigconv	add a,$30
	cp $3a
	jr c,hxdone
	add a,7
hxdone	ret




hexword_to_ascii	

	ld a,d			;ascii version of DE is stored at hl to hl+3
	call hexbyte_to_ascii
	ld a,e
	call hexbyte_to_ascii
	ret
	


ascii_to_hexword
	
	call os_scan_for_non_space	; set text address in hl, de = hex word on return
	or a
	jr nz,ascii_to_hex_no_scan
	ld a,$1f			; if a=0, set "no hex" return code $1f
	ret	
	
ascii_to_hex_no_scan
	
	ld de,0
	push bc
	ld b,4
athlp	call ascii_to_hex_digit
	cp $f0			; is char a space?
	jr z,athend
	cp $d0
	jr z,athend		; or 0 terminator?
	cp 16
	jr nc,badhex		; is it not a hex char?
	ex de,hl
	add hl,hl			; shift bits across to make room for new digit 
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	or e
	ld e,a
	inc hl
	djnz athlp
athend	pop bc
	xor a			; a=0 on return, all ok
	ret
		
badhex	xor a
	ld a,$0c
	pop bc
	ret
	
	
		
ascii_to_hex_digit

	ld a,(hl)			;source char at hl
	sub $3a			;a = returned nybble
	jr c,zeronine
	add a,$f9
zeronine:	add a,$a
	ret


		
;--------- Text Input / Non-numeric string functions ------------------------------------

os_user_input

;waits for user to enter a string of characters followed by Enter
;returns HL = string location (zero termimated)
;        A  = number of characters in entered string (zero if aborted by ESC)

	ld hl,ui_string		;clear old string and index
	ld bc,OS_window_cols
	xor a
	ld (ui_index),a
	call os_bchl_memfill
	
ui_loop	ld hl,$43f		;draw underscore cursor
	call draw_cursor
	call os_wait_key_press	;wait for a new scan code in buffer
	ld (current_scancode),a
	ld a,b
	ld (current_asciicode),a	;store ascii version	
	call delete_cursor
	
	ld a,(current_scancode)
	cp $66			;pressed back space?
	jr nz,os_nuibs
	ld a,(ui_index)
	or a
	jr z,ui_loop		;cant delete if at start
	ld hl,cursor_x		;shift cursor left and put a 	
	dec (hl)			;space at new position
os_uixok	ld b,(hl)		
	ld a,(cursor_y)
	ld c,a
	ld a,32
	call os_plotchar
	
	ld hl,ui_index
	dec (hl)			;dec char count
	ld a,(hl)
	ld hl,ui_string
	add a,l
	jr nc,ui_ncry2
	inc h
ui_ncry2	ld l,a
	ld (hl),0
	jr ui_loop

os_nuibs	cp $76
	jr z,ui_aborted
	cp $5a			; pressed enter?
	jr z,ui_enter_pressed
	
	ld a,(cursor_x)		; no action if at right of screen
	cp OS_window_cols-1
	jr z,ui_loop	

	ld a,(current_asciicode)	; not a bkspace or enter... 
	or a			; if scancode is not an ascii char
	jr z,ui_loop		; skip plotting char.

	cp $7b			; upper <-> lower case are flipped in OS 
	jr nc,ui_gtcha		; to make unshifted = upper case
	cp $61
	jr c,ui_ntupc
	sub $20
	jr ui_gtcha
ui_ntupc	cp $5b
	jr nc,ui_gtcha
	cp $41
	jr c,ui_gtcha
	add a,$20

ui_gtcha	ld d,a
	ld hl,ui_string
	ld a,(ui_index)
	add a,l
	jr nc,ui_ncry
	inc h
ui_ncry	ld l,a
	ld (hl),d			; enter char in user input string
	ld hl,ui_index
	inc (hl)			; next string position
				
	ld bc,(cursor_y)		; and print character on screen...
	ld a,d
	call os_plotchar		
	ld hl,cursor_x		; ..and move cursor right
	inc (hl)
	jp ui_loop

ui_enter_pressed

	ld hl,ui_string
	ld a,(ui_index)
	ret

ui_aborted

	xor a			; on exit a = 0 if escape pressed / aborted
	ret
		
;--------------------------------------------------------------------------------
	
os_count_lines

	push hl			;counts output lines and says "More?"
	ld b,"y"			;default "no wait" key return
	ld hl,os_linecount		;every 20, waiting for a keypress to continue
	inc (hl)			;b (ascii code) = "y" by default
	ld a,(hl)
	cp 20
	jr nz,os_nntpo
	ld (hl),0
	ld hl,os_more_txt
	call os_print_string
	call os_wait_key_press	
os_nntpo	pop hl
	ret

	
;---------------------------------------------------------------------------------

os_compare_strings

; both strings should be zero terminated.
; compare will fail if string lengths are different
; unless count (b) is reached
; carry flag set on return if same

	push hl			;set de = source string
	push de			;set hl = compare string
ocslp	ld a,(de)			;b = max chars to compare
	or a
	jr z,ocsbt
	cp (hl)
	jr nz,ocs_diff
	inc de
	inc hl
	djnz ocslp
	jr ocs_same
ocsbt	ld a,(de)			;check both strings at termination point
	or (hl)
	jr nz,ocs_diff
ocs_same	pop de
	pop hl
	scf			; carry flag set if same		
	ret
ocs_diff	pop de
	pop hl
	xor a			; carry flag zero if different	
	ret


;-----------------------------------------------------------------------------------

os_copy_ascii_run

;INPUT HL = source ($00 or $20 terminates)
;      DE = dest
;       b = max chars

;OUTPUT HL/DE = end of runs
;           c = char count
	
	ld c,0
cpyar_lp	ld a,(hl)
	or a
	ret z
	cp 32
	ret z
	ld (de),a
	inc hl
	inc de
	inc c
	djnz cpyar_lp
	ret

;-----------------------------------------------------------------------------------

uppercasify_string

; Set HL to string location ($00 quits)
; Set B to max number of chars

	ld a,(hl)
	or a
	ret z
	call os_uppercasify
	ld (hl),a
	inc hl
	djnz uppercasify_string
	ret
	

os_uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

	cp $61			
	ret c
	cp $7b
	ret nc
	sub $20				
	ret
				
;----------------------------------------------------------------------------------

os_decimal_add

;INPUT HL = source LSB, DE = dest LSB, b = number of digits

	push bc
	ld c,0
decdlp	ld a,(de)
	add a,(hl)
	add a,c
	cp 10
	jr c,daddnc
	sub 10
	ld c,1
decnclp	ld (de),a
	inc hl
	inc de
	djnz decdlp
	pop bc
	ret
daddnc	ld c,0
	jr decnclp
	
;----------------------------------------------------------------------------------

os_hex_to_decimal

; INPUT HL:DE hex longword
; OUTPUT HL = decimal LSB address (10 digits) 

hex_to_convert	equ scratch_pad
decimal_digits	equ scratch_pad+4
decimal_add_digits	equ scratch_pad+14


	ld (hex_to_convert),de
	ld (hex_to_convert+2),hl
		
	ld hl,decimal_add_digits
	push hl
	ld de,decimal_digits
	xor a
	ld b,10
setupdec	ld (de),a
	ld (hl),a
	inc hl
	inc de
	djnz setupdec
	pop hl
	ld (hl),1
	
	ld hl,hex_to_convert
	ld b,4
decconvlp	push bc
	ld a,(hl)
	call decadder
	call decaddx16
	ld a,(hl)
	rrca
	rrca
	rrca
	rrca
	call decadder
	call decaddx16
	pop bc
	inc hl
	djnz decconvlp
	ld hl,decimal_digits
	ret



decadder	and 15
	ret z
	ld b,a
	push hl
daddlp	push bc
	ld de,decimal_digits
	ld hl,decimal_add_digits
	ld b,10
	call os_decimal_add
	pop bc
	djnz daddlp	
	pop hl
	ret

	
	
decaddx16	push hl
	ld b,4				;add the add value to itself 4 times 
x16loop	push bc
	ld de,decimal_add_digits
	ld hl,decimal_add_digits
	ld b,10
	call os_decimal_add
	pop bc
	djnz x16loop	
	pop hl
	ret
	
	
;----------------------------------------------------------------------------------

os_show_decimal

	ld de,output_line			;skips leading zeros
	ld bc,9
	add hl,bc
	ld b,10
shdeclp	ld a,(hl)
	or a
	jr z,dnodigit
	add a,$30
	ld (de),a
	inc de
dnodigit	dec hl
	djnz shdeclp
	xor a
	ld (de),a
	call os_print_output_line
	ret
	
;-----------------------------------------------------------------------------------

		
os_copy_to_output_line
	
	push de
	push bc
	ld de,output_line		;hl = zero terminated string
	ld bc,OS_window_cols+1	;note copies terminating zero
os_cloll	ldi
	ld a,(hl)
	or a
	jr z,os_clold
	ld a,b
	or c
	jr nz,os_cloll
os_clold	ld (de),a
	pop bc
	pop de
	ret


;----------------------------------------------------------------------------------

os_show_hex_byte

	push hl			; put byte to display in A
	ld hl,output_line
	call hexbyte_to_ascii
	jr shb_nt

os_show_hex_word

	push hl			; put word to display in DE
	ld hl,output_line
	call hexword_to_ascii
shb_nt	ld (hl),0
	pop hl
	
os_print_output_line

	push hl
	ld hl,output_line
cproline	call os_print_string
	pop hl
	ret



os_print_output_line_skip_zeroes

	push hl
	ld hl,output_line
	call os_skip_leading_ascii_zeros
	jr cproline
	
		
;----------------------------------------------------------------------------------

os_store_CPU_regs

	push af
	ld (a_store1),a		;store_register_values - PC is not stored at present
	ex af,af'
	ld (a_store2),a
	ex af,af'
	ld (bc_store1),bc		
	ld (de_store1),de
	ld (hl_store1),hl
	exx
	ld (bc_store2),bc
	ld (de_store2),de
	ld (hl_store2),hl
	exx
	ld (storeix),ix
	ld (storeiy),iy
	ld (storesp),sp

	push bc
	ld b,0
	jr nz,zfstzero		;test zero flag
	set 6,b

zfstzero	jr nc,cfstzero		;test carry flag
	set 0,b

cfstzero	jp p,sfstzero		;test sign flag 1=minus
	set 7,b

sfstzero	jp pe,pfstzero		;test parity flag 1=par odd
	set 2,b

pfstzero	ld a,i			
	jp pe,ifstzero		;test iff flag
	set 4,b

ifstzero	ld a,b
	ld (storef),a
	pop bc
	pop af
	ret



os_dont_store_registers

	xor a
	ld (store_registers),a
	ret
	
	
;-----------------------------------------------------------------------------------

os_new_line_cond

	call test_quiet_mode
	ret nz

	
os_new_line

	push hl
	ld hl,crlfx2_txt+1
	call os_print_string
	pop hl
	ret
	

;-----------------------------------------------------------------------------------

os_set_cursor_position

	push de			; if either coordinate is out of range
	ld e,0			; it will be set at zero and the routine
	ld a,b			; returns with zero flag not set
	cp OS_window_cols
	jr c,xposok
	inc e
	xor a
xposok	ld (cursor_x),a
	ld a,c
	cp OS_window_rows
	jr c,yposok
	inc e
	xor a
yposok	ld (cursor_y),a
	ld a,e
	pop de
	or a
	ret
		
	
	
os_get_cursor_position

	ld bc,(cursor_y)		; returns pos in bc (b = x, c = y)
	ret


os_get_charmap_xy

	push de
	push af	
	ld hl,OS_window_cols*64	; HL returns charmap address of coords B,C (x,y)
	ld (mult_table),hl		 
	xor a			; find char map offset
	ld (mult_index),a		
	ld d,c			; y coord
	ld e,a			
	ld (mult_write),de
	ld de,(mult_read)		; y line offset (chars)	
	ld l,b
	ld h,a
	add hl,de
	ex de,hl			; de = charmap offset
	
	ld hl,OS_charmap		; charmap
	add hl,de	
	pop af
	pop de
	ret	

;---------------------------------------------------------------------------------------------

os_show_packed_text_cond

	call test_quiet_mode
	ret nz

	
os_show_packed_text

; Construct sentence from internal dictionary using word indexes from HL
	
	push bc
	push de
	push ix
	ld ix,output_line
readpind	ld a,(hl)
	or a
	jr nz,getword		;if word index = 0, its the end of the line
	dec ix			;remove previously added space from end of line
	ld (ix),a			;null terminate output line

	push hl
	call os_print_output_line
	pop hl

	pop ix
	pop de
	pop bc
	ret
	
getword	ld de,dictionary-1
	ld c,0
dictloop	inc de
	ld a,(de)
	or a			;is this a marker byte (not a char)
	jr z,faword
	bit 7,a			;""                              ""
	jr z,dictloop	

faword	inc c			;reached desired word count?
	ld a,c
	cp (hl)
	jr nz,dictloop
copytol	inc de			;skip the marker char
	ld a,(de)
	or a
	jr z,eoword		;if find a marker char, its the end of the word
	bit 7,a
	jr nz,eoword
	ld (ix),a			;copy char to output line
	inc ix
	jr copytol
eoword	ld (ix),32		;enter a space		
	inc ix
	inc hl
	jr readpind


		
;===========================================================================
; LOW LEVEL ROUTINES
;===========================================================================

;-------- Memory bank switching /paging functions ---------------------------

os_forcebank

; sets which of the 32KB banks is mapped into address space $8000-$ffff
; set A to required bank (range: 0 - max_bank)

	push bc			
	inc a					
	and %00001111
set_op1	ld b,a
	in a,(sys_mem_select)
          and %11110000
          or  b
	pop bc
set_op2	out (sys_mem_select),a
	ret
	



os_getbank

; returns current bank number in A

	in a,(sys_mem_select)		
	and %00001111	
	ret z			;if %000, forcebank has not been called previously.
	dec a			;range is normally %001 to %111 so sub 1 to give 0-maxbank
	ret



os_cachebank

	in a,(sys_mem_select)	; stores the current bank number internally
	and %00001111
	ld (banksel_cache),a
	ret


	
os_restorebank
	
	push bc			; restores the bank saved with above function
	ld a,(banksel_cache)
	jr set_op1
	
	
	
os_incbank

	call os_getbank		; selects the next bank, if > max_bank, error 8 is returned in A
	inc a			; A=0 if successful
	call test_bank
	jr z,fs_iberr
	call os_forcebank
	xor a			; set zero flag
	ret
fs_iberr	ld a,8			; error 8 - address out of range
	or a			; clear carry flag / reset zero flag
	ret



test_bank	push hl
	ld hl,max_bank
	ld l,(hl)
	inc l
	cp l
	pop hl
	ret


;--------- Mouse functions ------------------------------------------------------------------------

os_enable_mouse

; Set: HL/DE = window size mouse pointer is to work within
	
	di
	ld (mouse_window_size_x),hl	 
	ld (mouse_window_size_y),de
	xor a
	ld (mouse_packet_index),a
	ld h,a
	ld l,a
	ld (mouse_pos_x),hl
	ld (mouse_pos_y),hl
	ld (mouse_disp_x),hl
	ld (mouse_disp_y),hl
	ld (old_mouse_disp_x),hl
	ld (old_mouse_disp_y),hl
	ld a,%10000011
	out (sys_irq_enable),a	; enable mouse (and keyboard) interrupts
	ld a,1
	ld (use_mouse),a		; set bit 0 - driver enabled
	ei
	ret
	

os_get_mouse_position

; Returns: ZF = Set: X coord in HL, y coord in DE, buttons in A
;          ZF = Not set: Mouse driver not initialized.

	ld a,(use_mouse)		; is mouse driver enabled?	
	and 1
	xor 1
	ret nz
	ld hl,(mouse_pos_x)		
	ld de,(mouse_pos_y)
mouse_end	xor a
	ld a,(mouse_buttons)
	ret


os_get_mouse_motion

	ld a,(use_mouse)		; is mouse driver enabled?	
	and 1
	xor 1
	ret nz
	di
	push bc
	ld hl,(mouse_disp_x)		
	push hl
	ld de,(old_mouse_disp_x)
	xor a
	sbc hl,de
	pop de
	ld (old_mouse_disp_x),de
	ex de,hl
	
	ld hl,(mouse_disp_y)		
	push hl
	ld bc,(old_mouse_disp_y)
	xor a
	sbc hl,bc
	pop bc
	ld (old_mouse_disp_y),bc
	ex de,hl
	pop bc
	ei
	jr mouse_end
	
	
;-------- Timer functions ----------------------------------------------------------------------------


wait_4ms	xor a

os_timer_wait

; set a = number of 16 microsecond periods to wait

	neg 			;timer counts up, so invert value
	out (sys_timer),a		
	ld a,%00000100
	out (sys_clear_irq_flags),a	;clear timer overflow flag
twait	in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
	bit 2,a			
	jr z,twait
	ret	


os_pause

; set b = number of 4 millisecond second periods to wait 


twait1	call wait_4ms
	djnz twait1			; loop 256 times
	ret

;----------------------------------------------------------------------------------------------------

os_get_version

;returns hardware version in de and OS version in hl
 	
 	
 	ld b,16			;bit number to read
	ld c,sys_hw_flags		;port to read from
verloop	dec b
	in a,(c)			;serial data is bit 7
	inc b
	sla a			;force into carry flag
	rl e			;word ends up in DE
	rl d
	djnz verloop		;next bit
 	ld hl,(os_version)
 	ret
 	

;====================================================================================================
;----- General Subroutines --------------------------------------------------------------------------
;====================================================================================================

; .--------------.
; ! CRC Checksum !
; '--------------'

; makes checksum in HL, src addr = DE, length = C bytes

crc_checksum

	ld hl,$ffff		
crcloop	ld a,(de)			
	xor h			
	ld h,a			
	ld b,8
crcbyte	add hl,hl
	jr nc,crcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
crcnext	djnz crcbyte
	inc de
	dec c
	jr nz,crcloop
	ret

;----------------------------------------------------------------------------------------------

setup_mult_table

	push af
	push hl
	ld hl,OS_window_cols*64
	ld (mult_table),hl
	xor a			
	ld (mult_index),a
	pop hl
	pop af
	ret

;----------------------------------------------------------------------------------------------

os_get_key_mod_flags

	ld a,(key_mod_flags)
	ret

;-----------------------------------------------------------------------------------------------

os_get_display_size

	ld b,OS_window_cols
	ld c,OS_window_rows
	ret

;-----------------------------------------------------------------------------------------------


os_readmemflat

	ld c,sys_mem_select		;put byte from memory location E:HL into A
	ld a,h
	rlca			;convert flat memory location to bank:addr
	rl e
	jr z,lopage1
	set 7,h
lopage1	in b,(c)			;get current bank
	out (c),e			;set bank reqd for read
	ld a,(hl)			;get byte at location in A
	out (c),b			;restore original bank
	ret	


os_writememflat

	ld c,sys_mem_select		;Write byte in A to memory location E:HL
	ld b,h			;convert flat memory location to bank:addr
	sla b
	rl e
	jr z,lopage2
	set 7,h
lopage2	in b,(c)			;get current bank
	out (c),e			;set bank reqd for write
	ld (hl),a			;get byte at location in A
	out (c),b			;restore original bank
	ret		


;-----------------------------------------------------------------------------------------------

	
;==============================================================================================
; Internal OS command routines
;==============================================================================================

include "commands\b.asm"
include "commands\c.asm"
include "commands\cd.asm"
include "commands\cls.asm"
include "commands\colon.asm"
include "commands\d.asm"
include "commands\del.asm"
include "commands\dir.asm"
include "commands\f.asm"
include "commands\format.asm"
include "commands\h.asm"
include "commands\help.asm"
include "commands\gtr.asm"
include "commands\lb.asm"
include "commands\m.asm"
include "commands\md.asm"
include "commands\r.asm"
include "commands\rd.asm"
include "commands\rn.asm"
include "commands\sb.asm"
include "commands\rx.asm"
include "commands\tx.asm"
include "commands\t.asm"
include "commands\mount.asm"
include "commands\vers.asm"
include "commands\colour.asm"
include "commands\exec.asm"
include "commands\ltn.asm"

os_cmd_unused	ret		; <- dummy command, should never be called

;--------------------------------------------------------------------------------------
; IO Routines
;--------------------------------------------------------------------------------------

include	"serial_io_code.asm"	;serial port routines

;---------------------------------------------------------------------------------------
; Commonly called error messages - gets message code
;---------------------------------------------------------------------------------------


os_no_fn_error	ld a,$0d
		or a
		ret

os_fn_too_long	ld a,$15
		or a
		ret
	
os_no_start_addr	ld a,$16
		or a
		ret

os_no_filesize	ld a,$17
		or a
		ret

os_abort_save	ld a,$18
		or a
		ret

os_invalid_bank	ld a,$1b
		or a
		ret
	
os_no_e_addr_error	ld a,$1c
		or a
		ret

os_no_d_addr_error	ld a,$1d
		or a
		ret
	
os_range_error	ld a,$1e
		or a
		ret

os_no_args_error	ld a,$1f
		or a
		ret	

;--------------------------------------------------------------------------------------

os_find_file	

; Before calling, set HL to address of zero terminated filename.
; Opens the file and returns info on file via CPU registers


	call fs_hl_to_filename
	call fs_open_file_command	; Returns A = 0, file found OK..
	jr c,os_fferr		; If carry = 1: h/w error.
	or a			; If A <> 0: File Error.
	ret nz		
	
	ld a,(fs_z80_bank)		; B = start bank of file
	ld b,a
	ld hl,(fs_z80_address)	; HL = address file originally saved from
	ld ix,(fs_file_length+2)	; IX:IY = length of file
	ld iy,(fs_file_length)
	xor a			; Zero flag set, all OK
	ret	

os_fferr	ld b,a			; hardware error: A = $00, B = error bits
	xor a			
	ld c,a
	inc c			; Zero flag cleared
	ret	

;--------------------------------------------------------------------------------------------------------

os_set_load_length

	ld (fs_file_length_temp),iy	; set load length to IX:IY
	ld (fs_file_length_temp+2),ix
	ret
	
;----------------------------------------------------------------------------------------------------------	

os_set_file_pointer

; Moves the "start of file" pointer allowing random access to file contents.
; Note: File pointer is reset by opening a file, and automatically incremented
;       by normal read function.

	ld (fs_file_pointer),iy	; set file pointer to IX:IY  
	ld (fs_file_pointer+2),ix
	push af
	xor a
	ld (fs_filepointer_valid),a	; invalidate filepointer
	pop af
	ret
	
;-----------------------------------------------------------------------------------------------------------

os_force_load
  
	ld (fs_z80_address),hl	;Set: HL = load address	
	ld a,b			;      B = bank to load to
	ld (fs_z80_bank),a		 

os_load_file

	call fs_read_data_command
	jr c,os_fferr
	or a
	ret

;-----------------------------------------------------------------------------------------------------------

os_create_file	

; Before calling, set..

; HL = address of zero terminated filename.
; IX = address that file should load to when no overrides are specified (irrelevent on FAT16)
;  B = bank part of reload address (irrelevent on FAT16)

; On return:

; If zero flag NOT set, there was an error.
; If   A = $00, b = hardware error code
; Else A = File system error code

	ld (fs_z80_address),ix
	ld a,b
	ld (fs_z80_bank),a
	call fs_hl_to_filename
	call fs_create_file_command	; this routine returns A = 0/carry clear if file created OK..
	jp c,os_fferr		; translate errors to standard FLOS format (Zero Flag,A,B)
	or a
	ret

;--------------------------------------------------------------------------------------------------------

os_write_bytes_to_file

; Before calling, set..

; IX   = address to save data from
; B    = bank to save data from
; C:DE = number of bytes to save
; HL   = address of null-terminated ascii name of file the databytes are to be appended to

; On return:

; If zero flag NOT set, there was an error.
; If   A = $00, b = hardware error code
; Else A = File system error code

; NOTE:
; Will return "file not found" if the file has not been created previously.

	ld a,b					
	ld (fs_z80_bank),a	
	call test_bank
	jp nc,os_invalid_bank
	xor a
	ld (fs_file_length+3),a
	ld a,c
	ld (fs_file_length+2),a
	ld (fs_file_length),de
	ld (fs_z80_address),ix	 	
	call fs_hl_to_filename

os_wbfgo	ld a,(fs_file_length+2)
	ld c,a
	ld a,(max_bank)	
	add a,2
	srl a
	dec a
	cp c
	jr c,os_ftbig		;attempting to save > memory size?

	call fs_write_bytes_to_file_command
	jp c,os_fferr
	or a
	ret

os_ftbig	ld a,$22			;error - file is too long
	or a
	ret	

;--------------------------------------------------------------------------------------------------------

os_save_file

; This routine both creates and saves data to a new file. It is provided for compatibility with
; the legacy kjt_save_file routine. New programs should instead use the kjt_create_file and
; kjt_write_bytes_to_file routines. It cannot be used to append data to an existing file and
; will return the error "File already exists" if this is attempted.

; Before calling, set..
; HL = address of zero terminated filename.
; IX = address of file data
;  B = bank that file data resides in
; C:DE = number of bytes to save
	
	ld a,b					
	ld (fs_z80_bank),a	
	call test_bank
	jp nc,os_invalid_bank
	xor a
	ld (fs_file_length+3),a
	ld a,c
	ld (fs_file_length+2),a
	ld (fs_file_length),de	
	call os_create_file
	ret nz
	jr os_wbfgo

		
;-----------------------------------------------------------------------------------------------------------

os_store_dir

	push de
	call fs_get_dir_block
	ld (dir_pos_cache),de
	pop de
	ret
	
	
	
	
os_restore_dir
	
	push de
	ld de,(dir_pos_cache)
	call fs_update_dir_block
	pop de
	ret
		
	
	

os_check_volume_format

	call fs_check_disk_format
os_rffsc	jp c,os_fferr
	or a
	ret




os_format
	push hl				;set HL to label and A to DEV number
	call dev_to_driver_lookup
	pop hl
	jr c,sdevok
	ld a,$22				 ;invalid DEVICE selection
	or a
	ret

sdevok	push af				
	ld de,fs_sought_filename
	call fs_clear_filename
	ld b,11
	call os_copy_ascii_run
	pop af
	
	ld hl,current_driver
	ld b,(hl)
	ld (hl),a
	push bc
	push hl
	call fs_format_device_command
	pop hl
	pop bc
	ld (hl),b
	jr os_rffsc




os_make_dir

	call fs_hl_to_filename
	call fs_make_dir_command
	jr os_rffsc
	




os_change_dir

	call fs_hl_to_filename
	call fs_change_dir_command
	jr os_rffsc
	
	
	
	
os_parent_dir

	call fs_parent_dir_command
	jr os_rffsc
	


	
os_root_dir

	call fs_goto_root_dir_command
	jr os_rffsc
	

os_erase_file	
	
	call fs_hl_to_filename
	call fs_erase_file_command
	jr os_rffsc
	



os_goto_first_dir_entry	

	call fs_goto_first_dir_entry
	jr os_rffsc




os_get_dir_entry		

	call fs_get_dir_entry	
	jr os_rffsc




os_goto_next_dir_entry	
	
	call fs_goto_next_dir_entry	
	jr os_rffsc
	


os_get_current_dir_name

	call fs_get_current_dir_name
	jr os_rffsc
	


os_rename_file

	push de
	call fs_hl_to_alt_filename		;set hl = file to rename, de = new filename
	pop hl				
	call fs_hl_to_filename	
	call fs_rename_command
	jr os_rffsc
	


os_delete_dir

	push hl
	call os_change_dir			; delete dir, and if any %assigns are pointing to it
	pop hl
	ret nz				; remove them
	push hl
	call kjt_get_dir_cluster		
	ld (scratch_pad),de			; get cluster of dir we're deleting for assign compare
	call os_parent_dir
	pop hl
	ret nz
	
	call fs_hl_to_filename
	call fs_delete_dir_command
	jp c,os_fferr
	or a
	ret nz
	
	ld ix,env_var_list
	ld b,max_envars
evloop	ld a,(ix)				; is this envar an %assign?
	cp "%"
	jr nz,notdenv
	ld a,(current_volume)		; if this doesnt refer to the same volume, skip it
	cp (ix+6)
	jr nz,notdenv
	ld e,(ix+4)
	ld d,(ix+5)
	ld hl,(scratch_pad)
	xor a
	sbc hl,de
	jr nz,notdenv			; is the assign refering to the deleted dir?
	call page_out_hw_registers
	ld (ix),0
	call page_in_hw_registers
notdenv	ld de,8
	add ix,de
	djnz evloop
	xor a
	ret
	
		
	
;----- LOW LEVEL SECTOR ACCESS ETC FOR EXTERNAL PROGRAMS ---------------------------------------------------


user_read_sector
	
	call user_access_preamble
	ret nz
	ld (current_driver),a
	call fs_read_sector
sect_done	push af
	ld a,(sys_driver_backup)		;restore system driver number
	ld (current_driver),a
	pop af
	jp os_rffsc
	

user_write_sector

	call user_access_preamble
	ret nz
	ld (current_driver),a
	call fs_write_sector
	jr sect_done


user_access_preamble
	
	push af				;set A = device 
	ld (sector_lba0),de			;set sector required = BC:DE 
	ld (sector_lba2),bc			
	call dev_to_driver_lookup		;on return if ZF set: all OK, else sector out of range
	push hl
	pop ix
	ld l,(ix+3)
	ld h,(ix+4)
	ld de,(sector_lba2)
	xor a
	sbc hl,de
	jr c,range_err
	jr nz,range_ok
	ld l,(ix+1)
	ld h,(ix+2)
	ld de,(sector_lba0)
	xor a
	sbc hl,de
	jr c,range_err
	jr nz,range_ok
range_err	pop af
	ld a,$1e				;"bad range" error
	or a				;clear zero flag
	ret
	
range_ok	ld a,(current_driver)
	ld (sys_driver_backup),a
	pop af				;get requested device back
	call dev_to_driver_lookup
	jr nc,bad_dev
os_null	cp a				;set zero flag, retaining contents of A (driver number)
	ret
		
bad_dev	ld a,$22				;"invalid device" error
	or a				;clear zero flag
	ret





os_get_device_info

	ld hl,host_device_hardware_info
	ld de,driver_table
	ld a,(device_count)
	ld b,a
	ld a,(current_driver)
	ret




os_get_volume_info

	ld hl,volume_mount_list	
	ld a,(volume_count)
	ld b,a
	ld a,(current_volume)
	ret
	
		
;------------------------------------------------------------------------------------------------------------



os_serial_get_header

	call serial_get_header
	or a
	ret
	
	
os_serial_receive_file

	call ext_serial_receive_file
	or a
	ret
	
	
os_serial_send_file

	call serial_send_file
	or a
	ret


os_serial_tx
	
	call send_serial_byte
	ret


os_serial_rx

	ld (serial_timeout),a
	call receive_serial_byte
	ret
	

;------------------------------------------------------------------------------------------------------------



page_out_hw_registers

	push af
	ld a,%10000000
	out (sys_alt_write_page),a	; write "below" the hardware register range
	pop af
	ret


page_in_hw_registers
	
	push af
	xor a
	out (sys_alt_write_page),a
	pop af
	ret
	
					
;-----------------------------------------------------------------------------------------------


os_mount_volumes
	
	ld (os_quiet_mode),a
	
	ld hl,storage_txt
	call os_print_string_cond
	call mount_go
	call page_in_hw_registers
	xor a
tvloop	ld (current_volume),a
	call os_change_volume	;after mount, current volume is set to 0
	ret z			;unless its not valid, then try next vol
	ld a,(current_volume)	;until good volume found
	inc a
	cp max_volumes
	jr nz,tvloop
	ld a,(device_count)
	or a
	jr nz,mfsdevs
	ld hl,none_found_msg
	call os_show_packed_text_cond
mfsdevs	xor a
	ret
	
mount_go	call page_out_hw_registers
	ld hl,volume_mount_list	; wipe current mount list
	ld bc,max_volumes*16
clrdl_lp	xor a
	call os_bchl_memfill
	call page_in_hw_registers
	
	ld hl,volume_dir_clusters	; wipe directory cluster list
	ld bc,max_volumes*2		
	xor a	
	call os_bchl_memfill	

	ld de,host_device_hardware_info
	ld (dhwn_temp_pointer),de
	
	ld iy,volume_mount_list
	xor a
	ld (volume_count),a
	ld (device_count),a
mnt_loop	ld (current_driver),a	; host driver number
	call locate_driver_base
	ld a,e
	or d
	jr z,nxt_drv		; if driver addr, skip it
	ex de,hl
	ld de,$0e			
	add hl,de			; hl = "get_id" subroutine address for host device
	push iy
	call find_dev		; "get_id" routines must return Carry=1 if present
	pop iy			; size in bc:de and h/w device name location at HL
	call c,got_dev		
nxt_drv	ld a,(current_driver)	; try next driver type 	
	inc a
	cp 4
	jr nz,mnt_loop
	ret
	
find_dev	jp (hl)


got_dev	push hl			; Host device found, hl = name from get_id
	push de
	push bc
	call os_new_line_cond	; bc:de = total device capacity in sectors
	ld bc,$015b
	call os_print_multiple_chars_cond	; "["
	ld a,(current_driver)
	call locate_driver_base
	ex de,hl
	call os_print_string_cond	; show driver name "SD_CARD" etc
	ld bc,$015d
	call os_print_multiple_chars_cond	; "]"
	pop bc
	pop de
	xor a
	ld (vols_on_device_temp),a
	
	call page_out_hw_registers
	ld hl,device_count
	inc (hl)			; Increase the device count
	ld a,(current_driver)
	ld hl,(dhwn_temp_pointer)	
	ld (hl),a
	inc hl
	ld (hl),e			; Fill in total capacity of host device (in sectors) BC:DE
	ld (iy+4),e		; Also put total capacity in first volume entry for devices
	inc hl			; where there is no MBR
	ld (hl),d
	ld (iy+5),d
	inc hl
	ld (hl),c			
	ld (iy+6),c
	inc hl
	ld (hl),b			; capacity MSB
	inc hl
	pop de
	ld b,22			; Fill in hardware name of host device - limit to 22 chars
dnloop	ld a,(de)
	ld (hl),a
	inc hl
	inc de
	djnz dnloop	
	ld b,5		
clrrode	ld (hl),0			; pad device entry with zeroes to 32 bytes
	inc hl
	djnz clrrode
	ld (dhwn_temp_pointer),hl	; update device info pointer ready for next device
		
	xor a			; Now scan this device for partitions
fnxtpart	call page_out_hw_registers
	push iy
	call fs_get_partition_info
	pop iy
	jr c,nxt_dev		; if hardware error or bad format, skip device
	cp $13
	jr z,nxt_dev
	push af
	ld (iy),1			; Found a partition - set volume present
	ld a,(current_driver)
	ld (iy+1),a		; Set volume's Host driver number
	ld a,(partition_temp)	
	ld (iy+7),a		; Set its partition-on-host device number	
	pop af
	or a
	jr z,dev_mbr
	xor a
	ld (iy+8),a		; No MBR on device - fill in partition offset as zero
	ld (iy+9),a		; and go immediately to next device
	ld (iy+10),a		; (capacity data has already been filled in)
	ld (iy+11),a
	call show_vol_info
	call test_max_vol
	ret z			; quit if reached max allowable number of volumes

nxt_dev	ld a,(vols_on_device_temp)	; were any volumes found on the previous device?
	or a
	ret nz		
	call test_quiet_mode
	jr nz,skp_cu
	ld a,10
	ld (cursor_x),a
skp_cu	ld hl,no_vols_msg		; if not say "No volumes"
	call os_show_packed_text_cond
	call os_new_line_cond
	ret
	

dev_mbr	ld de,4
	add hl,de
	ld a,(hl)			;A = type of partition
	or a
	ret z			;end if partition type is zero
	add hl,de
	
	push iy
	ld b,4
sfmbrlp	ld a,(hl)			; fill in offset in sectors from MBR to partition
	ld (iy+8),a
	inc hl
	inc iy
	djnz sfmbrlp
	pop iy
	push iy
	ld b,3	
nsivlp	ld a,(hl)
	ld (iy+4),a		; fill in number of sectors in volume (partition)
	inc hl
	inc iy
	djnz nsivlp
	pop iy
	
	call show_vol_info
	call test_max_vol	
	ret z			; quit if reached max allowable number of volumes
	ld a,(partition_temp)
	inc a
	cp 4			; max number of partitions per device
	jp nz,fnxtpart
	jr nxt_dev
	
	
test_max_vol

	ld de,16
	add iy,de			
	ld hl,volume_count
	inc (hl)
	ld a,(hl)
	cp max_volumes
	ret


show_vol_info
	
	call page_in_hw_registers	;ensure hw regs paged in for print / screen scrolling routines etc
	call test_quiet_mode
	jr nz,skp_cm2
	ld a,9			
	ld (cursor_x),a
skp_cm2	ld a,(volume_count)
	push af
	add a,$30		
	ld (vol_txt+4),a	
	ld hl,vol_txt
	call os_print_string_cond	;show "VOLx:"
	ld hl,vols_on_device_temp
	set 0,(hl)		;note that some volumes were found on this device

	pop af
	push iy
	call os_change_volume	;sets up the data structures and variables for the desired volume
	jr z,vform_ok		;so format type / label can be read
svi_fe	ld hl,format_err_msg		
svi_pem	call os_show_packed_text_cond	;volume not formatted to fat16
	jr skpsvl

vform_ok	call fs_get_volume_label
	jr c,svi_hwe
	or a
	jr nz,svi_fe
	call os_print_string_cond	;show volume label

skpsvl	call os_new_line_cond
	pop iy
	ret
	
svi_hwe	ld hl,disk_err_msg
	jr svi_pem


test_quiet_mode

	ld a,(os_quiet_mode)
	or a
	ret

;-----------------------------------------------------------------------------------------------


show_dev_driver_name
	
	
	call locate_driver_base	;set driver number in A before calling	
	ex de,hl
	call os_print_string	;show friendly name (IE: "IDE(M)", "SD Card" etc).
	push bc
	ld bc,$0120
	call os_print_multiple_chars
	pop bc
	ret


locate_driver_base

	push hl			;returns driver base address in DE
	rlca			;set driver number in A before calling
	ld e,a
	ld d,0
	ld hl,driver_table
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)			
	pop hl
	ret
	
		
;-------------------------------------------------------------------------------------------------------

os_print_multiple_chars_cond

	call test_quiet_mode
	ret nz

os_print_multiple_chars

	push hl
	ld a,c
	ld hl,rep_char_txt
	ld (hl),a
pmch_lp	push hl
	call os_print_string
	pop hl
	djnz pmch_lp
	pop hl
	ret
		
	
;-----------------------------------------------------------------------------------------------------


include	"fat16_code.asm"


;-----------------------------------------------------------------------------------------------
; Some file system related routines 
;-----------------------------------------------------------------------------------------------


fs_get_dir_block


	push af			;returns current volume's dir cluster in DE  
	push hl			
	call fs_get_dir_cluster_address
	ld e,(hl)
	inc hl
	ld d,(hl)
dclopdone	pop hl
	pop af
	ret
	




fs_update_dir_block

	push af			;updates current volume's dir cluster from DE
	push hl			
	push de			
	call fs_get_dir_cluster_address	
	pop de
	ld (hl),e
	inc hl
	ld (hl),d
	jr dclopdone





fs_get_dir_cluster_address

	ld hl,volume_dir_clusters	;HL returns location dir cluster pointer
	ld a,(current_volume)	
	rlca
	ld e,a
	ld d,0
	add hl,de
	ret
	
	

	
	
fs_get_total_sectors


	push af
	push hl			;returns total sectors of current volume in C:DE 
	call fs_calc_volume_offset	
	ld hl,volume_mount_list+4
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld c,(hl)
	pop hl
	pop af
	ret





fs_calc_volume_offset

	ld a,(current_volume)	;selected volume
calc_vol	rlca
	rlca
	rlca
	rlca
	ld e,a
	ld d,0
	ret





dev_to_driver_lookup

	ld hl,device_count		;set A to DEVICE, on return if carry is set: A is driver number
	cp (hl)			;(and hl is device_info base) else: invalid device selected
	ret nc
	rlca			
	rlca
	rlca 
	ld e,a
	ld d,0
	ld hl,host_device_hardware_info
	add hl,de
	ld a,(hl)
	scf
	ret
	




os_change_volume

	ld b,a			; set A to required volume before calling
	cp max_volumes		
	jr nc,fs_ccv2		; report error if above max number of allowable volumes

	ld a,(current_volume)	; note the original volume selection
	push af
	ld a,b
	ld (current_volume),a	; change to new volume
	call fs_set_driver_for_volume	; set driver appropriately
	
	call fs_check_disk_format	; check that its a valid volume
	jr c,fs_cant_chg_vols
	or a
	jr nz,fs_cant_chg_vols
	pop af			; restore stack parity
	xor a			; Exit, All OK
	ret

fs_cant_chg_vols

	pop af
	ld (current_volume),a	;restore original volume selection
	call fs_set_driver_for_volume	;set driver appropriately
	
fs_ccv2	ld a,$0e			;say "no disk" if required volume selection is not valid	
	or a
	ret
		
	
fs_set_driver_for_volume

	call fs_calc_volume_offset	; update "current_driver" based on volume info table
	ld hl,volume_mount_list+1
	add hl,de
	ld a,(hl)
	ld (current_driver),a
	ret


;--------------------------------------------------------------------------------------------

os_file_sector_list

;Input DE = cluster, A = sector offset

;Output DE = new cluster, A = new sector number
;       HL = address of LBA0 LSB of sector (internally updates the LBA pointer)

	push af
	ld hl,fs_cluster_size
	cp (hl)
	jr nz,fsl_sc
	ex de,hl
	call get_fat_entry_for_cluster
	ex de,hl
	pop af
	xor a
	push af
fsl_sc	ex de,hl
	call cluster_and_offset_to_lba
	ex de,hl
	pop af
	inc a
fsl_done	ld hl,sector_lba0
	ret
	
	
			
;--------------------------------------------------------------------------------------------
; Environment variable code
;--------------------------------------------------------------------------------------------

os_get_envar

;Set: 	HL = name of required variable (null terminated string, 4 ascii bytes max)

;Returns:	HL = address of variable data
;         ZF = Not Set: Couldn't find variable (HL = start of var list, A = maximum vars allowed)

	ld c,max_envars
	ld de,env_var_list
	push hl

ev_nxt	pop hl
	push hl
	ld b,4
ev_lp1	ld a,(de)
	cp (hl)
	jr nz,ev_nm1
	ld a,(hl)				;if did match and its a zero then got short var
	or a
	jr z,ev_mshrt
	inc hl
	inc de
	djnz ev_lp1
ev_end	pop bc				;level the stack
	ex de,hl				;found match (4 byte ASCII name)
	xor a
	ret

ev_mshrt	ld a,e				;found match short ASCII name
	and $f8
	add a,4
	ld e,a
	jr ev_end

ev_nm1	ld a,e
	and $f8
	add a,8
	ld e,a
	dec c
	jr nz,ev_nxt
	pop hl				;level the stack
	ld hl,env_var_list
	ld a,max_envars			;ZF not set, didnt find envar
	or a
	ret
	

;--------------------------------------------------------------------------------------------

os_set_envar

;HL = addr of variable name (4 bytes max ASCII, zero terminated)
;DE = addr of data for variable (4 bytes max)

;Returns:

;ZF = No Set: No enough space for new variable

	push de
	push hl				;cache new data location on stack
	call os_delete_envar		;remove existing var of this name (doesnt matter if didn't exist)
	
	ld hl,env_var_list
	ld de,8
	ld b,max_envars			;max number of  environment vars
ev_fsp	ld a,(hl)
	or a
	jr z,ev_wrdat
	add hl,de
	djnz ev_fsp
ev_nosp	xor a
	inc a				;zf not set, no space for new var
	ret
	
ev_wrdat	call page_out_hw_registers
	ex de,hl
	pop hl
	ld bc,4
	ldir
	pop hl
	ld bc,4
	ldir
env_wrend	call page_in_hw_registers
	xor a
	ret
		
;--------------------------------------------------------------------------------------------

os_delete_envar

;Set    :	HL = name of required variable (null terminated string, 4 bytes max)
;Returns: Nothing relevent

	call os_get_envar
	ret nz
	ld a,l
	and $f8
	ld l,a
	call page_out_hw_registers
	xor a
	ld (hl),a				;zero first byte = entry is available
	jr env_wrend


;-----------------------------------------------------------------------------------------------
; DRIVERS
;-----------------------------------------------------------------------------------------------


include	"sdcard_driver_v105.asm"	;low level MMC/SD Card driver 


;-----------------------------------------------------------------------------------------------
; OS Data 
;-----------------------------------------------------------------------------------------------

include	"os_data.asm"		;data


;-----------------------------------------------------------------------------------------------




;================================================================================================
	
os_high	db 0			; address marker for start of safe user RAM
	
	end		
;================================================================================================

