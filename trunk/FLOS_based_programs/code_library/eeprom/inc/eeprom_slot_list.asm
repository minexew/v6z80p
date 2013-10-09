;-----------------------------------------------------------------------------------------------------------------
; EEPROM slot list routine
;-----------------------------------------------------------------------------------------------------------------
;
; Routine List
; ------------
;
; eeprom_slot_list     - displays the contents of the EEPROM's slots
; get_eeprom_slot_name - sets HL to the address of the text ID string associated with the slot number held in A
;
;------------------------------------------------------------------------------------------------------------------
	  
eeprom_slot_list
	  
		call get_eeprom_size
		jr z,got_esize
		
		call get_pic_fw				; eeprom ID read failed, read PIC firmware..
		ld b,4
		jr nz,slots4				; if firmware version >634 assume 8 slots else 4
		cp $35
		jr c,slots4
		ld b,8
slots4		ld a,b
		ld (number_of_slots),a
		
		ld hl,est_size_txt
		call kjt_print_string
	  
got_esize	call kjt_get_cursor_position
		ld (ee_cursor_pos),bc
		  
		xor a
id_loop   	ld (ee_working_slot),a
		ld bc,(ee_cursor_pos)
		cp 16
		jr nz,sameside
		push af
		ld a,c
		sub 16
		ld c,a
		pop af

sameside  	jr c,leftside
		ld b,20   

leftside  	call kjt_set_cursor_position
		inc c
		ld (ee_cursor_pos),bc
		ld a,(ee_working_slot)                     
		ld hl,slot_number_txt+1
		call kjt_hex_byte_to_ascii
		ld hl,slot_number_txt
		call kjt_print_string
		  
		ld a,(ee_working_slot)                  ; read in EEPROM page that contains the ID string
		call get_eeprom_slot_name
		call kjt_print_string
		ld hl,number_of_slots
		ld a,(ee_working_slot)
		inc a
		cp (hl)
		jr nz,id_loop
		
		inc c
		ld b,0
		call kjt_set_cursor_position
		
		xor a
		ret


;--------------------------------------------------------------------------------------------------------------------

get_eeprom_slot_name

		ld hl,bootcode_txt			;set A to slot number
		or a
		ret z
		
		ld h,a
		ld l,0
		add hl,hl
		ld de,$01fb
		add hl,de
		ex de,hl
		call read_eeprom_page
		jr z,eerep_ok  
		ld hl,ee_repf_txt
		jr id_ok
eerep_ok	ld hl,page_buffer+$de                   ;location of ID (filename ASCII)
		ld a,(hl)
		or a
		jr z,unk_id
		bit 7,a
		jr z,id_ok
unk_id    	ld hl,unknown_txt
id_ok     	ret

;----------------------------------------------------------------------------------------------------------------------

est_size_txt	db "Note: Command GET_EEPROM_SIZE failed..",11

slot_number_txt	db " xx:",0
unknown_txt	db "UNKNOWN",0
bootcode_txt    db "BOOTCODE ETC",0
ee_repf_txt	db "READ FAILED",0

ee_cursor_pos	dw 0
ee_working_slot	db 0
