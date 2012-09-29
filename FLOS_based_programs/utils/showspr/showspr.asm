;---------------------------------------------------------------------------------------
; SHOWSPR - A util to browse sprite memory - v0.01 by Phil Ruston 2012
;---------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;---------------------------------------------------------------------------------------------
; Init
;---------------------------------------------------------------------------------------------

required_flos	equ $602
include 		"test_flos_version.asm"

;-------- Parse command line arguments ---------------------------------------------------------

	ld a,(hl)				; examine argument text, if none, run with default settings
	or a
	jp z,no_args
	
;-------------------------------------------------------------------------------------------------

parse_args

	push hl
	pop ix
	call hex_string_to_numeric		;ix = source, dehl = value
	ret nz
	ld (spr_addr),hl			;set default sprite number
	ld a,e
	ld (spr_addr+2),a

no_args

;--------- Get video mode --------------------------------------------------------------------

	ld b,0					
	in a,(sys_hw_flags)			;VGA jumper on?
	bit 5,a
	jr z,not_vga
	ld b,2
	jr got_mode 
not_vga	ld a,(vreg_read)			;60 Hz?
	bit 5,a
	jr z,got_mode
	ld b,1				;0=PAL, 1=NTSC, 2=VGA

got_mode	ld e,b
	ld d,0
	ld hl,spr_ybase_list
	add hl,de
	ld a,(hl)
	ld (sprite_ybase),a			;adjust linecop split depending on video mode

;-------------------------------------------------------------------------------------------

	call kjt_get_cursor_position		; back up some flos display stuff
	ld (orig_cursor),bc
	call w_backup_display
	call kjt_clear_screen

	call show_sprite_numbers
	
	ld a,1
	ld (vreg_sprctrl),a			;enable sprites, most basic mode
	
	ld a,0				; window number
	ld b,0				; x
	ld c,0				; y
	call draw_window		

	ld a,1
	call w_set_element_selection	
	call w_get_selected_element_data_location
	ld hl,(spr_addr)
	ld de,(spr_addr+2)
	ld d,0
	call req_test_num_limits		;put default address in requester

;---------------------------------------------------------------------------------------------------------


req_loop	call req_show_selection
	call req_show_cursor
	
	ld hl,(spr_addr)			
	ld a,(spr_addr+2)
	push af
	push hl
	call write_spr_addr			;extract data from user input box
	ld a,(spr_addr+2)			
	ld b,a
	pop hl
	pop af
	cp b
	jr nz,rdws
	ld de,(spr_addr)
	xor a
	sbc hl,de
	jr z,nordws
rdws	call show_sprite_numbers		;if address changed, we need to redraw

	
nordws	ld hl,vreg_read			;wait raster
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
	
;	cp $72
;	jp z,req_down_pressed
;	cp $75
;	jp z,req_up_pressed
;	cp $74
;	jp z,req_right_pressed
;	cp $6b
;	jp z,req_left_pressed

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
	jr z,quit				;and continue
	call w_show_associated_text
	xor a
	ld (req_ascii_input_mode),a
	jp req_loop

quit	xor a
	ld (vreg_sprctrl),a
		
	call w_restore_display
	
	ld bc,(orig_cursor)
	call kjt_set_cursor_position
	xor a
	ret
		
	
;---------------------------------------------------------------------------------------------------------

req_tab_pressed
req_down_pressed

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

	db 1,1, $ff

left_element_sel_swaps

	db 1,1, $ff

up_element_sel_swaps

	db 1,1, $ff


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
	push bc
	ld b,4
req_shdw	add hl,hl
	rl e
	rl d
	djnz req_shdw
	pop bc
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
	
req_hvok	bit 2,(ix+17)			;use granularity mask?
	jr z,req_nogm
	ld a,l
	and (ix+18)
	ld l,a
	ld a,h
	and (ix+19)
	ld h,a
	
req_nogm	call req_hex_to_ascii		;DE:HL to ASCII version of hex, HL returns pointing to string 
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


;------------------------------------------------------------------------------------------------------------
	
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
	
	ld l,(ix+5)			;yes, so test upper/lower limits against inputted figure
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


write_spr_addr

	ld a,1
	call read_hex_from_element
	ld (spr_addr),hl
	ld a,e
	ld (spr_addr+2),a
	ret	


;----------------------------------------------------------------------------------------------
	
	
read_hex_from_element
	
	call w_get_element_a_data_location
	ld l,(ix+5)
	ld h,(ix+6)
	call req_ascii_to_hex
	ret



;---------------------------------------------------------------------------------------------------------

find_next_arg

	ld a,(ix)
	or a
	jr z,missing_args
	cp " "
	jr nz,got_narg
	inc ix
	jr find_next_arg
got_narg	cp a
	ret
		

	
missing_args

	ld a,$1f
	or a
	ret

;-------------------------------------------------------------------------------------------


show_sprite_numbers
	
	ld hl,(spr_addr+1)			;update the digit chars
	ld b,2				;first char x coord
	ld e,6
sspnl2	ld c,7				;first char y coord
	ld d,8				

sspnl1	push de
	push bc

	ld a,h
	push hl
	ld hl,num_txt
	call kjt_hex_byte_to_ascii
	pop hl
	
	ld a,l
	push hl
	ld hl,num_txt+2
	call kjt_hex_byte_to_ascii
	pop hl
	
	pop bc
	call kjt_set_cursor_position
	
	push hl
	ld hl,num_txt+1
	call kjt_print_string
	pop hl
	
	inc hl
	ld a,h
	and 1
	ld h,a
	
	pop de
	inc c
	inc c
	dec d
	jr nz,sspnl1
	ld a,b
	add a,6
	ld b,a
	dec e
	jr nz,sspnl2
	
	
	
	ld b,6				;update the sprite registers
	ld de,(spr_addr+1)			;def number
	ld hl,128+16+(8*3)			;x coord
	ld ix,sprite_registers
	
spreglp	ld (ix+0),l			;set x coord low
	ld (ix+3),e			;set def low
	ld a,d
	rlca
	rlca
	and 4
	ld c,a
	ld a,h
	and 1
	or $80
	or c
	ld (ix+1),a			;set msbs
	ld a,(sprite_ybase)
	ld (ix+2),a			;set y coord low
	
	ld a,l				;next x coord
	add a,6*8
	ld l,a
	jr nc,xcomok
	inc h
	
xcomok	ld a,e				;def + 8
	add a,8
	ld e,a
	jr nc,defmok
	inc d

defmok	inc ix				;next spr reg
	inc ix
	inc ix
	inc ix
	
	djnz spreglp
	ret
	
			
spr_num	dw 0
num_txt	db "xxxx",0
	
	
;------------------------------------------------------------------------------------------------------------------

	include "window_draw_routines.asm"
	include "window_support_routines.asm"
	include "hex_string_to_numeric.asm"
		
;-------------------------------------------------------------------------------------------------------------------

spr_addr 		db $00,$00,$00		;numeric data extracted from user input window

orig_cursor	dw 0

spr_ybase_list	db $11+(10*8), $01+(10*8), $01+(10*8)

sprite_ybase	db 0

;------------------------------------------------------------------------------------------------------------------



;------ My Window Descriptions -----------------------------------------------------

window_list	dw win_inf_inputs			;Window 0


;------ Window Info -----------------------------------------------------------

win_inf_inputs	db 0,0			;0 - position on screen of frame (x,y) 
		db 38,5			;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		
		db 8,3			;6 - position of first element (x,y)
		dw win_element0		;8 - location of first element description
		db 24,3
		dw win_element1
		
		db 3,1
		dw win_element2
		
		db 255			;255 = end of list of window elements
		
		
;---- Window Elements ---------------------------------------------------------------------

; ADDR GADGET

		
win_element0	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 15,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input, b4=checkbox)
		db 0			;4 = event flag
		dw addr_txt		;5/6 = location of associated data
;		dw 0,0			;7/8/9/10 = when numeric input (bit3 of control set), upper limit
;		dw 0,0			;11/12/13/14 = when numeric input, bottom limit
;		dw 0			;15/16= when numeric input with +/- this is the min incrememnt
;		db 0			;17 = control for numeric input, bit0 = sign extend input, bit1 = skip leading zeroes
					
win_element1	db 1
		db 5,1
		db %1101			;b0:selectable + b2:accepts user input + b3:hex
		db 0
		dw entry1_txt
		dw $ff00,$0001		;upper limit for hex value
		dw $0000,$0000		;lower limit for hex value
		dw $100			;min inc/decrement for +/- buttons
		db %110			;sign extend input: off, skip leading zeroes: on. granularity mask = on
		dw $ff00			;granularity mask (low 16 bits)
		
addr_txt		db "SPRITE RAM ADDR",0
entry1_txt	db "0    ",0



;---------------------------------------------------------------------------------------------

win_element2	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 32,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
		db 0			;4 = event flag
		dw title_txt		;5/6 = location of associated data

title_txt		db "** Sprite Memory Browser V0.01 **",0

;---------------------------------------------------------------------------------------------


