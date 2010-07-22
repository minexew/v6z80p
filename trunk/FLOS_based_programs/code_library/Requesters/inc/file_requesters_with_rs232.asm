;--------------------------------------------------------------------------------
; Library Code: FLOS File Requestors with RS232 RX/TX v0.03 By Phil Ruston
;--------------------------------------------------------------------------------
;
; Changes:
; --------
; 0.03 -  Added automatic "File not found" requester - disk load performs "kjt_find_file" on exit.
;         Added re-mount drives option to disk h/w error requester
;         Fixed error code reporting - Now standard FLOS KJT (ZF/A/B) No carry flag tests! 
; 0.02 -  Added file error requesters.
;
;
; Routine list:
; -------------
;
; "load_requester"
; "save_requester"
; "file_error_requester"
; "hw_error_requester"
;
;----------------------------------------------------------------------------------
;
;
; LOAD_REQUESTER DETAILS
; ----------------------
;
; When calling "load_requester" Set:
;
;    HL : The location of a 0-terminated filename (or 0 if not supplied)
;    B  : Desired x coordinate of the requester (in characters from left)
;    C  : Desired y coordinate of the requester (in characters from top)
;
; ...then call "load_requester" which invokes the requester...
;
; When control is returned to the host program, the following registers are set up:
; 
;   Zero Flag: If set, the requester operation encountered no errors. In this case:
;
;              A =  $00 : Ready to load file from disk, IX:IY = Length of file. 
;                         HL = Address of selected filename. 
;
;   Zero Flag: Not set, in this case:
; 
;              A = $FF  User aborted file load - EG: Pressed Escape or Cancel
;
;              A = $FE (Requester with RS232 button only) All OK - ready to load file serially:
;                      IX will be pointing to the file header:
;                      IX+$00 = Filename ASCII 
;                      IX+$10 = Length of file (low word)
;                      IX+$12 = Length of file (high word)
;                 Note that serial loads accept the header of ANY file offered, it is
;                 up to the user's program to examine the filename in the header (if it
;                 cares what it is.)
;       
;              A = $xx : Any other value: A standard FLOS error code. If A = 0,
;                        there was a disk hardware error during requester activity.
;                        (This can be reported with the call "hw_error_requester")
;                        Other errors (file system related) can be reported with
;                        the call "file_error_requester" if required)
;
;----------------------------------------------------------------------------------
;
; SAVE_REQUESTER DETAILS
; ----------------------
;
; When calling "save_requester" Set:
;
;
;    HL : The location of a 0-terminated filename (or 0 if not supplied)
;    B  : Desired x coordinate of the requester (in characters from left)
;    C  : Desired y coordinate of the requester (in characters from top)
;
; ...then call "load_requester" which invokes the requester...
;
; When control is returned to the host program, the following registers are set up:
; 
;   Zero Flag: If set, the requester operation encountered no errors. In this case:
;
;              A =  $00 : Ready to load file from disk, IX:IY = Length of file. 
;                         HL = Address of selected filename. 
;
;   Zero Flag: Not set, in this case:
; 
;              A = $FF  User aborted file load - EG: Pressed Escape or Cancel
;
;              A = $FE (Requester with RS232 button only) All OK - ready to load file serially:
;                      IX will be pointing to the file header:
;                      IX+$00 = Filename ASCII 
;                      IX+$10 = Length of file (low word)
;                      IX+$12 = Length of file (high word)
;                 Note that serial loads accept the header of ANY file offered, it is
;                 up to the user's program to examine the filename in the header (if it
;                 cares what it is.)
;       
;              A = $xx : Any other value: A standard FLOS error code. If A = 0,
;                        there was a disk hardware error during requester activity.
;                        (This can be reported with the call "hw_error_requester")
;                        Other errors (file system related) can be reported with
;                        the call "file_error_requester" if required)
;
;----------------------------------------------------------------------------------
;
; "FILE_ERROR_REQUESTER" DETAILS
; ------------------------------
;
; Set:
;
;   A = file error code (shown as hex byte in requester)
;   There are no output registers.
;   Window will be located centrally based on Load/Save requester coordinates
;
;----------------------------------------------------------------------------------
;
; "HW_ERROR_REQUESTER" DETAILS
; ----------------------------
;
;   No input / No output registers.
;   Window will be located centrally based on Load/Save requester coordinates
;
;----------------------------------------------------------------------------------


	include "window_draw_routines.asm"
	include "window_support_routines.asm"

;--------------------------------------------------------------------------

load_requester

	xor a				; window number 0 = load requester
	jr req_tlsetup
	
save_requester

	ld a,1				; window number 1 = save requester
	
req_tlsetup

	ld (req_top_level_window_number),a
	ld (req_top_level_window_coords),bc

	push af
	push bc
	ld c,6				; default element selection (load/save button)
	ld a,h				
	or l				; was a filename supplied?
	jr nz,req_usfn
	ld hl,req_filename+16		
	ld c,3				; if no filename, default element is dir window
req_usfn	ld de,req_filename
	ld b,12
srq_cfnlp	ld a,32
	ld (de),a
	ld a,(hl)
	or a
	jr z,srq_sknfc
	ld (de),a
	inc hl
srq_sknfc	inc de
	djnz srq_cfnlp	
	ld e,c
	pop bc
	pop af
	call req_draw_requester

	
srq_fncpd	ld a,1
	call w_get_element_a_coords
	call kjt_set_cursor_position
	call kjt_get_dir_name				
	ret nz
	call kjt_print_string		; show current dir name

	call req_fill_in_filename
	
	xor a			
	ld (req_dir_line_selection),a		; zero initial directory selection line
	ld (req_eodf),a			; zero end of dir flag
	ld (req_rs232_waiting),a
	ld h,a
	ld l,a
	ld (req_dlp),hl			; zero dir line position
	call req_show_dir_page

	
;--------------------------------------------------------------------------------


req_loop	call req_show_selection
	call req_show_cursor
		
	ld hl,vreg_read
wait_ras1	bit 2,(hl)
	jr z,wait_ras1
wait_ras2	bit 2,(hl)
	jr nz,wait_ras2

	call req_unshow_selection
	ld hl,0
	call kjt_draw_cursor

	call kjt_get_key
	ld (req_current_scancode),a
	ld c,a
	ld a,b
	ld (req_current_ascii_char),a
	ld a,c
	cp $0d
	jp z,req_tab_pressed
	cp $72
	jp z,req_down_pressed
	cp $75
	jp z,req_up_pressed
	cp $66
	jp z,req_backspace_pressed
	cp $5a
	jp z,req_enter_pressed
	cp $76
	jr z,req_esc_pressed
	ld a,(req_current_ascii_char)
	or a
	jp nz,req_ascii_input
	
	ld a,(req_rs232_waiting)
	or a
	jp nz,req_rs232_header_wait
	
	jp req_loop
	
;----------------------------------------------------------------------------------------------	

req_esc_pressed
	
	ld a,(w_active_window)
	cp 2
	jp z,req_redsr			;"make new dir" aborted
	cp 3
	jp z,req_redsr			;"dir already exists" window active
	cp 4
	jp z,req_redsr			;"file already exists" window active
	cp 5
	jp z,req_redsr			; rs232 load active
	cp 6
	jp z,req_redsr			; rs232 save active
	cp 9				
	jp z,req_redsr			;"file not found" window active
	
req_aborted

	xor a				;"load" / "save" aborted, exist with A = $FF
	dec a				;and zero flag clear
	ret

;------------------------------------------------------------------------------------------------

req_rs232_exit

	ld hl,req_filename
	ld a,$fe
	or a
	ret
	
;----------------------------------------------------------------------------------------------

req_exit_ok

	ld hl,req_filename
	xor a
	ret
			
;----------------------------------------------------------------------------------------------


req_tab_pressed

	xor a
	ld (req_ascii_input_mode),a
	call w_next_selectable_element
	jp req_loop


;----------------------------------------------------------------------------------------------


req_down_pressed

	call w_get_element_selection
	cp 3				;cant move highlight if not in dir window
	jr nz,req_dpok
	
	call w_get_selected_element_data_location
	ld b,(ix+2)			; b = lines in element (text window)
	dec b
	ld hl,req_dir_line_selection		;can only scroll down..
	ld a,(hl)
	cp b				;if selection line is at the bottom of text area
	jr z,req_sdd
	inc (hl)
	jr req_dpok
	
req_sdd	ld a,(req_eodf)			;move down directory list (if not already at end)
	or a
	jr nz,req_dpok
	ld hl,(req_dlp)
	inc hl
	ld (req_dlp),hl
	call req_show_dir_page
req_dpok	jp req_loop


;----------------------------------------------------------------------------------------------

req_up_pressed

	call w_get_element_selection
	cp 3				;cant move highlight if not in dir window
	jr nz,req_dpok

	ld hl,req_dir_line_selection		;can only scroll up if selection line
	ld a,(hl)				;is at the top
	or a			
	jr z,req_sdu
	dec (hl)
	jr req_pdok
	
req_sdu	ld hl,(req_dlp)			;move up the dir list (if not already at 0)
	ld a,h
	or l
	jr z,req_pdok
	dec hl
	ld (req_dlp),hl
	xor a
	ld (req_eodf),a
	call req_show_dir_page
req_pdok	jp req_loop


;----------------------------------------------------------------------------------------------

req_ascii_input

	call w_get_selected_element_data_location
	bit 2,(ix+3)			;does element allow ascii input?
	jr z,req_nai
	
	ld a,(req_ascii_input_mode)		;already entering text?		
	or a
	call z,req_set_ascii_input_mode	;if not set up the input line
	ld a,(req_ti_cursor)		
	cp (ix+1)				;cant enter more text if at end of line
	jr z,req_nai
	call req_ascii_cursor_pos
	ld a,(req_current_ascii_char)
	cp $60				;Entered text converted to capitals
	jr c,req_loca
	sub $20
req_loca	call kjt_plot_char
	ld hl,req_ti_cursor			;advance cursor
	inc (hl)
req_nai	jp req_loop
	
	
	
req_set_ascii_input_mode

	xor a				;put the cursor at zero and
	ld (req_ti_cursor),a		;clear the text input line.
	inc a				
	ld (req_ascii_input_mode),a
	call w_get_selected_element_coords
	call w_get_selected_element_data_location
	ld e,(ix+1)			;width of line
req_ctilp	ld a,32
	call kjt_plot_char			
	inc b
	dec e
	jr nz,req_ctilp
	ret		



req_ascii_cursor_pos

	call w_get_selected_element_coords
	ld a,(req_ti_cursor)
	add a,b
	ld b,a
	ret
	
	
;----------------------------------------------------------------------------------------------


req_backspace_pressed


	ld a,(req_ascii_input_mode)		;dont do anything if not in ascii input mode
	or a
	jr z,req_nbs
	
	ld a,(req_ti_cursor)		;cant move back if cursor at 0
	or a
	jr z,req_nbs
		
	ld hl,req_ti_cursor			;move back and put a space at current location
	dec (hl)
req_dmcb	call req_ascii_cursor_pos
	ld a,32
	call kjt_plot_char
req_nbs	jp req_loop


;----------------------------------------------------------------------------------------------


req_enter_pressed

	ld a,(w_active_window)		;which window was active when Enter pressed?
	or a
	jr z,req_lsact			;0 = load window?
	cp 1
	jr z,req_lsact			;1 = save window?
	cp 2
	jp z,req_ndact			;2 = new dir window?
	cp 3
	jp z,req_makenewdir			;3 = dir name already exists window?
	cp 4
	jp z,req_fae			;4 = file already exists window?
	cp 5
	jp z,req_redsr			;5 = rs232 load active - cancel button pressed
	cp 6
	jp z,req_rs232save			;6 = rs232 save active - save/cancel button pressed
	cp 9
	jp z,req_redsr
	jp req_loop

	
req_lsact	call w_get_element_selection
	cp 2				;pressed Enter on which element
	jr z,req_makenewdir			;in the load/save requester?
	cp 3
	jr z,req_chdir
	cp 5
	jp z,req_asciifn
	cp 6
	jp z,req_copyfn_and_exit
	cp 7
	jp z,req_rx_tx			;pop up the RS232 window
	cp 8
	jp z,req_aborted
	jp req_loop



req_ndact

	call w_get_selected_element_coords
	call kjt_get_charmap_addr_xy		; make new dir 
	ld de,req_dir_name			; copy line to dir filename buffer	
	push de
	ld bc,8
	ldir
	pop hl
	call kjt_make_dir
	jr z,req_redsr	
	cp 9				;if error 9, dir already exists
	ret nz	
req_faew	ld bc,(req_top_level_window_coords)	
	ld a,b
	add a,6
	ld b,a
	ld a,c
	add a,5
	ld c,a
	ld e,1				; gadget selection = 1
	ld a,3				; show dir already exists window
	call req_draw_requester
	jp req_loop



req_makenewdir
	
	ld bc,(req_top_level_window_coords)
	ld a,b
	add a,6
	ld b,a
	ld a,c
	add a,5
	ld c,a
	ld e,1				; set element selection = 1
	ld a,2				; set new dir name window active
	call req_draw_requester
	ld a,1			
	ld (req_ascii_input_mode),a		; force text input mode on at start
	xor a
	ld (req_ti_cursor),a	
	jp req_loop



req_chdir	
	
	call w_get_selected_element_coords	; Pressed enter in dir box...
	ld a,(req_dir_line_selection)		
	add a,c
	ld c,a
	call kjt_get_charmap_addr_xy	
	push hl
	pop ix
	ld a,(ix+20)
	cp 32				; if there's not a space at end of selection line, its a file
	jr nz,req_pesf
	ld a,(hl)
	cp "."				; is this a parent dir entry?
	jr nz,req_npdir
	call kjt_parent_dir
	ret nz
	jr req_redsr
	
req_npdir	ld de,req_dir_name			; copy line to dir filename buffer and change dir		
	push de
	ld bc,12
	ldir
	pop hl
	call kjt_change_dir
	ret nz
req_redsr	ld bc,(req_top_level_window_coords)	
	ld e,3				; set element selection = dir box
	ld a,(req_top_level_window_number)		
	call req_draw_requester		; redraw the requester
	jp srq_fncpd

req_pesf	push ix				; copy charmap chars at selection to filename
	pop hl
	call req_copy_filename
	call req_fill_in_filename
	
req_losav	ld a,(w_active_window)		; if the *load* requester is active, check file
	or a				; exists before exit.
	jr nz,req_save			; 
	ld hl,req_filename			
	call kjt_find_file
	jp z,req_exit_ok
	cp $02				; if doesnt exist or is a dir, show fnf requester
	jr z,req_fnf
	cp $06				; if a dir name, also say file not found, else exit with error
	ret nz
req_fnf	ld bc,(req_top_level_window_coords)
	ld a,b				; retrieve x coord of save requester
	add a,3				; add on centered offset
	ld b,a
	ld a,c				; retrieve y coord "" ""
	add a,6				; add on centered offset
	ld c,a
	ld e,1				; set gadget selection = 0
	ld a,9			
	call req_draw_requester		; show "file not found" window
	jp req_loop	
	
		
req_save	ld hl,req_filename			; does file already exist?
	call kjt_find_file	
	jr z,req_sfe			; if found ok, file exists ask to overwrite	
	cp 2
	jp z,req_exit_ok			; if error 2: file not found, its OK to save
	cp 6
	jp z,req_faew			; if error 6: filename is used by a directory
	ret
	
req_sfe	ld bc,(req_top_level_window_coords)
	ld a,b				; retrieve x coord of save requester
	add a,5				; add on centered offset
	ld b,a
	ld a,c				; retrieve y coord "" ""
	add a,5				; add on centered offset
	ld c,a
	ld e,1				; set gadget selection = 0
	ld a,4			
	call req_draw_requester		; show "file already exists" window
	jp req_loop



req_fae	
	call w_get_element_selection		; file exists requester
	cp 2
	jr z,req_redsr			; if pressed Enter on "NO", go back to load/save requester
	ld hl,req_filename	
	call kjt_erase_file			; if pressed Enter on "OK", delete existing file and
	ret nz
	jp req_exit_ok




req_asciifn

	ld a,(req_ascii_input_mode)
	xor 1
	ld (req_ascii_input_mode),a
	jr nz,req_gotim			
	call w_get_selected_element_coords 	; if pressed enter after entering text, copy
	jr req_rdytx

req_gotim	call req_set_ascii_input_mode
	jp req_loop			; otherwise clear line and go input mode




req_copyfn_and_exit

	ld a,5
	call w_get_element_a_coords
req_rdytx	call kjt_get_charmap_addr_xy		; copy text from filename box to filename and save
	call req_copy_filename
	jp req_losav
	



req_rs232save

	call w_get_element_selection		;if element 2 was active, save via rs232
	cp 2				;else go back to main requester
	jp nz,req_redsr			
	call req_rs232_say_sending
	jp req_rs232_exit			


	
req_rx_tx

	ld a,5
	call w_get_element_a_coords
	call kjt_get_charmap_addr_xy		; copy text from filename box to filename
	call req_copy_filename

	ld a,(w_active_window)		; if saving via rs232 go to apt section
	cp 1
	jr z,req_show_tx

	ld bc,(req_top_level_window_coords)
	ld a,b				; retrieve x coord of load requester
	add a,3				; add on centered offset
	ld b,a
	ld a,c				; retrieve y coord "" ""
	add a,5				; add on centered offset
	ld c,a
	ld e,2				; set gadget selection = 0
	ld a,5			
	call req_draw_requester		; show "rs232 receive" window
	call req_rs232_say_waiting
	ld a,1
	ld (req_rs232_waiting),a
	
req_rs232_header_wait

	ld hl,req_any_filename_txt		; filename address of * wildcard
	ld a,1				; time out = 1 second
	call kjt_serial_receive_header
	jr nz,req_rs232_nogo		; file header loaded ok?
	call req_rs232_say_receiving
	jp req_rs232_exit	

req_rs232_nogo
	
	cp $14				; only a time-out error?
	jp z,req_loop
	call req_rs232_say_error
	xor a
	ld (req_rs232_waiting),a
	jp req_loop


	
	
req_show_tx


	ld bc,(req_top_level_window_coords)
	ld a,b				; retrieve x coord of load requester
	add a,3				; add on centered offset
	ld b,a
	ld a,c				; retrieve y coord "" ""
	add a,5				; add on centered offset
	ld c,a
	ld e,2				; set gadget selection = 0
	ld a,6			
	call req_draw_requester		; show "rs232 send" window
	call req_rs232_say_waiting
	jp req_loop

;----------------------------------------------------------------------------------------------

req_rs232_say_waiting

	ld a,1
	ld hl,req_waiting_txt
	call req_put_text_at_element
	ret

req_rs232_say_sending

	ld a,1
	ld hl,req_sending_txt
	call req_put_text_at_element
	ret
	
req_rs232_say_receiving

	ld a,1
	ld hl,req_receiving_txt
	call req_put_text_at_element
	ret
	
req_rs232_say_error

	ld a,1
	ld hl,req_serial_error_txt
	call req_put_text_at_element
	ret
				
;----------------------------------------------------------------------------------------------

req_copy_filename

	ld de,req_filename
	ld bc,12
	ldir
	ret

;---------------------------------------------------------------------------------------------

req_fill_in_filename

	ld a,5
	ld hl,req_filename
	call req_put_text_at_element		; show filename
	ret

;----------------------------------------------------------------------------------------------

req_put_text_at_element

	call w_get_element_a_coords
	call kjt_set_cursor_position
	call kjt_print_string		
	ret
			
;----------------------------------------------------------------------------------------------

req_show_dir_page
	
	call kjt_dir_list_first_entry		; find starting point in dir list
	ret nz
	ld hl,(req_dlp)			; skip "HL" entries
req_fdsp	ld a,h
	or l
	jr z,req_dsp
	dec hl
	push hl
	call kjt_dir_list_next_entry
	jp nz,req_dlhe
	pop hl
	jr req_fdsp
	
req_dsp	ld a,3
	call w_get_element_a_data_location
	ld b,(ix+2)			; b = lines in element (text window)
	ld c,0				; line offset
req_fdplp	ld e,c
	push bc			
	ld a,3
	call w_get_element_a_coords
	ld a,e
	add a,c
	ld c,a
	push bc
	ld a,3
	call w_get_element_a_data_location
	ld e,(ix+1)
req_dirbl	ld a,32				; blank string
	call kjt_plot_char
	inc b
	dec e
	jr nz,req_dirbl
	pop bc
	ld (req_dircurpos),bc
	call kjt_set_cursor_position
	
	ld a,(req_eodf)
	or a
	jr nz,req_neod
	call kjt_dir_list_get_entry
	jr c,req_dlhe
	cp $24				; end of dir?
	jr z,req_lde

	push iy				; push filelength etc
	push ix
	push bc
	call kjt_print_string		; show filename
	pop bc
	ld a,b
	or a
	jr z,req_df
	pop ix
	pop iy
	jr req_denaf
req_df	ld bc,(req_dircurpos)
	ld a,b
	add a,14
	ld b,a
	call kjt_set_cursor_position
	pop de
	ld a,e
	ld hl,req_fn_len+1
	call kjt_hex_byte_to_ascii
	pop de
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	ld hl,req_fn_len
	call kjt_print_string		; show file length
		
req_denaf	call kjt_dir_list_next_entry
	jr z,req_neod			; dir entry advance ok?
	or a
	jr z,req_dlhe
req_lde	ld a,1
	ld (req_eodf),a
req_neod	pop bc
	inc c
	djnz req_fdplp
	
	call kjt_dir_list_get_entry		; check if reached end of dir on last line
	jr z,req_neod2
	or a			
	jr z,req_dlhwe
	ld a,1
	ld (req_eodf),a
req_neod2	xor a				; ZF set = all ok
	ret

req_dlhe	pop bc				; ZF not set, error
req_dlhwe	xor a
	inc a
	ret
	
	
;----------------------------------------------------------------------------------------------
		
req_unshow_selection
	
	ld a,(req_ascii_input_mode)
	or a
	ret nz
	call w_unhighlight_selected_element
	ret
	
req_show_selection

	ld a,(req_ascii_input_mode)
	or a
	ret nz
	ld a,$80				; highlight pen colour
	call w_highlight_selected_element
	ret
	
;----------------------------------------------------------------------------------------------

req_show_cursor

	ld a,(req_ascii_input_mode)
	or a
	ret z
	
	call req_ascii_cursor_pos
	push bc
	call w_get_selected_element_data_location
	pop bc
	ld a,(req_ti_cursor)	
	cp (ix+1)
	jr nz,req_cnmax
	dec b				; keep the cursor at the end of the 
req_cnmax	call kjt_set_cursor_position		; text box if necessary
	ld hl,$c00
	call kjt_draw_cursor
	ret
	
;--------------------------------------------------------------------------------------
	
req_draw_requester	

	call draw_window
	xor a
	ld (req_ascii_input_mode),a
	ld a,e
	call w_set_element_selection
	ret


;======== FILE ERROR REQUESTERS ========================================================

file_error_requester

	push hl
	push de
	push bc
	push af
	ld hl,req_file_ercode_txt
	call kjt_hex_byte_to_ascii
	ld bc,(req_top_level_window_coords)
	ld a,b
	add a,3
	ld b,a
	ld a,c
	add a,5
	ld c,a
	ld a,7
	call draw_window
	ld a,1
	call w_set_element_selection
	jr req_disk_err_loop

hw_error_requester

	push hl
	push de
	push bc
	push af
	ld bc,(req_top_level_window_coords)
	ld a,b
	add a,1
	ld b,a
	ld a,c
	add a,7
	ld c,a
	ld a,8
	call draw_window
	ld a,1
	call w_set_element_selection

req_disk_err_loop

	ld a,$80
	call w_highlight_selected_element
	call kjt_wait_vrt
	call w_unhighlight_selected_element
	call kjt_get_key
	cp $0d
	jr nz,de_notab
	call w_next_selectable_element
	xor a
de_notab	cp $5a
	jr z,req_de_pe			;pressed enter?
	cp $76				
	jr z,req_de_exit			;pressed escape?
	jr req_disk_err_loop

req_de_pe	ld a,(w_active_window)		;is this the hardware error requester?
	cp 8
	jr nz,req_de_exit
	call w_get_element_selection		;was OK pressed?
	cp 1
	call z,kjt_mount_volumes		;if so remount drives
	
req_de_exit
	
	pop af
	pop bc
	pop de
	pop hl
	xor a
	ret		


;------ My Window Descriptions --------------------------------------------------------

window_list	dw win_inf_load		; Window 0
		dw win_inf_save		; Window 1
		dw win_inf_new_dir		; Window 2
		dw win_inf_dir_exists	; Window 3
		dw win_inf_overwrite	; Window 4
		dw win_inf_receive		; Window 5
		dw win_inf_send		; Window 6
		dw win_inf_file_error	; Window 7
		dw win_inf_hw_error		; Window 8
		dw win_fnf_error		; Window 9

;------ Window Info -------------------------------------------------------------------

win_inf_load	db 0,0			;0 - position on screen of frame (x,y) 
		db 23,20			;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		db 1,1			;element 0 (x,y)
		dw win_element_a		;element 0 (address)
		db 5,1
		dw win_element_b		;element 1
		db 19,1
		dw win_element_c		;element 2
		db 1,3
		dw win_element_d		;element 3
		db 1,16
		dw win_element_e		;element 4
		db 10,16
		dw win_element_f		;element 5
		db 1,18
		dw win_element_g		;element 6
		db 7,18
		dw win_element_rs232	;element 7
		db 16,18
		dw win_element_cancel	;element 8
		db 255			;255 = end of list of window elements
		
		
win_inf_save	db 0,0				 
		db 23,20				
		db 0				
		db 0				
		db 1,1			;0
		dw win_element_a				
		db 5,1			;1
		dw win_element_b
		db 19,1			;2
		dw win_element_c
		db 1,3			;3
		dw win_element_d
		db 1,16			;4
		dw win_element_e
		db 10,16			;5
		dw win_element_f
		db 1,18			;6
		dw win_element_i
		db 7,18			;7
		dw win_element_rs232		
		db 16,18			;8
		dw win_element_cancel
		db 255				


win_inf_new_dir	db 0,0
		db 10,7
		db 0
		db 0
		db 1,1
		dw win_element_j
		db 1,5
		dw win_element_k
		db 255


win_inf_dir_exists	db 0,0
		db 10,7
		db 0
		db 0
		db 1,1
		dw win_element_l
		db 4,5
		dw win_element_m
		db 255


win_inf_overwrite	db 0,0
		db 13,7
		db 0
		db 0
		db 1,1
		dw win_element_o
		db 2,5
		dw win_element_m
		db 9,5
		dw win_element_n
		db 255
		
win_inf_receive	db 0,0
		db 18,7
		db 0
		db 0
		db 3,1				;element 0
		dw win_element_rs232rectxt
		db 1,3				;element 1
		dw win_element_rs232_status
		db 6,5				;element 2
		dw win_element_cancel
		db 255


win_inf_send	db 0,0
		db 18,7
		db 0
		db 0
		db 3,1				;element 0
		dw win_element_rs232sendtxt
		db 1,3				;element 1
		dw win_element_rs232_status
		db 2,5				;element 2
		dw win_element_send
		db 11,5				;element 3
		dw win_element_cancel
		db 255


win_inf_file_error	db 0,0				;window for file error  
		db 17,8			
		db 0			
		db 0			
		db 0,0			
		dw win_file_err_elem	
		db 7,6
		dw win_element_m
		db 255			
		
		
win_inf_hw_error	db 0,0				;window for h/w error  
		db 21,5			
		db 0			
		db 0			
		db 1,0			
		dw win_hw_err_elem	
		db 6,3
		dw win_element_m
		db 13,3
		dw win_element_n
		db 255			


win_fnf_error	db 0,0				;window for file not found
		db 17,5
		db 0
		db 0
		db 1,1
		dw win_fnf_msg_elem
		db 7,3
		dw win_element_m
		db 255

;---- Window Elements ---------------------------------------------------------------------

		
win_element_a	db 2			;0 = Element Type: 0=button, 1=data area, 2=display info (text)
		db 3,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=accept ascii input)
		db 0			;4 = event flag
		dw req_dir_txt		;5/6 = location of associated data
		
win_element_b	db 1
		db 12,1
		db 0
		db 0
		
win_element_c	db 0
		db 3,1
		db 1
		db 0
		dw req_new_txt

win_element_d	db 1
		db 21,12
		db 3
		db 0
		dw req_dir_line_selection
		
win_element_e	db 2
		db 8,1
		db 0
		db 0
		dw req_filename_txt

win_element_f	db 1
		db 12,1
		db 5
		db 0
		dw req_filename

win_element_g	db 0
		db 4,1
		db 1
		db 0
		dw req_load_txt

win_element_cancel	db 0
		db 6,1
		db 1
		db 0
		dw req_cancel_txt

win_element_i	db 0
		db 4,1
		db 1
		db 0
		dw req_save_txt

win_element_j	db 2
		db 8,3
		db 0
		db 0
		dw req_new_dir_txt

win_element_k	db 1
		db 8,1
		db 5
		db 0
		dw req_dir_name

win_element_l	db 2
		db 8,4
		db 0
		db 0
		dw req_alr_exists_txt
		
win_element_m	db 0
		db 2,1
		db 1
		db 0
		dw req_ok_txt
		
win_element_n	db 0
		db 2,1
		db 1
		db 0
		dw req_no_txt		

win_element_o	db 2
		db 11,3
		db 0
		db 0
		dw req_overwrite_txt

win_element_rs232	db 0
		db 5,1
		db 1
		db 0
		dw req_rs232_txt
		

win_element_rs232rectxt

		db 2
		db 13,1
		db 0
		db 0
		dw req_rs232rec_txt

win_element_rs232sendtxt

		db 2
		db 13,1
		db 0
		db 0
		dw req_rs232send_txt

		
win_element_rs232_status

		db 1
		db 16,1
		db 0
		db 0
		dw req_waiting_txt


win_element_send	db 0
		db 4,1
		db 1
		db 0
		dw req_send_txt
	

win_file_err_elem	db 2			
		db 17,5			
		db 0			
		db 0			
		dw req_file_err_txt	
		

win_hw_err_elem	db 2			
		db 20,2			
		db 0			
		db 0			
		dw req_hw_err_txt


win_fnf_msg_elem	db 2
		db 17,5
		db 0
		db 0
		dw req_fnf_err_txt
						
		
req_dir_txt	db "DIR",0
req_new_txt	db "NEW",0
req_filename_txt	db "FILENAME",0
req_save_txt	db "SAVE",0
req_cancel_txt	db "CANCEL",0
req_load_txt	db "LOAD",0
req_new_dir_txt	db "NEW DIR",11,11," NAME?",0
req_alr_exists_txt	db "ALREADY",11,11," EXISTS!",0
req_ok_txt	db "OK",0
req_no_txt	db "NO",0
req_overwrite_txt	db "FILE EXISTS",11,"OVERWRITE ?",0
req_rs232_txt	db "RS232",0
req_rs232rec_txt	db "RS232 RECEIVE",0
req_rs232send_txt	db "RS232 SEND",0
req_send_txt	db "SEND",0

req_file_err_txt	db "   File Error!",11,11," The File System",11," Returned Error",11,"    Code:$"
req_file_ercode_txt	db "xx",0

req_hw_err_txt	db "Hardware Disk Error   Remount Drives?",0

req_fnf_err_txt	db "File Not Found!",0

;--------------------------------------------------------------------------------------

req_filename		ds 17,0
req_dir_name		ds 17,0
req_dir_line_selection	db 0
req_eodf			db 0		;end of dir flag
req_dlp			dw 0		;directory line position
req_current_scancode	db 0
req_current_ascii_char	db 0
req_ti_cursor		db 0
req_top_level_window_coords	dw 0
req_top_level_window_number	db 0
req_dircurpos		dw 0
req_fn_len		db "$xxxxxx",0
req_ascii_input_mode	db 0

req_waiting_txt		db "Waiting..",0
req_sending_txt		db "Sending..",0
req_receiving_txt		db "Receiving..",0
req_serial_error_txt	db "Header error!",0

req_any_filename_txt	db "*",0
req_rs232_waiting		db 0

;--------------------------------------------------------------------------------------
			
