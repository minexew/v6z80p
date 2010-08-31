; ****************************************************************************
; * ONBOARD EEPROM MANAGEMENT TOOL FOR VxZ80P V1.12 - P.Ruston '08 - '09     *
; ****************************************************************************


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- CONSTANTS ----------------------------------------------------------

data_buffer 	equ $8000 ; Dont change this

req_hw_version	equ $280

;--------------------------------------------------------------------------
; Check hardware revision is appropriate for code
;--------------------------------------------------------------------------

	call kjt_get_version
	ld hl,req_hw_version-1
	xor a
	sbc hl,de
	jr c,hw_vers_ok
	
	ld hl,bad_hw_vers
	call kjt_print_string
	xor a
	ret
	
bad_hw_vers

	db 11,"Program requires hardware version v280+",11,11,0
	
hw_vers_ok

;--------------------------------------------------------------------------------
; Check FLOS version
;-------------------------------------------------------------------------------

	call kjt_get_version		
	ld de,$544
	xor a
	sbc hl,de
	jr nc,flos_ok
	
	ld hl,old_flos_txt
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v544+",11,11,0

flos_ok	


;-------- INIT -----------------------------------------------------------------

	xor a	
	out (sys_timer),a		; set timer - 256 overflows per irq

	in a,(sys_serial_port)	; flush serial buffer at prog start


;-------- V5Z80P compatibility -------------------------------------------------

	ld a,%00000010		; set PIC clock high (NMI inactive during
	out (sys_pic_comms),a	; change over)

	ld a,%00000001		; disable NMI switch, enabled PIC comms
	ld hl,vreg_read		;
	bit 5,(hl)		; keep 60Hz mode if active
	jr z,pal50hz		;	
	ld a,%00000101		; NMI inhibit + 60Hz mode
pal50hz	out (sys_hw_settings),a

	ld a,%00000000		; set PIC clock low for microcontroller 
	out (sys_pic_comms),a	; commands etc


;-------- MAIN LOOP -----------------------------------------------------------

	
begin	call show_banner
	call show_eeprom_type
	ld hl,start_text2
	call kjt_print_string

waitkey	call kjt_wait_key_press

	cp $76
	jr z,quit

	ld a,b
	or a
	jr z,waitkey
	cp "1"
	jr z,option_1
	cp "2"
	jp z,option_2
	cp "3"
	jp z,option_3
	cp "4"
	jp z,option_4
	cp "5"
	jp z,option_5
	cp "6"
	jp z,option_6	
	cp "7"
	jp z,option_7	
	
	jr waitkey

quit

;-------- V5Z80P compatibility ----------------------------------------------

	ld a,%00000010		; set PIC clock high (NMI inactive during
	out (sys_pic_comms),a	; change over)

	ld a,%00000000		; enable NMI switch, disables PIC comms
	ld hl,vreg_read		;
	bit 5,(hl)		; keep 60Hz mode if active
	jr z,pal50hzb		;	
	ld a,%00000100		; NMI not disabled + 60Hz mode
pal50hzb	out (sys_hw_settings),a

;------------------------------------------------------------------------------
	
	xor a			; exit to OS
	ret
	
	
;---------------------------------------------------------------------------------
;-------- OPTION 1: Write an FPGA config file to a slot in EEPROM ----------------
;---------------------------------------------------------------------------------


option_1	call show_banner
	call show_slot_ids

	ld hl,filename_txt
	ld bc,16
	xor a
	call kjt_bchl_memfill

	ld hl,slot_prompt_text	; which slot?
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,begin
	call kjt_ascii_to_hex_word	; returns de = slot number
	or a
	jp nz,invalid_input
	ld a,e
	ld (slot_number),a
	or a
	jp z,slot_zero		; dont allow writes to slot 0 
	ld hl,number_of_slots
	cp (hl)
	jp nc,invalid_input
	
	ld hl,active_slot
	cp (hl)			; if uploading to current active slot show warning
	jr nz,ok_to_wr
	ld hl,warning_1_text
	call kjt_print_string
	call kjt_get_input_string	; and ask for confirmation
	or a
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,begin

ok_to_wr	ld a,0			; fill 128KB data buffer with $ff
	call kjt_forcebank
	ld b,4
fbloop	push bc
	ld a,$ff
	ld bc,$8000		; databuffer = 4 x 32KB upper RAM pages
	ld hl,data_buffer
	call kjt_bchl_memfill
	call kjt_incbank
	pop bc
	djnz fbloop

	ld hl,cfg_prompt_txt	; serial download or diskload?
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "d"
	jr z,sdownload
	cp "l"
	jp nz,begin
	
	ld hl,filename_prompt_txt	; get filename for disk load
	call kjt_print_string
	call kjt_get_input_string	
	or a
	jp z,begin

	push hl
	ld de,filename_txt
	ld b,16
fnloop1	ldi
	or a
	jr z,fnc_done1
	djnz fnloop1
fnc_done1	pop hl

	call kjt_find_file
	jr nz,file_error
	push ix
	pop bc
	push iy
	pop de
	ld hl,$fbdc		;check file length
	xor a
	sbc hl,de
	jr nz,flenerr
	ld hl,$0001
	xor a
	sbc hl,bc
	jr z,flen_ok
flenerr	ld hl,cfg_file_error_text
	jp do_end

disk_error
	ld hl,disk_error_txt
	jp do_end
file_error
	ld hl,file_error_txt
	jp do_end
	
flen_ok	ld hl,loading_txt
	call kjt_print_string

	ld hl,data_buffer		;load address
	ld b,0			;bank 0
	call kjt_force_load		;load config data to buffer	
	jr nz,file_error
	jp cfgloaded	
	
	

sdownload	ld hl,download_text		; ask for serial file
	call kjt_print_string

recwloop	ld hl,wildcard_filename	; filename address
	ld ix,data_buffer		; load address
	ld b,0			; load to bank 0
	ld a,1			; time out = 1 second
	call kjt_serial_receive_header
	jr z,fh_ok
	cp $14			; only a time out error?
	jp nz,serial_error
	call animate_working_chars
	call kjt_get_key		; pressed ESC?
	cp $76
	jp z,begin	
	jr recwloop
	
fh_ok	push ix			; show "receiving filename.bin"
	ld hl,receiving_text
	call kjt_print_string
	pop hl
	ld de,filename_txt
	ld bc,16
	ldir
	ld hl,filename_txt
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string
	ld l,(ix+18)		; config file must be < $1ffff bytes
	ld h,(ix+19)
	ld a,h
	or a
	jp nz,too_big
	ld a,l
	and $fe
	jp nz,too_big

fsok	call kjt_serial_receive_file	; download the file
	jp nz,serial_error

cfgloaded	ld a,0			; is is a Xilinx cfg file?
	call kjt_forcebank
	ld hl,data_buffer
	ld de,cfg_id
	ld b,8
	call kjt_compare_strings
	jp nc,not_cfg_error
	
	ld a,3
	call kjt_forcebank
	ld hl,filename_txt		; attach the filename to the end of the cfg string
	ld de,data_buffer+$7bde
	ld bc,18
	ldir	
	
	ld a,(slot_number)		
	ld hl,erase_chars
	call kjt_hex_byte_to_ascii
	ld hl,erasing_text		; show "erasing slot xx" text
	call kjt_print_string
	ld a,(slot_number)		; erase the required 2 x 64KB eeprom sectors 
	sla a
	call erase_eeprom_sector
	inc a
	call erase_eeprom_sector
	
	ld hl,writing_text		; show "writing" text
	call kjt_print_string
	ld a,0
	call kjt_forcebank
	ld hl,data_buffer
	ld bc,512			; 512 x 256 byte pages = 128KB
	ld a,(slot_number)
	sla a
	ld d,a
	ld e,0			; de = EEPROM page
wrpagelp	call program_eeprom_page
	or a
	jp nz,write_error
	inc h			; next databuffer page
	jr nz,samebank
	ld h,$80
	call kjt_incbank
samebank	call animate_working_chars
	inc de			; next eeprom page
	dec bc
	ld a,b
	or c
	jr nz,wrpagelp
	
	ld hl,verifying_text	; show "verifying" text
	call kjt_print_string
	ld a,0
	call kjt_forcebank
	ld hl,data_buffer
	ld bc,512
	ld a,(slot_number)
	sla a
	ld d,a
	ld e,0
vrpagelp	call read_eeprom_page
	or a
	jr nz,time_out_error
	ld ix,page_buffer
verlp	ld a,(ix)
	cp (hl)
	jp nz,verify_error
	inc ix
	inc l
	jr nz,verlp
	inc h
	jr nz,samebankv
	ld h,$80
	call kjt_incbank
samebankv	call animate_working_chars
	inc de
	dec bc
	ld a,b
	or c
	jr nz,vrpagelp

	ld hl,ok_text		; show "completed" text
	call kjt_print_string
	call kjt_wait_key_press
	jp begin


time_out_error

	ld hl,time_out_text		; timed out waiting for databurst
do_end	call kjt_print_string
	call kjt_wait_key_press
	jp begin

serial_error

	ld hl,serial_error_text	; serial comms problem
	jr do_end


too_big	ld hl,file_too_big_text	; file too big
	jr do_end

write_error

	ld hl,write_error_text
	jr do_end

verify_error

	ld hl,verify_error_text
	jr do_end
	

invalid_input

	ld hl,input_error_text
	jr do_end

not_cfg_error
	
	ld hl,cfg_file_error_text
	jr do_end

slot_zero

	ld hl,slot_zero_text
	jr do_end
		
;---------------------------------------------------------------------------------
;-------- OPTION 2: Reconfigure the FPGA from a slot now -------------------------
;---------------------------------------------------------------------------------


option_2	call show_banner

	call show_slot_ids

	ld hl,reconfig_now_text	; reconfig now - what slot?
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,begin
	call kjt_ascii_to_hex_word	; de = slot number
	or a
	jp nz,invalid_input
	ld a,e
	ld (slot_number),a
	or a
	jp z,slot_zero
	ld hl,number_of_slots
	cp (hl)
	jp nc,invalid_input	
	

	ld hl,restart_text
	call kjt_print_string

	ld d,0				; wait a second 
op2wait	in a,(sys_irq_ps2_flags)		 
	and 4
	jr z,op2wait	
	out (sys_clear_irq_flags),a		 
	dec d				
	jr nz,op2wait					


	ld a,$88			; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic	; send address low
	ld a,$00		
	call send_byte_to_pic	; send address mid
	ld a,(slot_number)
	sla a
	call send_byte_to_pic	; send address high

	ld a,$88			; send reconfigure command
	call send_byte_to_pic
	ld a,$a1
	call send_byte_to_pic

	jp begin

		
;---------------------------------------------------------------------------------	
;--------- OPTION 3: Change the slot the FPGA configures from on power up --------
;---------------------------------------------------------------------------------

option_3	call show_banner

	call show_slot_ids
	
	ld hl,set_slot_text		; change config to what slot?
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,begin
	call kjt_ascii_to_hex_word	; de = slot number
	or a
	jp nz,invalid_input
	ld a,e
	ld (slot_number),a
	or a
	jp z,slot_zero
	ld hl,number_of_slots
	cp (hl)
	jp nc,invalid_input	
	ld hl,active_slot
	cp (hl)			; same slot?
	jr z,no_change
	
	ld hl,check_digit
	call kjt_hex_byte_to_ascii

	ld hl,warning_2_text
	call kjt_print_string

	call kjt_get_input_string	; ask for confirmation
	or a
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,begin

is_zero	ld a,$88			; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic	; send address low
	ld a,$00		
	call send_byte_to_pic	; send address mid
	ld a,(slot_number)
	sla a
	call send_byte_to_pic	; send address high
	
	call enter_programming_mode
	
	ld a,$88			; send "fix config base in PIC" command
	call send_byte_to_pic
	ld a,$37
	call send_byte_to_pic
	ld a,$d8
	call send_byte_to_pic
	ld a,$06
	call send_byte_to_pic
	
	call wait_pic_busy		; wait for PIC to complete update
	jr c,toer1
	call exit_programming_mode

	ld hl,ok_text+5		; show "completed" text
endop3	call kjt_print_string
	call kjt_wait_key_press
	jp begin

toer1	call exit_programming_mode
	ld hl,time_out_text
	jr endop3

no_change
	ld hl,no_change_text
	jr endop3

;------------------------------------------------------------------------------------
;-------- OPTION 4: Install OS ------------------------------------------------------
;------------------------------------------------------------------------------------

option_4	call show_banner
	
	ld hl,install_os_txt
	call kjt_print_string
			
	xor a
	ld (block_number),a
	
	call read_in_block
	ld hl,eeprom_error_text
	jr nz,endop4
	
	ld hl,$800		; OS starts at EEPROM block 0, offset $800
	ld (inblock_addr),hl
	call set_load_pos

	call obtain_new_data
	jp nz,begin

	ld hl,(file_size)		; make sure OS size < $e800 so it doesnt overwrite
	ld de,$e800		; bootcode
	xor a
	sbc hl,de
	jr c,fsokop4
	ld hl,os_size_error_txt
	jp endop4

fsokop4	call erase_block	
	
	call write_block
	jr nz,endop4
	
	call verify_block
	jr nz,endop4
	
	ld hl,ok_text		; show "completed" text
endop4	call kjt_print_string
	call kjt_wait_key_press
	jp begin


;------------------------------------------------------------------------------------
;-------- OPTION 5: Uninstall OS ----------------------------------------------------
;------------------------------------------------------------------------------------


option_5	call show_banner

	ld hl,uninstall_os_txt
	call kjt_print_string
			
	xor a
	ld (block_number),a
	
	call read_in_block
	ld hl,eeprom_error_text
	jr nz,endop5
	
	ld hl,delpage_txt
	call kjt_print_string
	
	ld hl,$800		; OS starts at EEPROM block 0, offset $800
	ld (inblock_addr),hl
	call set_load_pos
	ld a,(dload_bank)
	call kjt_forcebank		
	ld hl,(dload_address)	; replace first 256 bytes of OS file with $FFs
	ld b,0
ufp0	ld (hl),$ff
	inc hl
	djnz ufp0			

	call erase_block

	call write_block
	jr nz,endop5
	
	call verify_block
	jr nz,endop5
	
	ld hl,ok_text		; show "completed" text
endop5	call kjt_print_string
	call kjt_wait_key_press
	jp begin

;------------------------------------------------------------------------------------
;-------- OPTION 6: Update bootcode -------------------------------------------------
;------------------------------------------------------------------------------------

option_6	call show_banner
	
	ld hl,update_bootcode_txt	; ask which bootcode to update
	call kjt_print_string
	
	call kjt_get_input_string
	or a
	jp z,begin
	call kjt_ascii_to_hex_word	; de = block number (primary or backup bootcode)
	or a
	jp nz,invalid_input
	ld a,e
	ld (block_number),a
	and $fe
	jp nz,invalid_input		;must be 0 or 1
			
	call read_in_block
	ld hl,eeprom_error_text
	jr nz,endop6
	
	ld hl,$f000		; bootcode starts at EEPROM block 0, offset $F000
	ld (inblock_addr),hl
	call set_load_pos

	call obtain_new_data
	jp nz,begin
	
fsokop6	call erase_block	
	
	call write_block
	jr nz,endop6
	
	call verify_block
	jr nz,endop6
	
	ld hl,ok_text		; show "completed" text
endop6	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
	
;------------------------------------------------------------------------------------
;-------- OPTION 7: Insert arbitary data into EEPROM block --------------------------
;------------------------------------------------------------------------------------


option_7	call show_banner
	ld a,(number_of_slots)
	sla a
	dec a
	ld hl,total_blocks_figs
	call kjt_hex_byte_to_ascii
	ld hl,total_blocks_text
	call kjt_print_string
	
	call show_active_slot
	ld a,(active_slot)
	or a
	jr z,as_unk
	sla a
	ld hl,op7_fig_text1
	push af
	call kjt_hex_byte_to_ascii
	pop af
	inc a
	ld hl,op7_fig_text2
	call kjt_hex_byte_to_ascii
	ld hl,op7_block_text
	call kjt_print_string
	
as_unk	ld hl,block_prompt_text		; write data to block - ask what block..
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,aborted
	call kjt_ascii_to_hex_word		; de = block number
	or a
	jp nz,invalid_input
	ld a,e
	ld (block_number),a
	or a
	jr z,selpzero			; if block 0 or 1: no warning
	cp 1
	jr z,selpzero

	ld a,(number_of_slots)		; is block within capacity of eeprom?
	sla a
	ld b,a
	ld a,(block_number)
	cp b
	jp nc,invalid_input
	
	srl a				; disallow writes to active slot
	ld b,a
	ld a,(active_slot)
	or a
	jr z,as_unk2			; (if active slot is known)
	cp b
	jp z,stopwas
	
as_unk2	ld hl,cfg_warning_txt
	call kjt_print_string
	call kjt_get_input_string		; ask for confirmation
	or a				
	jp z,aborted
	ld a,(hl)
	cp "Y"
	jp nz,aborted
	
selpzero	call read_in_block
	ld hl,eeprom_error_text
	jp nz,op7end
	
	ld hl,addr_prompt_text		; ask what address to load to..
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,aborted
	call kjt_ascii_to_hex_word		; de = in-block address
	or a
	jp nz,invalid_input
	ld (inblock_addr),de

	call set_load_pos
	
	ld hl,cr_txt
	call kjt_print_string
	
	call obtain_new_data
	jp nz,begin
	
	ld a,(block_number)
	and $fe
	jr nz,fsokop7
	ld hl,(file_size)			; make sure bootcode is safe
	ld de,(inblock_addr)			
	add hl,de
	ld a,h
	and $f0
	jr z,fsokop7
	ld a,(block_number)
	or a
	jr nz,allowwarn
	ld hl,pbc_warning_txt
	jr op7end
allowwarn	ld hl,bbc_warning_txt
	call kjt_print_string
	call kjt_get_input_string		
	or a				
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,aborted

fsokop7	ld a,(block_number)			;warn about OS..
	or a
	jr nz,osissafe
	ld hl,os_warn_txt
	call kjt_print_string
	call kjt_get_input_string		
	or a				
	jp z,aborted
	ld a,(hl)
	cp "Y"
	jp nz,aborted
	
osissafe	call erase_block

	call write_block
	jr nz,op7end
	
	call verify_block
	jr nz,op7end

	ld hl,ok_text			; show "completed" text
op7end	call kjt_print_string
	call kjt_wait_key_press
	jp begin


aborted	ld hl,abort_error_txt
	jr op7end

stopwas	ld hl,warn_active_slot_txt
	jr op7end
			
;------------------------------------------------------------------------------------------

read_in_block
	
	ld hl,block_read_text		; say "reading existing data"
	call kjt_print_string

	xor a
	call kjt_forcebank
	ld a,(block_number)
	ld d,a
	ld e,0
	exx
	ld de,data_buffer			;read in existing 64KB page
	exx
	ld b,0
riedplp	push bc
	call read_eeprom_page
	or a
	jr nz,eprd_err
	exx
	ld hl,page_buffer
	ld bc,$100
	ldir
	ld a,d
	or e
	jr nz,sameb4
	call kjt_incbank
	ld de,data_buffer
sameb4	exx	
	inc de				;next eeprom page
	pop bc				
	call animate_working_chars
	djnz riedplp
	ld hl,no_anim_chars
	call kjt_print_string
	xor a
	ret

eprd_err	pop bc
	ld hl,time_out_error_txt
	xor a
	inc a
	ret
	
	
;------------------------------------------------------------------------------------------

erase_block

	ld a,(block_number)		
	add a,$30
	ld (erase_blk_char),a
	ld hl,erasing_blk_text		; show "erasing" text
	call kjt_print_string

	ld a,(block_number)			; erase the required 64KB eeprom sector 
	call erase_eeprom_sector
	ret

;------------------------------------------------------------------------------------------

write_block

	ld hl,writing_text			; show "writing" text
	call kjt_print_string
	xor a
	call kjt_forcebank
	ld hl,data_buffer
	ld b,0				; 256 pages to write
	ld a,(block_number)
	ld d,a
	ld e,0
dwrpagelp	call program_eeprom_page
	or a
	jr nz,wr_error
	inc h
	jr nz,samebdb
	ld h,$80
	call kjt_incbank
samebdb	call animate_working_chars
	inc de
	djnz dwrpagelp
	ld hl,no_anim_chars
	call kjt_print_string
	xor a
	ret


wr_error	ld hl,write_error_txt
	xor a
	inc a
	ret


;------------------------------------------------------------------------------------------

verify_block
	
	ld hl,verifying_data_txt		; show "verifying" text
	call kjt_print_string
	ld a,0
	call kjt_forcebank
	ld hl,data_buffer
	ld b,0
	ld a,(block_number)
	ld d,a
	ld e,0
dvrpagelp	call read_eeprom_page
	or a
	jr nz,time_out_err
	ld ix,page_buffer
dverlp	ld a,(ix)
	cp (hl)
	jr nz,ver_error
	inc ix
	inc l
	jr nz,dverlp
	inc h
	jr nz,dsamebnkv
	ld h,$80
	call kjt_incbank
dsamebnkv	call animate_working_chars
	inc de
	djnz dvrpagelp
	ld hl,no_anim_chars
	call kjt_print_string
	xor a
	ret
	
ver_error	ld hl,verify_error_txt
	xor a
	inc a
	ret

time_out_err

	ld hl,time_out_error_txt
	xor a
	inc a
	ret
			
;------------------------------------------------------------------------------------------
	
obtain_new_data

	ld hl,data_prompt_txt		; serial download or diskload?
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "d"
	jr z,sdownload2
	cp "l"
	jp nz,od_ld_err

	ld hl,filename_prompt_txt		; get filename for disk load
	call kjt_print_string
	call kjt_get_input_string	
	or a
	jr nz,ondsok
abortond	ld hl,abort_error_txt
	jp od_ld_err

ondsok	push hl
	ld de,filename_txt
	ld b,16
fnloop2	ldi
	or a
	jr z,fnc_done2
	djnz fnloop2
fnc_done2	pop hl

	call kjt_find_file
	ld hl,fnf_error_txt
	jp nz,od_ld_err
	
	ld (file_size),ix			;store filesize	
	push ix
	pop hl	
	ld a,h				;check file fits within 64KB block
	or l
	jr z,fsok40
	dec hl
	ld a,h
	or l
	jr nz,fsbad2
fsok40	push iy
	pop hl
	dec hl
	ld de,(inblock_addr)
	add hl,de
	jr nc,flen_ok2

fsbad2	ld hl,addr_error_text
	jp od_ld_err

flen_ok2	ld hl,loading_txt
	call kjt_print_string

	ld hl,(dload_address)		;data load address
	ld a,(dload_bank)			;data bank
	ld b,a				
	call kjt_force_load			;load data to buffer	
	jp nz,fl_error
	xor a
	ret

fl_error	ld hl,fl_error_txt
	jp od_ld_err

	

sdownload2	

	ld hl,download_text			; ask for serial file
	call kjt_print_string
recdploop	ld hl,wildcard_filename		; filename address
	ld ix,(dload_address)		; load address
	ld a,(dload_bank)
	ld b,a				; load bank
	ld a,1				; time out = 1 second
	call kjt_serial_receive_header
	jr z,fhpd_ok
	cp $14				; only a time out error?
	jp nz,ser_error
	call animate_working_chars
	call kjt_get_key			; pressed ESC?
	cp $76
	jr nz,recdploop	
	ld hl,no_anim_chars
	call kjt_print_string
	jp abortond
	
fhpd_ok	push ix				; show "receiving filename.bin"
	ld hl,no_anim_chars
	call kjt_print_string
	ld hl,receiving_text
	call kjt_print_string
	pop hl
	ld de,filename_txt
	ld bc,16
	ldir
	ld hl,filename_txt
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string
	ld l,(ix+18)
	ld h,(ix+19)
	ld a,h
	or l
	jr z,fsok4
	dec hl
	ld a,h
	or l
	jr nz,fsbad
fsok4	ld l,(ix+16)			;check file fits in 64KB block
	ld h,(ix+17)
	dec hl
	ld de,(inblock_addr)
	add hl,de
	jr nc,dfile_ok
fsbad	jp fsbad2
	
dfile_ok	call kjt_serial_receive_file		; download the file
	jp nz,ser_error
	xor a	
	ret


ser_error	ld hl,serial_error_txt

od_ld_err
	
	xor a
	inc a
	ret
	
;------------------------------------------------------------------------------------------

set_load_pos

	ld de,(inblock_addr)
	xor a				; convert flat 64K to 2 x upper 32KB + bank
	bit 7,d
	jr z,lowbank
	inc a
lowbank	ld (dload_bank),a
	set 7,d				; This relies on data buffer being at $8000
	ld (dload_address),de
	ret

;------------------------------------------------------------------------------------------
	

animate_working_chars

	push hl
	push de
	push bc
	ld hl,anim_chars
	ld a,(anim_charpos)
	ld e,a
	add a,5
	cp 15
	jr nz,achpok
	xor a
achpok	ld (anim_charpos),a
	ld d,0
	add hl,de
	call kjt_print_string
	pop bc
	pop de
	pop hl
	ret

;----------------------------------------------------------------------------------------

show_slot_ids

	ld hl,current_slots_text
	call kjt_print_string

	ld a,1
id_loop	ld (working_slot),a
	ld hl,slot_number_text
	call kjt_hex_byte_to_ascii
	ld hl,slot_text
	call kjt_print_string
	ld hl,slot_number_text
	call kjt_print_string
	
	ld a,(working_slot)			;read in EEPROM page that contains the ID string
	ld h,a
	ld l,0
	add hl,hl
	ld de,$01fb
	add hl,de
	ex de,hl
	call read_eeprom_page
	
	ld hl,page_buffer+$de		;location of ID (filename ASCII)
	ld a,(hl)
	or a
	jr z,unk_id
	bit 7,a
	jr z,id_ok
unk_id	ld hl,unknown_text
id_ok	call kjt_print_string
	ld hl,number_of_slots
	ld a,(working_slot)
	inc a
	cp (hl)
	jr nz,id_loop
	
	call show_active_slot
	ret

;--------------------------------------------------------------------------------------

show_active_slot

	ld a,$88				; send PIC the command to prompt it to
	call send_byte_to_pic		; return the slot pointer MSB
	ld a,$76
	call send_byte_to_pic
    
	ld hl,active_slot			; read bits from PIC RB7 
	ld (hl),0
	ld c,8				                 
nxt_bit	sla (hl)
	ld a,1<<pic_clock_input		; prompt PIC to present next bit by raising PIC clock line
	out (sys_pic_comms),a
	ld b,128				; wait a while so PIC can keep up..
pause_lp1	djnz pause_lp1
	xor a				; drop clock line again
	out (sys_pic_comms),a
	in a,(sys_hw_flags)			; read the bit into shifter
	bit 3,a
	jr z,nobit
	set 0,(hl)
nobit	ld b,128
pause_lp2	djnz pause_lp2
	dec c
	jr nz,nxt_bit

	srl (hl)
	ld a,(hl)				; if slot returns $00, the PIC code does not support the command
	or a				; so cannot show active slot text
	ret z
	
	ld hl,act_slot_figures
	call kjt_hex_byte_to_ascii
	
	ld hl,act_slot_text			; show the active slot
	call kjt_print_string
	ld hl,act_slot_figures
endit	call kjt_print_string
	xor a
	ret

;--------------------------------------------------------------------------------------

show_eeprom_type

	in a,(sys_eeprom_byte)		; clear shift reg count with a read

	ld a,$88				; send PIC the command to prompt the EEPROM to
	call send_byte_to_pic		; return its ID code byte
	ld a,$53
	call send_byte_to_pic
                
	ld d,32				; D counts timer overflows
	ld a,1<<pic_clock_input		; prompt PIC to send a byte by raising PIC clock line
	out (sys_pic_comms),a
wbc_byte2	in a,(sys_hw_flags)			; have 8 bits been received?		
	bit 4,a
	jr nz,gbcbyte2
	in a,(sys_irq_ps2_flags)		; check for timer overflow..
	and 4
	jr z,wbc_byte2	
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	dec d				; dec count of overflows,
	jr nz,wbc_byte2					
	xor a				; if waited too long give up (and drop PIC clock)
	out (sys_pic_comms),a
	jr no_id				
gbcbyte2	xor a			
	out (sys_pic_comms),a		; drop PIC clock line, PIC will then wait for next high 
	in a,(sys_eeprom_byte)		; read byte received, clear bit count
	push af
	ld hl,eeprom_id_text
	call kjt_print_string
	pop af
	ld (eeprom_id_byte),a	
	sub $11
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,eeprom_id_list
	add hl,de
	call kjt_print_string

	ld a,(eeprom_id_byte)
	sub $10
	ld b,a
	ld a,1
slotslp	sla a
	djnz slotslp
	ld (number_of_slots),a
	ret

no_id	ld hl,no_id_text
	call kjt_print_string
	ret
	
	
;--------------------------------------------------------------------------------------


show_banner

	call kjt_clear_screen
	call kjt_get_pen
	push af
	rrca
	rrca
	rrca
	rrca
	call kjt_set_pen
	ld hl,start_text1
	call kjt_print_string
	pop af
	call kjt_set_pen
	ret
		
;----------------------------------------------------------------------------------------

include "eeprom_routines.asm"

;----------------------------------------------------------------------------------------




start_text1	db 11," ************************************ ",11
		db    " * VxZ80P ONBOARD EEPROM TOOL V1.12 * ",11
		db    " ************************************ ",11,0
		
start_text2	db 11
		db    "Select:",11
		db    "-------",11,11
		db    "1 - Write FPGA config file to a slot",11
		db    "2 - Reconfigure the FPGA now",11
		db    "3 - Change the active slot",11
		db 11
		db    "4 - Install OS to EEPROM",11
		db    "5 - Remove OS from EEPROM",11
		db 11
		db    "6 - Update bootcode",11
		db 11
		db    "7 - Insert data into EEPROM block",11
		db 11
		db    "ESC - Quit",11,11,0
		
slot_prompt_text	db 11,11,"Write new config to which slot? ",0

warning_1_text	db 11,11,"Are you sure you want to write",11
		db "to the currently active slot (y/n) ",0
		
download_text	db 11,"Please start serial download (ESC=Quit)",11,0

receiving_text	db 13,"    ",11,"Receiving:",0

erasing_text	db 11,"Erasing slot:"
erase_chars	db "xx",0

writing_text	db 11,11,"Writing data - please wait",11,0

verifying_text	db 13,"    ",11,"Verifying data",11,0

serial_error_text	db 11,"Download error. Press any key.",0

eeprom_error_text	db 11,"ERROR! EEPROM problem.",0


block_prompt_text	db 11,11,"Write data to which 64KB block? ",0

block_read_text	db 11,11,"Reading existing data from block",11,0

addr_prompt_text	db 11,"Hex address within block? (0-FFFF) ",0

addr_error_text	db 11,"ERROR! File cannot overlap 64KB block",11,11
		db "Press any key",0


erasing_blk_text	db 11,"Erasing block:"
erase_blk_char	db "x",0


block_erase_text	db 11,"Erasing current block",0

set_slot_text	db 11,11,"Which slot should the FPGA",11
		db "configure from upon power up? ",0

warning_2_text	db 11,11,"WARNING! You are changing the power",11
		db "on configuration slot selection.",11
		db "If the new config in the selected slot",11
		db "offers no means of switching slots",11
		db "(or is invalid) you will be stuck with",11
		db "that selection. Testing the slot with",11
		db "option [2] first is advised. It is",11
		db "possible to manually reset the slot",11
		db "pointer (see V6Z80P documentation) but",11
		db "this should be treated as a last resort.",11 
		
		db "On power up the FPGA will now configure",11
		db "from EEPROM slot "
check_digit	db "xx - Sure? (y/n) ",0
		
reconfig_now_text	db 11,11,"Reconfigure FPGA now (non permanent)"
		db 11,11,"Which slot? ",0

ok_text		db 13,"    ",11,11,"Completed OK - Press any key",11,0

cr_txt		db 11,0

time_out_text	db 11,11,"ERROR - Timed out. Press any key.",0

file_too_big_text	db 11,"Filesize error - Press any key.",0

write_error_text	db 11,"Write error - Press any key",0

verify_error_text	db 11,"Verify error - Press any key",0

input_error_text	db 11,11,"Invalid input - Press any key",0

wildcard_filename	db "*",0

anim_chars	db ".  ",13,0
		db ".. ",13,0
		db "...",13,0
no_anim_chars	db "   ",0

anim_charpos	db 0

cfg_id		db $ff,$ff,$ff,$ff,$aa,$99,$55,$66

cfg_file_error_text	db 11,"Not a valid Xilinx config file!",11,11
		db "Press any key",11,0

cfg_prompt_txt	db 11,11,"[D]ownload config file from PC or",11,"[L]oad it from disk?",11,0
data_prompt_txt	db 11,"[D]ownload data from PC or",11,"[L]oad file from disk?",11,0

filename_prompt_txt	db 11,"Enter filename..",11,0

filename_txt	ds 20,0

disk_error_txt	db 11,11,"Disk error - Press any key",0
	
file_error_txt	db 11,11,"File not found? - Press any key",0

loading_txt	db 11,"Loading...",11,0

install_os_txt	db 11,"Install OS..",0

uninstall_os_txt	db 11,"Uninstall OS...",0

os_size_error_txt	db "File to big for EEPROM page!",11
		db "OS must be $E800 bytes or less",11,0

abort_error_txt	db 11,11,"Aborted - Press any key",11,0

time_out_error_txt	db "   ",11,"Time out error - Press any key",11,0

write_error_txt	db "   ",11,"Write error - Press any key",11,0

verify_error_txt	db "   ",11,"Verify error - Press any key",11,0

fnf_error_txt	db 11,"File not found - Press any key",11,0

fl_error_txt	db 11,"File load error - Press any key",11,0

serial_error_txt	db 11,"Serial error - Press any key",11,0

verifying_data_txt	db 11,"Verifying data..",11,0

delpage_txt	db 11,"Removing OS signature..",11,0

update_bootcode_txt	db 11,"Update Bootcode..",11,11
		db "Primary [0] or backup [1] (0/1) ",0

pbc_warning_txt	db 11,"Error! This would overwrite the primary",11
		db "bootcode at $0f000 which is not allowed.",11,11
		db "Press any key.",11,0

bbc_warning_txt	db 11,"Caution! This will overwrite the backup",11
		db "bootcode at $1f000 - Are you sure",11
		db "you want to proceed? (y/n) ",0

cfg_warning_txt	db 11,11,"Caution! FPGA config data MAY exist",11
		db "in this block. OK to proceed? (y/n) ",0

os_warn_txt	db 11,"Caution! An Operating System may be",11
		db "installed in this block. Are you sure",11
		db "you want to proceed? (y/n) ",0

warn_active_slot_txt db 11,11,"ERROR! Writing data to a block within",11
		 db "the Active Slot is not allowed!",11,0

current_slots_text	db 11,"Current EEPROM slot contents..",11,11
		db " SLOT 00 - BOOTCODE / OS etc",11,0

slot_text		db 11," SLOT ",0
slot_number_text	db "xx - ",0
unknown_text	db "UNKNOWN",0

slot_zero_text	db 11,11,"SLOT 0 cannot hold FPGA configs!"
		db 11,11,"Press any key.",0		

current_slot_txt	db 11,11,"Current Active Slot: "
active_slot_txt	db "xx",11,11,0


eeprom_id_text	db 11,"Detected EEPROM type: 25x",0

eeprom_id_list	db "20 (256KB)    ",11,0	;id = $11
		db "40 (512KB)    ",11,0	;id = $12
		db "80 (1MB)      ",11,0	;id = $13
		db "16 (2MB)      ",11,0	;id = $14
		db "32 (4MB)      ",11,0	;id = $15
		db "64 (8MB)      ",11,0	;id = $16

no_id_text	db 11,"EEPROM: Unknown - Assuming 25x40 (512KB)",0

eeprom_id_byte	db 0
working_slot	db 0

number_of_slots	db 4			;including slot 0


active_slot	db 0
act_slot_text	db 11,11,"Current active slot:",0
act_slot_figures	db "xx",0

no_change_text	db 11,11,"Active slot unchanged.."
		db 11,11,"Press any key",0

total_blocks_text	db 11,"Max EEPROM block: "
total_blocks_figs	db "xx",0

op7_block_text	db " (Blocks "
op7_fig_text1	db "xx/"
op7_fig_text2	db "xx)",11,0
	
restart_text	db 11,11,"Reconfiguring...",0
	
;---------------------------------------------------------------------------------------

file_size		dw 0
slot_number	db 0
block_number	db 0
inblock_addr	dw 0
dload_address	dw 0
dload_bank	db 0

page_buffer	ds 256,0
	
;-----------------------------------------------------------------------------------------

