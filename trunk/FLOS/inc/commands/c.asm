;-----------------------------------------------------------------------
;"c" - Copy memory command. V6.02
;-----------------------------------------------------------------------

os_cmd_c

	call get_start_and_end
	cp $c			;bad hex?
	ret z
	cp $1f		
	jp z,os_no_start_addr	;no start address
	cp $20
	jp z,os_no_e_addr_error	;no end address
	
	call ascii_to_hexword	;get destination address in DE
	cp $c
	ret z
	cp $1f
	jp z,os_no_d_addr_error
	ld (copy_dest_address),de
	inc hl
	call ascii_to_hexword	;get dest bank number if supplied 
	cp $c
	ret z
	cp $1f
	jp z,copytsb		;1f = no args so copy to same bank
	ld a,e
	call test_bank
	jp nc,os_invalid_bank
	
	ld (copy_dest_bank),a
	call set_copy_regs		;bank flipping copy
	jp c,os_range_error		;abort if end addr < start addr
	call os_cachebank
bfcopylp	call os_restorebank
	push bc
	ld b,(hl)
	ld a,(copy_dest_bank)
	call os_forcebank	
	ld a,b
	ld (de),a
	pop bc
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,bfcopylp
	call os_restorebank
	jr copydone	
	
copytsb	call set_copy_regs		;straightforward copy - no bank flipping	
	jp c,os_range_error		;abort if end addr <= start addr
	ldir

copydone	xor a			;completion message
	ld a,$20
	ret

;-----------------------------------------------------------------------


get_start_and_end

	call ascii_to_hexword	;get start address
	inc hl
	ld (cmdop_start_address),de
	or a
	ret nz
	
	call ascii_to_hexword	;get end address
	inc hl
	ld (cmdop_end_address),de
	cp $c
	ret z
	cp $1f
	ret nz
	inc a
	ret

;-----------------------------------------------------------------------

set_copy_regs

; on return:
;
; carry flag = range valid or not
; BC = run length on return
; HL = start address

	ld hl,(cmdop_end_address)	
	ld bc,(cmdop_start_address)
	push bc
	ld de,(copy_dest_address)
	xor a
	sbc hl,bc
	ld b,h
	ld c,l
	inc bc
	pop hl
	ret
	
;------------------------------------------------------------------------
