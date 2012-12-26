;------------------------------------------------------------------------------------------
;'B' for Bank Selection command. V6.05
;------------------------------------------------------------------------------------------

os_cmd_b	

		call hexword_or_bust		; the call only returns here if the hex in DE is valid
		jr z,shwbnk			; If no args so just show bank currently selected
		
		ld a,e				; force new bank setting
		cp max_bank+1			; must be in range
		jp nc,os_invalid_bank
		ld (bank_pre_cmd),a		; code on return actually changes the bank
		jr shwbnk2

shwbnk		call os_getbank		

shwbnk2		push af			; show bank number (and sysram section paged) 
		ld hl,banknum_txt
		call hexbyte_to_ascii
		pop af
		inc a
		rlca
		rlca
		rlca
		push af
		ld hl,sysram1_txt
		call hexbyte_to_ascii
		pop af
		add a,7
		ld hl,sysram2_txt
		call hexbyte_to_ascii
		
		ld hl,sysram_banked_txt

print_and_return

		call kjt_print_string
		xor a
		ret
	
;-----------------------------------------------------------------------------------------

hexword_or_bust

; Set HL to string address:
; Returns to parent routine ONLY if the string is valid hex (OR no hex found) in which case:
; DE = hex word. 
; If no hex found, the zero flag is set (and A = error code $1f)
; If chars are invalid hex, returns to grandparent (IE: main OS) with error code

		call ascii_to_hexword		
		cp $1f
		ret z

		or a
		jr nz,bad_hex
		inc a				; returns with ZF NOT set if valid hex
		ret

bad_hex		pop hl				; remove parent return address from stack
		or a	
		ret			 
	
;------------------------------------------------------------------------------------------