;------------------------------------------------------------------------------------------
;'B' for Bank Selection command. V6.02
;------------------------------------------------------------------------------------------

os_cmd_b	

	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jr z,shwbnk		;If no args so just show bank currently selected
	
	ld a,e			;force new bank setting
	cp max_bank+1		;must be in range
	jp nc,os_invalid_bank
	ld (bank_pre_cmd),a		;code on return actually changes the bank
	jr shwbnk2

shwbnk	call os_getbank		;show bank msg 
shwbnk2	ld hl,hex_byte_txt
	call hexbyte_to_ascii
	ld a,$1a
	or a
	ret
	
;-----------------------------------------------------------------------------------------

hexword_or_bust

; Set HL to string address:
; Returns to parent routine ONLY if the string is valid hex (or no hex found) in which case:
; DE = hex word. If no hex found, the zero flag is set (A = error code $1f)
; If chars are invalid hex, returns to grandparent (IE: main OS) with error code $0c: bad hex

	call ascii_to_hexword		
	cp $c
	jr nz,hex_good
	pop hl			; remove parent return address from stack
	or a	
	ret			 
hex_good	cp $1f			; no args?
	ret
	
;------------------------------------------------------------------------------------------