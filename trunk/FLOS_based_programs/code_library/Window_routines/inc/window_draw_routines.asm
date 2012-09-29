;---------------------------------------------------------------------------------------
; FLOS Character-based window drawing code v0.11 by Phil Ruston, last update: 27-09-2012
;---------------------------------------------------------------------------------------
;
; Before calling "draw_window", set:
;
; A = Window number
; B = X coordinate of top left window border
; C = Y coordinate of top left window border
;
; Requires an array labelled "window_list" which contains the description of
; windows and their elements - See end of source for an example.. (The variable
; "w_addr_loc" by default contains this base address, but it can be changed by
; a user program so that different groups of windows can be used, if desired).
;
;-------------------------------------------------------------------------------
; ALL REGISTERS ARE PRESERVED!
;-------------------------------------------------------------------------------

display_width 	equ 40

checkbox_tick_char	equ 205

draw_window

	push iy
	push ix
	push hl
	push de
	push bc
	push af
	
	ld (w_active_window),a
	push bc
	
	ld hl,w_window_buffer	;clear window draw buffer
	ld de,w_window_buffer+1
	ld bc,0+(40*25)-1
	ld (hl),0
	ldir
	
	ld hl,w_my_chars		;patch font chars 176-207 with custom window characters
	ld a,176
	ld b,32
pafntlp	push hl
	push bc
	push af
	call kjt_patch_font
	pop af
	inc a
	pop bc
	pop hl
	ld de,8
	add hl,de
	djnz pafntlp
		
	call kjt_get_pen		;create inverse version of current pen	
	ld (w_norm_pen),a
	rrca
	rrca
	rrca
	rrca
	ld (w_inv_pen),a
	ld (w_draw_pen),a		;use inverse pen for window frame
	
	ld hl,(w_list_loc)		;locate desired window info
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
	call w_char_to_buffer
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
	pop iy			

	ld hl,w_window_buffer	;finally, reveal the completed window
	ld ix,w_window_buffer+(40*25)
	ld c,0			
w_btdlp2	ld b,0	
w_btdlp1	ld a,(hl)
	or a
	jr z,w_tchar		;slip char location if nothing there
	ld e,a
	ld a,(ix)
	call kjt_set_pen
	ld a,e
	call kjt_plot_char
w_tchar	inc hl
	inc ix
	inc b
	ld a,b
	cp 40
	jr nz,w_btdlp1
	inc c
	ld a,c
	cp 25
	jr nz,w_btdlp2

	ld a,(w_norm_pen)
	call kjt_set_pen
	
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
	jp w_drw_tnv		;add the button text (non-inverse text)

	
w_draw_data_area

	ld hl,w_text_area_chars
	ld de,w_text_area_swaplist
	call w_gadget_draw		;if the data area can accept user input, check for default data
	bit 2,(ix+3)
	call nz,w_drw_tnv		;display default data
	bit 4,(ix+3)
	call nz,w_drw_tnv		;display default selection if a checkbox
	bit 3,(ix+3)
	jr z,w_nincdec		;is the input area numeric?
	ld a,(w_frame_y)		
	add a,(iy+7)
	inc a
	ld c,a			;y position
	ld a,(w_frame_x)
	add a,(iy+6)
	add a,(ix+1)		;max width
	inc a
	ld b,a			;x position
	ld a,$ce
	call w_char_to_buffer	;"+" gadget
	inc b
	ld a,$cf
	call w_char_to_buffer	;"-" gadget
w_nincdec	xor a
	ret
	
w_gadget_draw	
	
	ld a,(w_norm_pen)
	ld (w_draw_pen),a
	
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


w_gdlp1	call w_get_buffer_char	;is there empty space at desired plot location?
	cp $20		
	jr z,w_norm_ch
	exx			;if not a find a suitable compensating char def
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
	call nz,w_char_to_buffer
	
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

	ld a,(w_inv_pen)		;inverse
	jr w_drw_tgo
w_drw_tnv	ld a,(w_norm_pen)		;not inverse
w_drw_tgo	ld (w_draw_pen),a
	
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
	
	bit 4,(ix+3)		;is gadget a textbox? If so swap 0/1 to space or tick char
	call nz,w_01_to_space_tick

	call w_char_to_buffer
	inc b
	dec e
	jr nz,w_drw_tl1
w_tcr	inc c
	dec d
	jr nz,w_drw_tl2
w_drwtdun	xor a
	ret

;----------------------------------------------------------------------------------

w_01_to_space_tick

	sub $10			;if data = "0" display a space, if "1" display a tick
	cp $20
	ret z
	ld a,checkbox_tick_char
	ret

;---------------------------------------------------------------------------------

w_char_to_buffer	
	
	push hl		
	push de			;a = char, b = x, c = y
	ld h,0			;current w_draw_pen value is used for attribute
	ld l,c
	add hl,hl
	add hl,hl
	add hl,hl
	push hl
	add hl,hl
	add hl,hl
	pop de
	add hl,de
	ld d,0
	ld e,b
	add hl,de
	ld de,w_window_buffer
	add hl,de
	ld (hl),a
	ld de,40*25
	add hl,de
	ld a,(w_draw_pen)
	ld (hl),a
	pop de
	pop hl
	ret


w_get_buffer_char

	push hl
	push de			;b = x, c = y, char returned in A
	ld h,0			
	ld l,c
	add hl,hl
	add hl,hl
	add hl,hl
	push hl
	add hl,hl
	add hl,hl
	pop de
	add hl,de
	ld d,0
	ld e,b
	add hl,de
	ld de,w_window_buffer
	add hl,de
	ld a,(hl)
	pop de
	pop hl
	ret

;---------------------------------------------------------------------------------
					
w_backup_display
	
	push hl
	push de
	push bc
	
	ld a,(w_backup_stack)
	cp 3
	jr nz,w_budok
	
	or a
w_quitpop	pop bc
	pop de
	pop hl
	ret
	
w_budok	rlca
	rlca
	rlca
	add a,$28
	ld d,a
	ld e,0
	
	ld bc,0
	call kjt_get_charmap_addr_xy		;get start of charmap location
	
	ld a,$0e				;IE: $1c000/$2000
	ld (vreg_vidpage),a
	call kjt_page_in_video
	
	ld bc,40*25			;char map
	ldir
	ld hl,$2000			;attr buffer
	ld bc,40*25
	ldir
	
	call kjt_page_out_video
	
	ld hl,w_backup_stack
	inc (hl)
	jr w_quitpop





w_restore_level_a

	push hl
	push de
	push bc
	jr w_restore_abs

w_restore_display
	
	push hl
	push de
	push bc
	
	ld a,(w_backup_stack)
	or a
	jr nz,w_busok
	inc a
	jr w_quitpop

w_busok	dec a
	ld (w_backup_stack),a
	
w_restore_abs
		
	rlca
	rlca
	rlca
	add a,$28
	ld h,a
	ld l,0
	push hl
	ld de,25*40
	add hl,de
	ex de,hl
	pop hl
	
	ld a,$0e				;IE: $1c000/$2000
	ld (vreg_vidpage),a
	
	ld c,0			
w_rdlp2	ld b,0	
w_rdlp1	in a,(sys_mem_select)		;make sure video is paged in for the read
	or $40				;(kjt_plot_char keeping paging it out)
	out (sys_mem_select),a
	ld a,(de)
	call kjt_set_pen
	ld a,(hl)
	call kjt_plot_char
	inc hl
	inc de
	inc b
	ld a,b
	cp 40
	jr nz,w_rdlp1
	inc c
	ld a,c
	cp 25
	jr nz,w_rdlp2
	
	ld a,(w_norm_pen)
	call kjt_set_pen
	xor a
	jp w_quitpop
	


w_backup_stack
	
	db 0
		
	
;---------------------------------------------------------------------------------


w_window_chars

	db 0, 0,$be,1,$b6,0,$bf, $80
	db 1, 0,$b7,1,$20,0,$b8, $80
	db 0, 0,$c0,1,$b9,0,$c1, $80
	db $80	
	
w_text_area_chars	

	db 0, 0,$00,1,$b0,0,$00, $80
	db 1, 0,$b1,1,$20,0,$b2, $80
	db 0, 0,$00,1,$b3,0,$00, $80
	db $80		

w_text_area_swaplist

	db $b0,$b3,$b5, $b1,$b2,$b4, $b2,$b1,$b4, $b3,$b0,$b5
	db $b0,$b9,$bd, $b1,$b8,$bc, $b2,$b7,$bb, $b3,$b6,$ba
	db $b0,$c0,$c4, $b0,$c1,$c5, $b1,$bf,$c7, $b1,$c1,$c9
	db $b2,$be,$c6, $b2,$c0,$c8, $b3,$be,$c6, $b3,$bf,$c7
	db 0
	
w_button_swaplist

	db $be,$b3,$c2, $b6,$b3,$ba, $bf,$b3,$c3
	db $b7,$b2,$bb, $b8,$b1,$bc
	db $c0,$b0,$c4, $b9,$b0,$bd, $c1,$b0,$c5
	db $be,$b2,$c6, $ff,$b1,$c7, $c0,$b2,$c8, $c1,$b1,$c9
	db 0
	

w_list_loc	dw window_list
	
w_swap_list	dw 0	;internal working registers
w_frame_x		db 0
w_frame_y		db 0
w_norm_pen	db 0
w_inv_pen		db 0
w_draw_pen	db 0
w_active_window	db 0

w_my_chars	incbin "winchrs3.fff"

;--------------------------------------------------------------------------------

w_window_buffer	ds 2*40*25,0		; map and colour buffers


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
;		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=accept ascii input. b3= hex input, b4=checkbox)
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
