;-------------------------------------------------------------------------------
; FLOS Character-based window drawing code v0.03 by Phil Ruston
;-------------------------------------------------------------------------------
;
; Before calling "draw_window", set:
;
; A = Window number
; B = X coordinate of top left window border
; C = Y coordinate of top left window border
;
; Requires an array labelled "window_list" which contains the description of
; windows and their elements - See end of source for an example..
;
;-------------------------------------------------------------------------------
; ALL REGISTERS ARE PRESERVED!
;-------------------------------------------------------------------------------

display_width equ 40

draw_window

	push iy
	push ix
	push hl
	push de
	push bc
	push af
	
	ld (w_active_window),a
	push bc
	
	ld a,%00001111		;copy window graphic chars to FLOS font
	ld (vreg_vidpage),a		
	call kjt_page_in_video			
	ld hl,w_my_chars		
	ld b,8
	ld de,video_base+$460
w_rorgflp	push bc
	ld bc,32
	ldir
	ld bc,96
	ex de,hl
	add hl,bc
	ex de,hl	
	pop bc
	djnz w_rorgflp
	ld bc,$400		
	ld hl,video_base+$400
	ld de,video_base+$800
w_invloop	ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,w_invloop
	call kjt_page_out_video

	call kjt_get_pen		
	ld (w_norm_pen),a
	rrca
	rrca
	rrca
	rrca
	ld (w_inv_pen),a
	
	ld hl,window_list		;locate desired window info
	ld a,(w_active_window)
	sla a
	ld e,a
	ld d,0
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	push de
	pop iy
	pop bc
	ld (iy),b
	ld (iy+1),c
	ld hl,w_window_chars	;draw main background window
	ld c,(iy+1)		;y pos
w_lp3	ld d,1
	ld a,(hl)
	inc hl
	or a
	jr z,w_yrep
	ld d,(iy+3)		;y repetitions
w_yrep	ld b,(iy+0)		;x pos
	push hl
w_lp2	ld e,1
	ld a,(hl)
	inc hl
	or a
	jr z,w_lp1
	ld e,(iy+2)		;x repetitions
w_lp1	ld a,(hl)
	sub $80			;plot as 0-$1f so reveal routine knows they're inverse "extra" chars
	push hl
	call kjt_get_charmap_addr_xy
	ld (hl),a
	pop hl
	inc b
	dec e
	jr nz,w_lp1
	inc hl
	bit 7,(hl)		;end of line?
	jr z,w_lp2
	pop hl
	inc c
	dec d
	jr nz,w_yrep
	ld de,7
	add hl,de
	bit 7,(hl)		;end of box?
	jr z,w_lp3

	ld a,(iy)			;now fill in the window's elements		
	ld (w_frame_x),a
	ld a,(iy+1)
	ld (w_frame_y),a
	push iy
w_drw_glp	ld a,(iy+6)		;255 = end of element list
	inc a
	jr nz,w_neoe

	ld a,(w_norm_pen)		
	call kjt_set_pen
	pop iy			;finally, reveal the completed window by actually plotting
	ld c,(iy+1)		;the characters previously written to charmap. This is done to
	ld e,(iy+3)		;avoid seeing the window being drawn an element at a time.
	inc e
	inc e
w_revwlp2	ld b,(iy)
	ld d,(iy+2)
	inc d
	inc d
w_revwlp1	call kjt_get_charmap_addr_xy
	ld a,(hl)
	cp $20			;if the char plotted was < $20, its actually an extra char ($80-$9f)
	jr c,w_inv		;that needs to be drawn in inverse (IE: the window outline)
	cp $a0
	jr c,w_notinv
w_inv	add a,$80
	push af
	ld a,(w_inv_pen)
	call kjt_set_pen
	pop af
	call kjt_plot_char
	ld a,(w_norm_pen)
	call kjt_set_pen
	jr w_nxtrch	
w_notinv	call kjt_plot_char
w_nxtrch	inc b
	dec d
	jr nz,w_revwlp1
	inc c
	dec e
	jr nz,w_revwlp2
	pop af
	pop bc
	pop de
	pop hl
	pop ix
	pop iy
	ret
	
w_neoe	ld l,(iy+8)		;location of element description	
	ld h,(iy+9)
	push hl
	pop ix
	ld a,(hl)			;get element type
	or a
	call z,w_draw_button
	cp 1
	call z,w_draw_data_area
	cp 2
	call z,w_draw_text
	ld de,4
	add iy,de
	jr w_drw_glp
	

w_draw_button
	
	ld hl,w_window_chars	;button chars (but same info as window chars)
	ld de,w_button_swaplist
	call w_gadget_draw
	jp w_drw_tnv		;add the button text

	
w_draw_data_area

	ld hl,w_text_area_chars
	ld de,w_text_area_swaplist

w_gadget_draw	
		
	ld (w_swap_list),de
	ld a,(w_frame_y)		
	add a,(iy+7)
	ld c,a			;y pos
w_gdlp3	ld d,1
	ld a,(hl)
	inc hl
	or a
	jr z,w_gdyrep
	ld d,(ix+2)		;y repetitions
w_gdyrep	ld a,(w_frame_x)
	add a,(iy+6)
	ld b,a			;x pos
	push hl
w_gdlp2	ld e,1
	ld a,(hl)
	inc hl
	or a
	jr z,w_gdlp1
	ld e,(ix+1)		;x repetitions


w_gdlp1	push hl			;find what char is at desired plot location
	call kjt_get_charmap_addr_xy
	ld a,(hl)
	pop hl
	cp $a0
	jr z,w_norm_ch
	exx			;not a blank char (inv space), find a suitable compensating char def
	ld b,a			;b = char at location 
	exx
	ld a,(hl)
	exx
	ld c,a			;c = originally intended plot character
	ld hl,(w_swap_list)
w_fndswap	ld a,(hl)			;swap list entries are 3 bytes: intended, current, replacement
	inc hl
	or a			;skip swap if at end of swap list
	jr nz,w_swchar
	exx
	jr w_norm_ch
w_swchar	cp c			;list entry match char originally wanted to plot?
	jr nz,w_swchnx1
	ld a,(hl)		
	inc hl
	cp b			;list entry + 1 match the char present?
	jr nz,w_swchnx2
	ld a,(hl)			;this is the replacement char
	exx
	jr w_gotswch
w_swchnx1	inc hl
w_swchnx2	inc hl
	jr w_fndswap
	
w_norm_ch	ld a,(hl)
w_gotswch	or a
	jr z,w_skipch
	push hl
	call kjt_get_charmap_addr_xy
	ld (hl),a
	pop hl
w_skipch	inc b
	dec e
	jr nz,w_gdlp1
	inc hl
	bit 7,(hl)		;end of line?
	jr z,w_gdlp2
	pop hl
	inc c
	dec d
	jr nz,w_gdyrep
	ld de,7
	add hl,de
	bit 7,(hl)		;end of box?
	jp z,w_gdlp3
	xor a
	ret


w_draw_text
	
	ld b,$80			;inverse
	jr w_drw_tgo
w_drw_tnv	ld b,$0			;not inverse
w_drw_tgo	exx
	ld l,(ix+5)
	ld h,(ix+6)		;HL = location of associated data (text)
	ld a,(w_frame_y)		
	add a,(iy+7)
	inc a
	ld c,a			;y position
	ld d,(ix+2)		;max height
w_drw_tl2	ld a,(w_frame_x)
	add a,(iy+6)
	inc a
	ld b,a			;x position
	ld e,(ix+1)		;max width
w_drw_tl1	ld a,(hl)
	inc hl
	or a
	jr z,w_drwtdun
	cp 11
	jr z,w_tcr
	exx
	add a,b			;element text appears in inverse video
	exx
	push hl
	call kjt_get_charmap_addr_xy
	ld (hl),a
	pop hl
	inc b
	dec e
	jr nz,w_drw_tl1
w_tcr	inc c
	dec d
	jr nz,w_drw_tl2
w_drwtdun	xor a
	ret

		
;---------------------------------------------------------------------------------


w_window_chars

	db 0, 0,$8e,1,$86,0,$8f, $80
	db 1, 0,$87,1,$20,0,$88, $80
	db 0, 0,$90,1,$89,0,$91, $80
	db $80	
	
w_text_area_chars	

	db 0, 0,$00,1,$80,0,$00, $80
	db 1, 0,$81,1,$20,0,$82, $80
	db 0, 0,$00,1,$83,0,$00, $80
	db $80		

w_text_area_swaplist

	db $80,$83,$85, $81,$82,$84, $82,$81,$84, $83,$80,$85
	db $80,$89,$8d, $81,$88,$8c, $82,$87,$8b, $83,$86,$8a
	db $80,$90,$94, $80,$91,$95, $81,$8f,$97, $81,$91,$99
	db $82,$8e,$96, $82,$90,$98, $83,$8e,$96, $83,$8f,$97
	db 0
	
w_button_swaplist

	db $8e,$83,$92, $86,$83,$8a, $8f,$83,$93
	db $87,$82,$8b, $88,$81,$8c
	db $90,$80,$94, $89,$80,$8d, $91,$80,$95
	db $8e,$82,$96, $bf,$81,$97, $90,$82,$98, $91,$81,$99
	db 0
	
	
w_swap_list	dw 0	;internal working registers
w_frame_x		db 0
w_frame_y		db 0
w_norm_pen	db 0
w_inv_pen		db 0
w_active_window	db 0

w_my_chars	incbin "winchars.bin"

;--------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
; Example window list data follows (commented out)
;---------------------------------------------------------------------------------
;
;window_list	dw win_inf_load		;Window 0
;		dw win_inf_new_dir		;Window 1
;
;
;win_inf_load	db 0,0			;0 - position on screen of frame (x,y) 
;		db 23,20			;2 - dimensions of frame (x,y)
;		db 0			;4 - current element/gadget selected
;		db 0			;5 - unused at present
;		db 1,1			;6 - position of first element (x,y)
;		dw win_elementa		;8 - location of first element description
;		db 5,1
;		dw win_elementb
;		db 19,1
;		dw win_elementc
;		db 1,3
;		dw win_elementd
;		db 1,16
;		dw win_elemente
;		db 10,16
;		dw win_elementf
;		db 1,18
;		dw win_elementg
;		db 16,18
;		dw win_elementh
;		db 255			;255 = end of list of window elements
;		
;win_inf_new_dir	db 0,0			;as above for second window type...
;		db 10,7
;		db 0
;		db 0
;		db 1,1
;		dw win_elementj
;		db 1,5
;		dw win_elementk
;		db 255
;
;
;---- Window Elements ---------------------------------------------------------------------
;
;		
;win_elementa	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
;		db 3,1			;1/2 = dimensions of element x,y
;		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=accept ascii input)
;		db 0			;4 = event flag (for external apps)
;		dw dir_txt		;5/6 = location of associated data
;		
;win_elementb	db 1
;		db 12,1
;		db 0
;		db 0
;		
;win_elementc	db 0
;		db 3,1
;		db 0
;		db 0
;		dw new_txt
;
;win_elementd	db 1
;		db 21,12
;		db 0
;		db 0
;		
;win_elemente	db 2
;		db 8,1
;		db 0
;		db 0
;		dw filename_txt
;
;win_elementf	db 1
;		db 12,1
;		db 0
;		db 0
;		dw w_filename
;
;win_elementg	db 0
;		db 4,1
;		db 0
;		db 0
;		dw load_txt
;
;win_elementh	db 0
;		db 6,1
;		db 0
;		db 0
;		dw cancel_txt
;
;win_elementi	db 0
;		db 4,1
;		db 0
;		db 0
;		dw save_txt
;
;win_elementj	db 2
;		db 8,3
;		db 0
;		db 0
;		dw new_dir_txt
;
;win_elementk	db 1
;		db 8,1
;		db 0
;		db 0
;		dw w_dirname
;
;
;dir_txt		db "DIR",0
;new_txt		db "NEW",0
;filename_txt	db "FILENAME",0
;save_txt		db "SAVE",0
;cancel_txt	db "CANCEL",0
;load_txt		db "LOAD",0
;new_dir_txt	db "NEW DIR",11,11," NAME?",0
;
;w_filename	ds 14,0
;w_dirname	ds 14,0
;
;--------------------------------------------------------------------------------------
