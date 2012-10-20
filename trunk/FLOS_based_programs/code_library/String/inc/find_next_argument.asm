;move to HL to next argument in string (delineated by spaces) if ZF is not set - no more args

find_next_argument

	ld a,(hl)			
	or a
	jr z,mis_arg
	cp " "
	jr z,got_spc
	inc hl
	jr find_next_argument

got_spc	inc hl
	ld a,(hl)
	or a
	jr z,mis_arg
	cp " "
	jr z,got_spc
	cp a			;return with zero flag set, char in A
	ret
	
mis_arg	ld a,$1f		;return with zero flag unset, error code $1f
	or a
	ret
	
	
	