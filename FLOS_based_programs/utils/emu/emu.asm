; EMU.exe - A boot util for emulators (only useful for V6Z80P v1.1)
; -----------------------------------------------------------------
;
; Currently supports:
; -------------------
;
; Alessandro's Cycle Perfect Spectrum 48 and 128 Emulators for V6Z80P v1.1
;
;
; Changes:
; --------
;
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

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

required_flos	equ $602
include 		"test_flos_version.asm"

required_osca	equ $671
include 		"test_osca_version.asm"

;----------------------------------------------------------------------------------------------

buffer_size	equ 512			
buffer_bank	equ 0

spectrum_rom_addr	equ $8000
spectrum_rom_bank	equ 1

;----------------------------------------------------------------------------------------------

	call kjt_get_pen
	ld (pen_colour),a
	
	call kjt_get_dir_cluster		; save current dir
	push de
	
	xor a
	call kjt_force_bank
	
	call kjt_root_dir
	ld hl,settings_dir
	call kjt_change_dir	
	jr nz,lcfgbad
	
	ld hl,cfg_fn			; load config file (if available)
	ld b,0
	ld ix,cfg_line1_txt
	call kjt_load_file				

	call update_vars_from_cfg_file	

lcfgbad	pop de
	call kjt_set_dir_cluster		; restore original dir


;----------------------------------------------------------------------------------------------

	ld a,2
	out (sys_io_dir),a			;make sure exp B jumper is in input mode
	call read_expb
	ld (residos_esxdos),a		;0 = residos, 1 = esxdos
	
;----------------------------------------------------------------------------------------------
	
start	call update_vars_from_cfg_file

menu_text	call kjt_clear_screen
	call show_menu
	
menu_wait	call read_expb			;has jumper exp_b changed?
	ld hl,residos_esxdos
	cp (hl)
	jr z,read_key			
	ld (hl),a
	jr menu_text		
		
read_key	call kjt_get_key
	cp $76
	jr nz,not_quit
	xor a
	ret
	
not_quit	ld a,b
	cp "1"
	jr z,option1
	cp "2"
	jr z,option2
	cp "3"
	jr z,option3
	cp "4"
	jr z,option4
	cp "5"
	jr z,option5
	cp "6"
	jr z,option6
	jr menu_wait

	
option1	ld a,(residos_esxdos)
	or a
	jr nz,menu_wait
	call reconfigure
	jr error_menu	
	
option2	ld a,(residos_esxdos)
	or a
	jr nz,menu_wait
	call load_tap_reconf
	jr nz,error_menu
	jr menu_wait			;no need to redraw menu, requester code replaces previous chars
	
option3	call residos_reconf 
	jr nz,error_menu
	jr menu_text
	
option4	call change_machine	
	jr nz,error_menu
	jr start
	
option5	call set_cfg_slot
	jr nz,error_menu
	jr start

option6	call save_config_file
	jr nz,error_menu
	jr start

error_menu

	ld hl,error_txt
	call kjt_print_string

	call press_a_key
	jp start


;-----------------------------------------------------------------------------------------


show_menu
	call inverse_video
	ld hl,banner_txt
	call kjt_print_string
	call normal_video

	ld hl,machine_txt
	call kjt_print_string

	ld hl,m0_txt
	ld a,(machine_selection)
	or a
	jr z,shws48
	ld hl,m1_txt
shws48	call kjt_print_string
	
	call show_slot
	
	ld hl,menu_txt_norm		;options 1/2 only work in Residos mode
	ld a,(residos_esxdos)
	or a
	jr z,mt_norm
	ld hl,menu_txt_esxdos
mt_norm	call kjt_print_string
		
	ld a,(residos_esxdos)
	ld l,a
	ld h,0
	add hl,hl
	ld de,menu_nvr_list
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	call kjt_print_string
	ld hl,menu_txt2
	call kjt_print_string
	ret
	

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
	
			
;------------------------------------------------------------------------------------------
	
	
reconfigure

	call check_reconf_slot		
	ret nz				; if not set up correctly exit

	call load_rom			; load the appropriate ROM
	ret nz				

	call copy_bank_switch_code_to_vram
		
go_cfg	ld a,$88				; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		; send address low
	ld a,$00		
	call send_byte_to_pic		; send address mid
	
	ld a,(machine_selection)
	ld e,a
	ld d,0
	ld hl,slot_list
	add hl,de
	ld a,(hl)
	sla a
	call send_byte_to_pic		; send address high

	ld a,$88				; send reconfigure command
	call send_byte_to_pic
	ld a,$a1
	call send_byte_to_pic


stop_here	jr stop_here
	
	
;------------------------------------------------------------------------------------------


load_tap_reconf

	call check_reconf_slot		; if config slot not set up correctly exit
	ret nz
	
retrylr	ld b,8				; invoke load requester
	ld c,2
	xor a
	ld hl,0
	call load_requester
	jr z,ftapok
	
	cp $ff				; aborted?
	ret z

ld_error	or a
	jr z,hw_err1
	
	call file_error_requester
	jr retrylr

hw_err1	call hw_error_requester
	jr retrylr


ftapok	push hl
	push ix				; put $0,$0 at the end of tap files to assist
	pop bc				; tap player logic in Spectrum config determine the end
	push iy
	pop de
	xor a
	call write_vram_flat
	ld bc,1
	add iy,bc
	jr nc,addmswok
	inc ix
addmswok	push ix
	pop bc
	push iy
	pop de
	xor a
	call write_vram_flat
	pop hl

		
ldreq_ok1	call copy_filename
	
	call kjt_clear_screen
	
	call load_rom			; load the [spectrum] ROM
	ret nz

	call show_loading_msg
	
	ld de,0
	ld (vram_load_addr_lo),de		; normally, load file to VRAM $00000

	ld hl,filename
	ld b,11
fnddot	ld a,(hl)
	cp "."
	jr z,gotdot
	inc hl
	djnz fnddot
	jr not_tap
gotdot	inc hl
	ld a,(hl)
	cp "t"
	jr z,got_t
	cp "T"
	jr nz,not_tap
got_t	inc hl
	ld a,(hl)
	cp "a"
	jr z,got_a
	cp "A"
	jr nz,not_tap
got_a	inc hl
	ld a,(hl)
	cp "p"
	jr z,is_tap
	cp "P"
	jr nz,not_tap
	
is_tap	call copy_bank_switch_code_to_vram	; but if it is a .tap file, copy the bank switch code to $00000
	ld de,$14				; and load the .tap file after it (VRAM $00014)
	ld (vram_load_addr_lo),de
	
not_tap	ld a,0
	ld (vram_load_addr_hi),a
	call load_to_vram			
	ret nz
		
vrlok	jp go_cfg			


load_quit	xor a
	inc a
	ret
	
;------------------------------------------------------------------------------------------


residos_reconf
	
	call check_reconf_slot
	ret nz				; if  not set up correctly, exit
	
	ld a,(residos_esxdos)
	or a
	jr z,resimode
	ld hl,restore_esx_fn
	jr gotnvrfn	
	
resimode	ld hl,restore_48_fn
	ld a,(machine_selection)
	or a
	jr z,gotnvrfn
	ld hl,restore_128_fn
gotnvrfn	ld (restore_fn_addr),hl
	
	call kjt_root_dir			; look in root dir and root:spectrum dir
	
	ld hl,(restore_fn_addr)
	push hl
	call kjt_find_file
	pop hl
	jp z,ldreq_ok1
	
	ld hl,spectrum_dir
	call kjt_change_dir
	jr nz,norestf
	
	ld hl,(restore_fn_addr)
	push hl
	call kjt_find_file
	pop hl
	jp z,ldreq_ok1
	
norestf	ld hl,cannot_find_txt
	call kjt_print_string
	ld hl,(restore_fn_addr)
	call kjt_print_string
	xor a
	inc a
	ret
	

;------------------------------------------------------------------------------------------

	
check_reconf_slot
	
	ld a,(machine_selection)
	ld e,a
	ld d,0
	ld hl,slot_list
	add hl,de
	ld a,(hl)
	or a
	jr z,set_cfg_slot			; If Spectrum Emu slot for the chosen machine hasnt been set.
	xor a				; prompt for slot
	ret
	

set_cfg_slot
	
	call show_eeprom_slot_contents
	
	ld hl,slot_prompt_txt
	call kjt_print_string
	
	ld hl,slot_prompt_m0_txt
	ld a,(machine_selection)
	or a
	jr z,gslotm0
	ld hl,slot_prompt_m1_txt
gslotm0	call kjt_print_string
	
	ld a,2
	call kjt_get_input_string
	or a
	jr nz,gotstr
	inc a				; return with ZF not set: error
	ret
	
gotstr	push hl
	call kjt_ascii_to_hex_word		; is entered text a valid number (result in DE)?
	pop hl
	or a
	ret nz
	
	ld hl,cfg_line2_txt			; copy value to appropriate line in config file
	ld a,(machine_selection)
	or a
	jr z,prin48
	ld hl,cfg_line3_txt
prin48	ld a,e
	call kjt_hex_byte_to_ascii
	
	call update_vars_from_cfg_file
	
	
save_config_file
	
	call kjt_root_dir			;save config file "EMU.CFG" in ROOT:SETTINGS dir
	
gsdir	ld hl,settings_dir
	call kjt_change_dir	
	jr z,setdok
	cp $23
	ret nz
	ld hl,settings_dir			;make the dir
	call kjt_make_dir
	jr gsdir
	
setdok	ld hl,cfg_fn			;remove old cfg file (if exists)
	call kjt_erase_file
	
	ld hl,saving_cfg_txt
	call kjt_print_string
	
	ld hl,cfg_fn
	ld ix,cfg_line1_txt
	ld b,0
	ld c,0
	ld de,cfg_txt_end-cfg_line1_txt
	call kjt_save_file
	ret nz

	call kjt_root_dir	
			
	xor a
	ret
	

;---------------------------------------------------------------------------------------
	
	
change_machine

	ld a,(machine_selection)
	xor 1
	ld (machine_selection),a
	add a,$30
	ld (cfg_line1_txt+1),a
	xor a
	ret

		
;---------------------------------------------------------------------------------------


update_vars_from_cfg_file

	ld hl,cfg_line1_txt
	call kjt_ascii_to_hex_word
	or a
	ret nz
	ld a,e
	ld (machine_selection),a

	ld hl,cfg_line2_txt		
	call kjt_ascii_to_hex_word
	or a
	ret nz
	ld a,e
	ld (slot_list),a
	
	ld hl,cfg_line3_txt
	call kjt_ascii_to_hex_word
	or a
	ret nz
	ld a,e
	ld (slot_list+1),a
	
	xor a
	ret
	
;----------------------------------------------------------------------------------------


copy_filename

	push bc
	push de
	push hl
	ld b,12
	ld de,filename
cpyfnlp	ld a,(hl)
	or a
	jr z,cpyfndone
	ld (de),a
	inc hl
	inc de
	djnz cpyfnlp
cpyfndone	pop hl
	pop de
	pop bc
	ret

;----------------------------------------------------------------------------------------

show_slot

	ld a,(machine_selection)
	ld e,a
	ld d,0
	ld hl,slot_list
	add hl,de
	ld a,(hl)
	or a
	ret z
	ld hl,slot_value_txt
	call kjt_hex_byte_to_ascii
	
	ld hl,slot_txt
	call kjt_print_string
	ret
	

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
id_loop	ld (working_slot),a
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
	
	ret


;--------------------------------------------------------------------------------------


get_eeprom_type

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

	cp $bf				; If SST25VF type EEPROM is present, we'll have received
	jr nz,got_eid			; manufacturer's ID ($BF) not the capacity

	ld b,0				; wait a while to ensure PIC is ready for command
deloop1	djnz deloop1
	
	ld a,$88				; Use alternate "Get EEPROM ID" command to find ID 
	call send_byte_to_pic		
	ld a,$6c
	call send_byte_to_pic
   	ld hl,eeprom_id_byte			
	call read_pic_byte
	ld a,(hl)
	
got_eid	ld (eeprom_id_byte),a	
	sub $10
	ld b,a
	ld a,1
slotslp	sla a
	djnz slotslp
	ld (number_of_slots),a
	ret

no_id	xor a				;error reading eeprom ID
	inc a
	ret
	
			
;----------------------------------------------------------------------------------------
	
read_pic_byte

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
	ret

;----------------------------------------------------------------------------------------

read_expb	
	in a,(sys_io_pins)			
	cpl
	rrca
	and 1
	ret

;-----------------------------------------------------------------------------------------

load_to_vram


	call vram_load_main
	ret z
	
	ld hl,$f00		;if error, make text red
	ld (palette+2),hl
	ret

	
vram_load_main
	

	ld a,(vram_load_addr_hi)	; H:DE = VRAM load address
	ld h,a
	ld de,(vram_load_addr_lo)

	ld a,e			; convert linear address to 8KB page and address between 2000-3fff
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
	
range_ok	ld hl,filename		; does filename exist?
	call kjt_find_file
	ret nz
	ld (length_hi),ix		; ix:iy = size of file (bytes-to-go)
	ld (length_lo),iy
	
	ld a,(video_page)	
	ld (vreg_vidpage),a

b_loop	ld de,(length_hi)		; de:hl = bytes to go..
	ld hl,(length_lo)
	ld bc,buffer_size		; ix:iy = default load length (buffer size)	
	xor a
	sbc hl,bc
	jr nc,btg_ok		
	ex de,hl
	ld bc,0
	sbc hl,bc			; do the borrow for hi word
	ex de,hl
	jr nc,btg_ok
	ld bc,buffer_size
	add hl,bc			; bytes-to-go is less than a full buffer: only load the bytes required
	ld (read_bytes),hl
	call fill_buffer
	call copy_buffer_to_vram
	xor a
	ret
	
btg_ok	ld (length_hi),de		; update bytes-to-go
	ld (length_lo),hl
	ld bc,buffer_size
	ld (read_bytes),bc
	call fill_buffer
	call copy_buffer_to_vram
	
	ld hl,$222		; flash loading message
	ld a,(length_lo+1)
	and $40
	jr z,got_col
	ld hl,$aaa
got_col	ld (palette+2),hl
	
	jr b_loop


;----------------------------------------------------------------------------------------------------------

fill_buffer


	ld bc,(read_bytes)
	ld a,b			; if read bytes count = 0, dont do anything
	or c
	ret z

	push bc
	pop iy
	ld ix,0
	call kjt_set_load_length	; ix:iy = load length (normally a full buffer)

	ld hl,load_buffer
	ld b,buffer_bank
	call kjt_force_load		; load to a buffer in sys ram
	ret
	
;----------------------------------------------------------------------------------------------------------

	
copy_buffer_to_vram
	
	call kjt_page_in_video
	
	ld bc,(read_bytes)
	ld a,b			; if read bytes count = 0, dont do anything
	or c
	jr z,cpy_done	

	ld hl,(page_address)
	add hl,bc
	ld a,h
	and $c0
	jr z,sp_copy		; will the bytes in buffer spill into a new video page?
	
	ld de,(page_address)	; always between 2000-3fff
	ld hl,load_buffer	
	ld bc,(read_bytes)
cpylp	ldi			; this is the slow copy, when the video page buffer will
	bit 6,d			; change during the write
	jr z,samepage
	ld d,$20
	ld a,(video_page)		; next video page
	inc a
	cp $40
	jr nc,bad_addr
	ld (video_page),a
	ld (vreg_vidpage),a
samepage	ld a,b
	or c
	jr nz,cpylp
	ld (page_address),de
	jr cpy_done
	
sp_copy	ld de,(page_address)	; always between 2000-3fff	
	ld hl,load_buffer		; copy the buffered bytes to VRAM
	ld bc,(read_bytes)	
	ldir			; this is the faster copy when the video page wont be changed
	ld (page_address),de

cpy_done	call kjt_page_out_video
	xor a
	ret
	
bad_addr	call kjt_page_out_video
	xor a			
	inc a
	ret
	
;----------------------------------------------------------------------------------------------

load_rom

;	ld hl,load_rom_txt			;Commented out as there is barely time for
;	call kjt_print_string		;it to be displayed before the system reconfigures

	call kjt_get_dir_cluster
	ld (dir_cache),de
	call kjt_root_dir
	ld hl,spectrum_dir
	call kjt_change_dir

	ld hl,spectrum48_rom_fn
	ld a,(machine_selection)
	or a
	jr z,s48romreq
	ld hl,spectrum128_rom_fn
s48romreq	ld ix,spectrum_rom_addr
	ld b,spectrum_rom_bank
	call kjt_load_file
	push af	
	ld de,(dir_cache)
	call kjt_set_dir_cluster
	pop af
	ret z
	
	ld hl,cannot_find_txt		;Couldn't find ROM file message
	call kjt_print_string
	ld hl,spectrum48_rom_fn
	ld a,(machine_selection)
	or a
	jr z,s48romnf
	ld hl,spectrum128_rom_fn
s48romnf	call kjt_print_string
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
bscc_lp	ld a,(hl)
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

	incbin "bank_switch_code.bin"

end_of_bank_switch_code


;-------------------------------------------------------------------------------------------------

include "eeprom_routines.asm"
include "file_requesters.asm"

;----------------------------------------------------------------------------------------


show_loading_msg

	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$f0
	ld (vreg_window),a		; set y window size/position (48 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$aa
	ld (vreg_window),a		; set x window size/position (256 pixels)
	
	ld a,0
	ld (vreg_yhws_bplcount),a	; set 1 bitplane display
		
	ld a,0
	ld (vreg_vidctrl),a		; set bitmap mode + normal border + video enabled

	ld hl,$f800
	ld (bitplane0a_loc),hl	; start address of video datafetch for window [15:0]
	ld a,7
	ld (bitplane0a_loc+2),a	; start address of video datafetch for window [18:16]


	ld hl,palette		; background = black, colour 1 = white
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),$ff
	inc hl
	ld (hl),$0f


	call kjt_page_in_video	; page video RAM in at $2000-$3fff
	
	ld a,63
	ld (vreg_vidpage),a		; read / writes to last VRAM page 

	ld hl,loading_msg
	ld de,$2000+$1800
	ld bc,$100
	ldir
	ld bc,$700
gfxlp	xor a
	ld (de),a
	inc de
	dec bc
	ld a,b
	or c
	jr nz,gfxlp
	
	call kjt_page_out_video	; page video RAM out of $2000-$3fff
	ret

;-----------------------------------------------------------------------------------

loading_msg

	incbin	"loading_txt.bin"

;------------------------------------------------------------------------------------


cfg_fn		db "EMU.CFG",0

spectrum_dir	db "spectrum",0
settings_dir	db "settings",0

cannot_find_txt	db "Cannot find: ",0
restore_48_fn	db "RESI48K.NVR",0
restore_128_fn	db "RESI128K.NVR",0
restore_esx_fn	db "ESXDOS.NVR",0

spectrum48_rom_fn	db "ZXSPEC48.ROM",0
spectrum128_rom_fn	db "ZXSPE128.ROM",0

load_rom_txt	db 11,"Loading ROM file..",11,11,0

press_a_key_txt	db 11,11,"Press any key.",11,0

saving_cfg_txt	db 11,11,"OK, saving config file..",11,11,0

filename_txt	ds 16,0	

bad_fn_txt	db 11,"Can't find that file.",11,11,0

banner_txt	db "                              ",11
		db "   Emulator Kickstart V0.05   ",11
		db "                              ",11,0
	
machine_txt	db 11,"Selected machine: ",11,11," ",0

m0_txt		db "SPECTRUM 48",0			;machine type $00
m1_txt		db "SPECTRUM 128",0			;machine type $01



		
menu_txt_norm	db 11,11," 1. Reset/boot machine (BASIC).",11
		db " 2. Load .tap /.bin file & boot.",11,0
		
menu_txt_esxdos	db 11,11," 1. N/A in ESXDOS mode.",11
		db " 2. N/A in ESXDOS mode.",11,0
		
menu_nvr0		db " 3. Boot into RESIDOS (.nvr)",11,0
menu_nvr1		db " 3. Boot into ESXDOS (.nvr)",11,0
		
		
menu_txt2		db " 4. Change selected machine.",11
		db " 5. Set config slot for emulator.",11
		db " 6. Set machine selection as default.",11,11

		db " ESC - Quit to FLOS.",11,11,0

menu_nvr_list	dw menu_nvr0,menu_nvr1





eeprom_contents_txt	db 11,"EEPROM contents:",11,11,0	

slot_prompt_txt	db 11,11,"Please enter the slot which contains..",11,11,0
		
slot_prompt_m0_txt	db "Spectrum 48 FPGA config file :",0		;machine type $00
slot_prompt_m1_txt	db "Spectrum 128 FPGA config file :",0		;machine type $01
		
cfg_line1_txt	db "00 ;Active machine",10,13
cfg_line2_txt  	db "00 ;Spectrum 48 Slot",10,13
cfg_line3_txt	db "00 ;Spectrum 128 Slot",10,13
cfg_txt_end 	db 0

slot_txt		db " [Slot:"
slot_value_txt	db "00]",0

error_txt		db 11,11,"THERE HAS BEEN AN ERROR!",0

slot_text		db " ",0
slot_number_text	db "xx - ",0
unknown_text	db "UNKNOWN",0
bootcode_text	db "BOOTCODE ETC",0

;-------------------------------------------------------------------------------------------------

residos_esxdos	db 0

pen_colour	db 0
cursor_pos	dw 0

eeprom_id_byte	db 0
number_of_slots	db 4
working_slot	db 0

machine_selection	db 0		;0=Spec 48, 1= Spec 128
slot_list		db 0,0		;slot for 48, slot for 128

video_page	db 0
page_address	dw 0

length_hi		dw 0
length_lo		dw 0

read_bytes	dw 0

filename		ds 16,0

restore_fn_addr	dw 0

dir_cache		dw 0

vram_load_addr_hi	db $0		;bits 23:16 of the VRAM load address
vram_load_addr_lo	dw $0000		;bits 15:0 of the VRAM load address

page_buffer	ds 256,0

load_buffer	ds buffer_size,0

;-------------------------------------------------------------------------------------------------
