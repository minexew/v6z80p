
;-----------------------------------------------------------------------------------------------------------------
; EEPROM / PIC interogation related routines
;-----------------------------------------------------------------------------------------------------------------
;
; Routine List
; ------------
;
; get_eeprom_size - returns number of slots in A (and eeprom type in E, eeprom ID in D) 
;
; read_eeprom_id - returns eeprom type (0=25x, 1=SST25VF) in E, eeprom ID in D ($10-$16) 
;
; get_pic_fw - returns lower 2 digits of config PIC firmware in A *
;
; get_active_slot - returns the power on boot slot in A *
;
; * Old firmware may not support this feature and will fail with ZF not set on return.
;
;------------------------------------------------------------------------------------------------------------------

get_eeprom_size

; If ZF is set on return, number of slots is in A, ID in D, EEPROM Type in E

		di
		xor a
		ld (number_of_slots),a
		
		ld b,3					; Max attempts to read ID
rereadeid	push bc
		call read_eeprom_id
		pop bc
		jr z,eidtoslots
		djnz rereadeid
		ei
		xor a
		inc a
		jr epr_cmd_exit	
		
eidtoslots	sub $10					; convert EEPROM ID to slot count
		ld b,a
		ld a,1
slotslp		sla a
		djnz slotslp
		
		ld (number_of_slots),a
		ei
		cp a
		jr epr_cmd_exit
		

number_of_slots	db 0

;-----------------------------------------------------------------------------------------

epr_cmd_exit	push af
		call kjt_get_key			; as IRQs were switched off, clear the keyboard buffer in case of mangled input
		pop af
		ret
		
;-----------------------------------------------------------------------------------------
		
read_eeprom_id	

; If ZF is set on return, ID in D, EEPROM Type in E

		di
		in a,(sys_eeprom_byte)			; clear shift reg count with a read

		ld b,0					; wait a while to ensure PIC is ready for command
deloop2		djnz deloop2

		xor a
		out (sys_timer),a			; set timer to count 0-255
		out (sys_clear_irq_flags),a		; clear timer overflow flag
		ld (eeprom_type),a
		ld (eeprom_id_byte),a

		ld hl,cmd_get_eeprom_id			; send get ID command 
		call send_pic_command
			
		ld d,32					; D counts timer overflows
		ld a,1<<pic_clock_input			; prompt PIC to send a byte by raising PIC clock line
		out (sys_pic_comms),a
wbc_byte2	in a,(sys_hw_flags)			; have 8 bits been received?		
		bit 4,a
		jr nz,gbcbyte2
		in a,(sys_irq_ps2_flags)		; check for timer overflow..
		and 4
		jr z,wbc_byte2	
		out (sys_clear_irq_flags),a		; clear timer overflow flag
		dec d					; dec count of overflows,
		jr nz,wbc_byte2					
		xor a					; if waited too long give up (and drop PIC clock)
		out (sys_pic_comms),a
		jr ee_no_id				
gbcbyte2	xor a			
		out (sys_pic_comms),a			; drop PIC clock line, PIC will then wait for next high 
		in a,(sys_eeprom_byte)			; read byte received, clear bit count
		or a
		jr z,ee_no_id				; if received $00, read failed
		cp $ff				
		jr z,ee_no_id				; if received $ff, read failed
		cp $bf					; If SST25VF type EEPROM is present, we'll have received
		jr z,sst25type				; manufacturer's ID ($BF) not the capacity

got_eid		ld (eeprom_id_byte),a	
		ld de,(eeprom_type)
		ei
		cp a
		jr epr_cmd_exit

						
sst25type	ld a,1
		ld (eeprom_type),a			; set SST25vf flag

		call pic_delay				; wait a while to ensure PIC is ready for command	
		call pic_delay
		
		ld hl,cmd_get_alt_eeprom_id		; Use alternate "Get EEPROM ID" command to find ID 
		call send_pic_command
		
		call read_pic_byte
		or a
		jr z,ee_no_id				; if received $00, read failed
		cp $ff
		jr nz,got_eid				; if received $ff, read failed
		
ee_no_id	ei
		ld de,(eeprom_type)
		xor a					; ZF not set, error reading eeprom ID
		inc a
		jr epr_cmd_exit
		


cmd_get_eeprom_id

		db 2
		db $88,$53
		
cmd_get_alt_eeprom_id

		db 2
		db $88,$6c
		
eeprom_type	db 0					; 0 = 25x, 1=25vf
eeprom_id_byte	db 0


;----------------------------------------------------------------------------------------

get_pic_fw	di
		ld hl,cmd_get_fw
		call send_pic_command
		call read_pic_byte
post_pic_cmd	or a
		jr nz,gpfw_ok				; if returned $00, clear ZF (failed or really old firmware)
		ei
		inc a
		jp epr_cmd_exit

gpfw_ok		ei
		cp a					; ZF set, all ok
		jp epr_cmd_exit
		

cmd_get_fw	db 2
		db $88,$4e

;----------------------------------------------------------------------------------------

get_active_slot

		di
		ld hl,cmd_get_cfg_base
		call send_pic_command
		call read_pic_byte
		srl a
		jr post_pic_cmd
		
		
cmd_get_cfg_base

		db 2
		db $88,$76

;--------------------------------------------------------------------------------------		