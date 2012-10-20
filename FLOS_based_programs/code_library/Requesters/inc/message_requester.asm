;--------------------------------------------------------------------------------
; Library Code: FLOS Message Requestor v0.01 - By Phil Ruston
;---------------------------------------------------------------------------------
;
; SOURCE TAB SIZE = 10
;
; Routine list:
; -------------
;
; "message_requester"
;
;
; Before calling "message_requester" set..
; ----------------------------------------
;
;   B  = X coordinate of requester (in chars from top left)
;   C  = Y coordinate of requester (in chars from top left)
;   D  = X Dimension of message area of requester (in chars)
;   E  = Y Dimension of message area of requester (in chars)
;   HL = Address of text for requester
;
; Upon return, the following registers are set..
; ----------------------------------------------
;
;   A = 0.
;
;--------------------------------------------------------------------------

	include "flos_based_programs\code_library\window_routines\inc\window_draw_routines.asm"	; comment these lines out if
	include "flos_based_programs\code_library\window_routines\inc\window_support_routines.asm"	; any other code includes them

;--------------------------------------------------------------------------

message_requester

	ld ix,win_inf_message
	ld iy,win_msg_element_a
	ld (iy+1),d			;set dims of text area
	ld (iy+2),e
	ld (iy+5),l			;set location of text to display in window
	ld (iy+6),h
	ld a,e	
	inc e				;add y lines for OK button			
	inc e
	inc e
	ld (ix+2),d			;set dims of window frame
	ld (ix+3),e
	ld e,a
	srl d
	dec d
	ld (ix+10),d			;set location of OK button based on dims
	inc e
	ld (ix+11),e
	xor a
	call draw_window
	ld a,1
	call w_set_element_selection
	
;--------------------------------------------------------------------------------


mreq_loop	ld a,$80
	call w_highlight_selected_element
	call kjt_wait_vrt
	call w_unhighlight_selected_element

	call kjt_get_key
	cp $5a
	jp z,mreq_enter_pressed
	cp $76
	jr z,mreq_esc_pressed
	jr mreq_loop

;----------------------------------------------------------------------------------------------	

mreq_esc_pressed
mreq_enter_pressed

	xor a
	ret
		
		
;------ My Window Descriptions --------------------------------------------------------

window_list	dw win_inf_message		; Window 0

;------ Window Info -------------------------------------------------------------------

win_inf_message	db 0,0			;0 - position on screen of frame (x,y) 
		db 10,10			;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		db 0,0			;6 - position of first element (x,y)
		dw win_msg_element_a	;8 - location of first element description
		db 0,0
		dw win_msg_element_b
		db 255			;255 = end of list of window elements
		

;---- Window Elements ---------------------------------------------------------------------

		
win_msg_element_a	db 2			;0 = Element Type: 0=button, 1=data area, 2=display info (text)
		db 1,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=accept ascii input)
		db 0			;4 = event flag
		dw 0			;5/6 = location of associated data
		
win_msg_element_b	db 0			;OK button
		db 2,1
		db 1
		db 0
		dw req_msg_ok_txt

;------------------------------------------------------------------------------------------

req_msg_ok_txt	db "OK",0

;------------------------------------------------------------------------------------------
