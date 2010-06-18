;-----------------------------------------------------------------------
;"R" - show CPU register values saved on return from command. V6.02
;-----------------------------------------------------------------------

os_cmd_r	
	ld ix,a_store1			; show CPU register values
	ld hl,register_txt
rcmdloop2	call os_print_string
rcmdloop	ld a,(hl)
	cp 1
	jr z,showbyte
	cp 2
	jr z,showword
	inc hl
	jr rcmdloop
	
showbyte	ld a,(ix)
	inc ix
	push ix
	push hl
	call os_show_hex_byte
	jr showreg
	
showword	ld e,(ix)
	ld d,(ix+1)
	inc ix
	inc ix
	push ix
	push hl
	call os_show_hex_word
showreg	pop hl
	pop ix
	inc hl
	ld a,(hl)
	or a
	jr nz,rcmdloop2

	call os_new_line			; show the CPU flags
	ld hl,flag_txt
	call os_copy_to_output_line
	ld hl,output_line+4
	ld bc,5
	ld a,(storef)
	bit 6,a				;zero flag
	jr z,zfzero
	ld (hl),'1'
zfzero:	add hl,bc
	bit 0,a				;carry flag
	jr z,cfzero
	ld (hl),'1'
cfzero:	add hl,bc
	bit 7,a				;sign flag
	jr z,sfzero
	ld (hl),'M'
sfzero:	add hl,bc
	bit 2,a				;parity flag
	jr z,pfzero
	ld (hl),'O'
pfzero:	add hl,bc
	inc hl
	bit 4,a				;IFF flag
	jr z,iffzero
	ld (hl),'1'
iffzero:	call os_print_output_line
	xor a
	ret

;---------------------------------------------------------------------------------
	

register_txt	db " A=",0,1
		db " BC=",0,2
		db " DE=",0,2
		db " HL=",0,2
		
		db 11,$27,"A=",0,1
		db $27,"BC=",0,2
		db $27,"DE=",0,2
		db $27,"HL=",0,2
		
		db 11," IX=",0,2
		db " IY=",0,2
		db " SP=",0,2
		db " PC=",0,2,0,0

flag_txt		db " ZF=0 CF=0 SF=P PV=E IFF=0",11,11,0
		
;---------------------------------------------------------------------------------
