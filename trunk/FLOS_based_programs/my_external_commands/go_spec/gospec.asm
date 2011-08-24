;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;----------------------------------------------------------------------------------------------

buffer_size	equ 512			
buffer_bank	equ 0

vram_load_addr_hi	equ $0		;bits 23:16 of the VRAM load address
vram_load_addr_lo	equ $0000		;bits 15:0 of the VRAM load address

spectrum_rom_addr	equ $8000
spectrum_rom_bank	equ 1

;----------------------------------------------------------------------------------------------

	push hl			; save argument location
	
	call kjt_get_dir_cluster	; save current dir
	push de
	ld a,0
	call kjt_force_bank
	call kjt_root_dir
	ld hl,spectrum_dir
	call kjt_change_dir	
	ld hl,cfg_fn
	ld b,0
	ld ix,cfg_txt
	call kjt_load_file		; load config file (if available)	
	call kjt_root_dir
	call put_slot_in_menu	; sets slot (if valid)

	pop de
	call kjt_set_dir_cluster	; restore original dir
	
	call check_reconf_slot	; if the slot hasn't been set, ask now
	
	pop hl			; restore argument location
	jr z,find_args		; was the slot set?
	ld hl,slot_not_set_txt
	jr err_quit
	
find_args	ld a,(hl)			; examine name argument text, if encounter 0: give up
	or a			
	jp z,no_args
	cp " "			; ignore leading spaces...
	jr nz,got_args
	inc hl
	jr find_args

got_args	push hl			; look for specified file
	call kjt_find_file
	pop hl		
	jp z,ldreq_ok1		; load spectrum rom etc and restart if found
	
	ld hl,bad_fn_txt		; else show an error message
err_quit	call kjt_print_string
	xor a
	ret


no_args

;----------------------------------------------------------------------------------------------
	

start	call kjt_clear_screen	
	call put_slot_in_menu
	
menu	ld hl,options_txt
	call kjt_print_string
	
menu_wait	call kjt_wait_key_press
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
	jr menu_wait

	
option1	call reconfigure
	jr error_menu	
	
option2	call load_tap_reconf
	jr nz,error_menu
	jr start
	
option3	call restore_reconf 
	jr error_menu
	
option4	call set_cfg_slot
	jr z,start


error_menu

	ld hl,error_txt
	call kjt_print_string

	call press_a_key
	jp start

;-----------------------------------------------------------------------------------------


press_a_key

	ld hl,press_a_key_txt
	call kjt_print_string
	call kjt_wait_key_press
	ret
	
			
;------------------------------------------------------------------------------------------
	
	
reconfigure

	call check_reconf_slot		
	ret nz				; if still not set up correctly exit

	call load_spectrum_rom		; load the spectrum ROM
	ret nz				
		
go_cfg	ld a,$88				; send "set config base" command
	call send_byte_to_pic
	ld a,$b8
	call send_byte_to_pic
	ld a,$00			
	call send_byte_to_pic		; send address low
	ld a,$00		
	call send_byte_to_pic		; send address mid
	ld a,(slot_number)
	sla a
	call send_byte_to_pic		; send address high

	ld a,$88				; send reconfigure command
	call send_byte_to_pic
	ld a,$a1
	call send_byte_to_pic

	nop				; should never actaully return as FPFA will be
	nop				; reconfiguring
	ret
	
	
;------------------------------------------------------------------------------------------


load_tap_reconf

	call check_reconf_slot		; if still not set up correctly exit
	ret nz
	
retrylr	ld b,8				; invoke load requester
	ld c,2
	xor a
	ld hl,0
	call load_requester
	jr z,ldreq_ok1
	
	cp $ff				; aborted?
	ret z

ld_error	or a
	jr z,hw_err1
	
	call file_error_requester
	jr retrylr

hw_err1	call hw_error_requester
	jr retrylr

	
ldreq_ok1	call copy_filename
	
	call kjt_clear_screen
	
	call load_spectrum_rom		; load the spectrum ROM
	ret nz
	
	call load_to_vram			
	ret nz
		
vrlok	jr go_cfg			


load_quit	xor a
	inc a
	ret
	
;------------------------------------------------------------------------------------------


restore_reconf
	
	call check_reconf_slot
	ret nz				; if still not set up correctly exit
	
	call kjt_root_dir			; assume restore file is in root dir
	
	ld hl,restore_fn
	push hl
	call kjt_find_file
	pop hl
	jr z,ldreq_ok1
	
	ld hl,no_restore_txt
	call kjt_print_string
	xor a
	inc a
	ret
	
;------------------------------------------------------------------------------------------

	
check_reconf_slot
	
	ld a,(slot_number)
	or a
	jr z,set_cfg_slot			; has Spectrum Emu slot been set?
	xor a
	ret
	
set_cfg_slot

	ld hl,slot_prompt_txt
	call kjt_print_string
	
	call kjt_get_input_string
	or a
	jr nz,gotstr
	inc a
	ret
	
gotstr	push hl
	call kjt_ascii_to_hex_word
	pop hl
	or a
	ret nz
	
	ld a,e
	ld (slot_number),a
	
	ld hl,cfg_txt
	call kjt_hex_byte_to_ascii


	call kjt_root_dir			;save config in ROOT:/SPECTRUM dir
	ld hl,spectrum_dir
	call kjt_change_dir	

	ld hl,cfg_fn			;remove old cfg file
	call kjt_erase_file
	
	ld hl,cfg_fn
	ld ix,cfg_txt
	ld b,0
	ld c,0
	ld de,cfg_txt_end-cfg_txt
	call kjt_save_file
	ret nz

	call kjt_root_dir	
		
	ld hl,cfg_saved_txt
	call kjt_print_string
	
	call press_a_key	
	
	xor a
	ret

;---------------------------------------------------------------------------------------

put_slot_in_menu

	ld hl,cfg_txt			; has Spectrum Emu slot been set?
	call kjt_ascii_to_hex_word
	or a
	ret nz
	ld a,e
	ld (slot_number),a
	
	ld hl,(cfg_txt)
	ld (slot_txt),hl
	ld hl,slot_txt+2
	ld bc,7
	ld a," "
	call kjt_bchl_memfill
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

load_to_vram

	ld h,vram_load_addr_hi	; H:DE = VRAM load address
	ld de,vram_load_addr_lo

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

load_spectrum_rom

	ld hl,load_rom_txt
	call kjt_print_string

	call kjt_get_dir_cluster
	ld (dir_cache),de
	call kjt_root_dir
	ld hl,spectrum_dir
	call kjt_change_dir

	ld hl,spectrum_rom_fn
	ld ix,spectrum_rom_addr
	ld b,spectrum_rom_bank
	call kjt_load_file
	push af	
	ld de,(dir_cache)
	call kjt_set_dir_cluster
	pop af
	ret z
	
	ld hl,no_rom_txt
	call kjt_print_string
	xor a
	inc a
	ret
	
;------------------------------------------------------------------------------------------	

send_byte_to_pic

pic_data_input	equ 0	; from FPGA to PIC
pic_clock_input	equ 1	; from FPGA to PIC

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

	push bc
	push de
	ld c,a			
	ld d,8
bit_loop	xor a
	rl c
	jr nc,zero_bit
	set pic_data_input,a
zero_bit	out (sys_pic_comms),a	; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a	; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1		; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a	; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2		; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60			; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp		; allows time for PIC to act on received byte
	pop de			; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			
	
;-------------------------------------------------------------------------------------------------

include "file_requesters.asm"

;----------------------------------------------------------------------------------------

no_restore_txt	db "Cannot find:"
restore_fn	db "RAMDUMP.BIN",0

spectrum_dir	db "spectrum",0

no_rom_txt	db 11,"Cannot find:"
spectrum_rom_fn	db "ZXSPEC48.ROM",0

cfg_fn		db "GOSPEC.CFG",0

load_rom_txt	db 11,"Loading Spectrum ROM",11,0

press_a_key_txt	db 11,11,"Press any key.",11,0

cfg_saved_txt	db 11,11,"Config file saved..",11,11,0

filename_txt	ds 16,0	

bad_fn_txt	db 11,"Can't find that file.",11,11,0

slot_not_set_txt	db 11,"Please set the Spectrum EEPROM slot,",11,11,0


options_txt

	db "***************************************",11
	db "* Spectrum Emulator Kickstarter v0.01 *",11
	db "***************************************",11
	db 11,11
	db "Emulator EEPROM slot: "
slot_txt	db "Undefined",11,11
	db "1.Reconfigure to Spectrum.",11
	db "2.Load a .tap file and reconfigure.",11
	db "3.Restore RAM and reconfigure.",11
	db "4.Set Spectrum emulator config slot.",11,11
	db "ESC - quit",11
	db 11,11,0

	
slot_prompt_txt	db "Which EEPROM slot contains the",11,"Spectrum emulator? :",0
		
cfg_txt	  	db "xx ; <- Spectrum Emu Slot",10,13
cfg_txt_end 	db 0

error_txt		db 11,11,"ERROR!",0

slot_number	db 0	

video_page	db 0
page_address	dw 0

length_hi		dw 0
length_lo		dw 0

read_bytes	dw 0

filename		ds 16,0

dir_cache		dw 0

load_buffer	ds buffer_size,0

;-------------------------------------------------------------------------------------------------
