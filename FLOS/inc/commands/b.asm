;-----------------------------------------------------------------------
;'B' for Bank Selection command. V6.01
;-----------------------------------------------------------------------

os_cmd_b	

	call ascii_to_hexword	;e is digit we want
	cp $c			;error code?
	ret z
	cp $1f
	jr z,shwbnk		;2 = no args so just show bank currently selected
	
	ld a,e			;force new bank setting
	call test_bank		;must be in range
	jp nc,os_invalid_bank
	ld (bank_pre_cmd),a		;code on return actually changes the bank
	jr shwbnk2

shwbnk	call os_getbank		;show bank msg 
shwbnk2	ld hl,hex_byte_txt
	call hexbyte_to_ascii
	xor a
	ld a,$1a
	ret
	
;-----------------------------------------------------------------------
