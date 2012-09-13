
show_info_bar

	ld b,0
	ld c,24
	call kjt_set_cursor_position
	
	call inverse_video	
	
	ld hl,filename
	call kjt_print_string
	
	call kjt_get_cursor_position
ibloop1	ld a,b
	cp 14
	jr z,fnprok
	ld a," "
	call print_char
	inc b
	jr ibloop1
	
	
fnprok	ld a,"L"
	call print_char
	ld a,":"
	call print_char
	ld hl,(line_position)
	ld a,(cursor_y)
	ld e,a
	ld d,0
	add hl,de
	call print_decimal
	
	ld a," "
	call print_char
	ld a,"C"
	call print_char
	ld a,":"
	call print_char
	ld a,(cursor_x)
	ld l,a
	ld a,(column_offset)
	add a,l
	ld l,a
	ld h,0
	inc hl
	call print_decimal
	
	call kjt_get_cursor_position
ibloop2	ld a," "
	call kjt_plot_char
	inc b
	ld a,b
	cp 40
	jr nz,ibloop2
			
	call normal_video
	ret



	
			
;------------------------------------------------------------------------------------------------



inverse_video

	ld a,(inv_video_colour)
	call kjt_set_pen
	ret
	
	
normal_video

	ld a,(normal_video_colour)
	call kjt_set_pen
	ret
	

normal_video_colour	db 0

inv_video_colour	db 0
		
;------------------------------------------------------------------------------------------------


print_char

	push hl
	ld hl,char_to_print
	ld (hl),a
	call kjt_print_string
	pop hl
	ret

char_to_print

	db 0,0

;---------------------------------------------------------------------------------

print_decimal
	
;Number in hl to decimal ASCII, skips leading zereos
;Thanks to z80 Bits
;inputs:	hl = number to ASCII
;example: hl=300 outputs '300'
;destroys: af, bc, hl, de used

DispHL:	ld d,5
	ld e,0
	ld bc,-10000
	call Num1
	ld bc,-1000
	call Num1
	ld bc,-100
	call Num1
	ld c,-10
	call Num1
	ld c,-1
Num1:	ld a,'0'-1
Num2:	inc a
	add hl,bc
	jr c,Num2
	sbc hl,bc
	dec d
	jr z,notzero
	cp "0"
	jr nz,notzero
	bit 0,e
	ret z
notzero	call print_char
	ld e,1
	ret 
	
;---------------------------------------------------------------------------------
