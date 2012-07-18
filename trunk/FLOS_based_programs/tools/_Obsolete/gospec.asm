; GoSpec.exe - A boot util for Alessandro's Cycle Perfect Spectrum Emulator (V6Z80P v1.1 only)

; Changes:

; v0.07 - fixed for FLOS v593 (kjt_get_input_string limiter)

; v0.06 - restore system filename "ramdump.bin" changed to "residos.nvr"
; to use with Garry Lancaster's update of Residos. Note: Awaiting further
; Residos update from Garry - needs to init SD Cards after restart.

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

	call copy_bank_switch_code_to_vram
		
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


stop_here	jr stop_here
	
	
;------------------------------------------------------------------------------------------


load_tap_reconf

	call check_reconf_slot		; if still not set up correctly exit
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
	
	call load_spectrum_rom		; load the spectrum ROM
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
	
	ld a,2
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
	ld hl,$fff
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

no_restore_txt	db "Cannot find:"
restore_fn	db "residos.nvr",0

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
	db "* Spectrum Emulator Kickstarter v0.07 *",11
	db "***************************************",11
	db 11,11
	db "Emulator EEPROM slot: "
slot_txt	db "Undefined",11,11
	db "1.Reconfigure to Spectrum 48",11
	db "2.Load .tap /.bin file & reconfigure.",11
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

vram_load_addr_hi	db $0		;bits 23:16 of the VRAM load address
vram_load_addr_lo	dw $0000		;bits 15:0 of the VRAM load address

load_buffer	ds buffer_size,0

;-------------------------------------------------------------------------------------------------
