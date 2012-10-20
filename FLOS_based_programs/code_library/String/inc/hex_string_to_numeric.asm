
hex_string_to_numeric

;-----------------------------------------------------------------------------------
; Coverts an ASCII representation of 32bit (max) unsigned hex number to numeric 
;
; Set source IX = hex string address (ends on space or null ($00))
; Dest value in = DE:HL
; ZF set if OK, ZF not set and A = $0c ("invalid hex" FLOS error code) if bad chars
; IX = address of trailing space or null
;-----------------------------------------------------------------------------------
; source tab size = 8
;-----------------------------------------------------------------------------------

		ld de,0
		ld hl,0				;de:hl = initially $00000000 

		ld b,8				;max chars
hsn_hexlp	ld a,(ix)
		or a
		ret z				;end if null
		cp 32
		ret z				;end if space
		
		cp $61				;convert char to hex value 0-15		
		jr c,hsn_chrok
		sub $20				
hsn_chrok	sub $3a			
		jr c,hsn_hex09
		add a,$f9
hsn_hex09	add a,$a
		
		cp 16				;is char 0-15?
		jr c,hsn_hxok
		ld a,$12
		or a				;ZF not set (a=$0c) if bad char
		ret		
		
hsn_hxok	ld c,a				;shift de:hl 4 bits left
		push bc
		ld b,4
hsn_shdw	add hl,hl
		rl e
		rl d
		djnz hsn_shdw
		pop bc		
		ld a,l				;and place new nybble at bits [3:0] 
		or c
		ld l,a
		inc ix
		djnz hsn_hexlp
		xor a
		ret
	


