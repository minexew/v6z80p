;-------------------------------------------------------------------------------------------------------
; ShowVRAM - VRAM scroll-through viewer
;-------------------------------------------------------------------------------------------------------
;
; Requires FLOS v602
;
;---Standard header for OSCA and FLOS ------------------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"


	org $5000

;--------------------------------------------------------------------------------------------------------

	call kjt_get_cursor_position
	ld (orig_cursor),bc
	
	call w_backup_display
	
	in a,(sys_vreg_read)		; adjust linecop split positions for non-PAL systems
	bit 5,a
	jr z,pal_tv
	ld a,$5f
	ld (lc_split1),a
	inc a
	ld (lc_split2),a
	inc a
	ld (lc_split3),a		
pal_tv

	ld a,13				; Set up lineCop		
	call kjt_set_bank
	
	ld hl,$8000			; back up RAM area that will be used for linecop list
	ld de,orig_lc_ram
	ld bc,end_my_linecoplist-my_linecoplist
	push bc
	ldir
	ld hl,my_linecoplist		; now copy linecop list to $70000 in sysRAM
	ld de,$8000
	pop bc
	ldir				
	xor a
	call kjt_set_bank
	ld de,1
	ld (vreg_linecop_lo),de		; set Linecop address ($0000) and enable (bit 0 set)

;--------------------------------------------------------------------------------------------------------
	
	ld a,0			;window number
	ld b,0			;x
	ld c,0			;y
	call draw_window		

	ld a,1
	call w_set_element_selection

;---------------------------------------------------------------------------------------------------------

req_loop	call req_show_selection
	call req_show_cursor
	call write_bpl_addr
	call write_modulo
	call write_chunky
	call write_winsize
	
	ld hl,vreg_read			;wait raster
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
	
	ld a,(req_ascii_input_mode)
	or a
	jp nz,nocurs
	ld a,(req_current_scancode)
	cp $72
	jp z,req_down_pressed
	cp $75
	jp z,req_up_pressed
	cp $74
	jp z,req_right_pressed
	cp $6b
	jp z,req_left_pressed

nocurs	ld a,(req_current_scancode)
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
	jp req_loop
	
;---------------------------------------------------------------------------------------------------------

req_esc_pressed
	
	ld a,(req_ascii_input_mode)		;if pressed ESC whilst entering text
	or a				;restore the original text for the element
	jr z,req_quit			;and continue
	call w_show_associated_text
	xor a
	ld (req_ascii_input_mode),a
	jp req_loop
	
req_quit	ld de,0
	ld (vreg_linecop_lo),de		; Disable Linecop
	
	call kjt_flos_display
	
	call w_restore_display
	
	ld a,13				; restore system memory that was used by linecop program			
	call kjt_set_bank
	ld hl,orig_lc_ram			
	ld de,$8000
	ld bc,end_my_linecoplist-my_linecoplist
	ldir
	xor a
	call kjt_set_bank
		
	ld bc,(orig_cursor)
	call kjt_set_cursor_position
	xor a
	ret
	
;---------------------------------------------------------------------------------------------------------

req_down_pressed
req_tab_pressed

	ld a,(req_ascii_input_mode)
	or a
	call nz,req_end_ascii_input_mode
		
	call w_next_selectable_element
	jp req_loop

req_up_pressed

	ld ix,up_element_sel_swaps
	call element_sel_swap
	jp req_loop



req_left_pressed

	ld ix,left_element_sel_swaps
	call element_sel_swap
	jp req_loop
	


req_right_pressed

	ld ix,right_element_sel_swaps
	call element_sel_swap
	jp req_loop
	

		
element_sel_swap

	ld a,(ix)
	cp $ff
	ret z
	call w_get_element_selection
	cp (ix)
	jr z,gotswap
	inc ix
	inc ix
	jr element_sel_swap
gotswap	ld a,(ix+1)
	call w_set_element_selection
	ret


	

right_element_sel_swaps

	db 1,7, 3,9, 7,1, 9,3, $ff

left_element_sel_swaps

	db 7,1, 9,3, 1,7, 3,9, $ff

up_element_sel_swaps

	db 1,9, 3,1, 5,3, 7,5, 9,7, $ff

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
	
req_hxok	push bc
	ld c,a
	ld b,4
req_shdw	add hl,hl
	rl e
	rl d
	djnz req_shdw
	ld a,l
	or c
	ld l,a
	inc iy
	
	pop bc
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
	
	call w_get_selected_element_data_location	
	bit 4,(ix+3)			
	jr z,notchkb			;is the selected element a checkbox?
	call w_get_associated_data_location
	ld a,(hl)
	xor 1				;flip string "0" / "1"
	ld (hl),a
	call w_show_associated_text		;and display new data
	jp req_loop

notchkb	ld a,(req_ascii_input_mode)		;if pressed Enter on text input box init text input here
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

;----------------------------------------------------------------------------------------------


write_bpl_addr

	ld a,1
	call read_hex_from_element
	ld (bitplane0b_loc),hl
	ld a,e
	ld (bitplane0b_loc+2),a
	ret	



write_modulo
	
	ld a,3
	call read_hex_from_element
	srl h
	rr l
	push hl
	
	ld hl,lc_mod
	ld de,my_linecoplist
	xor a
	sbc hl,de
	
	pop bc
	ld a,c
	ld e,7
	call kjt_write_sysram_flat
	ret
		

write_chunky

	ld a,5
	call read_hex_from_element
	push hl
	
	ld hl,lc_vreg1
	ld de,my_linecoplist
	xor a
	sbc hl,de
	
	pop bc
	ld a,c
	rrca
	and $80
	or $20
	ld e,7
	call kjt_write_sysram_flat
	ret


write_winsize


	ld a,7			;combine nybbles for vreg_winsize
	call read_hex_from_element
	sla l
	sla l
	sla l
	sla l
	push hl
	
	ld a,9
	call read_hex_from_element
	ld a,l
	and $0f
	pop hl
	or l
		
	ld hl,lc_wsize
	ld de,my_linecoplist
	or a
	sbc hl,de
	ld e,7
	call kjt_write_sysram_flat
	ret
	
	
read_hex_from_element
	
	call w_get_element_a_data_location
	ld l,(ix+5)
	ld h,(ix+6)
	call req_ascii_to_hex
	ret
	
;------------------------------------------------------------------------------------

	include "window_draw_routines.asm"
	include "window_support_routines.asm"
	

;------ My Window Descriptions -----------------------------------------------------

window_list	dw win_inf_inputs			;Window 0


;------ Window Info -----------------------------------------------------------

win_inf_inputs	db 0,0			;0 - position on screen of frame (x,y) 
		db 38,7			;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		
		db 1,1			;6 - position of first element (x,y)
		dw win_element0		;8 - location of first element description
		db 10,1
		dw win_element1
		
		db 1,3			
		dw win_element2		
		db 10,3
		dw win_element3
		
		db 1,5			
		dw win_element4		
		db 10,5
		dw win_element5
		
		db 20,1			
		dw win_element6		
		db 30,1
		dw win_element7
		
		db 20,3			
		dw win_element8		
		db 30,3
		dw win_element9		
		
		db 255			;255 = end of list of window elements
		
		
;---- Window Elements ---------------------------------------------------------------------

;---------------------------------------------------------------------------------------------
; ADDR GADGET
;---------------------------------------------------------------------------------------------

		
win_element0	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 7,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw addr_txt		;5/6 = location of associated data
;		dw 0,0			;7/8/9/10 = when numeric input (bit3 of control set), upper limit
;		dw 0,0			;11/12/13/14 = when numeric input, bottom limit
;		dw 0			;15/16= when numeric input with +/- this is the min incrememnt
;		db 0			;17 = control for numeric input, bit0 = sign extend input, bit1 = skip leading zeroes
					
win_element1	db 1
		db 5,1
		db %1101			;b0:selectable + b2:accepts user input, b3=hex input
		db 0
		dw entry1_txt
		dw $ffff,$0007		;upper limit for hex value
		dw $0000,$0000		;lower limit for hex value
		dw 1			;min inc/decrement for +/- buttons
		db 0

addr_txt		db "ADDRESS",0
entry1_txt	db "00000",0


;---------------------------------------------------------------------------------------------
; MODULO GADGET
;---------------------------------------------------------------------------------------------

		
win_element2	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 6,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw mod_txt		;5/6 = location of associated data
		
win_element3	db 1
		db 3,1
		db %1101			;b0:selectable + b2:accepts user input, b3=hex input
		db 0
		dw entry2_txt
		dw $0180,$0000
		dw $0000,$0000
		dw 2
		db 0

mod_txt		db "MODULO",0
entry2_txt	db "000",0

		
;---------------------------------------------------------------------------------------------
; CHUNKY ON/OFF GADGET
;---------------------------------------------------------------------------------------------
		

win_element4	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 8,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw chunky_txt		;5/6 = location of associated data
		
win_element5	db 1
		db 1,1
		db %10001			;b0:selectable + b4: checkbox
		db 0
		dw entry3_txt

chunky_txt	db "CHUNKY?",0
entry3_txt	db "0",0


;---------------------------------------------------------------------------------------------
; WIN LEFT GADGET
;---------------------------------------------------------------------------------------------
		

win_element6	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 8,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw winleft_txt		;5/6 = location of associated data
		
win_element7	db 1
		db 1,1
		db %1101			;b0:selectable + b2:accepts user input, b3=hex input
		db 0
		dw entry4_txt
		dw $000f,$0000		;upper limit for hex value
		dw $0005,$0000		;lower limit for hex value
		dw 1			;min inc/decrement for +/- buttons
		db 0			;sign extend input: on, skip leading zeroes: on
			
			
winleft_txt	db "WINDOW L",0
entry4_txt	db "8",0

;---------------------------------------------------------------------------------------------
; WIN RIGHT GADGET
;---------------------------------------------------------------------------------------------
		

win_element8	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 8,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw winright_txt		;5/6 = location of associated data
		
win_element9	db 1
		db 1,1
		db %1101			;b0:selectable + b2:accepts user input, b3=hex input
		db 0
		dw entry5_txt
		dw $000f,$0000		;upper limit for hex value
		dw $0000,$0000		;lower limit for hex value
		dw 1			;min inc/decrement for +/- buttons
		db 0			;sign extend input: on, skip leading zeroes: on
			
			
winright_txt	db "WINDOW R",0
entry5_txt	db "C",0


;--------------------------------------------------------------------------------------
; Linecop program for split screen
;---------------------------------------------------------------------------------------

my_linecoplist	

	dw $c008		;wait for line $08 (NORMAL FLOS DISPLAY SECTION)
	
	dw $8204		;set window x
	dw $0004		
	dw $8202
	dw $008c
	
	dw $8247		;select modulo register
	dw $0000		;set modulo for FLOS display area
	
	dw $8203		;select reg $203, bitplane count
	dw $0005		;use 6 bitplanes
	
	dw $8201		;set register $201 (vreg_victrl)
	dw $0000		;write 0 to register (bitmap bitplane mode, use register set A)
	
lc_split1	dw $c06f		;wait for $6f
	dw $0024		;blank display at split (use register set B)
	
	dw $8202
lc_wsize	dw $008c		;set custom window width
	
lc_split2	dw $c070		;wait for line $70 (VRAM DISPLAY AREA)
	
	dw $8203		;select register $203 (bpl count)
	dw $0000		;write 00 - 1 bitplane
	
	dw $8247		;select modulo reg
lc_mod	dw $0005		;set modulo for data area
		
	dw $8243		;select register $243 (reset video counter)
	dw $0000		;write $00, reset counter
		
	dw $8201
lc_split3	dw $c071		;wait for $71
lc_vreg1	dw $0020		;renable video (use register set B)
	
	
	dw $c1ff		;wait for line $1ff (end of list)

		
end_my_linecoplist	db 0

;---------------------------------------------------------------------------------------

orig_cursor	dw 0

orig_lc_ram	db 0	; dont put anything after this point (also, must not enter paged ram ($8000))

;---------------------------------------------------------------------------------------