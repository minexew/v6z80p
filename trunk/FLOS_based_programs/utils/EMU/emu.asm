; EMU.exe - A boot util for emulators (only useful for V6Z80P v1.1)
; -----------------------------------------------------------------
;
; Currently configured to support:
; --------------------------------
;
; Spectrum 48   - By Alessandro Dorigatti
; Spectrum 128  - ""                    "
; Pentagon 128  - ""                    "
; 
;
; Changes:
; --------
;
; v0.10 - Requester code 0.28
; v0.08 - More easily customizable, supports up to 10 machines
; v0.07 - Allows boot (to residos/esxdos) via arguments ("EMU M0" = machine0, "EMU M1" = machine1)
; V0.06 - Tests OSCA version on boot
; V0.05 - Options 1/2 disabled in ESXDOS mode
; v0.04 - Supports jumper Exp_b detect for RESIDOS/ESXDOS.NVR select: Closed = ESXDOS, Open = Residos
;         (Note: If OSCA is < $671, the pin is ignored due to lack of weak pullup: Residos only.)       
;
; v0.03 - Uses new requester code
; v0.02 - Manual saving of machine selection
; v0.01 - First release (previously called "gospec.exe")


;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

required_flos   equ $608
include         "flos_based_programs\code_library\program_header\inc\test_flos_version.asm"

required_osca   equ $672
include         "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

max_path_length	equ 255

;----------------------------------------------------------------------------------------------

buffer_size         equ 512                       
buffer_bank         equ 0

machine_rom_addr   equ $8000
machine_rom_bank   equ 1

;----------------------------------------------------------------------------------------------


          call save_dir_vol
          call emu_go
          call restore_dir_vol
          ret

;----------------------------------------------------------------------------------------------
                   
emu_go    ld (arg_string),hl
          
          call kjt_get_pen
          ld (pen_colour),a
                  
          xor a
          call kjt_set_bank
          
          call load_config_file      		 ; load config file, if exists                      
          jr nz,nocfg
	  call parse_config_file
	  call set_default_slot_ascii_hex
nocfg	  
          ld a,2
          out (sys_io_dir),a                     ; make sure exp B jumper is in input mode
          call compare_exp_pin			  ; sets default value
	  
;----------------------------------------------------------------------------------------------
          
          ld hl,(arg_string)
          ld a,(hl)                               ;was this run via arg string?
          or a
          jr z,no_args
          
          xor a
          ld (args_set),a
          
argloop   ld a,(hl)
          or a
          jr nz,notlarg

last_arg  ld a,(args_set)
          cp 1                                    ;number of args required for successful boot
          jr z,args_ok
          ld a,$12                                ;bad args
          or a
          ret

args_ok   jp boot_nvr                             ;boot to residos/esxdos
          
notlarg   cp "M"
          jr z,config_arg
          cp "m"
          jr z,config_arg
nxtarg    inc hl
          jr argloop


config_arg

          inc hl
          ld a,(hl)
          push hl
          sub $30
	  jr c,bad_mach
          cp number_of_machines
	  jr nc,bad_mach
	  ld (machine_selection),a
	  ld a,(args_set)
          inc a
          ld (args_set),a
bad_mach  pop hl
          inc hl
          jr nxtarg

          
no_args	  call goto_spectrum_dir
          
          
;-----------------------------------------------------------------------------------------------    
; Menu is customized depending on machine type settings
;-----------------------------------------------------------------------------------------------    
          
start     

menu_text call kjt_clear_screen
          call show_custom_menu
          
menu_wait call compare_exp_pin			; redraw menu if Hw jumper pins changed
          jr nz,menu_text                  
                    
read_key  call kjt_get_key
          cp $76
          jr nz,not_quit
          xor a
          ret
          
not_quit  ld a,b
	  ld c,"1"
	  ld ix,custom_menu_jps
	  ld b,8
cmelp	  cp c
	  jr z,cust_option_selected
	  inc c
	  inc ix
	  inc ix
	  djnz cmelp
	  
          cp "s"
          jp z,s_option
          cp "c"
          jp z,c_option
          cp "m"
          jp z,m_option
          jr menu_wait

cust_option_selected
	
	  ld l,(ix)
	  ld h,(ix+1)
	  jp (hl)
	  
;------------------------------------------------------------------------------------------

          
go_basic  call basic_reconfigure
          jr error_menu       
        
;------------------------------------------------------------------------------------------
  
preload_tap

	  call load_tap_reconf
          jr nz,error_menu
          jr menu_wait                            ;no need to redraw menu, requester code replaces previous chars

;------------------------------------------------------------------------------------------

boot_nvr  call nvr_reconfig 
          jr nz,error_menu
          jr menu_text

;------------------------------------------------------------------------------------------

s_option  call select_machine 
          jr nz,error_menu
          jr start

;------------------------------------------------------------------------------------------

c_option  call set_machines_config_slot
          jr nz,error_menu
       	  jr start

;------------------------------------------------------------------------------------------

m_option  call set_default_slot_ascii_hex
	  call save_config_file
          jr nz,error_menu
	  jr start

;------------------------------------------------------------------------------------------

error_menu

          ld hl,error_txt
          call kjt_print_string
          call press_a_key
          jp start

;-----------------------------------------------------------------------------------------

inverse_video

          ld a,(pen_colour)
          rrca
          rrca
          rrca
          rrca
          call kjt_set_pen
          ret


normal_video

          ld a,(pen_colour)
          call kjt_set_pen
          ret
          
          
;-----------------------------------------------------------------------------------------

press_a_key

          ld hl,press_a_key_txt
          call kjt_print_string
          call kjt_wait_key_press
          ret

;----------------------------------------------------------------------------------------

goto_spectrum_dir
          
    	  ld hl,spectrum_dir
	  call kjt_parse_path
	  ret
	


goto_settings_dir

          ld hl,settings_dir
          call kjt_parse_path
	  ret
 


make_settings_dir
  
	  ld a,0
	  call kjt_change_volume		  ;change to vol0:
	  ret nz

          call kjt_root_dir			  ;go to root
          ret nz
	  
          ld hl,settings_txt                      ;make the dir
          call kjt_make_dir
          ret

;------------------------------------------------------------------------------------------
          
          
basic_reconfigure

          call check_reconf_slot                  
          ret nz                                  ; if not set up correctly exit

          call load_machine_rom                   ; load the appropriate ROM for machine
          ret nz                                  

          call copy_bank_switch_code_to_vram
                    
go_cfg    ld a,$88                                ; send "set config base" command
          call send_byte_to_pic
          ld a,$b8
          call send_byte_to_pic
          ld a,$00                      
          call send_byte_to_pic                   ; send address low
          ld a,$00            
          call send_byte_to_pic                   ; send address mid
          
          ld a,(machine_selection)
          ld e,a
          ld d,0
          ld hl,machine_slot_list
          add hl,de
          ld a,(hl)
          sla a
          call send_byte_to_pic                   ; send address high

          ld a,$88                                ; send reconfigure command
          call send_byte_to_pic
          ld a,$a1
          call send_byte_to_pic


stop_here jr stop_here
          
          
;------------------------------------------------------------------------------------------


load_tap_reconf

          call check_reconf_slot                  ; if config slot not set up correctly exit
          ret nz
          
retrylr   ld b,8                                  ; invoke load requester
          ld c,2
          xor a
          ld hl,0
          call load_requester
          jr z,ftapok
          
          cp $ff                                  ; aborted?
          ret z

ld_error  or a
          jr z,hw_err1
          
          call file_error_requester
          jr retrylr

hw_err1   call hw_error_requester
          jr retrylr


ftapok    push hl
          push ix                                 ; put $0,$0 at the end of tap files to assist
          pop bc                                  ; tap player logic in Spectrum config determine the end
          push iy
          pop de
          xor a
          call write_vram_flat
          ld bc,1
          add iy,bc
          jr nc,addmswok
          inc ix
addmswok  push ix
          pop bc
          push iy
          pop de
          xor a
          call write_vram_flat
          pop hl

                    
ldreq_ok1 call copy_filename
          
          call kjt_clear_screen
          					  ; Load in machine's ROM, (directory postion is saved around the ROM load)
          call load_machine_rom                   
	  ret nz

          call show_loading_msg
          
          ld de,0
          ld (vram_load_addr_lo),de               ; normally, load file to VRAM $00000

          ld hl,filename
          ld b,11
fnddot    ld a,(hl)
          cp "."
          jr z,gotdot
          inc hl
          djnz fnddot
          jr not_tap
gotdot    inc hl
          ld a,(hl)
          cp "t"
          jr z,got_t
          cp "T"
          jr nz,not_tap
got_t     inc hl
          ld a,(hl)
          cp "a"
          jr z,got_a
          cp "A"
          jr nz,not_tap
got_a     inc hl
          ld a,(hl)
          cp "p"
          jr z,is_tap
          cp "P"
          jr nz,not_tap
          
is_tap    call copy_bank_switch_code_to_vram      ; but if it is a .tap file, copy the bank switch code to $00000
          ld de,$14                               ; and load the .tap file after it (VRAM $00014)
          ld (vram_load_addr_lo),de
          
not_tap   ld a,0
          ld (vram_load_addr_hi),a
          call load_to_vram                       
          ret nz
                    
vrlok     jp go_cfg                     


load_quit xor a
          inc a
          ret
          



copy_filename

          push bc
          push de
          push hl
          ld b,12
          ld de,filename
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

;------------------------------------------------------------------------------------------


nvr_reconfig
          
          call check_reconf_slot
          ret nz                                  ; if  not set up correctly, exit
          
	  ld a,(machine_selection)
          call get_machine_nvr_filename
          call extract_path_and_filename
	  ld hl,path_txt
	  call kjt_parse_path
	  ld hl,filename_txt
	  call kjt_open_file
	  ld hl,filename_txt
	  jp z,ldreq_ok1
          
          ld hl,cannot_find_txt
          call kjt_print_string
	  ld a,(machine_selection)
          call get_machine_nvr_filename
          call kjt_print_string
          xor a
          inc a
          ret
          

;------------------------------------------------------------------------------------------

         
check_reconf_slot
          
          ld a,(machine_selection)
          call get_machines_slot_address
	  ld a,(hl)
          or a
          jr z,set_machines_config_slot           ; If slot for the chosen machine hasnt been set
          xor a                                   ; prompt for slot number
          ret
          

set_machines_config_slot
          
          call show_eeprom_slot_contents
          
          ld hl,slot_prompt_txt
          call kjt_print_string
	  ld a,(machine_selection)
          call get_machine_name
	  call kjt_print_string
          ld hl,slot_prompt2_txt
	  call kjt_print_string
	  ld a,2
          call kjt_get_input_string
          or a
          jr nz,gotstr
          inc a                                   ; return with ZF not set: error
          ret

gotstr    call kjt_ascii_to_hex_word              ; is entered text a valid number (result in DE)?
          or a
          ret nz
      	  ld a,(machine_selection)
	  call get_machines_slot_address
	  ld (hl),e
	   	  
	  
save_config_file

	  call push_dir_vol
	  call save_cfg
	  call pop_dir_vol
	  ret

save_cfg  call build_new_config_file

gsdir     call goto_settings_dir		  ;save config file "EMU.CFG" in VOL:SETTINGS dir
	  jr z,setdok
	  call make_settings_dir
	  ret nz
	  call goto_settings_dir
	  ret nz
          
setdok    ld hl,cfg_fn                            ;remove old cfg file (if exists)
          call kjt_erase_file
          
          ld hl,saving_cfg_txt
          call kjt_print_string
          
          ld hl,cfg_fn
          ld ix,config_file_buffer
          ld b,0
          ld c,0
          ld de,(config_file_size)
          call kjt_save_file
          ret
          
;---------------------------------------------------------------------------------------
          
          
select_machine

	ld a,(machine_selection)		;simple flip through selection
	inc a
	cp number_of_machines
	jr nz,msok
	xor a
msok	ld (machine_selection),a
	xor a					;so no error on return
	ret
	



	  call kjt_clear_screen			; alterntaive menu based selection
	  
	  call inverse_video
          ld hl,banner_txt
          call kjt_print_string
          call normal_video

	  ld hl,machine_list_txt
	  call kjt_print_string
	  ld b,number_of_machines
	  ld c,$31
maclistlp push bc
	  ld a,c
	  ld hl,menu_numchr_txt+1
	  ld (hl),a
	  dec hl
	  call kjt_print_string
	  ld a,c
	  sub $31
	  call get_machine_name
	  call kjt_print_string
	  call new_line
	  pop bc
	  inc c
	  djnz maclistlp
	  
	  call kjt_wait_key_press
	  ld a,b
	  or a
	  ret z
	  sub $31
	  jr c,ms_bad
	  cp number_of_machines
	  jr nc,ms_bad
	 
          ld (machine_selection),a

ms_bad    xor a
          ret
           
	   
machine_list_txt

	  db 11,"Select a machine:",11,11,0

;----------------------------------------------------------------------------------------


new_line	

	push hl
	ld hl,cr_txt
	call kjt_print_string
	pop hl
	ret

cr_txt	db 11,0


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------- 
          
show_eeprom_slot_contents

          call get_eeprom_type
          
          call kjt_clear_screen

          call inverse_video
          ld hl,banner_txt
          call kjt_print_string
          call normal_video

          ld hl,eeprom_contents_txt
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
          ld hl,slot_number_text
          call kjt_hex_byte_to_ascii
          ld hl,slot_text
          call kjt_print_string
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
          
          ret


;--------------------------------------------------------------------------------------


get_eeprom_type

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

          cp $bf                                  ; If SST25VF type EEPROM is present, we'll have received
          jr nz,got_eid                           ; manufacturer's ID ($BF) not the capacity

          ld b,0                                  ; wait a while to ensure PIC is ready for command
deloop1   djnz deloop1
          
          ld a,$88                                ; Use alternate "Get EEPROM ID" command to find ID 
          call send_byte_to_pic                   
          ld a,$6c
          call send_byte_to_pic
          ld hl,eeprom_id_byte                              
          call read_pic_byte
          ld a,(hl)
          
got_eid   ld (eeprom_id_byte),a         
          sub $10
          ld b,a
          ld a,1
slotslp   sla a
          djnz slotslp
          ld (number_of_slots),a
          ret

no_id     xor a                                   ;error reading eeprom ID
          inc a
          ret
          
                              
;----------------------------------------------------------------------------------------
          
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

;----------------------------------------------------------------------------------------

compare_exp_pin
	  
	  call read_exp_pin
	  ld hl,exp_pin_status
	  cp (hl)
	  ld (exp_pin_status),a
	  ret
	  
	  
read_exp_pin
	  
          in a,(sys_io_pins)                      
          cpl
          rrca
          and 1
          ret


exp_pin_status

	  db 0
	 
;-----------------------------------------------------------------------------------------

load_to_vram


          call vram_load_main
          ret z
          
          ld hl,$f00                    ;if error, make text red
          ld (palette+2),hl
          ret

          
vram_load_main
          

          ld a,(vram_load_addr_hi)      ; H:DE = VRAM load address
          ld h,a
          ld de,(vram_load_addr_lo)

          ld a,e                        ; convert linear address to 8KB page and address between 2000-3fff
          ld (page_address),a
          ld a,d
          and $1f
          or $20
          ld (page_address+1),a
          srl h
          rr d
          srl h
          rr d
          srl h
          rr d
          srl h
          rr d
          srl h
          rr d
          ld a,d
          and $7f
          cp $40
          ld (video_page),a   
          jp c,range_ok
          xor a
          inc a
          ret
          
range_ok  ld hl,filename                ; does filename exist?
          call kjt_find_file
          ret nz
          ld (length_hi),ix             ; ix:iy = size of file (bytes-to-go)
          ld (length_lo),iy
          
          ld a,(video_page)   
          ld (vreg_vidpage),a

b_loop    ld de,(length_hi)             ; de:hl = bytes to go..
          ld hl,(length_lo)
          ld bc,buffer_size             ; ix:iy = default load length (buffer size)       
          xor a
          sbc hl,bc
          jr nc,btg_ok                  
          ex de,hl
          ld bc,0
          sbc hl,bc                     ; do the borrow for hi word
          ex de,hl
          jr nc,btg_ok
          ld bc,buffer_size
          add hl,bc                     ; bytes-to-go is less than a full buffer: only load the bytes required
          ld (read_bytes),hl
          call fill_buffer
          call copy_buffer_to_vram
          xor a
          ret
          
btg_ok    ld (length_hi),de             ; update bytes-to-go
          ld (length_lo),hl
          ld bc,buffer_size
          ld (read_bytes),bc
          call fill_buffer
          call copy_buffer_to_vram
          
          ld hl,$222                    ; flash loading message
          ld a,(length_lo+1)
          and $40
          jr z,got_col
          ld hl,$aaa
got_col   ld (palette+2),hl
          
          jr b_loop


;----------------------------------------------------------------------------------------------------------

fill_buffer


          ld bc,(read_bytes)
          ld a,b                        ; if read bytes count = 0, dont do anything
          or c
          ret z

          push bc
          pop iy
          ld ix,0
          call kjt_set_load_length      ; ix:iy = load length (normally a full buffer)

          ld hl,load_buffer
          ld b,buffer_bank
          call kjt_force_load           ; load to a buffer in sys ram
          ret
          
;----------------------------------------------------------------------------------------------------------

          
copy_buffer_to_vram
          
          call kjt_page_in_video
          
          ld bc,(read_bytes)
          ld a,b                        ; if read bytes count = 0, dont do anything
          or c
          jr z,cpy_done       

          ld hl,(page_address)
          add hl,bc
          ld a,h
          and $c0
          jr z,sp_copy                  ; will the bytes in buffer spill into a new video page?
          
          ld de,(page_address)          ; always between 2000-3fff
          ld hl,load_buffer   
          ld bc,(read_bytes)
cpylp     ldi                           ; this is the slow copy, when the video page buffer will
          bit 6,d                       ; change during the write
          jr z,samepage
          ld d,$20
          ld a,(video_page)             ; next video page
          inc a
          cp $40
          jr nc,bad_addr
          ld (video_page),a
          ld (vreg_vidpage),a
samepage  ld a,b
          or c
          jr nz,cpylp
          ld (page_address),de
          jr cpy_done
          
sp_copy   ld de,(page_address)          ; always between 2000-3fff    
          ld hl,load_buffer             ; copy the buffered bytes to VRAM
          ld bc,(read_bytes)  
          ldir                          ; this is the faster copy when the video page wont be changed
          ld (page_address),de

cpy_done  call kjt_page_out_video
          xor a
          ret
          
bad_addr  call kjt_page_out_video
          xor a                         
          inc a
          ret
          
;----------------------------------------------------------------------------------------------

load_machine_rom

	  call push_dir_vol
	  call get_rom
	  call pop_dir_vol
	  ret
	  
get_rom   ld a,(machine_selection)
          call get_machine_rom_filename
	  call extract_path_and_filename
	  ld hl,path_txt
	  call kjt_parse_path
	  ld hl,filename_txt
	  ld ix,machine_rom_addr
          ld b,machine_rom_bank
          call kjt_load_file
          ret z
          
          ld hl,cannot_find_txt                   ;Couldn't find ROM file message
          call kjt_print_string
	  ld a,(machine_selection)
	  call get_machine_rom_filename
	  call kjt_print_string
          xor a
          inc a
          ret
          
;-------------------------------------------------------------------------------------------------

write_vram_flat

;set c:de to vram address
;set a to byte to write
;carry set on return if all OK

          ld b,a
          ld l,e
          ld a,d
          and $1f
          or $20
          ld h,a
          srl c
          rr d
          srl c
          rr d
          srl c
          rr d
          srl c
          rr d
          srl c
          rr d
          ld a,d
          cp $40
          ret nc
          ld (vreg_vidpage),a 
          in a,(sys_mem_select)
          set 6,a
          out (sys_mem_select),a
          ld (hl),b
          res 6,a
          out (sys_mem_select),a
          scf
          ret


;-------------------------------------------------------------------------------------------------


copy_bank_switch_code_to_vram

          ld hl,bank_switch_code
          ld de,0
          ld c,0
          ld b,end_of_bank_switch_code-bank_switch_code
bscc_lp   ld a,(hl)
          push bc
          push de
          push hl
          call write_vram_flat
          pop hl
          pop de
          pop bc
          inc hl
          inc de
          djnz bscc_lp        
          ret


bank_switch_code

          incbin "FLOS_based_programs\utils\emu\data\bank_switch_code.bin"

end_of_bank_switch_code

;-----------------------------------------------------------------------------------------------------

push_dir_vol

	push af
	push hl
	push de
	push bc
	
	call kjt_get_volume_info
	ld (prior_vol),a
	call kjt_get_dir_cluster
	ld (prior_dir),de
	
	pop bc
	pop de
	pop hl
	pop af
	ret
	
	
pop_dir_vol

	push af
	push hl
	push de
	push bc

	ld a,(prior_vol)
	call kjt_change_volume
	ld de,(prior_dir)
	call kjt_set_dir_cluster

	pop bc
	pop de
	pop hl
	pop af
	ret
	

prior_dir	dw 0
prior_vol	db 0

;-----------------------------------------------------------------------------------------------------

include "FLOS_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

include "FLOS_based_programs\code_library\requesters\inc\file_requesters_with_rs232.asm"

include "flos_based_programs\code_library\loading\inc\save_restore_dir_vol.asm"

include "flos_based_programs\code_library\string\inc\extract_path_and_filename.asm"

;----------------------------------------------------------------------------------------


show_loading_msg

          ld a,0
          ld (vreg_rasthi),a            ; select y window reg
          ld a,$f0
          ld (vreg_window),a            ; set y window size/position (48 lines)
          ld a,%00000100
          ld (vreg_rasthi),a            ; select x window reg
          ld a,$aa
          ld (vreg_window),a            ; set x window size/position (256 pixels)
          
          ld a,0
          ld (vreg_yhws_bplcount),a     ; set 1 bitplane display
                    
          ld a,0
          ld (vreg_vidctrl),a           ; set bitmap mode + normal border + video enabled

          ld hl,$f800
          ld (bitplane0a_loc),hl        ; start address of video datafetch for window [15:0]
          ld a,7
          ld (bitplane0a_loc+2),a       ; start address of video datafetch for window [18:16]


          ld hl,palette                 ; background = black, colour 1 = white
          ld (hl),0
          inc hl
          ld (hl),0
          inc hl
          ld (hl),$ff
          inc hl
          ld (hl),$0f


          call kjt_page_in_video        ; page video RAM in at $2000-$3fff
          
          ld a,63
          ld (vreg_vidpage),a           ; read / writes to last VRAM page 

          ld hl,loading_msg
          ld de,$2000+$1800
          ld bc,$100
          ldir
          ld bc,$700
gfxlp     xor a
          ld (de),a
          inc de
          dec bc
          ld a,b
          or c
          jr nz,gfxlp
          
          call kjt_page_out_video       ; page video RAM out of $2000-$3fff
          ret

;-------------------------------------------------------------------------------------------------


load_config_file

	call push_dir_vol
	call get_cfg_file
	call pop_dir_vol
	ret


get_cfg_file

	 ld hl,config_file_buffer
	 ld bc,512
	 xor a
	 call kjt_bchl_memfill
         
         call goto_settings_dir
         ret nz
 
         ld hl,cfg_fn                            
         ld b,0
         ld ix,config_file_buffer
         call kjt_load_file                                
	 ret
	 

;-------------------------------------------------------------------------------------------------


set_default_slot_ascii_hex
	
	ld a,(machine_selection)
	ld hl,cfg_file_line1_txt
	call kjt_hex_byte_to_ascii
	ret
	
build_new_config_file

	ld de,config_file_buffer
	ld hl,cfg_file_line1_txt
	call copy_to_zero
	
	ld ix,machine_slot_list
	ld b,number_of_machines
	ld c,0
	
bcfgflp	push bc
	ld a,c
	add a,$30
	ld hl,cfg_file_line_b_txt
	ld (hl),a
	
	ld hl,cfg_file_line_a_txt
	ld a,(ix)
	call kjt_hex_byte_to_ascii
	dec hl
	dec hl	
	call copy_to_zero
	
	inc ix
	pop bc
	inc c
	djnz bcfgflp
	
	ld hl,config_file_buffer
	ex de,hl
	xor a
	sbc hl,de
	ld (config_file_size),hl
	ret
	
	
copy_to_zero

	ld a,(hl)
	or a
	ret z
	ld (de),a
	inc hl
	inc de
	jr copy_to_zero


config_file_size dw 0

;------------------------------------------------------------------------------------------------


parse_config_file

	ld hl,config_file_buffer
	call kjt_ascii_to_hex_word
	ret nz
	ld a,e
	ld (machine_selection),a
	
	ld ix,machine_slot_list
	ld b,number_of_machines
pcfgflp	call find13
	ret z
	push bc
	push ix
	call kjt_ascii_to_hex_word
	pop ix
	pop bc
	ret nz
	ld (ix),e
	inc ix
	djnz pcfgflp
	ret
	
find13	ld a,(hl)
	cp 13
	jr z,got13
	inc hl
	jr find13
got13	inc hl
	ld a,(hl)
	or a
	ret


;------------------------------------------------------------------------------------------------

get_machine_name

; Set machine in A
; Result: Address of machine name at HL

	push de
	sla a
	ld e,a
	ld d,0
	ld hl,machine_name_addrs
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	ret
	
	
	
get_machine_rom_filename

; Set machine in A
; Result: Address of machine name at HL

	push de
	sla a
	ld e,a
	ld d,0
	ld hl,machine_romfn_addrs
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	ret
		


get_machine_bits

; Set machine in A
; Result in A

	push de
	push hl
	ld e,a
	ld d,0
	ld hl,machine0_bits
	add hl,de
	ld a,(hl)
	pop hl
	pop de
	ret
	
	
get_machine_nvr_name

; Set nvr type in A
; Result: Address of nvr filename at HL
	
	push de
	ld a,(machine_selection)
	call get_nvr_type
	sla a
	ld e,a
	ld d,0
	ld hl,nvr_name_addrs
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	ret
	
	
get_machine_nvr_filename

; Set nvr type in A
; Result: Address of nvr filename at HL
	
	push de
	ld a,(machine_selection)
	call get_nvr_type
	sla a
	ld e,a
	ld d,0
	ld hl,nvr_filename_addrs
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	ret
	
	
	
get_nvr_type

; set machine in A
; A out = nvr type
	
	push bc
	call get_machine_bits				;returns NVR type in A
	bit 7,a
	jr nz,nvrpa
	and 7
	pop bc
	ret

nvrpa	and 7
	ld b,a
	call read_exp_pin
	add a,b
	pop bc
	ret



get_nvr_menu_mask_bits

;set A to nvr type
;A = nvr bits

	push hl
	push de
	ld e,a
	ld d,0
	ld hl,nvr_type0_opt_mask
	add hl,de
	ld a,(hl)
	pop de
	pop hl
	ret



get_machines_slot_address

; set machine in A
; HL = slot address

        push de
	ld e,a
        ld d,0
        ld hl,machine_slot_list
        add hl,de
	pop de
	ret
	
;-------------------------------------------------------------------------------------------------

show_custom_menu
	
	ld de,menu_wait
	ld hl,custom_menu_jps
	ld b,8
clmjplp	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	djnz clmjplp
	
        call inverse_video
        ld hl,banner_txt
        call kjt_print_string
        call normal_video

        ld hl,machine_txt
        call kjt_print_string

	ld a,(machine_selection)
        call get_machine_name
	call kjt_print_string
          
        call show_slot
	
	call new_line
	call new_line
	
	ld a,(machine_selection)
	call get_nvr_type
	call get_nvr_menu_mask_bits
	ld e,a
	
	ld d,$31
	ld ix,maskable_menu_addrs
	ld iy,custom_menu_jps
	
mmloop	srl e
	jr nc,nomline
	
	ld l,(ix)
	ld h,(ix+1)
	inc hl
	inc hl
	ld a,(hl)
	or a
	jr z,restofmenu
	dec hl
	dec hl
	
	push hl
	ld a,d
	ld hl,menu_numchr_txt+1
	ld (hl),a
	dec hl
	call kjt_print_string
	pop hl
	
	ld a,(hl)
	ld (iy),a
	inc hl
	ld a,(hl)
	inc hl
	ld (iy+1),a
	inc iy
	inc iy
		
	ld a,(hl)
	cp "*"
	jr nz,normtxt
	ld hl,boot_into_txt
	call kjt_print_string
	ld a,(machine_selection)
	call get_machine_nvr_name
	call kjt_print_string
	ld hl,cr_txt
normtxt	call kjt_print_string
	inc d
	
nomline	inc ix
	inc ix
	jr mmloop


restofmenu
	
	ld hl,fixed_menu_txt
	call kjt_print_string
	ret
	
;----------------------------------------------------------------------------------------

show_slot

	  ld a,(machine_selection)
	  call get_machines_slot_address
	  ld a,(hl)
          or a
          ret z
          ld hl,slot_value_txt
          call kjt_hex_byte_to_ascii
          ld hl,slot_txt
          call kjt_print_string
          ret

slot_txt            db " [Slot:"
slot_value_txt      db "00]",0
         
;-----------------------------------------------------------------------------------------------------------


maskable_menu1	dw go_basic
		db " Reset/boot machine (BASIC)",11,0

maskable_menu2  dw preload_tap
		db " Load .tap / .bin file & boot",11,0

maskable_menu3  dw boot_nvr
		db "*",0					;* = token, substituted by "BOOT INTO [NVR NAME]"
		
maskable_menu4	dw menu_wait
		db 0
		
maskable_menu5	dw menu_wait
		db 0
		
maskable_menu6	dw menu_wait
		db 0
		
maskable_menu7	dw menu_wait
		db 0
		
maskable_menu8	dw menu_wait
		db 0
		                              
fixed_menu_txt	db 11," S. Select a machine"
                db 11," C. Choose config slot for this machine"
                db 11," M. Make machine selection default"

                db 11,11," ESC - Quit to FLOS.",11,11,0

menu_numchr_txt db " x.",0


maskable_menu_addrs

		dw maskable_menu1
		dw maskable_menu2
		dw maskable_menu3
		dw maskable_menu4
		dw maskable_menu5
		dw maskable_menu6
		dw maskable_menu7
		dw maskable_menu8
	
	
custom_menu_jps	dw menu_wait
		dw menu_wait
		dw menu_wait
		dw menu_wait
		dw menu_wait
		dw menu_wait
		dw menu_wait
		dw menu_wait


;----------------------------------------------------------------------------------------

machine_selection	db 0              

machine_slot_list	ds 10,0             ;slot for machine 0, slot for machine 1, etc
			
;-------------------------------------------------------------------------------------------------


number_of_machines	equ 3			;max = 10 machines

machine0_name		db "Spectrum 48K",0
machine1_name  	 	db "Spectrum 128K",0
machine2_name   	db "Pentagon 128K",0
machine3_name		db " ",0
machine4_name		db " ",0
machine5_name		db " ",0
machine6_name   	db " ",0
machine7_name		db " ",0
machine8_name		db " ",0
machine9_name		db " ",0

machine0_romfn		db "vol0:spectrum/zxspec48.rom ",0
machine1_romfn		db "vol0:spectrum/zxspe128.rom ",0
machine2_romfn		db "vol0:spectrum/zxspe128.rom ",0
machine3_romfn		db " ",0
machine4_romfn		db " ",0
machine5_romfn		db " ",0
machine6_romfn		db " ",0
machine7_romfn		db " ",0
machine8_romfn		db " ",0
machine9_romfn		db " ",0

machine0_bits		db $80	; bit7=Sense EXP_B for NVR select offset (0 or 1), bits 2:0=NVR type
machine1_bits		db $82
machine2_bits		db $82
machine3_bits		db 0
machine4_bits		db 0
machine5_bits		db 0
machine6_bits		db 0
machine7_bits		db 0
machine8_bits		db 0
machine9_bits		db 0

nvr_type0_fn		db "vol0:spectrum/resi48k.nvr ",0
nvr_type1_fn		db "vol0:spectrum/esxdos.nvr ",0	
nvr_type2_fn		db "vol0:spectrum/resi128k.nvr ",0	
nvr_type3_fn		db "vol0:spectrum/esxdos.nvr ",0	
nvr_type4_fn		db " ",0
nvr_type5_fn		db " ",0	
nvr_type6_fn		db " ",0
nvr_type7_fn		db " ",0

nvr_type0_name	        db "RESIDOS (48K)",0
nvr_type1_name		db "ESXDOS",0
nvr_type2_name	        db "RESIDOS (128K)",0
nvr_type3_name		db "ESXDOS",0
nvr_type4_name		db " ",0
nvr_type5_name		db " ",0
nvr_type6_name		db " ",0
nvr_type7_name		db " ",0

nvr_type0_opt_mask	db %1111111
nvr_type1_opt_mask	db %1111100
nvr_type2_opt_mask	db %1111111
nvr_type3_opt_mask	db %1111100
nvr_type4_opt_mask	db %1111111
nvr_type5_opt_mask	db %1111100
nvr_type6_opt_mask	db %1111111
nvr_type7_opt_mask	db %1111111

;--------------------------------------------------------------------------------------------------------------------

nvr_filename_addrs	dw nvr_type0_fn
			dw nvr_type1_fn
			dw nvr_type2_fn
			dw nvr_type3_fn
			dw nvr_type4_fn
			dw nvr_type5_fn
			dw nvr_type6_fn
			dw nvr_type7_fn

nvr_name_addrs		dw nvr_type0_name
			dw nvr_type1_name
			dw nvr_type2_name
			dw nvr_type3_name
			dw nvr_type4_name
			dw nvr_type5_name
			dw nvr_type6_name
			dw nvr_type7_name

machine_romfn_addrs	dw machine0_romfn
			dw machine1_romfn
			dw machine2_romfn
			dw machine3_romfn
			dw machine4_romfn
			dw machine5_romfn
			dw machine6_romfn
			dw machine7_romfn
			dw machine8_romfn
			dw machine9_romfn	

machine_name_addrs	dw machine0_name
			dw machine1_name
			dw machine2_name
			dw machine3_name
			dw machine4_name
			dw machine5_name
			dw machine6_name
			dw machine7_name
			dw machine8_name
			dw machine9_name
		

;----------------------------------------------------------------------------------------

settings_dir        	db "vol0:settings",0
settings_txt		db "settings",0
cfg_fn              	db "EMU.CFG",0

cfg_file_line1_txt	db "00 ;Active machine",10,13,0
cfg_file_line_a_txt	db "00 ;Machine "
cfg_file_line_b_txt	db "0 Slot",10,13,0

cfg_file_size		dw 0

;----------------------------------------------------------------------------------------


cannot_find_txt     db "Cannot find: ",0

press_a_key_txt     db 11,11,"Press any key.",11,0

saving_cfg_txt      db 11,11,"OK, saving config file..",11,11,0

bad_fn_txt          db 11,"Can't find that file.",11,11,0

banner_txt          db "                              ",11
                    db "   Emulator Kickstart V0.10   ",11
                    db "                              ",11,0
          
machine_txt         db 11,"Selected machine: ",11,11," ",0

boot_into_txt	    db " Boot into ",0

;---------------------------------------------------------------------------------------------

eeprom_contents_txt db 11,"EEPROM contents:",11,11,0        

slot_prompt_txt     db 11,11,"Please enter the slot which contains",11
		    db "FPGA Config file for:" ,11,11,0

slot_prompt2_txt    db 11,11,"SLOT? :",0
	                  
error_txt           db 11,11,"THERE HAS BEEN AN ERROR!",0

slot_text           db " ",0
slot_number_text    db "xx - ",0
unknown_text        db "UNKNOWN",0
bootcode_text       db "BOOTCODE ETC",0

;-------------------------------------------------------------------------------------------------

loading_msg         incbin    "FLOS_based_programs\utils\emu\data\loading_txt.bin"

;------------------------------------------------------------------------------------------------

args_set            db 0
arg_string          dw 0

pen_colour          db 0
cursor_pos          dw 0

eeprom_id_byte      db 0
number_of_slots     db 4
working_slot        db 0

video_page          db 0
page_address        dw 0

length_hi           dw 0
length_lo           dw 0

read_bytes          dw 0

filename            ds 16,0

spectrum_dir        db "vol0:spectrum",0

restore_fn_addr     dw 0

dir_cache           dw 0

vram_load_addr_hi   db $0               ;bits 23:16 of the VRAM load address
vram_load_addr_lo   dw $0000            ;bits 15:0 of the VRAM load address

page_buffer         ds 256,0

load_buffer         ds buffer_size,0

;----------------------------------------------------------------------------------------------------

config_file_buffer ds 512,0

