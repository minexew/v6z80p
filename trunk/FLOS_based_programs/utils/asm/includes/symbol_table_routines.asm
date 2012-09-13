;----------------------------------------------------------------------------------
; Symbol code
;----------------------------------------------------------------------------------

init_symbol_table


	ld hl,symbol_offsets_az
	ld b,28*2
isymtlp	ld (hl),$ff
	inc hl
	djnz isymtlp
	
	ld hl,sym_buffer
	ld (symbol_buffer_address),hl
	
	ld hl,ix_txt			;make symbols called IX and IY - this
	ld de,0				;allows the normal expression handler to
	call new_symbol			;read "(ix+n)" strings
	ld hl,iy_txt
	ld de,0
	call new_symbol
	
	ret
	
ix_txt	db "ix",0
iy_txt	db "iy",0

;----------------------------------------------------------------------------------

look_up_symbol

; set HL to first char of zero-terminated ascii symbol name
; On return:
;
; if ZF set DE = value of symbol (else A = error: $11 = cannot find symbol, $12= bad symbol name)
;           HL = zero at end of label
	
	
	ld (symbol_name_loc),hl
	ld a,(hl)
	sub $5f
	jr c,bad_symbol_name	;name must start with "_" or a-z
	cp 28
	jr nc,bad_symbol_name			
	sla a
	ld e,a
	ld d,0
	ld ix,symbol_offsets_az
	add ix,de

nxt_sym_entry

	ld e,(ix)
	ld d,(ix+1)
	push de
	pop bc			; set bc = link addr
	inc de
	ld a,d			
	or e
	jr z,cant_find_symbol	; if entry for this char is not valid ($FFFF), no match

	inc de			; skip past the chain link prefix - 2nd byte
	ld hl,(symbol_name_loc)
		
sym_comp	ld a,(de)			; attempt to match symbol name
	cp (hl)
	jr nz,no_sym_match
	or a
	jr z,got_sym_match
	inc hl
	inc de
	jr sym_comp

got_sym_match

	push de			; found symbol!
	pop ix
	ld e,(ix+1)
	ld d,(ix+2)		; DE = value of symbol (terminator+1 and +2)
	xor a
	ret
		
	
no_sym_match

	push bc
	pop ix
	jr nxt_sym_entry
	

cant_find_symbol

	ld a,$11			;error 1 - cant find symbol
	or a
	ret

bad_symbol_name

	ld a,$12
	or a
	ret
	
;----------------------------------------------------------------------------------

new_symbol

; Set HL = symbol name ascii
;     DE = symbol value
; On return ZF is set if all OK, if not A = error ($12 = bad name, $13= symbol already defined)

	ld (symbol_value),de
	call look_up_symbol
	jr z,symbol_already_defined	;exit if label found
	cp $11
	jr z,ok_new_symbol
	ret	

ok_new_symbol

	ld de,(symbol_buffer_address)	;if at $ffxx, table is full
	ld a,d
	cp $ff
	jp z,symbol_table_full
	
	ld (ix),e			;at this point, IX will be the address of the last link prefix
	ld (ix+1),d		;so set it to point at the new entry
	ld a,$ff			;start of new entry in symbol buffer - set link_chain to "no next" ($ffff)
	ld (de),a
	inc de
	ld (de),a
	inc de
	ld hl,(symbol_name_loc)
esn_lp	ld a,(hl)			;copy the symbol name
	ld (de),a
	or a
	jr z,sym_name_entered
	inc hl
	inc de
	jr esn_lp

sym_name_entered

	inc de
	ld bc,(symbol_value)
	ld a,c
	ld (de),a			;and after the terminator, enter its symbol value
	inc de
	ld a,b
	ld (de),a
	inc de
	ld (symbol_buffer_address),de	;update next free symbol buffer address
	xor a
	ret

symbol_already_defined

	ld a,$13			;error $13 - symbol already defined
	or a
	ret
	
symbol_table_full

	ld a,$14			;erro $14 - symbol table is full
	or a
	ret
	
;----------------------------------------------------------------------------------

symbol_offsets_az

	dw $ffff,$ffff,$ffff,$ffff, $ffff,$ffff,$ffff,$ffff
	dw $ffff,$ffff,$ffff,$ffff, $ffff,$ffff,$ffff,$ffff
	dw $ffff,$ffff,$ffff,$ffff, $ffff,$ffff,$ffff,$ffff
	dw $ffff,$ffff,$ffff,$ffff
	
symbol_buffer_address	dw 0

symbol_name_loc		dw 0

symbol_value		dw 0
		
;----------------------------------------------------------------------------------
	