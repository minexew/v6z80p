;-----------------------------------------------------------------------
;"R" - show CPU register values saved on return from command. V6.03
;-----------------------------------------------------------------------

os_cmd_r	ld ix,af_store1			;show register values
	ld hl,register_txt
	ld c," "				;prefix char = space
	push hl
	call show_rr_cr
	pop hl
	ld c,$27				;prefix char = "'"
	call show_rr_cr
	ld c," "				;prefix char = space
	call show_rr_cr
	
	call show_reg_run
	call os_print_string		;show PC
	
	ld a,(mem_select_store)
	and $f
	sub 1
	jr nc,fbnkok
	xor a
fbnkok	call os_show_hex_byte		;show BANK
	
	call os_print_string		
	ld a,(mem_select_store)
	call os_show_hex_byte		;show port 0
	
	ld hl,flag_txt			; show the CPU flags
	call os_copy_to_output_line
	ld hl,output_line+5
	ld bc,5
	ld a,(af_store1)
	bit 6,a				;zero flag
	jr z,zfzero
	ld (hl),'1'
zfzero	add hl,bc
	bit 0,a				;carry flag
	jr z,cfzero
	ld (hl),'1'
cfzero	add hl,bc
	bit 7,a				;sign flag
	jr z,sfzero
	ld (hl),'M'
sfzero	add hl,bc
	bit 2,a				;parity flag
	jr z,pfzero
	ld (hl),'O'
pfzero	add hl,bc
	inc hl
	
	ld a,(iff2_store)			;IFF flag
	bit 0,a
	jr z,iffzero
	ld (hl),'1'
	
iffzero	call os_print_output_line
	xor a
	ret




show_reg_run
	
	push bc
	
	ld a,c
	call os_print_char
	
	call os_print_string
	ld e,(ix)
	ld d,(ix+1)
	inc ix
	inc ix
	call os_show_hex_word
	
	pop bc
	
	ld a,(hl)
	or a
	jr nz,show_reg_run
	inc hl
	ret



show_rr_cr

	call show_reg_run
	call os_new_line
	ret
		
;---------------------------------------------------------------------------------
	
