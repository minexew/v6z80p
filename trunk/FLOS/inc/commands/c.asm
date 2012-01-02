;-----------------------------------------------------------------------
;"c" - Copy memory command. V6.04
;-----------------------------------------------------------------------

os_cmd_c

	call get_start_and_end	;this routine only returns here if start/end data is valid
	
	call hexword_or_bust	;only returns here if the hex in DE (destination address) is valid
	jp z,os_no_d_addr_error
	ld (copy_dest_address),de

	inc hl
	call hexword_or_bust	;the call only returns here if the hex in DE is valid
	jp z,copytsb		;1f = no args so copy to same bank
	ld a,e
	cp max_bank+1
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

copydone	ld a,$20			;completion message
	or a
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

get_start_and_end

	call ascii_to_hexword	;get start address
	ld (cmdop_start_address),de
	inc hl
	or a
	jr z,st_addrok
	pop hl			;this pop is remove originating call addr from the stack
	cp $c			;bad hex error code
	jr z,c_badhex
	ld a,$16			;no start address error code
c_badhex	or a
	ret
	
st_addrok	call ascii_to_hexword	;get end address
	ld (cmdop_end_address),de
	inc hl
	or a
	ret z
	pop hl			;this pop is remove originating call addr from the stack
	cp $c			;bad hex error code
	jr z,c_badhex
	ld a,$1c			;no end address error code
	ret
	
;------------------------------------------------------------------------

