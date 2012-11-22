; ***************************************************
; * ONBOARD EEPROM MANAGEMENT TOOL FOR V6Z80P V1.25 *
; ***************************************************
;
; v1.25 - Backup/restores initial dir
;         Layout of slot list updated
; 
; v1.24 - Supports .v6c files to aid correct config installation.
;         Reports Bootcode and OS on-EEPROM status
;
; V1.23 - Requester code 0.28
;
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

;--------------------------------------------------------------------------
; Check hardware / OS versions are appropriate for code
;--------------------------------------------------------------------------

required_osca       equ $652
include             "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

required_flos       equ $608
include             "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"


;-------- CONSTANTS ----------------------------------------------------------

data_buffer         equ $8000 			; Banks 1,2,3,4 - Dont change this
data_bank  	    equ 1

;-----------------------------------------------------------------------------

          call save_dir_vol
          call go_eeprom
          call restore_dir_vol
          ret

;======== CODE / DATA that must be kept out of paged RAM =======================

clear_slot_buffer

	  ld a,data_bank              	  	; fill 128KB data buffer with $ff
          call kjt_set_bank
          ld b,4
fbloop    push bc
          ld a,$ff
          ld bc,$8000                   	; databuffer = 4 x 32KB upper RAM pages
          ld hl,data_buffer
          call kjt_bchl_memfill
          call kjt_incbank
          pop bc
          djnz fbloop
	  jr bank0ret

	  
	  
check_xilinx_cfg

	  ld a,data_bank               		 ; is it a Xilinx cfg file?
          call kjt_set_bank
          ld hl,data_buffer
          ld de,cfg_id
          ld b,8
          call kjt_compare_strings
bank0ret  push af
	  xor a
	  call kjt_set_bank
	  pop af
	  ret



check_pcb_version

          ld a,data_bank+3
	  call kjt_set_bank
          Call kjt_get_version
	  ld a,b
	  or a
	  jr nz,gotosca			
	  
	  ld hl,non_auto_txt			; if cannot detect pcb version ask for confirmation
	  call kjt_print_string
	  ld a,(data_buffer+$7bdd)
	  ld hl,pcb_types
	  ld bc,end_pcb_types-pcb_types
	  cpir
	  call kjt_print_string  
	  ld hl,sure_txt
	  call kjt_print_string
	  call yn_response
	  push af
	  call new_line
	  pop af
	  jr bank0ret
	  
gotosca   ld a,(data_buffer+$7bdd)
	  cp b
	  jr bank0ret
	  


insert_fn_into_cfg
	  
	  ld a,data_bank+3
          call kjt_set_bank
	  
	  ld hl,filename_txt            	; attach the filename to the end of the cfg string
          ld de,data_buffer+$7bde
          ld b,16
cfntclp   ld a,(hl)
	  cp "."				; end on dot
	  jr z,end_of_fn
	  cp $61				; uppercasify
	  jr c,alupca
	  sub $20
alupca	  ld (de),a
	  inc hl
	  inc de
	  djnz cfntclp
          xor a
	  ld (de),a
	  jr bank0ret
	  
end_of_fn 

spclp	  ld a," "	
	  ld (de),a
	  inc de
	  djnz spclp
	  xor a
	  ld (de),a  
	  jr bank0ret  

          


data_buffer_to_page_buffer	  
	  
	  ld a,b				; set b to bank, HL to data location
	  call kjt_force_bank
	  push bc
	  ld de,page_buffer
	  ld bc,256
	  ldir
	  pop bc

	  ld a,h                   
          or a
	  jr nz,bank0ret
          ld h,$80
          inc b
	  jr bank0ret
	
  
	  
data_buffer_to_verify_buffer	  
	  
	  ld a,b				; set b to bank, HL to data location
	  call kjt_set_bank
	  push bc
	  ld de,verify_buffer
	  ld bc,256
	  ldir
	  pop bc

	  ld a,h                   
          or a
	  jp nz,bank0ret
          ld h,$80
          inc b
	  jp bank0ret
	


wipe_os_sig_in_buffer

    	  ld a,data_bank
          call kjt_set_bank            
          ld hl,data_buffer+$800       		; replace first 256 bytes of OS file with $FFs
          ld b,0
ufp0      ld (hl),$ff
          inc hl
          djnz ufp0   
	  jp bank0ret
	 
 
 
page_buffer_to_data_buffer

	  ld a,b				; set b to bank, de to data dest location
	  call kjt_set_bank
	  push bc
	  ld hl,page_buffer
	  ld bc,256
	  ldir
	  pop bc 
	  ld a,d                   
          or a
	  jp nz,bank0ret
          ld d,$80
          inc b
	  jp bank0ret




yn_response

          ld a,1
          call kjt_get_input_string     	; and ask for confirmation - ZF set if response = Yes
          or a
          jr z,respbad
          ld a,(hl)
          cp "Y"
          jr nz,respbad
	  xor a
	  ret
respbad	  xor a
	  inc a
	  ret


	  
;------------------------------------------------------------------------------------------------------------------

cfg_id              db $ff,$ff,$ff,$ff,$aa,$99,$55,$66		;Xilinx ID string

filename_txt        ds 18,0

non_auto_txt	    db 11,"Note: Cannot determine your PCB version",11
		    db "(not supported with current OSCA)",11
		    db 11,"Config file is compatible with:",11,11,0
		    
sure_txt	    db 11,11,"Is this your PCB version? (y/n) ",0

pcb_types	    db 0,"?? Missing PCB ID!",0
                    db 1,"V6Z80P (original)",0
	            db 2,"V6Z80P+ V1.0",0
		    db 3,"V6Z80P+ V1.1",0
end_pcb_types	    db "Unknown PCB",0

newline_txt         db 11,0
	  
page_buffer         ds 256,0
verify_buffer       ds 256,0

page_count          dw 0
cursor_pos          dw 0

file_size           dw 0
slot_number         db 0
block_number        db 0
inblock_addr        dw 0
dload_address       dw 0
dload_bank          db 0

backup_cursor_position        dw 0

save_length_lo	    dw 0
save_length_hi      dw 0

eeprom_id_byte      db 0
working_slot        db 0
number_of_slots     db 4             ;including slot 0
active_slot         db 0

pic_fw_byte         db 0

	
;======== END OF CODE/DATA THAT MUST BE KEPT IN UNPAGED RAM =====================================================




;-------- INIT -----------------------------------------------------------------

go_eeprom xor a     
          out (sys_timer),a             ; set timer - 256 overflows per irq

          in a,(sys_serial_port)        ; flush serial buffer at prog start


;-------- MAIN LOOP -----------------------------------------------------------

          
begin     call show_banner
          call show_pic_firmware
          call show_eeprom_type
          
          ld hl,start_text2
          call kjt_print_string

waitkey   call kjt_wait_key_press

          cp $76
          jr z,quit

          ld a,b
          or a
          jr z,waitkey
          cp "1"
          jr z,write_slot
          cp "2"
          jp z,reconfigure
          cp "3"
          jp z,change_active_slot
          cp "4"
          jp z,erase_slot
          cp "5"
          jp z,install_os
          cp "6"
          jp z,uninstall_os     
          cp "7"
          jp z,update_bootcode      
          cp "8"
          jp z,insert_block_data
	  cp "9"
	  jp z,save_block_data
          
          jr waitkey

;------------------------------------------------------------------------------
          
quit      xor a                         ; exit to OS
          ret
          
          
;-----------------------------------------------------------------------
;-------- Write an FPGA config file to a slot in EEPROM ----------------
;-----------------------------------------------------------------------

write_slot

	  call show_banner
          call show_slot_ids

          ld hl,filename_txt
          ld bc,16
          xor a
          call kjt_bchl_memfill

          ld hl,slot_prompt_text        ; which slot?
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,begin
          call kjt_ascii_to_hex_word    ; returns de = slot number
          or a
          jp nz,invalid_input
          ld a,e
          ld (slot_number),a
          or a
          jp z,slot_zero                ; dont allow writes to slot 0 
          ld hl,number_of_slots
          cp (hl)
          jp nc,invalid_input
          
          ld hl,active_slot
          cp (hl)                       ; if uploading to current active slot show warning
          jr nz,ok_to_wr
          ld hl,warning_1_text
          call kjt_print_string
          call yn_response		; and ask for confirmation
          jp nz,begin

ok_to_wr  call clear_slot_buffer
       
retrylr   ld b,8
          ld c,2
          xor a
          ld hl,0
          call load_requester
          jr z,ldreq_ok1
          cp $ff
          jp z,begin
          cp $fe
          jr z,sdownload
ld_error  or a
          jr z,hw_err1
          call file_error_requester
          jr retrylr
hw_err1   call hw_error_requester
          jr retrylr
          
ldreq_ok1 call copy_filename
          call test_v6c_extension
	  jr nz,notv6c
	  push ix			;check file length for .v6c file
	  pop bc
	  push iy
	  pop de
	  ld hl,$fbf0
	  xor a
	  sbc hl,de
	  jr nz,flenerr
	  ld hl,1
	  xor a
	  sbc hl,bc
	  jr nz,flenerr
	  jr flen_ok
	  
notv6c	  push ix
          pop bc
          push iy
          pop de
          ld hl,$fbdc                   ;check file length for .bin file
          xor a
          sbc hl,de
          jr nz,flenerr
          ld hl,$0001
          xor a
          sbc hl,bc
          jr z,flen_ok
flenerr   ld hl,cfg_file_error_text
          jp do_end

          
flen_ok   ld hl,loading_txt
          call kjt_print_string

          ld hl,data_buffer             ;load address
          ld b,data_bank                ;load bank 
          call kjt_force_load           ;load config data to buffer   
          jp nz,load_error
          jp cfgloaded        
          


sdownload ld l,(ix+18)                  ;check serial file header 
          ld h,(ix+19)                  ;config file must be < $1ffff bytes
          ld a,h
          or a
          jp nz,too_big
          ld a,l
          and $fe
          jp nz,too_big

          push ix
          pop hl 
          call copy_filename
          call receiving_requester
          ld hl,data_buffer             ; load address
          ld b,data_bank                ; load bank 
          call kjt_serial_receive_file  ; download the file
          push af
          call w_restore_display
          pop af
          jp nz,serial_error
	  call new_line
	  
cfgloaded call check_xilinx_cfg
	  jp nc,not_cfg_error          
          
	  call test_v6c_extension
	  jr z,is_v6c
          call insert_fn_into_cfg  	; if a raw .bin file, copy filename to label 
          jr skippcbt
  
is_v6c	  call check_pcb_version
	  jp nz,not_right_pcb_error  
	  
skippcbt  ld a,(slot_number)            
          ld hl,erase_chars
          call kjt_hex_byte_to_ascii
          ld hl,erasing_text            ; show "erasing slot xx" text
          call kjt_print_string
          ld a,(slot_number)            ; erase the required 2 x 64KB eeprom sectors 
          sla a
          call erase_eeprom_sector
          inc a
          call erase_eeprom_sector
          

          ld hl,writing_text            ; show "writing" text
          call kjt_print_string
          ld hl,0
          ld (page_count),hl
       
	  ld hl,data_buffer
	  ld b,data_bank
	  exx
	  ld bc,512                     ; 512 x 256 byte pages = 128KB
          ld a,(slot_number)
          sla a
          ld d,a
          ld e,0                        ; de = EEPROM page
wrpagelp  exx
	  call data_buffer_to_page_buffer
	  exx
	  ld hl,page_buffer
	  call program_eeprom_page
          or a
          jp nz,write_error
          call show_progress
          inc de                        ; next eeprom page
          dec bc
          ld a,b
          or c
          jr nz,wrpagelp
          call show_progress
        	  
	  
          ld hl,verifying_text          ; show "verifying" text
          call kjt_print_string
          
	  ld hl,0
          ld (page_count),hl
          ld hl,data_buffer
          ld b,data_bank
	  exx
	  ld bc,512
          ld a,(slot_number)
          sla a
          ld d,a
          ld e,0
vrpagelp  call read_eeprom_page
          or a
          jr nz,time_out_error
	  exx
	  call data_buffer_to_verify_buffer
	  exx
	  push bc
	  push de
	  push hl
	  ld b,0
          ld hl,page_buffer
          ld de,verify_buffer
verblp1	  ld a,(de)
	  cp (hl)
	  jr nz,verify_lp_error
	  inc hl
	  inc de
	  djnz verblp1
          pop hl
	  pop de
	  pop bc
	  call show_progress
          inc de
          dec bc
          ld a,b
          or c
          jr nz,vrpagelp
          call show_progress

          ld hl,ok_text                 ; show "completed" text
          call kjt_print_string
          call kjt_wait_key_press
          jp begin


time_out_error

          ld hl,time_out_text           ; timed out waiting for databurst
do_end    call kjt_print_string
          call kjt_wait_key_press
          jp begin

load_error

          ld hl,load_error_text         ; serial comms problem
          jr do_end
          
serial_error

          ld hl,serial_error_text       ; serial comms problem
          jr do_end


too_big   ld hl,file_too_big_text       ; file too big
          jr do_end

write_error

          ld hl,write_error_text
          jr do_end

verify_lp_error

	  pop hl
	  pop de
	  pop bc

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

not_right_pcb_error
                   
	  ld hl,pcb_error_text
	  jr do_end
	  
;------------------------------------------------------------------------
;--------  Reconfigure the FPGA from a slot now -------------------------
;------------------------------------------------------------------------

reconfigure

          call show_banner

          call show_slot_ids

          ld hl,reconfig_now_text       ; reconfig now - what slot?
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,begin
          call kjt_ascii_to_hex_word    ; de = slot number
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

          ld d,0                        ; wait a second 
op2wait   in a,(sys_irq_ps2_flags)                 
          and 4
          jr z,op2wait        
          out (sys_clear_irq_flags),a              
          dec d                                   
          jr nz,op2wait                                               


          ld a,$88                      ; send "set config base" command
          call send_byte_to_pic
          ld a,$b8
          call send_byte_to_pic
          ld a,$00                      
          call send_byte_to_pic         ; send address low
          ld a,$00            
          call send_byte_to_pic         ; send address mid
          ld a,(slot_number)
          sla a
          call send_byte_to_pic         ; send address high

          ld a,$88                      ; send reconfigure command
          call send_byte_to_pic
          ld a,$a1
          call send_byte_to_pic

          jp begin

                    
;------------------------------------------------------------------------        
;---------  Change the slot the FPGA configures from on power up --------
;------------------------------------------------------------------------

change_active_slot

          call show_banner

          call show_slot_ids
          
          ld hl,set_slot_text           ; change config to what slot?
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,begin
          call kjt_ascii_to_hex_word    ; de = slot number
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
          cp (hl)                       ; same slot?
          jr z,no_change
          
          ld hl,check_digit
          call kjt_hex_byte_to_ascii

          ld hl,warning_2_text
          call kjt_print_string

          call yn_response
	  jp nz,begin

is_zero   ld a,$88                      ; send "set config base" command
          call send_byte_to_pic
          ld a,$b8
          call send_byte_to_pic
          ld a,$00                      
          call send_byte_to_pic         ; send address low
          ld a,$00            
          call send_byte_to_pic         ; send address mid
          ld a,(slot_number)
          sla a
          call send_byte_to_pic         ; send address high
          
          call enter_programming_mode
          
          ld a,$88                      ; send "fix config base in PIC" command
          call send_byte_to_pic
          ld a,$37
          call send_byte_to_pic
          ld a,$d8
          call send_byte_to_pic
          ld a,$06
          call send_byte_to_pic
          
          call wait_pic_busy            ; wait for PIC to complete update
          jr c,toer1
          call exit_programming_mode

          ld hl,ok_text                 ; show "completed" text
endop3    call kjt_print_string
          call kjt_wait_key_press
          jp begin

toer1     call exit_programming_mode
          ld hl,time_out_text
          jr endop3

no_change
          ld hl,no_change_text
          jr endop3

;--------------------------------------------------------------------------
;-------- Install OS ------------------------------------------------------
;--------------------------------------------------------------------------

install_os

	  call show_banner
          
	  call show_eeprom_os_status
	  
          ld hl,install_os_txt
          call kjt_print_string
	  call yn_response
          jp nz,begin
                    
          xor a
          ld (block_number),a
          
          call read_in_block
          ld hl,eeprom_error_text
          jr nz,endop4
          
          ld hl,$800                    ; OS starts at EEPROM block 0, offset $800
          ld (inblock_addr),hl
          call set_load_pos

          call obtain_new_data
          jp nz,show_error

          ld hl,(file_size)             ; make sure OS size < $e800 so it doesnt overwrite
          ld de,$e800                   ; bootcode
          xor a
          sbc hl,de
          jr c,fsokop4
          ld hl,os_size_error_txt
          jp endop4

fsokop4   call erase_block    
          
          call write_block
          ld hl,write_error_txt
          jr nz,op4retry
          
          call verify_block
          ld hl,verify_error_txt
          jr nz,op4retry                
          
          ld hl,ok_text                 ; show "completed" text
endop4    call kjt_print_string
          call kjt_wait_key_press
          jp begin

op4retry  call kjt_print_string         ; state error and ask if want to retry the write
          ld hl,retry_txt
          call kjt_print_string
op4gtri   ld a,1
          call kjt_get_input_string
          or a
          jr z,op4gtri
          ld a,(hl)
          cp "N"
          jp z,begin
          jr fsokop4
          

;--------------------------------------------------------------------------
;-------- Uninstall OS ----------------------------------------------------
;--------------------------------------------------------------------------

uninstall_os

          call show_banner

	  call show_eeprom_os_status
	  jr z,os_inst
	   
	  ld hl,pressanykey_txt 
          call kjt_print_string
	  call kjt_wait_key_press
	  jp begin

os_inst   ld hl,uninstall_os_txt
          call kjt_print_string
          
          call yn_response
          jp nz,begin
                              
          xor a
          ld (block_number),a
          
          call read_in_block
          ld hl,eeprom_error_text
          jr nz,endop5
          
          ld hl,delpage_txt
          call kjt_print_string
  
          call wipe_os_sig_in_buffer

fsokop5   call erase_block

          call write_block
          ld hl,write_error_txt
          jr nz,op5retry
          
          call verify_block
          ld hl,verify_error_txt
          jr nz,op5retry
          
          ld hl,ok_text                 ; show "completed" text
endop5    call kjt_print_string
          call kjt_wait_key_press
          jp begin


op5retry  call kjt_print_string         ; state error and ask if want to retry the write
          ld hl,retry_txt
          call kjt_print_string
op5gtri   ld a,1
          call kjt_get_input_string
          or a
          jr z,op5gtri
          ld a,(hl)
          cp "N"
          jp z,begin
          jr fsokop5
          
;--------------------------------------------------------------------------
;-------- Update bootcode -------------------------------------------------
;--------------------------------------------------------------------------

update_bootcode
 
          call show_banner
          
	  ld a,0
	  call show_eeprom_bootcode
	  ld a,1
	  call show_eeprom_bootcode

	  
          ld hl,update_bootcode_txt     ; ask which bootcode to update
          call kjt_print_string
          
          ld a,1
          call kjt_get_input_string
          or a
          jp z,begin
          call kjt_ascii_to_hex_word    ; de = block number (primary or backup bootcode)
          or a
          jp nz,invalid_input
          ld a,e
          ld (block_number),a
          and $fe
          jp nz,invalid_input           ;must be 0 or 1
                              
          call read_in_block
          ld hl,eeprom_error_text
          jr nz,endop6
          
          ld hl,$f000                   ; bootcode starts at EEPROM block 0, offset $F000
          ld (inblock_addr),hl
          call set_load_pos

          call obtain_new_data
          jp nz,show_error
          
fsokop6   call erase_block    
          
          call write_block
          ld hl,write_error_txt
          jr nz,op6retry
          
          call verify_block
          ld hl,verify_error_txt
          jr nz,op6retry
          
          ld hl,ok_text                 ; show "completed" text
endop6    call kjt_print_string
          call kjt_wait_key_press
          jp begin
          
          
op6retry  call kjt_print_string         ; state error and ask if want to retry the write
          ld hl,retry_txt
          call kjt_print_string
op6gtri   ld a,1
          call kjt_get_input_string
          or a
          jr z,op6gtri
          ld a,(hl)
          cp "N"
          jp z,begin
          jr fsokop6
          
                    
;--------------------------------------------------------------------------
;-------- Insert arbitary data into EEPROM block --------------------------
;--------------------------------------------------------------------------

insert_block_data
        
          call show_banner
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
          
as_unk    ld hl,block_prompt_text                 ; write data to block - ask what block..
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,aborted
          call kjt_ascii_to_hex_word              ; de = block number
          or a
          jp nz,invalid_input
          ld a,e
          ld (block_number),a
          or a
          jr z,selpzero                           ; if block 0 or 1: no warning
          cp 1
          jr z,selpzero

          ld a,(number_of_slots)                  ; is block within capacity of eeprom?
          sla a
          ld b,a
          ld a,(block_number)
          cp b
          jp nc,invalid_input
          
          srl a                                   ; disallow writes to active slot
          ld b,a
          ld a,(active_slot)
          or a
          jr z,as_unk2                            ; (if active slot is known)
          cp b
          jp z,stopwas
          
as_unk2   ld hl,cfg_warning_txt
          call kjt_print_string
          call yn_response
	  jp nz,aborted
                    
selpzero  call read_in_block
          ld hl,eeprom_error_text
          jp nz,op7end
          
          ld hl,addr_prompt_text                  ; ask what address to load to..
          call kjt_print_string
          ld a,4
          call kjt_get_input_string
          or a
          jp z,aborted
          call kjt_ascii_to_hex_word              ; de = in-block address
          or a
          jp nz,invalid_input
          ld (inblock_addr),de

          call set_load_pos
          
          ld hl,cr_txt
          call kjt_print_string
          
          call obtain_new_data
          jp nz,show_error
          
          ld a,(block_number)
          and $fe
          jr nz,fsokop7
          ld hl,(file_size)                       ; make sure bootcode is safe
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
allowwarn ld hl,bbc_warning_txt
          call kjt_print_string
          call yn_response
          jp nz,aborted

fsokop7   ld a,(block_number)                     ;warn about OS..
          or a
          jr nz,osissafe
          ld hl,os_warn_txt
          call kjt_print_string
          call yn_response
	  jp nz,aborted
                    
osissafe  call erase_block

          call write_block
          ld hl,write_error_txt
          jr nz,op7end
          
          call verify_block
          ld hl,verify_error_txt
          jr nz,op7end

          ld hl,ok_text                           ; show "completed" text
op7end    call kjt_print_string
          call kjt_wait_key_press
          jp begin


aborted   ld hl,abort_error_txt
          jr op7end

stopwas   ld hl,warn_active_slot_txt
          jr op7end


op7retry  call kjt_print_string                   ; state error and ask if want to retry the write
          ld hl,retry_txt
          call kjt_print_string
op7gtri   ld a,1
          call kjt_get_input_string
          or a
          jr z,op7gtri
          ld a,(hl)
          cp "N"
          jp z,begin
          jr osissafe
                              
;--------------------------------------------------------------------------
;-------- Erase Slot (and verify blank) -----------------------------------
;--------------------------------------------------------------------------

erase_slot

	  call show_banner
          call show_slot_ids

          ld hl,erase_prompt_text       ; which slot?
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,begin
          call kjt_ascii_to_hex_word    ; returns de = slot number
          or a
          jp nz,invalid_input
          ld a,e
          ld (slot_number),a
          ld hl,number_of_slots
          cp (hl)
          jp nc,invalid_input
          
          ld hl,active_slot
          cp (hl)                       ; if erasing current active slot show warning
          jr nz,ok_to_er
          ld hl,er_warning_1_text
          call kjt_print_string
          call yn_response
          jp nz,begin

ok_to_er  ld a,(slot_number)
          or a
          jr nz,ne_slot0                ; confirm slot 0 erase 
          ld hl,er_warning_2_text
          call kjt_print_string
          call yn_response
          jp nz,begin

ne_slot0  ld a,(slot_number)            
          ld hl,erase_chars
          call kjt_hex_byte_to_ascii
          ld hl,erasing_text            ; show "erasing slot xx" text
          call kjt_print_string
          ld a,(slot_number)            ; erase the required 2 x 64KB eeprom sectors 
          sla a
          call erase_eeprom_sector
          inc a
          call erase_eeprom_sector
          
          ld hl,verifying_erase         ; show "verifying" text
          call kjt_print_string
          ld hl,0
          ld (page_count),hl
          
          ld bc,512
          ld a,(slot_number)
          sla a
          ld d,a
          ld e,0
evrpagelp call read_eeprom_page
          or a
          jp nz,time_out_error
          ld ix,page_buffer
          ld l,0
everlp    ld a,(ix)
          cp $ff
          jp nz,verify_error
          inc ix
          inc l
          jr nz,everlp
          call show_progress
          inc de
          dec bc
          ld a,b
          or c
          jr nz,evrpagelp
          call show_progress
          
completed ld hl,ok_text                 ; show "completed" text
          call kjt_print_string
          call kjt_wait_key_press
          jp begin

;---------------------------------------------------------------------------
;--------  Save data from block---------------------------------------------
;---------------------------------------------------------------------------

save_block_data

          call show_banner
          ld a,(number_of_slots)
          sla a
          dec a
          ld hl,total_blocks_figs
          call kjt_hex_byte_to_ascii
          ld hl,total_blocks_text
          call kjt_print_string
          
          ld hl,read_block_prompt                  ; read data - ask which block..
          call kjt_print_string
          ld a,2
          call kjt_get_input_string
          or a
          jp z,aborted
          call kjt_ascii_to_hex_word              ; de = block number
          or a
          jp nz,invalid_input
          ld a,e
          ld (block_number),a

          ld a,(number_of_slots)                  ; is block within capacity of eeprom?
          sla a
          ld b,a
          ld a,(block_number)
          cp b
          jp nc,invalid_input
          
      	  call read_in_block
          ld hl,eeprom_error_text
          jp nz,error_msg
          
          ld hl,src_addr_prompt                   ; ask what address to save from
          call kjt_print_string
          ld a,4
          call kjt_get_input_string
          or a
          jp z,aborted
          call kjt_ascii_to_hex_word              ; de = in-block address
          or a
          jp nz,invalid_input
          ld (inblock_addr),de

	  ld hl,len_prompt                         ; ask what length to save.
          call kjt_print_string
          ld a,5
          call kjt_get_input_string
          or a
          jp z,aborted
          call kjt_ascii_to_hex32                  ; de = in-block address
          or a
          jp nz,invalid_input
          ld a,c
	  or d
	  or e
	  jp z,invalid_input
	  	  
sd_iok	  ld (save_length_lo),de
	  ld (save_length_hi),bc
	  
	  xor a						;check range does not overflow end of buffer
	  ld hl,(inblock_addr)
	  add hl,de
	  adc a,c
	  ld c,$01
	  scf
	  ld de,$0000
	  sbc hl,de
	  sbc a,c
	  jp nc,too_many_bytes
	  	  
retry_sd  ld hl,data_fn
	  ld b,8
          ld c,2
     	  call save_requester
	  jr z,save_data_to_disk
	  cp $ff
	  jp z,aborted
	  cp $fe
	  jr z,save_data_serially
	  or a
          jr z,hw_err3
          call file_error_requester
          jr retry_sd
hw_err3   call hw_error_requester
          jr retry_sd
	  
	   
save_data_to_disk
	  
	  call set_save_regs
          call kjt_save_file
	  jp z,begin

sd_error  ld hl,save_error_text
error_msg call kjt_print_string
          call kjt_wait_key_press
          jp begin

too_many_bytes

	  ld hl,block_oflow_txt
	  jr error_msg
	  
	 

save_data_serially
          
	  push hl
	  ld hl,sending_text
	  call kjt_print_string
	  pop hl
	  call set_save_regs
	  call kjt_serial_send_file
	  jp z,begin
          ld hl,upload_error_text
	  jr error_msg

 
set_save_regs  

	  ld de,(inblock_addr)
	  ld b,data_bank
	  bit 7,d
	  jr z,sdlb
	  inc b					;save bank
sdlb	  set 7,d
	  push de
	  pop ix				;save addr
	  ld de,(save_length_lo)
	  ld a,(save_length_hi)
	  ld c,a				;c:de = length
	  ret	  
	  
	  
;------------------------------------------------------------------------------------------------------
; Subroutines
;------------------------------------------------------------------------------------------------------

read_in_block
          
          ld hl,block_read_text                   ; say "reading existing data"
          call kjt_print_string
          ld hl,0
          ld (page_count),hl
          
	  ld de,data_buffer                       ;read in existing 64KB page
          ld b,data_bank
	  exx
      	  ld a,(block_number)
          ld d,a
          ld e,0
          ld b,0
riedplp   push bc
          call read_eeprom_page
          or a
          jr nz,eprd_err
          exx
          call page_buffer_to_data_buffer
	  exx       
          inc de                                  ;next eeprom page
          pop bc                                  
          call show_progress
          djnz riedplp
          
 	  call show_progress
          call new_line
          xor a
          ret

eprd_err  pop bc
          ld hl,time_out_error_txt
          xor a
          inc a
          ret
          
          
;------------------------------------------------------------------------------------------

erase_block

          ld a,(block_number)           
          ld hl,erase_blk_chars
          call kjt_hex_byte_to_ascii
          
          ld hl,erasing_blk_text                  ; show "erasing" text
          call kjt_print_string

          ld a,(block_number)                     ; erase the required 64KB eeprom sector 
          call erase_eeprom_sector
          ret

;------------------------------------------------------------------------------------------

write_block

          ld hl,writing_text                      ; show "writing" text
          call kjt_print_string
          ld hl,0
          ld (page_count),hl
          
	  ld hl,data_buffer
          ld b,data_bank
	  exx
	  ld b,0                                  ; 256 pages to write
      	  ld a,(block_number)
          ld d,a
          ld e,0
dwrpagelp exx
	  call data_buffer_to_page_buffer
	  exx
	  ld hl,page_buffer
          call program_eeprom_page
          or a
          jr nz,wr_error
          call show_progress
          inc de
          djnz dwrpagelp
          call show_progress
          call new_line
	  xor a
	  ret

new_line  ld hl,newline_txt
          call kjt_print_string
          xor a
          ret


wr_error  ld hl,write_error_txt
          xor a
          inc a
          ret


;------------------------------------------------------------------------------------------

verify_block
          
          ld hl,verifying_data_txt                ; show "verifying" text
          call kjt_print_string
       
	  ld hl,0
          ld (page_count),hl
          
          ld hl,data_buffer
          ld b,data_bank
	  exx
	  ld b,0
          ld a,(block_number)
          ld d,a
          ld e,0
dvrpagelp call read_eeprom_page
          or a
          jr nz,time_out_err
       	  exx
	  call data_buffer_to_verify_buffer
	  exx
	  push bc
	  push de
	  push hl
	  ld b,0
          ld hl,page_buffer
          ld de,verify_buffer
verblp2	  ld a,(de)
	  cp (hl)
	  jr nz,verb_lp_error
	  inc hl
	  inc de
	  djnz verblp2
          pop hl
	  pop de
	  pop bc
	  call show_progress
          inc de
          djnz dvrpagelp
          
	  call show_progress
	  
          ld hl,newline_txt
          call kjt_print_string
          xor a
          ret
          
verb_lp_error

	  pop hl
	  pop de
	  pop bc

	  ld hl,verify_error_txt
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


          
retry_lr2 ld b,8
          ld c,2
          xor a                                   ;requester 0 - load
          ld hl,0                                 ;no filename supplied
          call load_requester
          jr z,go_fl
          cp $ff
          jp z,od_abort
          cp $fe
          jp z,sdownload2
handle_le or a
          jr z,hw_err2
          call file_error_requester
          jr retry_lr2
hw_err2   call hw_error_requester
          jr retry_lr2        

go_fl     call copy_filename
          ld (file_size),ix                       ;store filesize     
          push ix
          pop hl    
          ld a,h                                  ;check file fits within 64KB block
          or l
          jr z,fsok40
          dec hl
          ld a,h
          or l
          jr nz,fsbad2
fsok40    push iy
          pop hl
          dec hl
          ld de,(inblock_addr)
          add hl,de
          jr nc,flen_ok2

fsbad2    ld hl,addr_error_text
          jp od_bexit

flen_ok2  ld hl,loading_txt
          call kjt_print_string
          ld hl,(dload_address)                   ;data load address
          ld a,(dload_bank)                       ;data bank
          ld b,a                                  
          call kjt_force_load                     ;load data to buffer          
          jr nz,fl_error
          xor a
          ret


sdownload2          

          ld l,(ix+18)                            ;IX = address of file header
          ld h,(ix+19)
          ld a,h
          or l
          jr z,fsok4                              ;check file fits in 64KB block
          dec hl
          ld a,h
          or l
          jr nz,fsbad2
fsok4     ld l,(ix+16)                            
          ld h,(ix+17)
          dec hl
          ld de,(inblock_addr)
          add hl,de
          jr nc,dfile_ok
          jp fsbad2
          
dfile_ok  call receiving_requester
          ld hl,(dload_address)                   ; load address
          ld a,(dload_bank)
          ld b,a                                  ; load bank
          call kjt_serial_receive_file            ; download the file
          push af
          call w_restore_display
          pop af
          jr nz,ser_error
          xor a     
          ret


fl_error  ld hl,load_error_text
          jr od_bexit

ser_error ld hl,serial_error_txt
          jr od_bexit

od_abort  ld hl,abort_error_txt
          jr od_bexit         

od_bexit  xor a
          inc a
          ret

;------------------------------------------------------------------------------------------
          
show_error

          call kjt_print_string
          call kjt_wait_key_press
          jp begin
          
;------------------------------------------------------------------------------------------

set_load_pos

          ld de,(inblock_addr)
          ld a,data_bank                          ; convert flat 64K to 2 x upper 32KB + bank
          bit 7,d
          jr z,lowbank
          inc a
lowbank   ld (dload_bank),a
          set 7,d                                 ; This relies on data buffer being at $8000
          ld (dload_address),de
          ret

;------------------------------------------------------------------------------------------

show_progress

          push hl
          ld hl,(page_count)
          srl h
          rr l
          srl h
          rr l
          ld a,l
          ld hl,prog_figures+1
          ld (hl),$30
          dec hl
          ld (hl),$30         
hundlp    sub 100
          jr c,tens
          inc (hl)
          jr hundlp

tens      add a,100
          inc hl
tens_lp   sub 10
          jr c,units
          inc (hl)
          jr tens_lp

units     add a,10
          inc hl
          add a,$30
          ld (hl),a

          ld hl,(page_count)
          inc hl
          ld (page_count),hl  

          ld hl,prog_figures
iglsp     ld a,(hl)
          cp "0"
          jr nz,showpr
          inc hl
          jr iglsp
          
showpr    call kjt_print_string
          pop hl    
          ret


;----------------------------------------------------------------------------------------

show_slot_ids

          ld hl,current_slots_text
          call kjt_print_string

          call kjt_get_cursor_position
          ld (cursor_pos),bc
          
          ld a,0
id_loop   ld (working_slot),a
          ld bc,(cursor_pos)
          cp 16
          jr nz,sameside
          push af
          ld a,c
          sub 16
          ld c,a
          pop af

sameside  jr c,leftside
          ld b,20   

leftside  call kjt_set_cursor_position
          inc c
          ld (cursor_pos),bc

          ld a,(working_slot)                     
          ld hl,slot_number_text+1
          call kjt_hex_byte_to_ascii
          ld hl,slot_number_text
          call kjt_print_string
          
          ld a,(working_slot)                     ;read in EEPROM page that contains the ID string
          or a
          jr nz,notszero
          ld hl,bootcode_text
          jr id_ok  

notszero  ld h,a
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
unk_id    ld hl,unknown_text
id_ok     call kjt_print_string
          ld hl,number_of_slots
          ld a,(working_slot)
          inc a
          cp (hl)
          jr nz,id_loop
          
          call show_active_slot
          ret

;--------------------------------------------------------------------------------------

show_active_slot

          ld a,$88                                ; send PIC the command to prompt it to
          call send_byte_to_pic                   ; return the slot pointer MSB
          ld a,$76
          call send_byte_to_pic
    
          ld hl,active_slot                       ; read bits from PIC RB7 
          call read_pic_byte
          srl (hl)
          ld a,(hl)                               ; if slot returns $00, the PIC code does not support the command
          or a                                    ; so cannot show active slot text
          ret z
          
          ld hl,act_slot_figures
          call kjt_hex_byte_to_ascii
          
          ld hl,act_slot_text                     ; show the active slot
          call kjt_print_string
          ld hl,act_slot_figures
endit     call kjt_print_string
          xor a
          ret
          

          
read_pic_byte

          ld (hl),0
          ld c,8                                                   
nxt_bit   sla (hl)
          ld a,1<<pic_clock_input                 ; prompt PIC to present next bit by raising PIC clock line
          out (sys_pic_comms),a
          ld b,128                                ; wait a while so PIC can keep up..
pause_lp1 djnz pause_lp1
          xor a                                   ; drop clock line again
          out (sys_pic_comms),a
          in a,(sys_hw_flags)                     ; read the bit into shifter
          bit 3,a
          jr z,nobit
          set 0,(hl)
nobit     ld b,128
pause_lp2 djnz pause_lp2
          dec c
          jr nz,nxt_bit
          ret

          
;--------------------------------------------------------------------------------------

show_pic_firmware

          ld hl,pic_fw_text
          call kjt_print_string
          
          ld a,$88                                ; send PIC the command to prompt it to
          call send_byte_to_pic                   ; return its firmware byte
          ld a,$4e
          call send_byte_to_pic
          ld hl,pic_fw_byte                       ; read bits from PIC RB7 
          call read_pic_byte
          ld a,(hl)                               ; if fw > $00, the PIC firmware is v618+
          or a                                    ; so cannot show active slot text
          jr nz,got_fw
          ld hl,pic_fw_unknown_text
          jr fw_end
          
got_fw    ld hl,pic_fw_figures+1
          call kjt_hex_byte_to_ascii
          ld hl,pic_fw_figures                              ; show pic fw
fw_end    call kjt_print_string
          xor a
          ret

;--------------------------------------------------------------------------------------

show_eeprom_type

          in a,(sys_eeprom_byte)                  ; clear shift reg count with a read

          ld a,$88                                ; send PIC the command to prompt the EEPROM to
          call send_byte_to_pic                   ; return its ID code byte
          ld a,$53
          call send_byte_to_pic
                
          ld d,32                                 ; D counts timer overflows
          ld a,1<<pic_clock_input                 ; prompt PIC to send a byte by raising PIC clock line
          out (sys_pic_comms),a
wbc_byte2 in a,(sys_hw_flags)                     ; have 8 bits been received?            
          bit 4,a
          jr nz,gbcbyte2
          in a,(sys_irq_ps2_flags)                ; check for timer overflow..
          and 4
          jr z,wbc_byte2      
          out (sys_clear_irq_flags),a             ; clear timer overflow flag
          dec d                                   ; dec count of overflows,
          jr nz,wbc_byte2                                             
          xor a                                   ; if waited too long give up (and drop PIC clock)
          out (sys_pic_comms),a
          jr no_id                                
gbcbyte2  xor a                         
          out (sys_pic_comms),a                   ; drop PIC clock line, PIC will then wait for next high 
          in a,(sys_eeprom_byte)                  ; read byte received, clear bit count

          push af
          ld hl,eeprom_id_text
          call kjt_print_string
          pop af

          cp $bf                                  ; If SST25VF type EEPROM is present, we'll have received
          jr nz,non_sst                           ; manufacturer's ID ($BF) not the capacity

          ld hl,sst25vf_text
          call kjt_print_string         
          ld a,$88                                ; Use alternate "Get EEPROM ID" command to find ID 
          call send_byte_to_pic                   
          ld a,$6c
          call send_byte_to_pic
          ld hl,eeprom_id_byte                              
          call read_pic_byte
          ld a,(hl)
          jr got_eid
          
non_sst   push af
          ld hl,at25x_text
          call kjt_print_string
          pop af
got_eid   ld (eeprom_id_byte),a         
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
slotslp   sla a
          djnz slotslp
          ld (number_of_slots),a
          ret

no_id     ld hl,no_id_text
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

copy_filename

          push bc
          push de
          push hl
          ld b,12
          ld de,filename_txt
cpyfnlp   ld a,(hl)
          or a
          jr z,cpyfndone
          ld (de),a
          inc hl
          inc de
          djnz cpyfnlp
cpyfndone pop hl
          pop de
          pop bc
          ret
          
	  
test_v6c_extension

	ld hl,filename_txt
	ld a,"."
	ld bc,9
	cpir
	ret nz

	ld a,(hl)
	cp "v"
	jr z,exok1
	cp "V"
	ret nz
exok1	inc hl
	ld a,(hl)
	cp "6"
	ret nz
	inc hl
	ld a,(hl)
	cp "c"
	ret z
	cp "C"
	ret

;----------------------------------------------------------------------------------------------------------------
	
	
hex_to_ascii_word

		ld a,d
		call kjt_hex_byte_to_ascii
		ld a,e
		call kjt_hex_byte_to_ascii
		ret


;----------------------------------------------------------------------------------------------------------------
	
		
show_eeprom_bootcode

		ld d,a
		ld hl,pebc_txt
		or a
		jr z,pribc
		ld hl,bebc_txt
pribc		call kjt_print_string
			
		ld e,$fd
		call read_eeprom_page
		ld ix,page_buffer+$bc
		ld e,(ix)
		ld d,(ix+1)
		ld a,d					;if $0000, assume its a version before 617
		or e
		jr nz,ebc_ok1
		ld hl,old_ebc_txt
		call kjt_print_string
		ret
		
ebc_ok1		ld a,d					;if $ffff, assume its blank
		and e
		inc a
		jr nz,ebc_ok2
		ld hl,no_ebc_txt
		call kjt_print_string
		ret
		
ebc_ok2		ld hl,ebc_txt
		push hl
		call hex_to_ascii_word
		pop hl
		call kjt_print_string
		ret

	
pebc_txt	db 11,11,"Primary bootcode on EEPROM: ",0
bebc_txt	db 11,"Backup bootcode on EEPROM : ",0
ebc_txt		db "????",0		

old_ebc_txt	db "< 0617",0

no_ebc_txt	db "None",0


;--------------------------------------------------------------------------------------------------------------------


show_eeprom_os_status

		ld hl,os_txt
		call kjt_print_string
		
		ld de,$8
		call read_eeprom_page			;load from EEPROM $00800
		ld hl,page_buffer			; check if 
		ld de,z80_OS_txt			; bytes 0-7 are "Z80P*OS*"
		ld b,8					
cmposn		ld a,(de)				 
		cp (hl)
		jr nz,noeos				
		inc de
		inc hl
		djnz cmposn
		
		ld de,(page_buffer+$e)			;any label location?
		ld a,d
		or e
		jr nz,gotoslab
unkeos		ld hl,unkos_txt
		call kjt_print_string
		xor a
		ret
		
gotoslab	ld hl,$0800				;move to page offset of label
		add hl,de
		jr c,unkeos
		ld e,h
		ld d,0
		push hl
		call read_eeprom_page
		pop hl
		ld h,0
		ld bc,page_buffer
		add hl,bc				;in-page label address
		ld bc,oslabel_txt
cpylab1		ld a,(bc)
		or a
		jr z,showoslab
		ld a,(hl)
		ld (bc),a
		or a
		jr z,showoslab
		inc bc
		inc l
		jr nz,cpylab1
		inc de					;in case label crosses page
		push bc
		call read_eeprom_page
		pop bc
		ld hl,page_buffer
cpylab2		ld a,(bc)
		or a
		jr z,showoslab
		ld a,(hl)
		ld (bc),a
		or a
		jr z,showoslab
		inc bc
		inc l
		jr nz,cpylab2
		
showoslab	ld hl,oslabel_txt
		call kjt_print_string
		xor a
		ret
		
		
noeos		ld hl,noos_txt
		call kjt_print_string
		xor a
		inc a
		ret
		

os_txt		db 11,"OS currently on EEPROM: ",11,11,0
z80_OS_txt	db "Z80P*OS*"

noos_txt	db "No OS installed.",0
unkos_txt	db "Yes, but no label.",0

oslabel_txt	ds 32,$ff					;label can be 32 chars max
		db 0
		
		
;----------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

include "FLOS_based_programs\code_library\requesters\inc\file_requesters_with_rs232.asm"

include "FLOS_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

;----------------------------------------------------------------------------------------




start_text1         db    "                                      ",11
                    db    "   V6Z80P ONBOARD EEPROM TOOL V1.25   ",11
                    db    "                                      ",11,0
                    
start_text2         db 11
                    db    "Select:",11
                    db    "-------",11,11
                    db    "1 - Write FPGA config file to a slot",11
                    db    "2 - Reconfigure the FPGA now",11
                    db    "3 - Change the power-up boot slot",11
		    db    "4 - Erase a slot",11
                    db 11
                    db    "5 - Install OS to EEPROM",11
                    db    "6 - Remove OS from EEPROM",11
                    db    "7 - Update bootcode",11
                    db 11
                    db    "8 - Insert data into EEPROM block",11
		    db    "9 - Save data from EEPROM block",11
                    db 11
                    db    "ESC - Quit",11,0
                    
slot_prompt_text    db 11,11,"Write new config to which slot? ",0

warning_1_text      db 11,11,"Sure you want to write to the",11
                    db "currently active slot (y/n) ",0

er_warning_1_text   db 11,11,"Sure you want to erase the",11
                    db "currently active slot (y/n) ",0

er_warning_2_text   db 11,11,"Sure you want to erase slot 0?",11
                    db "Bootcode, OS etc will be lost! (y/n) ",0
                                        
erasing_text        db 11,"Erasing slot:"
erase_chars         db "xx",11,0

writing_text        db 11,"Writing data - please wait",11,0

verifying_text      db 11,"Verifying data",11,0

verifying_erase     db 11,"Verifying erasure",11,0

serial_error_text   db 11,"Download error. Press any key.",0

eeprom_error_text   db 11,"ERROR! EEPROM problem.",0


block_prompt_text   db 11,11,"Write data to which 64KB block? ",0

block_read_text     db 11,11,"Reading data from block..",11,0

addr_prompt_text    db 11,"Hex address within block? (0-FFFF) ",0

addr_error_text     db 11,"ERROR! File cannot overlap 64KB block",11,11
                    db "Press any key",0

erasing_blk_text    db 11,"Erasing block:"
erase_blk_chars     db "xx..",11,0

set_slot_text       db 11,11,"Enter the slot number from which the",11
                    db "FPGA is to configure at power up: ",0

warning_2_text      db 11,11,"WARNING! You are changing the power",11
                    db "on configuration slot selection.",11,11
                    db "If the config in the selected slot",11
                    db "offers no means of changing back you",11
                    db "will have to resort to manual slot",11
                    db "selection. For safety, test the config",11
                    db "slot with option [2] first.",11,11
                    
                    db "On power up the FPGA will now configure",11
                    db "from EEPROM slot "
check_digit         db "xx - Sure? (y/n) ",0
                    
reconfig_now_text   db 11,11,"Reconfigure FPGA now (non permanent)"
                    db 11,11,"Which slot? ",0

ok_text             db 13,11,11,"SUCCESS! - Press any key..",11,0

cr_txt              db 11,0

time_out_text       db 11,11,"ERROR - Timed out. Press any key.",0

file_too_big_text   db 11,"Filesize error - Press any key.",0

write_error_text    db 11,"Write error - Press any key",0

verify_error_text   db 11,"Verify error - Press any key",0

input_error_text    db 11,11,"Invalid input - Press any key",0

wildcard_filename   db "*",0

cfg_file_error_text db 11,11,"Not a valid Xilinx config file!",11,11
                    db "Press any key",11,0

load_error_text     db 11,11,"Load error - Press any key",0
          
loading_txt         db 11,"Loading...",11,0

install_os_txt      db 11,11,"Sure you want to update OS? (y/n) ",0

uninstall_os_txt    db 11,11,"Sure you want to remove OS? (y/n) ",0

os_size_error_txt   db "File to big for EEPROM page!",11
                    db "OS must be $E800 bytes or less",11,0

abort_error_txt     db 11,11,"Aborted - Press any key",11,0

time_out_error_txt  db 11,"Time out error - Press any key",11,0

write_error_txt     db 11,"Write error!",11,0

verify_error_txt    db 11,"Verify error!",11,0

serial_error_txt    db 11,"Serial error - Press any key",11,0

verifying_data_txt  db 11,"Verifying data..",11,0

delpage_txt         db 11,"Removing OS signature..",11,0

update_bootcode_txt db 11,11,"Update:",11,11
                    db "[0] Primary bootcode",11,"[1] Backup bootcode",11,11
		    db "Enter 0 or 1 (or ESC to cancel) :",0

pbc_warning_txt     db 11,"Error! This would overwrite the primary",11
                    db "bootcode at $0f000 which is not allowed.",11,11
                    db "Press any key.",11,0

bbc_warning_txt     db 11,"Caution! This will overwrite the backup",11
                    db "bootcode at $1f000 - Sure you want to",11
                    db "proceed? (y/n) ",0

cfg_warning_txt     db 11,11,"Caution! FPGA config data MAY exist",11
                    db "in this block. OK to proceed? (y/n) ",0

os_warn_txt         db 11,"Caution! An Operating System may be",11
                    db "installed in this block. Sure you want",11
                    db "to proceed? (y/n) ",0

warn_active_slot_txt db 11,11,"ERROR! Writing data to a block within",11
                     db "the Active Slot is not allowed!",11,0

current_slots_text  db 11,"Current EEPROM slot contents..",11,11,0
bootcode_text       db "BOOTCODE ETC",0

slot_number_text    db " xx:",0
unknown_text        db "UNKNOWN",0

slot_zero_text      db 11,11,"SLOT 0 cannot hold FPGA configs!"
                    db 11,11,"Press any key.",0             

current_slot_txt    db 11,11,"Current Active Slot: "
active_slot_txt     db "xx",11,11,0


eeprom_id_text      db 11,"Detected EEPROM type: ",0
at25x_text          db "25*",0
sst25vf_text        db "SST25VF",0

eeprom_id_list      db "20 (256KB)",11,0,0,0,0,0  ;id = $11
                    db "40 (512KB)",11,0,0,0,0,0  ;id = $12
                    db "80 (1MB)  ",11,0,0,0,0,0  ;id = $13
                    db "16 (2MB)  ",11,0,0,0,0,0  ;id = $14
                    db "32 (4MB)  ",11,0,0,0,0,0  ;id = $15
                    db "64 (8MB)  ",11,0,0,0,0,0  ;id = $16


no_id_text          db 11,"EEPROM: Unknown - Assuming 25x40 (512KB)",0

act_slot_text       db 11,11,"Current active slot:",0
act_slot_figures    db "xx",0

no_change_text      db 11,11,"Active slot unchanged.."
                    db 11,11,"Press any key",0

total_blocks_text   db 11,"Max EEPROM block: "
total_blocks_figs   db "xx",0

op7_block_text      db " (Blocks "
op7_fig_text1       db "xx/"
op7_fig_text2       db "xx)",11,0
          
restart_text        db 11,11,"Reconfiguring...",0

pic_fw_text         db 11,"Config PIC firmware: ",0
pic_fw_figures      db "6xx",11,0
pic_fw_unknown_text db "Unknown",11,0

retry_txt           db 11,"Do you want to re-write the data (y/n)? ",0

erase_prompt_text   db 11,11,"Erase which slot? ",0

prog_figures        db "--- KB complete..",13,0

data_fn		    db "DATA.BIN",0
src_addr_prompt     db 11,"Save from what address 0-FFFF? ",0
len_prompt          db 11,11,"Save how many bytes? ",0
block_oflow_txt     db 11,11,"ERROR: Too many bytes requested",0
read_block_prompt   db 11,11,"Save data from which 64KB block? ",0
save_error_text     db 11,11,"Save error!",0
upload_error_text   db 11,11,"Serial Upload error!",0
sending_text	    db 11,11,"Sending...",0

pcb_error_text	    db 11,11,"ERROR: This config file is not",11
		    db "compatible with your V6Z80P PCB.",11,11
		    db "Press any key.",11,0

pressanykey_txt	    db 11,11,"Press any key..",0



;------------------------------------------------------------------------------------------
