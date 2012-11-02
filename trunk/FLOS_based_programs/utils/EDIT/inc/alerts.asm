;-----------------------------------------------------------------------------------------------


error_flash

	ret
				
	call kjt_wait_vrt			;change to onscreen warning eventually
	ld hl,$fff
	ld (palette),hl
	call kjt_wait_vrt
	ld hl,0
	ld (palette),hl
	ret
	

;----------------------------------------------------------------------------------------------------------------

alert_box
	push af
	ld (al_txtadr),hl
	call get_string_length		; adjust box elements to match string
	add a,2
	ld (warn_wins),a
	ld (conf_wins),a
	srl a
	dec a
	ld (warn_bloc),a
	ld hl,my_edit_windows
	ld (w_list_loc),hl			; tell windows code to use this window description list
	ld b,a				; (filerequesters automatically set it back)
	ld a,18
	sub b
	ld b,a				; set x coordinate
	ld c,9				; set y coordinate
	pop af
	call draw_window			; A=0: notice box, A=1:OK box
	ret
	
	
input_requester
	
	ld (al_txtadr),hl
	ld hl,my_edit_windows
	ld (w_list_loc),hl			; tell windows code to use this window description list
	ld bc,$0a09			; (filerequesters automatically set it back)
	call draw_window			; A=0: confirm, A=1:OK box

	call w_get_selected_element_coords
	call kjt_set_cursor_position
	call w_get_selected_element_data_location
	ld a,(ix+1)				; max input chars (FLOS <592 doesnt support this)
	call kjt_get_input_string
	ld b,0
	ld c,a
	or a
	jr z,input_aborted
	ld de,input_txt
	ldir
	xor a
	ld (de),a
	ret

input_aborted
	
	xor a
	inc a
	ret
	
;--------------------------------------------------------------------------------------------------------------------

get_string_length

	push hl
	ld b,0
fsl_lp	ld a,(hl)
	or a
	jr z,fsl_done
	inc hl
	inc b
	jr nz,fsl_lp
fsl_done	ld a,b
	pop hl
	ret
	
		
;-----------------------------------------------------------------------------------------------------------------

loading_txt	db "Loading..",0

saving_txt	db "Saving..",0

quit_req_txt	db "Confirm Quit (y/n)",0

fl_zero_txt	db "Nothing to save!",0

file_too_big_txt	db "File Is Too Big!",0

goto_too_big_txt	db "Line Out Of Range!",0

load_req_txt	db "Lose current file? (y/n)",0

goto_line_txt	db " Go To Line?",0

;------------------------------------------------------------------------------------------------------------------


store_charmap

	call kjt_get_cursor_position
	ld (original_cursor_pos),bc
	call kjt_get_pen
	ld (original_pen),a
	
	call kjt_get_display_size		;restore the original FLOS charmap
	push bc
	pop de
	
	ld ix,work_buffer
	ld c,0
stdsp2	ld b,0
stdsp1	push ix
	push bc
	push de
	call kjt_get_charmap_addr_xy
	pop de
	pop bc
	pop ix
	ld a,(hl)
	ld (ix),a
	inc ix
	inc b
	ld a,b
	cp d
	jr nz,stdsp1
	inc c
	ld a,c
	cp e
	jr nz,stdsp2
	
	ld a,1
	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld hl,work_buffer
	ld de,$2000
	ld bc,8192
	ldir
	call kjt_page_out_video
	ret


	
restore_charmap

	ld a,1
	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld hl,$2000
	ld de,work_buffer
	ld bc,8192
	ldir
	call kjt_page_out_video
	
	call kjt_get_display_size		
	push bc
	pop de
	
	ld hl,work_buffer
	ld c,0
rstdsp2	ld b,0
rstdsp1	call kjt_set_cursor_position
	ld a,(hl)
	call kjt_plot_char
	inc hl
	inc b
	ld a,b
	cp d
	jr nz,rstdsp1
	inc c
	ld a,c
	cp e
	jr nz,rstdsp2
	
	ld bc,(original_cursor_pos)
	call kjt_set_cursor_position
	ld a,(original_pen)
	call kjt_set_pen
	ret

original_cursor_pos dw 0
original_pen	db 0

;------------------------------------------------------------------------------------------------------------------


my_edit_windows

	dw confirm_window	;alternative set of windows (separate from file requesters)
	dw warn_window	
	dw input_window
	
confirm_window

	db 0,0		;position (filled by draw routine)
conf_wins	db 30,3		;size
	db 1		;current active element
	db 0		;not used at present
	db 1,1		;element 1 coords (text box)
	dw element_alert_tb
	db 255		;end of elements list for this window
		
warn_window

	db 0,0		;position (filled by draw routine)
warn_wins	db 30,6		;size
	db 1		;current active element
	db 0		;not used at present
	db 1,1		;element 1 coords (text box)
	dw element_alert_tb
warn_bloc	db 14,4		;element 2 coords (ok button)
	dw element_ok_but
	db 255		;end of elements list for this window

input_window

	db 0,0		;position (filled by draw routine)
	db 15,5		;size
	db 1		;current active element
	db 0		;not used at present
	db 1,1		;element 1 coords (textinfo box)
	dw element_alert_tb
	db 4,3		;element 2 coords (ok box)
	dw element_input
	db 255		;end of elements list for this window



element_alert_tb
	
	db 2		;0 = Element Type: 2 = Info text
	db 28,1		;1/2 = dimensions of element x,y
	db 0		;3 = control bits
	db 0		;4 = event flag (unused)
al_txtadr	dw 0		;5/6 = address of associated_data (filled in by call)



element_ok_but

	db 0		;0 = Element Type: 0 = A button
	db 2,1		;1/2 = dimensions of element x,y
	db 1		;3 = control bits
	db 0		;4 = event flag (currently unused)
	dw ok_txt		;5/6 = location of associated data

ok_txt	db "OK",0		;The ASCII that goes in the button	



element_input

	db 1		;Element type 1 = data area 
	db 6,1		;dimensions
	db 0		;ctrl bits
	db 0		;event
	dw input_txt	;location of associated data


;--------------------------------------------------------------------------------------------------------------

input_txt	ds 40,0

;--------------------------------------------------------------------------------------------------------------
