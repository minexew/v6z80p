;-----------------------------------------------------------------------
;;G command - jump (Call) address. V6.00
;-----------------------------------------------------------------------

os_cmd_g:				
	ld a,1
	ld (store_registers),a	;this kernal command does store the registers
	
	call ascii_to_hexword	;DE = address
	cp $c
	ret z
	cp $1f
	jp z,os_no_args_error

	ld hl,os_nmi_freeze		;allow NMI freezer
	ld (nmi_vector),hl	 

	ld h,d			;user routine must "xor a" before "ret" to	
	ld l,e			;continue without displaying an incorrect error
	ld (com_start_addr),hl	;code or clear carry and set a to $ff for monitor
	jp (hl)			;restart on return	
				
;-----------------------------------------------------------------------
	