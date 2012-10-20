;------------------------------------------------------------------------------
; Window support routines v0.11 - by Phil Ruston, last updated: 27-9-2012
;------------------------------------------------------------------------------
;
; TAB SIZE = 10
;
; These routines support the "Window_draw.asm" code, providing a framework of
; standard routines to operate simple window / requester functions.
;
; Routine list:
; -------------
;
; W_LOCATE_ACTIVE_WINDOW
; 
;   HL returns the address of window description for the active (last drawn) window 
;
; 
; W_LOCATE_WINDOW_A
;
;   HL returns the address of window description for window number in A
;
;			
; W_GET_ACTIVE_WINDOW_COORDS
;
;   BC returns coordinates of active (last drawn) window
;
;
; W_GET_WINDOW_A_COORDS
;
;   BC returns coordinates of window number in A
;
;
; W_GET_ELEMENT_SELECTION
;
;   A returns the number of the selected element in the active window
;
;
; W_SET_ELEMENT_SELECTION
;
;   A sets the element selection of the active window
;
;
; W_GET_SELECTED_ELEMENT_COORDS
;
;   BC returns the coords of the selected element in the active window
;
; 
; W_GET_ELEMENT_A_COORDS
;
;   BC returns the top left coords of element in A of the active window
;
;
; W_GET_SELECTED_ELEMENT_ADDRESS
;
;   HL returns the address in the window description of the selected element
;   in the active window (IE: the address of the group "x,y,element_address")
;
;
; W_GET_ELEMENT_A_ADDRESS
;
;   HL returns the address in the window description of element A in the active
;   window (IE: the address of the group "x,y,element_address")
;
;
; W_GET_SELECTED_ELEMENT_DATA_LOCATION
;
;   IX returns the location of the selected element itself in the active window
;   (IE: The address of the group "element_type,dimensions,flags" etc)
;
;
; W_GET_ELEMENT_A_DATA_LOCATION
;
;   IX returns the location of element A itself in the active window
;   (IE: The address of the group "element_type,dimensions,flags" etc)
;
;
; W_HIGHLIGHT_SELECTED_ELEMENT
;
;   Highlights the selected element in the active window with pen colour in A
;   If an element is the special line-by-line selection bit set, the a single
;   line will be highlighted, the y offset is taken from teh associated variable location.
;
;
; W_UNHIGHLIGHT_SELECTED_ELEMENT
;
;   Removes the highlight from the selected element
;
;
; W_NEXT_SELECTABLE_ELEMENT
;
;   Moves the element selection on top the next selectable element (and wraps around
;   if necessary)
;
;
; W_ASCII_TO_ASSOCIATED_DATA
;
;   Copies an ASCII string (source=HL) to the currently selected element's associated
;   data area. Stops on encountering null char ($00) (or width of element filled).
;
;
; W_SHOW_ASSOCIATED_TEXT
;
;   Updates the display with the "associated data" text string for the currently selected
;   element.
;
;
; W_GET_ASSOCIATED_DATA_LOCATION
;
;  Put address of the currently selected element's "associated data" in HL. If
;  Zero flag is set on return, the element has no associated data.

;------------------------------------------------------------------------------
; ALL REGISTERS NOT INVOLVED IN PASSING INFO TO/FROM ROUTINES ARE PRESERVED
;------------------------------------------------------------------------------

w_locate_active_window
	
	push af
	ld a,(w_active_window)		;HL returns address of active window description
	call w_locate_window_a
	pop af
	ret
		
w_locate_window_a

	push af
w_law	sla a				;HL returns "" window [A] 
	push de
	ld e,a
	ld d,0
	ld hl,(w_list_loc)
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	pop af
	ret

;------------------------------------------------------------------------------------

w_get_active_window_coords

	push af
	ld a,(w_active_window)		;returns coords of active window in B,C
	call w_get_window_a_coords
	pop af
	ret
	
w_get_window_a_coords
	
	push hl				;returns coords of window [A] in B,C
	call w_locate_window_a
	ld b,(hl)
	inc hl
	ld c,(hl)
	pop hl
	ret
	
;-----------------------------------------------------------------------------------

w_get_element_selection

	push hl				;A returns selected element of active window
	call w_locate_active_window	
	push de
	ld de,4
	add hl,de
	pop de
	ld a,(hl)
	pop hl
	ret

;-----------------------------------------------------------------------------------

w_set_element_selection

	push hl				;A = set the element selection of current active window
	push de			
	push af
	call w_locate_active_window
	ld de,4
	add hl,de
	pop af
	ld (hl),a
	pop de
	pop hl
	ret

;---------------------------------------------------------------------------------

w_get_selected_element_coords
	
	push hl				;B,C return coordinates of the top left position
	call w_get_selected_element_address	;of the selected element in active window
	jr w_gesec
	
w_get_element_a_coords
	
	push hl
	call w_get_element_a_address		;B,C "" of element A in active window 
w_gesec	call w_get_active_window_coords	
	push af				;NOTE: THIS DOES NOT OFFSET THE COORDINATES
	ld a,b				;FOR SPECIAL SELECTION LINE MODE. IT ALWAYS
	add a,(hl)			;RETURNS THE TOP LEFT COORDS OF THE ELEMENT
	inc a
	ld b,a
	inc hl
	ld a,c
	add a,(hl)
	inc a
	ld c,a
	pop af
	pop hl
	ret


;-------------------------------------------------------------------------------------

w_get_selected_element_address	
	
	call w_get_element_selection		;HL returns address in active window list of the
					;selected element info group (x,y,location)	

w_get_element_a_address

	call w_locate_active_window		;HL returns "" of element A (x,y,location)	
	push af
	sla a
	sla a
	push de
	ld e,a
	ld d,0
	add hl,de
	ld e,6
	add hl,de
	pop de
	pop af
	ret

	
;---------------------------------------------------------------------------------

w_get_selected_element_data_location	

	push hl
	call w_get_selected_element_address	;IX returns address of the currently selected
	jr w_gedl				;element of active window

w_get_element_a_data_location

	push hl				;IX returns "" of element in A		
w_gedl	call w_get_element_a_address
	inc hl
	inc hl
	push de
	ld e,(hl)
	inc hl
	ld d,(hl)
	push de
	pop ix
	pop de
	pop hl
	ret
	

;---------------------------------------------------------------------------------

w_unhighlight_selected_element

	ld a,(w_norm_pen)

w_highlight_selected_element

	call kjt_set_pen

	call w_get_selected_element_data_location
	call w_get_selected_element_coords
	bit 0,(ix+3)			;is this element selectable?
	ret z
	bit 1,(ix+3)			;is this special selection type (one line at a time)?
	jr z,w_nspsel
	ld l,(ix+5)			;if so use the associated data variable as an
	ld h,(ix+6)			;index to offset the selection point and only
	ld a,c				;highlight one line
	add a,(hl)
	ld c,a
	ld d,1
	jr w_hlp2
w_nspsel	ld d,(ix+2)			;y size
w_hlp2	ld e,(ix+1)			;x size
w_hlp1	call kjt_get_charmap_addr_xy
	ld a,(hl)
	call kjt_plot_char
	inc b
	dec e
	jr nz,w_hlp1
	ld a,b
	sub (ix+1)
	ld b,a
	inc c
	dec d
	jr nz,w_hlp2

	ld a,(w_norm_pen)
	call kjt_set_pen
	ret
	
 
;----------------------------------------------------------------------------------

w_next_selectable_element
	
	ld d,2				;move to next selectable element
w_nesinc	call w_get_element_selection		;if no elements are selectable exit
w_nsel	inc a
	call w_set_element_selection	
	call w_get_selected_element_address		
	ld a,(hl)				;if x coord = 255, this is the last element
	cp $ff				;in the window. 
	jr nz,w_nsene
	dec d				;make sure we dont get stuck in a loop
	jr nz,w_nsel			;if no elements are selectable
	xor a
	call w_set_element_selection
	ret
	
w_nsene	call w_get_selected_element_data_location
	bit 0,(ix+3)			;is this element selectable?
	jr z,w_nesinc
	ret
	
;----------------------------------------------------------------------------------


w_ascii_to_associated_data
	
	call w_get_selected_element_data_location	;Set HL to source
	ld e,(ix+5)			
	ld d,(ix+6)				;DE = location of associated data
	ld a,d
	or e
	ret z

	push de
	ld b,(ix+1)				;width of element
	ld a," "
w_fadws	ld (de),a					;fill associated data area with spaces
	inc de
	djnz w_fadws
	pop de
	
	ld b,(ix+1)				;width of element
w_atadlp	ld a,(hl)
	or a
	ret z					;terminate if encounter null 
	ld (de),a
	inc hl
	inc de
	djnz w_atadlp
	ret
	
;----------------------------------------------------------------------------------


w_show_associated_text

	call w_get_selected_element_data_location
	call w_get_selected_element_coords 
	call kjt_get_charmap_addr_xy
	ld l,(ix+5)
	ld h,(ix+6)
	ld e,(ix+1)
w_satlp	ld a,(hl)
	bit 4,(ix+3)				;is gadget a textbox? If so swap 0/1 to space or tick char
	call nz,w_01_to_space_tick
	call kjt_plot_char
	inc hl
	inc b
	dec e
	jr nz,w_satlp
	ret
	
;----------------------------------------------------------------------------------

w_get_associated_data_location

	call w_get_selected_element_data_location
	ld l,(ix+5)
	ld h,(ix+6)
	ld a,h
	or l
	ret
	
;----------------------------------------------------------------------------------