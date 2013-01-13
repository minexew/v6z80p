

page_out_hw_registers

		push af
		ld a,%10000000
wr_awpp		out (sys_alt_write_page),a		; write "below" the hardware register range
		pop af
		ret


page_in_hw_registers
	
		push af
		xor a					; hardware registers are to be written, not the RAM underneath. 
		jr wr_awpp
		
					
;----------------------------------------------------------------------------------------------

os_readmemflat

		ld c,sys_mem_select			;7 put byte from memory location E:HL into A
		ld a,h					;4
		rlca					;4 convert flat memory location to bank:addr
		rl e					;8
		jr z,lopage1				;13
		set 7,h					;8
lopage1		in b,(c)				;12 get current bank
		out (c),e				;12 set bank reqd for read
		ld a,(hl)				;7  get byte at location in A
		out (c),b				;12 restore original bank
		ret					;10


os_writememflat

		ld c,sys_mem_select			;Write byte in A to memory location E:HL
		ld b,h					;convert flat memory location to bank:addr
		sla b
		rl e
		jr z,lopage2
		set 7,h
lopage2		in b,(c)				;get current bank
		out (c),e				;set bank reqd for write
		ld (hl),a				;get byte at location in A
		out (c),b				;restore original bank
		ret		


;----------------------------------------------------------------------------------------------

os_read_baddr

;Set:
;b:hl = bank:addr
;Return
;A = byte from address

		push bc
		inc b
		ld c,sys_mem_select
		in a,(c)
		out (c),b
		ld b,(hl)
		out (c),a
		ld a,b
		pop bc
		ret

	
os_write_baddr

;Set:
;b:hl = bank:addr
;A = byte to write

		push bc
		push de
		inc b
		ld c,sys_mem_select
		in e,(c)
		out (c),b
		ld (hl),a
		out (c),e
		pop de
		pop bc
		ret
		
	
	
os_get_flos_bank

		ld a,(bank_pre_cmd)
		ret
		
;-----------------------------------------------------------------------------------------------
