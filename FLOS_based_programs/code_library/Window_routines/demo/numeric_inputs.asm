;TAB SIZE = 10
;--------------------------------------------------------------------------------------
; Demo of Support code for Window drawing routines
; Text input / numeric (hex) input with +/- programmable inc/dec and upper/lower limits
;--------------------------------------------------------------------------------------
;
; Requires FLOS v602
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"


	org $5000

;------------------------------------------------------------------------------
	
	call kjt_clear_screen
	ld hl,info_txt
	call kjt_print_string
	
	ld a,0			;window number
	ld b,8			;x
	ld c,6			;y
	call draw_window		

	ld a,1
	call w_set_element_selection

;---------------------------------------------------------------------------------------------------------

req_loop	call req_show_selection
	call req_show_cursor
		
	ld hl,vreg_read		;wait raster
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
	cp $66
	jp z,req_backspace_pressed
	cp $5a
	jp z,req_enter_pressed
	cp $55
	jp z,req_plus_pressed
	cp $4e
	jp z,req_minus_pressed
	cp $76
	jr z,req_esc_pressed
	
	ld hl,req_incdec_release		;if +/- not pressed for 0.25 second, set as key released
	inc (hl)
	jr nz,req_idrm
	ld (hl),$ff
req_idrm	ld a,(hl)
	cp 12
	jr c,req_nrsr
	xor a
	ld (req_incdec_repeat),a
	
req_nrsr	ld a,(req_current_ascii_char)
	or a
	jp nz,req_ascii_input
	jr req_loop
	
;---------------------------------------------------------------------------------------------------------

req_esc_pressed
	
	ld a,(req_ascii_input_mode)		;if pressed ESC whilst entering text
	or a				;restore the original text for the element
	jr z,req_quit			;and continue
	call w_show_associated_text
	xor a
	ld (req_ascii_input_mode),a
	jp req_loop
	
req_quit	xor a
	ret
	
;---------------------------------------------------------------------------------------------------------

req_tab_pressed

	ld a,(req_ascii_input_mode)
	or a
	call nz,req_end_ascii_input_mode
		
	call w_next_selectable_element
	jp req_loop


;----------------------------------------------------------------------------------------------------------

req_plus_pressed

	ld a,(req_ascii_input_mode)
	or a
	jp nz,req_ascii_input
	
	call w_get_associated_data_location	; no action if not a numeric input
	jp z,req_loop
	bit 3,(ix+3)
	jp z,req_loop
	
	call req_incdec_preamble
	jp nz,req_loop
	
	add hl,bc
	jr nc,req_hmsbs
	inc de

req_hmsbs	call req_test_num_limits
	jp req_loop

	
;----------------------------------------------------------------------------------------------------------
	
	

req_minus_pressed
	
	ld a,(req_ascii_input_mode)
	or a
	jp nz,req_ascii_input
	
	call w_get_associated_data_location	; no action if not a numeric input
	jp z,req_loop
	bit 3,(ix+3)
	jp z,req_loop

	call req_incdec_preamble
	jp nz,req_loop
	
	xor a
	sbc hl,bc
	jr nc,req_hmsbs
	dec de
	jr req_hmsbs


;----------------------------------------------------------------------------------------------------------
; Support code for +/- input hex value adjust
;----------------------------------------------------------------------------------------------------------


req_incdec_preamble
	
	xor a
	ld (req_incdec_release),a		;reset the release timer
	
	call req_signextend_decision		;get sign extend option
	call req_ascii_to_hex		;ASCII string to hex in DE:HL
	ret nz
	
	call w_get_selected_element_data_location

	ld c,(ix+15)			;get min increment
	ld b,(ix+16)
	ld a,(req_incdec_repeat)		;magnify adjust value based on time key held
	inc a
	jr nz,req_idho
	dec a
req_idho	ld (req_incdec_repeat),a
	rlca
	rlca
	rlca
	and 7
	jr z,req_gpav
req_aisp	sla c
	rl b
	dec a
	jr nz,req_aisp	
req_gpav	xor a
	ret




req_signextend_decision

	bit 0,(ix+17)			;if length of input = max length of input box, and
	ret z				;sign extend bit is set, we can check first char to

	push hl				;get sign extension decision
	ld b,0
req_floi	ld a,(hl)
	or a
	jr z,req_gloi
	cp " "
	jr z,req_gloi
	inc b
	inc hl
	jr req_floi
req_gloi	pop hl
	ld a,(ix+1)			;input box size
	cp b
	jr z,req_seok1
	xor a
	ret
req_seok1	ld a,(hl)
	call req_uppercasify
	call req_hex_digit
	bit 3,a
	ret
	

req_ascii_to_hex

	push hl				;String at HL, ZF = set: pack empty digits with 0, else F (for sign extend) 
	pop iy				;Result in DE:HL. IF ZF not set on return, not a hex number
	ld de,0
	ld hl,0				;de:hl = initially $00000000 
	jr z,req_athp
	dec hl				;or de:hl=$ffffffff when sign extension required
	dec de

req_athp	ld b,8				;max chars
req_hexlp	ld a,(iy)
	or a
	ret z
	cp 32
	ret z
	call req_uppercasify
	call req_hex_digit	
	cp 16
	jr c,req_hxok
	xor a
	inc a
	ret
	
req_hxok	ld c,a
	ld b,4
req_shdw	add hl,hl
	rl e
	rl d
	djnz req_shdw
	ld a,l
	or c
	ld l,a
	inc iy
	djnz req_hexlp
	xor a
	ret


	
	
req_hex_digit

	sub $3a			
	jr c,req_hex09
	add a,$f9
req_hex09	add a,$a
	ret




req_hex_to_ascii

	ld iy,req_hex_string_txt		;set DE:HL to hex value, returns string address at HL 
	ld c,8
req_msfh	ld a,d
	rrca
	rrca
	rrca
	rrca
	and $f
	add a,$30
	cp $3a
	jr c,req_ghxd
	add a,$41-$3a
req_ghxd	ld (iy),a
	inc iy
	ld b,4
req_hxsh	add hl,hl
	rl e
	rl d
	djnz req_hxsh
	dec c
	jr nz,req_msfh
	ret



req_uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

	cp $61			
	ret c
	cp $7b
	ret nc
	sub $20				
	ret
			



req_test_num_limits

	exx				;compare DE:HL with upper limit
	ld l,(ix+7)
	ld h,(ix+8)
	ld e,(ix+9)
	ld d,(ix+10)
	exx
	call req_compare_dehl_dehl
	jr c,req_ulok			 
	ld l,(ix+7)
	ld h,(ix+8)
	ld e,(ix+9)
	ld d,(ix+10)
	jr req_hvok

req_ulok	exx
	ld l,(ix+11)
	ld h,(ix+12)			;compare DE:HL with lower limit
	ld e,(ix+13)
	ld d,(ix+14)
	exx
	call req_compare_dehl_dehl
	jr nc,req_hvok			
	ld l,(ix+11)
	ld h,(ix+12)			
	ld e,(ix+13)
	ld d,(ix+14)
	
req_hvok	call req_hex_to_ascii		;DE:HL to ASCII version of hex at HL 
	ld e,(ix+1)
	ld d,0
	ld hl,req_hex_string_txt+8
	xor a
	sbc hl,de
	
	bit 1,(ix+17)			;skip leading zeroes?
	jr z,req_shex
	
	ld b,(ix+1)			; 
req_sklz	dec b
	jr z,req_shex
	ld a,(hl)
	cp "0"
	jr nz,req_shex
	inc hl
	jr req_sklz
	
req_shex	call w_ascii_to_associated_data
	call w_show_associated_text
	ret
	
	
	

req_compare_dehl_dehl

	push hl			;32bit signed compare. Carry set if de:hl' > de:hl
	push de
	
	exx
	ld a,d
	exx
	bit 7,a			
	jr nz,req_neg1
	bit 7,d			
	jr nz,req_gtr		
	call req_sub
			
req_cd	pop de
	pop hl
	ret
	
	
req_neg1	bit 7,d			
	jr z,req_sma
	call req_sub		 	
	jr req_cd


req_gtr	scf
	jr req_cd
req_sma	xor a
	jr req_cd


req_sub	exx
	push hl
	exx
	pop bc
	xor a			
	sbc hl,bc
	ex de,hl
	exx
	push de
	exx
	pop bc
	sbc hl,bc
	ret




req_hex_string_txt

	ds 8,32
	db 0

req_incdec_repeat
	
	db 0
	
req_incdec_release

	db 0
	
;-----------------------------------------------------------------------------------------------------------
; End of support code for +/- values
;-----------------------------------------------------------------------------------------------------------


req_enter_pressed

	ld a,(req_ascii_input_mode)		;if pressed Enter on text input box init text input here
	or a				;(unless already in input mode)
	jr z,req_ascii_input
	call req_end_ascii_input_mode	
	jp req_loop


;-------------------------------------------------------------------------------------------------------------

req_ascii_input

	call w_get_selected_element_data_location
	bit 2,(ix+3)			;does element allow ascii input?
	jp z,req_loop
	
	ld a,(req_ascii_input_mode)		;already entering text?		
	or a
	call z,req_set_ascii_input_mode	;if not set up the input line
	ld a,(req_ti_cursor)		
	cp (ix+1)				;cant enter more text if at end of line
	jr z,req_nai
	call req_ascii_cursor_pos
	ld a,(req_current_ascii_char)		;might be non-ascii (EG: initiated with Enter)
	or a
	jp z,req_loop
	call req_uppercasify
	call kjt_plot_char
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
	call kjt_plot_char			;fill input line with spaces	
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
	
	

req_end_ascii_input_mode

	xor a
	ld (req_ascii_input_mode),a
	
	call w_get_selected_element_coords 
	call kjt_get_charmap_addr_xy		; copy text from box to element's associated data location
	call w_ascii_to_associated_data
	
	call w_get_selected_element_data_location
	
	bit 3,(ix+3)			;is it a numeric input box?		
	ret z
	
	ld l,(ix+5)			;yes, so test upper/lower limits agaisnt inputted figure
	ld h,(ix+6)
	call req_signextend_decision
	call req_ascii_to_hex		;get sign extend option
	jp z,req_tnl			
	ld hl,0				;if bad hex, upper lower bounds check will insert lowest allowable value
	ld de,0
req_tnl	call req_test_num_limits
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
	ld hl,$1800
	call kjt_draw_cursor
	ret


;----------------------------------------------------------------------------------------------
	
req_current_ascii_char	db 0
req_current_scancode	db 0
req_ascii_input_mode	db 0
req_ti_cursor		db 0

info_txt	db "Press TAB to cycle through selectable",11
	db "elements. Enter data in boxes, press",11
	db "+/- keys on numerics. ESC to quit.",0

;----------------------------------------------------------------------------------------------















;------------------------------------------------------------------------------------

	include "window_routines\inc\window_draw_routines.asm"
	include "window_routines\inc\window_support_routines.asm"
	

;------ My Window Descriptions -----------------------------------------------------

window_list	dw win_inf_inputs			;Window 0


;------ Window Info -----------------------------------------------------------

win_inf_inputs	db 0,0			;0 - position on screen of frame (x,y) 
		db 19,8			;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		
		db 1,1			;6 - position of first element (x,y)
		dw win_element1		;8 - location of first element description
		db 5,1
		dw win_element2
		
		db 1,3			
		dw win_element3		
		db 5,3
		dw win_element4
		
		db 1,5			
		dw win_element5		
		db 5,5
		dw win_element6
		
		db 255			;255 = end of list of window elements
		
		
;---- Window Elements ---------------------------------------------------------------------

		
win_element1	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 3,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw input1_txt		;5/6 = location of associated data
;		dw 0,0			;7/8/9/10 = when numeric input (bit3 of control set), upper limit
;		dw 0,0			;11/12/13/14 = when numeric input, bottom limit
;		dw 0			;15/16= when numeric input with +/- this is the min incrememnt
;		db 0			;17 = control for numeric input, bit0 = sign extend input, bit1 = skip leading zeroes
					
win_element2	db 1
		db 8,1
		db %1101			;b0:selectable + b2:accepts user input + b3:hex
		db 0
		dw entry1_txt
		dw $0010,$0000		;upper limit for hex value
		dw $fff0,$ffff		;lower limit for hex value
		dw 1			;min inc/decrement for +/- buttons
		db 1
		
win_element3	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 3,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw input2_txt		;5/6 = location of associated data
		
win_element4	db 1
		db 12,1
		db %101			;b0:selectable + b2:accepts user input (not numeric)
		db 0
		dw entry2_txt
		

win_element5	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 3,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw input3_txt		;5/6 = location of associated data
		
win_element6	db 1
		db 4,1
		db %1101			;b0:selectable + b2:accepts user input
		db 0
		dw entry3_txt
		dw $4000,$0000		;upper limit for hex value
		dw $c000,$ffff		;lower limit for hex value
		dw 16			;min inc/decrement for +/- buttons
		db 3			;sign extend input: on, skip leading zeroes: on
				
input1_txt	db "IN1",0
input2_txt	db "IN2",0
input3_txt	db "IN3",0
input4_txt	db "IN4",0

entry1_txt	db "00000000",0
entry2_txt	db "BEETROOT    ",0
entry3_txt	db "0   ",0

;--------------------------------------------------------------------------------------

