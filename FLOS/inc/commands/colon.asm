;-----------------------------------------------------------------------
;":" for write hex bytes command. V6.01
;-----------------------------------------------------------------------

os_cmd_colon:			
	
	call ascii_to_hexword	;returns DE = address to write to
	cp $c
	ret z
	cp $1f
	jp z,os_no_start_addr
	
	push de
	pop ix			;ix is now dest

wmblp	call ascii_to_hexword	;copy hex bytes from line to RAM
	cp $c
	ret z
	cp $1f
	jr z,os_ccmdn
	ld (ix),e
	inc ix
	jr wmblp
os_ccmdn	xor a
	ret
		

;-----------------------------------------------------------------------
