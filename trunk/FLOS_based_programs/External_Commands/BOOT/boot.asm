; boot.exe command - reconfigs the FPGA v1.02
;
; Changes: 1.02 - when run without args, the EEPROM contents are displayed

;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;------------------------------------------------------------------------------------------------
; Actual program starts here..
;------------------------------------------------------------------------------------------------
	
		push hl			
		call get_eeprom_type
		pop hl
		
		ld a,(hl)				;any args supplied?	
		or a    
		jr nz,got_arg
	    
		call show_eeprom_slot_contents		;if args = null, show slot contents etc	
		
		ld hl,slot_prompt_txt
		call kjt_print_string
		ld a,2
		call kjt_get_input_string
		or a
		jr nz,got_arg
		ld a,$2d				; if no input show "aborted" error
		or a
		ret


got_arg		call kjt_ascii_to_hex_word		; is entered text a valid number (result in DE)?
		ld a,d
		or e
		jr z,badslot				; cant boot from slot 0
		
		ld a,(number_of_slots)	
		dec a
		cp e
		jr c,badslot
		
		ld a,e
		ld (slot_number),a
		
		ld hl,reconfig_txt
		call kjt_print_string
		
		ld b,244				; wait a second 
op2wait		xor a
		call kjt_timer_wait
		djnz op2wait					

		ld a,$88				; send "set config base" command
		call send_byte_to_pic
		ld a,$b8
		call send_byte_to_pic
		ld a,$00			
		call send_byte_to_pic			; send address low
		ld a,$00		
		call send_byte_to_pic			; send address mid
		ld a,(slot_number)
		sla a
		call send_byte_to_pic			; send address high

		ld a,$88				; send reconfigure command
		call send_byte_to_pic
		ld a,$a1
		call send_byte_to_pic
infloop		jr infloop


;--------------------------------------------------------------------------------------

badslot		ld hl,badslot_txt
		call kjt_print_string
		ld a,$80
		or a
		ret

;--------------------------------------------------------------------------------------


show_eeprom_slot_contents

		call kjt_clear_screen

		ld hl,contents_txt
		call kjt_print_string
		
		call kjt_get_cursor_position
		ld (cursor_pos),bc
		
		ld a,0
id_loop		ld (working_slot),a
		ld bc,(cursor_pos)
		cp 16
		jr nz,sameside
		push af
		ld a,c
		sub 16
		ld c,a
		pop af

sameside	jr c,leftside
		ld b,20	

leftside	call kjt_set_cursor_position
		inc c
		ld (cursor_pos),bc

		ld a,(working_slot)			
		ld hl,slot_number_text
		call kjt_hex_byte_to_ascii
		ld hl,slot_text
		call kjt_print_string
		ld hl,slot_number_text
		call kjt_print_string
		
		ld a,(working_slot)			;read in EEPROM page that contains the ID string
		or a
		jr nz,notszero
		ld hl,bootcode_text
		jr id_ok	

notszero	ld h,a
		ld l,0
		add hl,hl
		ld de,$01fb
		add hl,de
		ex de,hl
		call read_eeprom_page
		
		ld hl,page_buffer+$de			;location of ID (filename ASCII)
		ld a,(hl)
		or a
		jr z,unk_id
		bit 7,a
		jr z,id_ok
unk_id		ld hl,unknown_text
id_ok		call kjt_print_string
		ld hl,number_of_slots
		ld a,(working_slot)
		inc a
		cp (hl)
		jr nz,id_loop
		
		ret


;--------------------------------------------------------------------------------------


get_eeprom_type

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
		ret

no_id		xor a					;error reading eeprom ID
		inc a
		ret
		
				
;----------------------------------------------------------------------------------------
		
read_pic_byte

		ld (hl),0
		ld c,8				                 
nxt_bit		sla (hl)
		ld a,1<<pic_clock_input			; prompt PIC to present next bit by raising PIC clock line
		out (sys_pic_comms),a
		ld b,128				; wait a while so PIC can keep up..
pause_lp1	djnz pause_lp1
		xor a					; drop clock line again
		out (sys_pic_comms),a
		in a,(sys_hw_flags)			; read the bit into shifter
		bit 3,a
		jr z,nobit
		set 0,(hl)
nobit		ld b,128
pause_lp2	djnz pause_lp2
		dec c
		jr nz,nxt_bit
		ret

;------------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\eeprom_routines\eeprom_routines.asm"

;-------------------------------------------------------------------------------------------------

slot_number	db 0

cursor_pos	dw 0

working_slot	db 0

;------------------------------------------------------------------------------------------

contents_txt		db 11,"           EEPROM CONTENTS:",11
			db "           ----------------",11,11,0

slot_text		db " ",0
slot_number_text	db "xx - ",0
unknown_text		db "UNKNOWN",0
bootcode_text		db "BOOTCODE ETC",0

page_buffer		ds 256,0

eeprom_id_byte		db 0
number_of_slots		db 0

;------------------------------------------------------------------------------------------


reconfig_txt		db 11,11,"Reconfiguring...",0
badslot_txt		db 11,11,"Invalid slot selection.",11,0
slot_prompt_txt		db 11,11,"Enter slot to configure from: ",0

;-------------------------------------------------------------------------------------------
