;--------- Debug Code --------------------------------------------------------------------------------

debug_it	ld bc,$fdfe			; show memory if D is pressed
	in a,(c)				
	bit 2,a
	ret nz

	ld hl,$4000
	ld bc,32*8*16
clrlp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clrlp

	ld hl,$5800
	ld bc,16*32
atrlp	ld (hl),7
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,atrlp
	
	ld hl,$c000
	ld (memmonaddrl),hl
	xor a
	ld (memmonbank),a
	out (254),a
	ld bc,$7ffd
	out (c),a	
	call show_mem
	ei
	
db_loop	halt
	
	call test_up_key
	jr nz,npu
	ld hl,(memmonaddrl)
	ld de,$80
	xor a
	sbc hl,de
	ld (memmonaddrl),hl
	call show_mem
	
npu	call test_down_key
	jr nz,npd
	ld hl,(memmonaddrl)
	ld de,$80
	add hl,de
	ld (memmonaddrl),hl
	call show_mem
npd
	call test_b_key
	jr nz,nbk
	ld a,(memmonbank)	
	inc a
	and 7
	ld (memmonbank),a
	out (254),a		; border colour = bank / real spectrum RAM
	ld bc,$7ffd
	out (c),a			; select spectrum bank at $c000
	call show_mem
	
nbk	call test_select_key	; quit on enter pressed
	ret z
	
	jr db_loop


memmonaddrl	dw 0
memmonbank	db 0

;-----------------------------------------------------------------------------------------------------


show_mem
	ld bc,0
	ld (cursor_pos),bc
	
	ld de,(memmonaddrl)
validhex:	ld b,16			;shows 16 lines of bytes
smbllp:	push bc			;starting from current cursor position
	ld hl,output_line		;input: de = address
	call hexword_to_ascii
	ld b,8
mmbllp:	ld (hl)," "
	inc hl
	ld a,(de)	
	call hexbyte_to_ascii
	inc de
	djnz mmbllp
	ld (hl),11
	inc hl
	ld (hl),0
	ld hl,output_line
	push de
	call print_string
	pop de
	pop bc
	djnz smbllp
	ret



hexbyte_to_ascii

	push bc
	ld b,a			;puts ASCII version of hex byte value in A at HL (two chars)
	srl a			;then hl = hl + 2
	srl a
	srl a
	srl a
	call hxdigconv
	ld (hl),a
	inc hl
	ld a,b
	and $f
	call hxdigconv
	ld (hl),a
	inc hl
	pop bc
	ret
hxdigconv	add a,$30
	cp $3a
	jr c,hxdone
	add a,7
hxdone	ret




hexword_to_ascii	

	ld a,d			;ascii version of DE is stored at hl to hl+3
	call hexbyte_to_ascii
	ld a,e
	call hexbyte_to_ascii
	ret
	
	
output_line ds 32,0


;---------------------------------------------------------------------------------------------------------
