; UPDATE v1.00 - Bulk system Update
; ---------------------------------
;
; Must have data manually appended to assembled program file!
;
; + 64KB - BLOCK 0 data (all configs)
; + 128K - OSCA config for V6Z80P board
; + 128K - "" for V6Z80P+V1.0 board
; + 128k - "" for V6Z80P+V1.1b (board)
;
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

;------------------------------------------------------------------------------

data_buffer         equ $8000

;------------------------------------------------------------------------------

start		call kjt_clear_screen
		
		ld hl,menu_txt
		call kjt_print_string
		
menu_wait	ld a,1
		call kjt_get_input_string
		or a
		jp z,abort
		ld a,(hl)
		ld hl,board_type0
		cp "1"
		jr z,got_board
		ld hl,board_type1
		cp "2"
		jr z,got_board
		ld hl,board_type2
		cp "3"
		jr nz,start

got_board	sub $31
		ld (board_type),a
		push hl
		

;-------------------------------------------------------------------------------
		
		ld hl,confirm1_txt             
		call kjt_print_string
		pop hl
		call kjt_print_string
		ld hl,confirm2_txt
		call kjt_print_string
		ld a,1
		call kjt_get_input_string
		or a
		jp z,start
		ld a,(hl)
		cp "Y"
		jp nz,start
		
;-------------------------------------------------------------------------------

		ld hl,working_txt             
		call kjt_print_string

;-------------------------------------------------------------------------------
		
		ld hl,block0_txt             ; burn block 0
		call kjt_print_string

		xor a
		ld (block_number),a
		ld (source_bank),a
		call erase_block
		call write_block
		jr nz,epr_error
		call verify_block
		jr nz,epr_error


;-------------------------------------------------------------------------------
		
		ld hl,slot1_txt             ; burn slot 1
		call kjt_print_string
		
		ld a,(board_type)
		sla a
		sla a
		add a,2
		ld (source_bank),a
		ld a,2
		ld (block_number),a
		ld (blocks_to_write),a
	
nxt_page  	call erase_block    
		call write_block
		jr nz,epr_error
		call verify_block
		jr nz,epr_error
          
		ld hl,source_bank
		inc (hl)
		inc (hl)
		ld hl,block_number
		inc (hl)
		ld hl,blocks_to_write
		dec (hl)
		jr nz,nxt_page
          
;-------------------------------------------------------------------------------

		ld hl,set_slot1_txt             	; set power on slot 1
		call kjt_print_string

		ld a,1
		call set_power_on_boot_slot
		jp c,epr_error


;-------------------------------------------------------------------------------

		ld hl,done_txt                 		; show "completed" text
		call kjt_print_string
quit      	xor a
		ret


epr_error 	ld hl,eeprom_error
		call kjt_print_string
		xor a
		ret
                
          
abort    	ld hl,aborted_txt
		call kjt_print_string
		xor a
		ret                 
                    
;------------------------------------------------------------------------------------------

erase_block

		ld hl,erasing_block_txt                 ; show "verifying" text
		call kjt_print_string

		ld a,(block_number)           
		ld hl,block_num_txt 
		call kjt_hex_byte_to_ascii
		ld hl,block_num_txt                     ; show "erasing" text
		call kjt_print_string

		ld a,(block_number)                     ; erase the required 64KB eeprom sector 
		call erase_eeprom_sector
		ret

;------------------------------------------------------------------------------------------

write_block

		ld hl,writing_block_txt                 ; show "verifying" text
		call kjt_print_string

		ld a,(source_bank)
		call kjt_forcebank
		ld hl,data_buffer
		ld b,0                                  ; 256 pages to write
		ld a,(block_number)
		ld d,a
		ld e,0
dwrpagelp 	call program_eeprom_page
		or a
		jr nz,wr_error
		inc h
		jr nz,samebdb
		ld h,$80
		call kjt_incbank
samebdb   	inc de
		djnz dwrpagelp
		xor a
		ret

wr_error  	xor a
		inc a
		ret


;------------------------------------------------------------------------------------------

verify_block
          
		ld hl,verifying_block_txt               ; show "verifying" text
		call kjt_print_string
          
		ld a,(source_bank)
		call kjt_forcebank
		ld hl,data_buffer
		ld b,0
		ld a,(block_number)
		ld d,a
		ld e,0
dvrpagelp 	call read_eeprom_page
		or a
		jr nz,time_out_err
		ld ix,page_buffer
dverlp    	ld a,(ix)
		cp (hl)
		jr nz,ver_error
		inc ix
		inc l
		jr nz,dverlp
		inc h
		jr nz,dsamebnkv
		ld h,$80
		call kjt_incbank
dsamebnkv 	inc de
		djnz dvrpagelp
		xor a
		ret
          
ver_error 	xor a
		inc a
		ret

time_out_err

		xor a
		inc a
		ret
                              
          
;-----------------------------------------------------------------------------------

include "flos_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

;------------------------------------------------------------------------------------



menu_txt	db "V6Z80P Bulk Update 21-11-2013",11
		db "-----------------------------",11
		db 11
		db "Contains: OSCA:v676 (PAL) FLOS: v613",11
		db "          BOOTCODE v618",11,11
		
		db "This program writes to EEPROM block 0",11
		db "and slot 1, updating the bootcode,",11
		db "OS (on EEPROM) and OSCA Config",11
		db "in the first slot. Also, the power-on",11
		db "config slot will be set to 1.",11,11
		
		db "**  PLEASE USE THE 'EEPROM' UTIL IF  **",11
		db "** POSSIBLE INSTEAD OF THIS PROGRAM! **",11,11

		db "Which version of the V6Z80P board do",11
		db "you have?",11,11
		
		db "1. V6Z80P rev1.1",11
		db "2. V6Z80P+ rev1.0",11
		db "3. V6Z80P+ rev1.1(b)",11
		
		db 11,"Type 1,2,3 and Enter (or ESC to quit):",0
		
confirm1_txt    db 11,11,"---------------------------------------",11,11
		db "You selected: ",11,11,0


confirm2_txt	db "NOTE: It is critical the correct board",11
		db "is selected. If wrong, it may mean it",11
		db "can only be fixed via JTAG interface.",11,11		
		db "check PCB photos in the project folder:",11
		db "'Documentation/PCB related' if in doubt",11,11
		db "Absolutely sure? (y/n) ",0

board_type	db 0

working_txt	db 11,11,"---------------------------------------",11,11
		db "OK, working.. Please do not power off",11
		db "or reset until complete."
		db 11,11,"---------------------------------------",11,0

block0_txt	db 11,11,"Updating Block 0 (Pri Bootcode/OS)",11,11,0
slot1_txt	db "Updating Slot 1 (OSCA)",11,11,0
set_slot1_txt	db "Setting power-on cfg slot to SLOT 1..",11,11,0

done_txt	db 11
		db "************************************",11
		db "*  All done! Please power off and  *",11
		db "*   update your SD Card with the   *",11
		db "*  latest files from the project   *",11
		db "*   archive, if necessary. See:    *",11
		db "*       wiki.retroleum.co.uk       *",11
		db "************************************",11,11,0

eeprom_error    db 11,"** EEPROM Error! **",11,0


board_type0	db "V6Z80P rev1.1:",11
		db "This board is the original version of",11
		db "the V6Z80P - uniquely, it has a 6 pin",11
		db "miniDIN video connector and a 4-pin",11
		db "miniDIN serial port next to it.",11,11,0

board_type1	db "V6Z80P+ rev1.0:",11
		db "Uniquely, this board has a 3-pin serial",11
		db "connector",11,11,0

board_type2	db "V6Z80P+ rev1.1(b):",11
		db "Uniquely, this board has a tall 14MHz",11
		db "oscillator for Spectrum Emulation.",11
		db "The serial port is a 4-pin miniDIN",11
		db "located next to the mouse connector",11,11,0

erasing_block_txt   db "Erasing block $",0
block_num_txt       db "xx",11,0

writing_block_txt   db "Writing..",11,0

verifying_block_txt db "Verifying..",11,11,0

aborted_txt         db 11,11,"Aborted",11,11,0

block_number        db 0

blocks_to_write     db 0

source_bank         db 0

;------------------------------------------------------------------------------------

		org $7fff

		db 0
;------------------------------------------------------------------------------------