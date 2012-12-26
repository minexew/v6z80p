
program_eeprom_page

		di
		
		push hl			;DE = 256-byte page number to write
		push de			;HL = address of source data 
		push bc
	
		ld (wep_addr+1),de		; fill in values for databurst command sequence 
		xor a
		ld (wep_addr+0),a

		call enter_programming_mode

ee_prpalp	push hl
		ld hl,cmd_write_to_eeprom
		call send_pic_command		;send "write to EEPROM" command
		pop hl
		
		ld b,64				;send 64 byte data packet to burn
ee_wdplp1	ld a,(hl)
		call send_byte_to_pic
		inc hl
		djnz ee_wdplp1
		call wait_pic_busy		;wait for EEPROM burn to complete
		jp c,ee_pop_to_err
		ld a,(wep_addr+0)
		add a,$40
		ld (wep_addr+0),a
		jr nc,ee_prpalp
	
ee_pop_ok_ret	call exit_programming_mode
		pop bc
		pop de
		pop hl
		ei
		xor a
		ret

ee_pop_to_err	call exit_programming_mode
		pop bc
		pop de
		pop hl
		ei
		ld a,1
		or a
		ret

	
cmd_write_to_eeprom

		db 5
		db $88,$98
wep_addr	db $00,$00,$00

	

;--------------------------------------------------------------------------------


erase_eeprom_sector

		di
		push af			; put 64KB sector number to erase in A
		push hl
		ld (ee_sector_erase),a
		
		call enter_programming_mode
		
		ld hl,cmd_erase_eeprom_sector
		call send_pic_command
		call wait_pic_busy		; wait for EEPROM burn to complete

		call exit_programming_mode
		pop hl
		pop af
		cp a
		ei
		ret


cmd_erase_eeprom_sector

		db 5
		db $88,$f5,$00,$00
ee_sector_erase	db $00


;----------------------------------------------------------------------------------------

set_power_on_boot_slot

		call set_config_slot
 
		call enter_programming_mode
        
		ld hl,cmd_set_boot_slot
		call send_pic_command
		call wait_pic_busy            			; wait for PIC to complete update
		
		push af					; preserve carry flag
		call exit_programming_mode
		pop af
		ret
	  
cmd_set_boot_slot

		db 4
		db $88,$37,$d8,$06
		
;-----------------------------------------------------------------------------------------------------------------
			
	
enter_programming_mode

		push hl
		ld hl,cmd_enter_programming_mod
		call send_pic_command
		pop hl
		ret


cmd_enter_programming_mod

		db 4
		db $88,$25,$fa,$99
		

;----------------------------------------------------------------------------------------
	

exit_programming_mode

		push hl
		ld hl,cmd_exit_programming_mod
		call send_pic_command
		pop hl
		ret


cmd_exit_programming_mod

		db 2
		db $88,$1f


;----------------------------------------------------------------------------------------
			