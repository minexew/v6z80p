; V6Z80P EEPROM ROUTINES V1.02
; ----------------------------
;
; Main routine list:
; -------------------
; Program_eeprom_page (all 256 bytes of page must be $ff prior to write)
; read_eeprom_page    (reads 256 bytes to address label "page_buffer")
; erase_eeprom_sector (erases a 64KB sector to all $ff)
; get_eeprom_size     (returns number of slots, ZF not set on error)
; list_eeprom_contents (shows all slots contents)
;
; Subroutine list:
; ----------------
; send_byte_to_pic
; wait_pic_busy
; enter_programming_mode
; exit_programming_mode
; read_pic_byte
;
; Note: Code uses some sofware timing loops so it's probably best to disable/re-enable
; interrupts around calls.
;  
; Changes:
;
; V1.02 - added "list_eeprom_contents", "get_eeprom_size" and "read_pic_byte" routines
; V1.01 - "Wait busy" now times out after 5 seconds (not 1 second)
; 
;-------- EEPROM CONSTANTS -------------------------------------------------------------

pic_data_input	 equ 0	; from FPGA to PIC (bit 0 of sys_pic_comms)
pic_clock_input	 equ 1	; from FPGA to PIC (bit 1 of sys_pic_comms)

pic_clock_output equ 3	; from PIC to FPGA (bit 3 of sys_hw_flags) 

;--------- EEPROM SUBROUTINES ----------------------------------------------------------

program_eeprom_page

	push hl			;DE = 256-byte page number to write
	push de			;HL = address of source data 
	push bc
	
	ld a,d
	ld (page_hi),a
	ld a,e
	ld (page_med),a

	call enter_programming_mode

	ld a,$88			;send "write to EEPROM" command
	call send_byte_to_pic
	ld a,$98
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		;send address low
	ld a,(page_med)	
	call send_byte_to_pic		;send address mid
	ld a,(page_hi)
	call send_byte_to_pic		;send address high
	
	ld b,64				;send 64 byte data packet to burn
wdplp1	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz wdplp1
	call wait_pic_busy		;wait for EEPROM burn to complete
	jp c,toer3

	ld a,$88			;send "write to EEPROM" command
	call send_byte_to_pic
	ld a,$98
	call send_byte_to_pic
	ld a,$40			
	call send_byte_to_pic		;send address low
	ld a,(page_med)	
	call send_byte_to_pic		;send address mid
	ld a,(page_hi)
	call send_byte_to_pic		;send address high
	
	ld b,64				;send 64 byte data packet to burn
wdplp2	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz wdplp2
	call wait_pic_busy		;wait for EEPROM burn to complete
	jp c,toer3

	ld a,$88			;send "write to EEPROM" command
	call send_byte_to_pic
	ld a,$98
	call send_byte_to_pic
	ld a,$80			
	call send_byte_to_pic		;send address low
	ld a,(page_med)	
	call send_byte_to_pic		;send address mid
	ld a,(page_hi)
	call send_byte_to_pic		;send address high
	
	ld b,64				;send 64 byte data packet to burn
wdplp3	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz wdplp3
	call wait_pic_busy		;wait for EEPROM burn to complete
	jp c,toer3
	
	ld a,$88			;send "write to EEPROM" command
	call send_byte_to_pic
	ld a,$98
	call send_byte_to_pic
	ld a,$c0			
	call send_byte_to_pic		;send address low
	ld a,(page_med)	
	call send_byte_to_pic		;send address mid
	ld a,(page_hi)
	call send_byte_to_pic		;send address high
	
	ld b,64				;send 64 byte data packet to burn
wdplp4	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz wdplp4
	call wait_pic_busy		;wait for EEPROM burn to complete
	jr c,toer3
	
	call exit_programming_mode
	pop bc
	pop de
	pop hl
	xor a
	ret


toer3	call exit_programming_mode
	pop bc
	pop de
	pop hl
	ld a,1
	ret
	
	
;---------------------------------------------------------------------------------

read_eeprom_page

	push hl			;put page number to read to buffer in DE
	push de
	push bc
	
	ld a,d
	ld (page_hi),a
	ld a,e
	ld (page_med),a
	
	in a,(sys_eeprom_byte)		;at outset, clear input byte shift count with a read
	
	ld a,$88			;send "set databurst location" command
	call send_byte_to_pic
	ld a,$d4
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		;send address low
	ld a,(page_med)	
	call send_byte_to_pic		;send address mid
	ld a,(page_hi)
	call send_byte_to_pic		;send address high
	
	ld a,$88			;send "set databurst location" command
	call send_byte_to_pic
	ld a,$e2
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		;send length low
	ld a,$01	
	call send_byte_to_pic		;send length mid
	ld a,$00
	call send_byte_to_pic		;send length high
	
	ld a,$88			;send "start databurst" command
	call send_byte_to_pic
	ld a,$c9
	call send_byte_to_pic

	ld hl,page_buffer		; download loop.. 
	ld bc,$100			; page = 256 bytes                 
nxt_byte
	ld d,0				; D counts timer overflows
	ld a,1<<pic_clock_input		; raise clock to prompt PIC to send a byte
	out (sys_pic_comms),a
wbc_byte
	in a,(sys_hw_flags)		; have 8 bits been received?		
	bit 4,a
	jr nz,gbcbyte
	in a,(sys_irq_ps2_flags)	; check for timer overflow..
	and 4
	jr z,wbc_byte	
	out (sys_clear_irq_flags),a	; clear timer overflow flag
	inc d				; inc count of overflows,
	jr nz,wbc_byte			
	ld a,1				; timed out error
	pop bc
	pop de
	pop hl
	ret
				
gbcbyte	xor a				; drop pic clock
	out (sys_pic_comms),a	
	in a,(sys_eeprom_byte)		; read byte received (clears bit count)
	ld (hl),a			; copy to dest, loop back to wait for next byte
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,nxt_byte
	pop bc
	pop de
	pop hl
	xor a
	ret
	

;--------------------------------------------------------------------------------

erase_eeprom_sector

	push af			;put 64KB sector number to erase in A
	ld (erase_sector),a

	call enter_programming_mode
	
	ld a,$88			;send "erase 64KB EEPROM block" command
	call send_byte_to_pic
	ld a,$f5
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		;send address low - note: 64KB granularity
	ld a,$00		
	call send_byte_to_pic		;send address mid - note: 64KB granularity
	ld a,(erase_sector)
	call send_byte_to_pic		;send address high - note: 64KB granularity
	call wait_pic_busy		;wait for EEPROM burn to complete

	call exit_programming_mode
	pop af
	ret

	
;-----------------------------------------------------------------------------------	

send_byte_to_pic

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

	push bc
	push de
	ld c,a			
	ld d,8
bit_loop
	xor a
	rl c
	jr nc,zero_bit
	set pic_data_input,a
zero_bit
	out (sys_pic_comms),a		; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a		; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1			; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a		; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2			; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60				; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp			; allows time for PIC to act on received byte
	pop de				; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			


;-------------------------------------------------------------------------------------------


wait_pic_busy

	push de
	ld de,0
	
wait_pic
	in a,(sys_irq_ps2_flags)	; check for timer overflow..
	and 4
	jr z,test_pic	
	out (sys_clear_irq_flags),a	; clear timer overflow flag
	inc de				; inc count of overflows
	ld a,d
	cp 5
	jr nz,test_pic			; every 256 DE increments = 1 second		
	pop de
	scf				; timed out error - carry flag set
	ret
	
test_pic
	in a,(sys_hw_flags)		; if PIC is holding its clock output high it is
	bit pic_clock_output,a		; busy and cannot accept data bytes at this time
	jr nz,wait_pic
	pop de
	scf
	ccf				; carry flag zero if OK
	ret


;-----------------------------------------------------------------------------------------
	
enter_programming_mode
	
	ld a,$88			;send "enter programming mode" command
	call send_byte_to_pic
	ld a,$25
	call send_byte_to_pic
	ld a,$fa
	call send_byte_to_pic
	ld a,$99
	call send_byte_to_pic
	ret

;-----------------------------------------------------------------------------------------
	
exit_programming_mode

	ld a,$88			;send "disable programming mode" command
	call send_byte_to_pic
	ld a,$1f
	call send_byte_to_pic
	ret
	
;-----------------------------------------------------------------------------------------

get_eeprom_size
		
		ld a,4					; As a safety default, set number of slots to 4
		ld (number_of_slots),a
	
		ld b,3
rereadeid	push bc
		call read_eeprom_id
		pop bc
		jr nz,eiderr
		cp $ff
		jr z,eiderr
		cp a
		ret
eiderr		djnz rereadeid
		xor a
		inc a
		ret	
		

read_eeprom_id	ld b,0					; wait a while to ensure PIC is ready for command
deloop2		djnz deloop2

		xor a
		out (sys_timer),a			; set timer to count 0-255
		out (sys_clear_irq_flags),a		; clear timer overflow flag
		ld (eeprom_type),a
		
		in a,(sys_eeprom_byte)			; clear shift reg count with a read

		ld a,$88				; send PIC the command to prompt the EEPROM to
		call send_byte_to_pic			; return its ID code byte
		ld a,$53
		call send_byte_to_pic
			
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
		jr no_id				
gbcbyte2	xor a			
		out (sys_pic_comms),a			; drop PIC clock line, PIC will then wait for next high 
		in a,(sys_eeprom_byte)			; read byte received, clear bit count
	
		cp $bf					; If SST25VF type EEPROM is present, we'll have received
		jr nz,got_eid				; manufacturer's ID ($BF) not the capacity
		
		ld a,1
		ld (eeprom_type),a			; set SST25vf flag
		ld b,0					; wait a while to ensure PIC is ready for command
deloop1		djnz deloop1		
		ld a,$88				; Use alternate "Get EEPROM ID" command to find ID 
		call send_byte_to_pic		
		ld a,$6c
		call send_byte_to_pic
		ld hl,eeprom_id_byte			
		call read_pic_byte
		ld a,(hl)
		
got_eid		ld (eeprom_id_byte),a	
		sub $10
		ld b,a
		ld a,1
slotslp		sla a
		djnz slotslp
		ld (number_of_slots),a
		cp a
		ret

no_id		xor a					;error reading eeprom ID
		inc a
		ret
		
				
;----------------------------------------------------------------------------------------
		
read_pic_byte
		ld b,0					; wait a while to ensure PIC is ready
deloop3		djnz deloop3
		
		ld (hl),0
		ld c,8				                 
nxt_bit		sla (hl)
		ld a,1<<pic_clock_input			; prompt PIC to present next bit by raising PIC clock line
		out (sys_pic_comms),a
		ld b,0					; wait a while so PIC can keep up..
pause_lp1	djnz pause_lp1
		xor a					; drop clock line again
		out (sys_pic_comms),a
		in a,(sys_hw_flags)			; read the bit into shifter
		bit 3,a
		jr z,nobit
		set 0,(hl)
nobit		ld b,0
pause_lp2	djnz pause_lp2
		dec c
		jr nz,nxt_bit
		ret

;------------------------------------------------------------------------------------------
	  
list_eeprom_contents
	  
		call get_eeprom_size
		jr z,got_esize
		
		ld hl,utgesize_txt
		call kjt_print_string
		ld a,4
		ld (number_of_slots),a
	  
got_esize	call kjt_get_cursor_position
		ld (cursor_pos),bc
		  
		ld a,0
id_loop   	ld (working_slot),a
		ld bc,(cursor_pos)
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
		ld (cursor_pos),bc
		ld a,(working_slot)                     
		ld hl,slot_number_txt+1
		call kjt_hex_byte_to_ascii
		ld hl,slot_number_txt
		call kjt_print_string
		  
		ld a,(working_slot)                     ;read in EEPROM page that contains the ID string
		or a
		jr nz,notszero
		ld hl,bootcode_txt
		jr id_ok  

notszero  	ld h,a
		ld l,0
		add hl,hl
		ld de,$01fb
		add hl,de
		ex de,hl
		call read_eeprom_page
		  
		ld hl,page_buffer+$de                   ;location of ID (filename ASCII)
		ld a,(hl)
		or a
		jr z,unk_id
		bit 7,a
		jr z,id_ok
unk_id    	ld hl,unknown_txt
id_ok     	call kjt_print_string
		ld hl,number_of_slots
		ld a,(working_slot)
		inc a
		cp (hl)
		jr nz,id_loop
		ret

utgesize_txt	db "Unable to read EEPROM size.",11
		db "Defaulting to 4 slots.",11,11,0

slot_number_txt	db " xx:",0
unknown_txt	db "UNKNOWN",0
bootcode_txt    db "BOOTCODE ETC",0

;------------------------------------------------------------------------------------------
	  

page_lo		db 0
page_med	db 0
page_hi		db 0

erase_sector 	db 0

eeprom_type	db 0		;0 = 25x, 1=25vf
eeprom_id_byte	db 0
number_of_slots	db 0

;------------------------------------------------------------------------------------------
